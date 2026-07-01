extends Control

const _CHARACTER_TABLE_PATH: String = "res://data/json/角色表.json"
const _MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu/main_menu.tscn"
const _DIALOGUE_SCENE_PATH: String = "res://Scenes/Dialogue/dialogue_scene.tscn"

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var back_button: Button = $TopBar/BackButton
@onready var depart_button: Button = $TopBar/DepartButton
@onready var character_name_label: Label = $InfoPanel/CharacterName
@onready var hp_label: Label = $InfoPanel/StatsRow/HpLabel
@onready var gold_label: Label = $InfoPanel/StatsRow/GoldLabel
@onready var description_label: Label = $InfoPanel/DescriptionLabel
@onready var ability_label: Label = $InfoPanel/AbilityLabel
@onready var thumbnail_1: Button = $ThumbnailContainer/CharacterThumb1
@onready var thumbnail_2: Button = $ThumbnailContainer/CharacterThumb2
@onready var difficulty_bar: HBoxContainer = $DifficultyBar
@onready var difficulty_left: Button = $DifficultyBar/DifficultyLeftArrow
@onready var difficulty_right: Button = $DifficultyBar/DifficultyRightArrow
@onready var difficulty_label: Label = $DifficultyBar/DifficultyLabel
@onready var difficulty_desc: Label = $DifficultyDesc
@onready var gm_panel: ColorRect = $GMPanel
@onready var gm_close_btn: Button = $GMPanel/GMCloseBtn
@onready var gm_increase_btn: Button = $GMPanel/GMGrid/GMIncreaseBtn
@onready var gm_decrease_btn: Button = $GMPanel/GMGrid/GMDecreaseBtn
@onready var toast_container: VBoxContainer = $ToastContainer

var _characters: Array[Dictionary] = []
var _selected_index: int = 0
var _selected_difficulty: int = 0
var _difficulty_descs: Array[String] = []

func _ready() -> void:
	_load_character_table()
	_load_difficulty_descs()
	back_button.pressed.connect(_on_back_pressed)
	depart_button.pressed.connect(_on_depart_pressed)
	thumbnail_1.pressed.connect(_select_character.bind(0))
	thumbnail_2.pressed.connect(_select_character.bind(1))
	difficulty_left.pressed.connect(_on_diff_left)
	difficulty_right.pressed.connect(_on_diff_right)
	ConfigManager.gm_toggled.connect(_toggle_gm)
	gm_close_btn.pressed.connect(func(): gm_panel.visible = false)
	gm_increase_btn.pressed.connect(ConfigManager.gm_increase_difficulty)
	gm_decrease_btn.pressed.connect(ConfigManager.gm_decrease_difficulty)
	ConfigManager.toast_shown.connect(_show_toast)
	
	if _characters.is_empty():
		push_error("CharacterSelect: no character data found in table.")
		return
	
	_refresh_thumbnails()
	_select_character(0)
	_refresh_difficulty()

## 从 JSON 配置表读取角色数据。
func _load_character_table() -> void:
	if not FileAccess.file_exists(_CHARACTER_TABLE_PATH):
		push_error("CharacterSelect: character table not found at %s" % _CHARACTER_TABLE_PATH)
		return
	
	var file: FileAccess = FileAccess.open(_CHARACTER_TABLE_PATH, FileAccess.READ)
	var json_text: String = file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("CharacterSelect: failed to parse character table JSON.")
		return
	
	var data: Dictionary = parsed as Dictionary
	if not data.has("characters") or not data["characters"] is Array:
		push_error("CharacterSelect: invalid character table structure.")
		return
	
	var raw_characters: Array = data["characters"] as Array
	for i: int in range(raw_characters.size()):
		var raw_character: Variant = raw_characters[i]
		if raw_character is Dictionary:
			var character: Dictionary = raw_character
			_characters.append(character)

