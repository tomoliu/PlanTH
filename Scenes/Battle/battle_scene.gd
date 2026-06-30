extends Control

const _MOVE_SPEED: float = 300.0
const _PROJECTILE_SPEED: float = 250.0
const _FIRE_INTERVAL: float = 1.0
const _EMITTER_EDGE_RATIO: float = 0.1
const _PLAYER_RADIUS: float = 20.0
const _PROJECTILE_RADIUS: float = 10.0
const _MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu/main_menu.tscn"

@onready var player_indicator: Label = $PlayerIndicator
@onready var instructions: Label = $Instructions
@onready var emitter_tl: Label = $EmitterTL
@onready var emitter_tr: Label = $EmitterTR
@onready var emitter_bl: Label = $EmitterBL
@onready var emitter_br: Label = $EmitterBR

var _player_position: Vector2 = Vector2.ZERO
var _emitter_positions: Array[Vector2] = []
var _fire_cooldowns: Array[float] = []
var _projectile_positions: Array[Vector2] = []
var _projectile_velocities: Array[Vector2] = []
var _is_dead: bool = false

func _ready() -> void:
	$Background.queue_free()
	_player_position = size * 0.5
	_update_indicator_position()
	_setup_emitters()

func _setup_emitters() -> void:
	var w: float = size.x
	var h: float = size.y
	var r: float = _EMITTER_EDGE_RATIO
	_emitter_positions = [
		Vector2(w * r, h * r),
		Vector2(w * (1.0 - r), h * r),
		Vector2(w * r, h * (1.0 - r)),
		Vector2(w * (1.0 - r), h * (1.0 - r)),
	]
	_fire_cooldowns = [0.0, 0.0, 0.0, 0.0]
	var emitters: Array[Label] = [emitter_tl, emitter_tr, emitter_bl, emitter_br]
	for i: int in range(emitters.size()):
		emitters[i].position = _emitter_positions[i] - emitters[i].size * 0.5

func _process(delta: float) -> void:
	if _is_dead:
		return
	
	_handle_player_movement(delta)
	_handle_emitters(delta)
	_move_projectiles(delta)
	_check_player_collision()
	queue_redraw()

func _handle_player_movement(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		_player_position += direction * _MOVE_SPEED * delta
		_player_position.x = clampf(_player_position.x, _PLAYER_RADIUS, size.x - _PLAYER_RADIUS)
		_player_position.y = clampf(_player_position.y, _PLAYER_RADIUS, size.y - _PLAYER_RADIUS)
		_update_indicator_position()

func _handle_emitters(delta: float) -> void:
	for i: int in range(_emitter_positions.size()):
		_fire_cooldowns[i] -= delta
		if _fire_cooldowns[i] <= 0.0:
			_fire_cooldowns[i] += _FIRE_INTERVAL
			_fire_projectile(_emitter_positions[i])

func _fire_projectile(origin: Vector2) -> void:
	var direction: Vector2 = (_player_position - origin).normalized()
	var projectile_position: Vector2 = origin
	var projectile_velocity: Vector2 = direction * _PROJECTILE_SPEED
	_projectile_positions.append(projectile_position)
	_projectile_velocities.append(projectile_velocity)

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
		i -= 1

func _check_player_collision() -> void:
	for i: int in range(_projectile_positions.size()):
		var dist: float = _player_position.distance_to(_projectile_positions[i])
		if dist < _PLAYER_RADIUS + _PROJECTILE_RADIUS:
			_on_player_death()
			return

func _on_player_death() -> void:
	_is_dead = true
	instructions.text = "GAME OVER"
	var t: Tween = create_tween()
	t.tween_interval(1.5)
	t.tween_callback(_return_to_main_menu)

func _return_to_main_menu() -> void:
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_SCENE_PATH)
	if result != OK:
		push_error("BattleScene: failed to return to main menu, error code " + str(result))

func _update_indicator_position() -> void:
	player_indicator.position = _player_position - player_indicator.size * 0.5

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12, 1))
	for i: int in range(_projectile_positions.size()):
		var pos: Vector2 = _projectile_positions[i]
		draw_circle(pos, _PROJECTILE_RADIUS + 2.0, Color.RED)
		draw_circle(pos, _PROJECTILE_RADIUS, Color.ORANGE)
