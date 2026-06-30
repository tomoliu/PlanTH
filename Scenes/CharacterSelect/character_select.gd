extends Control

const _CHARACTER_TABLE_PATH: String = "res://data/tables/角色表.json"
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
@onready var difficulty_easy: Button = $InfoPanel/DifficultySection/DifficultyButtons/DifficultyEasy
@onready var difficulty_normal: Button = $InfoPanel/DifficultySection/DifficultyButtons/DifficultyNormal
@onready var difficulty_hard: Button = $InfoPanel/DifficultySection/DifficultyButtons/DifficultyHard
@onready var difficulty_hell: Button = $InfoPanel/DifficultySection/DifficultyButtons/DifficultyHell

var _characters: Array[Dictionary] = []
var _selected_index: int = 0
var _selected_difficulty: int = 1  # 0=简单, 1=普通, 2=困难, 3=地狱

func _ready() -> void:
	_load_character_table()
	back_button.pressed.connect(_on_back_pressed)
	depart_button.pressed.connect(_on_depart_pressed)
	thumbnail_1.pressed.connect(_select_character.bind(0))
	thumbnail_2.pressed.connect(_select_character.bind(1))
	difficulty_easy.pressed.connect(_select_difficulty.bind(0))
	difficulty_normal.pressed.connect(_select_difficulty.bind(1))
	difficulty_hard.pressed.connect(_select_difficulty.bind(2))
	difficulty_hell.pressed.connect(_select_difficulty.bind(3))
	
	if _characters.is_empty():
		push_error("CharacterSelect: no character data found in table.")
		return
	
	_refresh_thumbnails()
	_select_character(0)
	_select_difficulty(1)

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
	
	character_name_label.text = character_name
	hp_label.text = "❤ 75/75"
	gold_label.text = "💰 99"
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

## 选中难度等级并高亮对应按钮。
func _select_difficulty(index: int) -> void:
	_selected_difficulty = index
	_refresh_difficulty_buttons()

## 更新难度按钮的视觉状态：当前选中的按钮禁用（保持高亮态），其余启用。
func _refresh_difficulty_buttons() -> void:
	var buttons: Array[Button] = [difficulty_easy, difficulty_normal, difficulty_hard, difficulty_hell]
	for i: int in range(buttons.size()):
		buttons[i].disabled = (i == _selected_difficulty)

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
	var result: int = get_tree().change_scene_to_file(_DIALOGUE_SCENE_PATH)
	if result != OK:
		push_error("CharacterSelect: failed to enter dialogue scene, error code " + str(result))
