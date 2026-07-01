extends Control

const _MOVE_SPEED: float = 300.0
const _PROJECTILE_SPEED: float = 250.0
const _ENEMY_SPEED: float = 240.0
const _ENEMY_HP: int = 3
const _ENEMY_FIRE_INTERVAL: float = 2.0
const _PLAYER_RADIUS: float = 20.0
const _PROJECTILE_RADIUS: float = 10.0
const _ENEMY_RADIUS: float = 20.0
const _GRAZE_RADIUS: float = _PLAYER_RADIUS * 1.6
const _GRAZE_COOLDOWN: float = 1.0
const _MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu/main_menu.tscn"
const _ENEMY_CONFIG_PATH: String = "res://data/json/敌人配置表.json"
const _ENEMY_ATTR_PATH: String = "res://data/json/敌人属性表.json"

@onready var player_indicator: Label = $PlayerIndicator
@onready var instructions: Label = $Instructions
@onready var score_label: Label = $ScoreLabel
@onready var hp_label: Label = $HPLabel
@onready var gm_button: Button = $GMButton
@onready var gm_panel: ColorRect = $GMPanel
@onready var invincible_button: Button = $GMPanel/GMGrid/InvincibleButton
@onready var gm_close_button: Button = $GMPanel/CloseButton
@onready var gm_diff_increase: Button = $GMPanel/GMGrid/GMDiffIncrease
@onready var gm_diff_decrease: Button = $GMPanel/GMGrid/GMDiffDecrease
@onready var pause_panel: ColorRect = $PausePanel
@onready var resume_btn: Button = $PausePanel/PauseVBox/ResumeBtn
@onready var return_menu_btn: Button = $PausePanel/PauseVBox/ReturnMenuBtn
@onready var toast_container: VBoxContainer = $ToastContainer

var _player_position: Vector2 = Vector2.ZERO
var _player_hp: int = 6
var _player_max_hp: int = 6
var _projectile_positions: Array[Vector2] = []
var _projectile_velocities: Array[Vector2] = []
var _projectile_graze_cooldowns: Array[float] = []
var _projectile_was_in_graze: Array[bool] = []
var _score: int = 0
var _is_invincible: bool = false
var _is_dead: bool = false
var _is_paused: bool = false
var _enemy_count: int = 0

## 敌人数据
var _enemy_positions: Array[Vector2] = []
var _enemy_fire_cooldowns: Array[float] = []
var _enemy_hp: Array[int] = []

func _ready() -> void:
	$Background.queue_free()
	_player_position = size * 0.5
	_player_hp = ConfigManager.player_initial_hp
	_player_max_hp = ConfigManager.player_initial_hp
	_update_hp_label()
	_update_indicator_position()
	_load_enemy_config()
	ConfigManager.gm_toggled.connect(_toggle_gm)
	gm_button.pressed.connect(_on_gm_button_pressed)
	gm_close_button.pressed.connect(func(): gm_panel.hide())
	invincible_button.pressed.connect(_on_invincible_button_pressed)
	gm_diff_increase.pressed.connect(ConfigManager.gm_increase_difficulty)
	gm_diff_decrease.pressed.connect(ConfigManager.gm_decrease_difficulty)
	ConfigManager.toast_shown.connect(_show_toast)
	resume_btn.pressed.connect(_resume_game)
	return_menu_btn.pressed.connect(_return_to_menu_from_pause)
	gm_panel.hide()
	
	ConfigManager.last_scene_path = "res://Scenes/Battle/battle_scene.tscn"

func _load_enemy_config() -> void:
	if not FileAccess.file_exists(_ENEMY_CONFIG_PATH):
		_enemy_count = 1
		_spawn_enemies()
		return
	var file: FileAccess = FileAccess.open(_ENEMY_CONFIG_PATH, FileAccess.READ)
	var raw: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if raw == null or not raw is Dictionary:
		_enemy_count = 1
		_spawn_enemies()
		return
	var data: Dictionary = raw as Dictionary
	var levels: Array = data.get("levels", []) as Array
	# difficulty 0 = default
	for level: Variant in levels:
		if level is Dictionary:
			var d: Dictionary = level as Dictionary
			if d.get("difficulty", -1) == 0:
				_enemy_count = d.get("enemy_count", 1) as int
				break
	_spawn_enemies()