## 切换选中角色并更新 UI。
func _select_character(index: int) -> void:
	if index < 0 or index >= _characters.size():
		push_error("CharacterSelect: invalid character index %d (size=%d)" % [index, _characters.size()])
		return
	
	_selected_index = index
	var character: Dictionary = _characters[index]
	
	var character_name: String = character.get("name", "未知角色") as String
	var background_path: String = character.get("lobby_background", "") as String
	var initial_hp: int = character.get("initial_hp", 5) as int
	var initial_gold: int = character.get("initial_gold", 50) as int
	
	character_name_label.text = character_name
	hp_label.text = "❤ %d/%d" % [initial_hp, initial_hp]
	gold_label.text = "💰 %d" % initial_gold
	description_label.text = "角色描述占位文本。"
	ability_label.text = "角色能力占位文本。"
	
	if background_path.is_empty():
		push_warning("CharacterSelect: character '%s' has no lobby_background path." % character_name)
		return
	
	var texture: Texture2D = load(background_path) as Texture2D
	if texture == null:
		push_error("CharacterSelect: failed to load background texture at %s" % background_path)
		return
	
	background_texture.texture = texture

## 难度选择：只有通关后才显示，默认难度1。
func _load_difficulty_descs() -> void:
	var path: String = "res://data/json/敌人配置表.json"
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var raw: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if raw == null or not raw is Dictionary:
		return
	var levels: Array = (raw as Dictionary).get("levels", []) as Array
	_difficulty_descs.resize(11)
	for lv: Variant in levels:
		if lv is Dictionary:
			var d: Dictionary = lv as Dictionary
			var idx: int = d.get("difficulty", 0) as int
			if idx >= 0 and idx <= 10:
				_difficulty_descs[idx] = d.get("condition", "") as String

func _refresh_difficulty() -> void:
	_selected_difficulty = SaveManager.difficulty_level
	if _selected_difficulty > 0:
		difficulty_bar.visible = true
	else:
		difficulty_bar.visible = false
	_diff_label_update()

func _diff_label_update() -> void:
	difficulty_label.text = "难度 " + str(_selected_difficulty)
	difficulty_left.modulate.a = 1.0 if _selected_difficulty > 0 else 0.0
	difficulty_left.disabled = _selected_difficulty <= 0
	difficulty_right.modulate.a = 1.0 if _selected_difficulty < SaveManager.difficulty_level else 0.0
	difficulty_right.disabled = _selected_difficulty >= SaveManager.difficulty_level
	if _selected_difficulty < _difficulty_descs.size():
		difficulty_desc.text = _difficulty_descs[_selected_difficulty]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gm_toggle"):
		get_viewport().set_input_as_handled()
		ConfigManager.gm_toggled.emit()

func _on_diff_left() -> void:
	_selected_difficulty = maxi(_selected_difficulty - 1, 0)
	_diff_label_update()

func _on_diff_right() -> void:
	_selected_difficulty = mini(_selected_difficulty + 1, SaveManager.difficulty_level)
	_diff_label_update()

## 根据读取到的角色数据刷新底部缩略图按钮文本。
func _refresh_thumbnails() -> void:
	if _characters.size() > 0:
		thumbnail_1.text = _characters[0].get("name", "角色1") as String
	if _characters.size() > 1:
		thumbnail_2.text = _characters[1].get("name", "角色2") as String

func _on_back_pressed() -> void:
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_SCENE_PATH)
	if result != OK:
		push_error("CharacterSelect: failed to return to main menu, error code " + str(result))

func _on_depart_pressed() -> void:
	var character: Dictionary = _characters[_selected_index]
	ConfigManager.player_initial_hp = character.get("initial_hp", 5) as int
	ConfigManager.player_initial_gold = character.get("initial_gold", 50) as int
	ConfigManager.selected_difficulty = _selected_difficulty
	var result: int = get_tree().change_scene_to_file(_DIALOGUE_SCENE_PATH)
	if result != OK:
		push_error("CharacterSelect: failed to enter dialogue scene, error code " + str(result))

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