func _spawn_enemies() -> void:
	for i: int in range(_enemy_count):
		var angle: float = TAU * i / maxi(_enemy_count, 1)
		var spawn_pos: Vector2 = size * 0.5 + Vector2.RIGHT.rotated(angle) * min(size.x, size.y) * 0.3
		_enemy_positions.append(spawn_pos)
		_enemy_fire_cooldowns.append(0.0)
		_enemy_hp.append(_ENEMY_HP)

func _process(delta: float) -> void:
	if _is_dead or _is_paused:
		return
	
	_handle_player_movement(delta)
	_handle_enemies(delta)
	_move_projectiles(delta)
	_check_player_collision()
	_check_enemy_collision()
	_tick_graze_cooldowns(delta)
	_check_graze()
	queue_redraw()

func _handle_player_movement(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		_player_position += direction * _MOVE_SPEED * delta
		_player_position.x = clampf(_player_position.x, _PLAYER_RADIUS, size.x - _PLAYER_RADIUS)
		_player_position.y = clampf(_player_position.y, _PLAYER_RADIUS, size.y - _PLAYER_RADIUS)
		_update_indicator_position()

func _handle_enemies(delta: float) -> void:
	for i: int in range(_enemy_positions.size()):
		var enemy_pos: Vector2 = _enemy_positions[i]
		# 八向移动靠近玩家
		var direction: Vector2 = (_player_position - enemy_pos).normalized()
		_enemy_positions[i] += direction * _ENEMY_SPEED * delta
		
		# 边界约束
		_enemy_positions[i].x = clampf(_enemy_positions[i].x, _ENEMY_RADIUS, size.x - _ENEMY_RADIUS)
		_enemy_positions[i].y = clampf(_enemy_positions[i].y, _ENEMY_RADIUS, size.y - _ENEMY_RADIUS)
		
		# 敌人射击
		_enemy_fire_cooldowns[i] -= delta
		if _enemy_fire_cooldowns[i] <= 0.0:
			_enemy_fire_cooldowns[i] += _ENEMY_FIRE_INTERVAL
			_spawn_enemy_projectile(_enemy_positions[i])

func _spawn_enemy_projectile(origin: Vector2) -> void:
	var direction: Vector2 = (_player_position - origin).normalized()
	_projectile_positions.append(origin)
	_projectile_velocities.append(direction * _PROJECTILE_SPEED)
	_projectile_graze_cooldowns.append(0.0)
	_projectile_was_in_graze.append(false)

func _move_projectiles(delta: float) -> void:
	var margin: float = _PROJECTILE_RADIUS
	var max_x: float = size.x - margin
	var max_y: float = size.y - margin
	var i: int = _projectile_positions.size() - 1
	while i >= 0:
		_projectile_positions[i] += _projectile_velocities[i] * delta
		var pos: Vector2 = _projectile_positions[i]
		if pos.x < margin or pos.x > max_x or pos.y < margin or pos.y > max_y:
			_projectile_positions.remove_at(i)
			_projectile_velocities.remove_at(i)
			_projectile_graze_cooldowns.remove_at(i)
			_projectile_was_in_graze.remove_at(i)
		i -= 1

func _check_player_collision() -> void:
	if _is_invincible:
		return
	for i: int in range(_projectile_positions.size()):
		var dist: float = _player_position.distance_to(_projectile_positions[i])
		if dist < _PLAYER_RADIUS + _PROJECTILE_RADIUS:
			_on_player_death()
			return

func _check_enemy_collision() -> void:
	if _is_invincible:
		return
	for i: int in range(_enemy_positions.size()):
		var dist: float = _player_position.distance_to(_enemy_positions[i])
		if dist < _PLAYER_RADIUS + _ENEMY_RADIUS:
			_player_hp -= 1
			_update_hp_label()
			if _player_hp <= 0:
				_on_player_death()
				return
			# 碰触后将敌人弹开
			var push_dir: Vector2 = (_enemy_positions[i] - _player_position).normalized()
			_enemy_positions[i] = _player_position + push_dir * (_PLAYER_RADIUS + _ENEMY_RADIUS + 10.0)

func _on_player_death() -> void:
	_is_dead = true
	instructions.text = "GAME OVER"
	var t: Tween = create_tween()
	t.tween_interval(1.5)
	t.tween_callback(_return_to_main_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gm_toggle"):
		get_viewport().set_input_as_handled()
		ConfigManager.gm_toggled.emit()
		return
	if event.is_action_pressed("ui_cancel") and not _is_dead:
		get_viewport().set_input_as_handled()
		if _is_paused:
			_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	_is_paused = true
	pause_panel.visible = true

func _resume_game() -> void:
	_is_paused = false
	pause_panel.visible = false

func _return_to_menu_from_pause() -> void:
	ConfigManager.last_scene_path = "res://Scenes/Battle/battle_scene.tscn"
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_SCENE_PATH)
	if result != OK:
		push_error("BattleScene: failed to return to main menu, error code " + str(result))

func _update_hp_label() -> void:
	hp_label.text = "❤ %d/%d" % [_player_hp, _player_max_hp]

func _update_indicator_position() -> void:
	player_indicator.position = _player_position - player_indicator.size * 0.5

func _tick_graze_cooldowns(delta: float) -> void:
	for i: int in range(_projectile_graze_cooldowns.size()):
		if _projectile_graze_cooldowns[i] > 0.0:
			_projectile_graze_cooldowns[i] = maxf(0.0, _projectile_graze_cooldowns[i] - delta)

func _check_graze() -> void:
	var hit_range: float = _PLAYER_RADIUS + _PROJECTILE_RADIUS
	var graze_range: float = _GRAZE_RADIUS + _PROJECTILE_RADIUS
	for i: int in range(_projectile_positions.size()):
		var dist: float = _player_position.distance_to(_projectile_positions[i])
		var in_graze: bool = dist >= hit_range and dist < graze_range
		if _projectile_was_in_graze[i] and not in_graze and _projectile_graze_cooldowns[i] <= 0.0:
			_score += 1
			_projectile_graze_cooldowns[i] = _GRAZE_COOLDOWN
			score_label.text = "Score: " + str(_score)
		_projectile_was_in_graze[i] = in_graze

func _on_gm_button_pressed() -> void:
	gm_panel.visible = not gm_panel.visible

func _toggle_gm() -> void:
	gm_panel.visible = not gm_panel.visible

func _show_toast(msg: String) -> void:
	var label: Label = Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	toast_container.add_child(label)
	toast_container.move_child(label, 0)
	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(label.queue_free)

func _on_invincible_button_pressed() -> void:
	_is_invincible = not _is_invincible
	invincible_button.text = "关闭玩家无敌" if _is_invincible else "开启玩家无敌"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12, 1))
	draw_circle(_player_position, _GRAZE_RADIUS, Color(0.3, 0.7, 1.0, 0.15))
	draw_arc(_player_position, _GRAZE_RADIUS, 0.0, TAU, 64, Color(0.3, 0.7, 1.0, 0.3), 1.0, true)
	
	# Draw projectiles
	for i: int in range(_projectile_positions.size()):
		var pos: Vector2 = _projectile_positions[i]
		draw_circle(pos, _PROJECTILE_RADIUS + 2.0, Color.RED)
		draw_circle(pos, _PROJECTILE_RADIUS, Color.ORANGE)
	
	# Draw enemies
	for i: int in range(_enemy_positions.size()):
		var pos: Vector2 = _enemy_positions[i]
		draw_circle(pos, _ENEMY_RADIUS + 2.0, Color(0.7, 0.2, 0.2, 1.0))
		draw_circle(pos, _ENEMY_RADIUS, Color(0.9, 0.3, 0.3, 1.0))

func _return_to_main_menu() -> void:
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_SCENE_PATH)
	if result != OK:
		push_error("BattleScene: failed to return to main menu, error code " + str(result))
