extends Control

const _MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu/main_menu.tscn"
const _BATTLE_SCENE_PATH: String = "res://Scenes/Battle/battle_scene.tscn"

@onready var gear_button: Button = $GearButton
@onready var menu_panel: ColorRect = $MenuPanel
@onready var continue_button: Button = $MenuPanel/MenuVBox/ContinueButton
@onready var inventory_button: Button = $MenuPanel/MenuVBox/InventoryButton
@onready var settings_button: Button = $MenuPanel/MenuVBox/SettingsButton
@onready var return_to_menu_button: Button = $MenuPanel/MenuVBox/ReturnToMenuButton
@onready var exit_game_button: Button = $MenuPanel/MenuVBox/ExitGameButton
@onready var choice_1: Button = $DialoguePanel/ChoicesVBox/Choice1
@onready var choice_2: Button = $DialoguePanel/ChoicesVBox/Choice2
@onready var choice_3: Button = $DialoguePanel/ChoicesVBox/Choice3

func _ready() -> void:
	gear_button.pressed.connect(_toggle_menu)
	continue_button.pressed.connect(_on_continue)
	inventory_button.pressed.connect(_on_exit_game)
	settings_button.pressed.connect(_on_exit_game)
	exit_game_button.pressed.connect(_on_exit_game)
	return_to_menu_button.pressed.connect(_on_return_to_main_menu)
	choice_1.pressed.connect(_on_exit_game)
	choice_2.pressed.connect(_on_exit_game)
	choice_3.pressed.connect(_on_enter_battle)

func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible

func _on_continue() -> void:
	menu_panel.visible = false

func _on_return_to_main_menu() -> void:
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_SCENE_PATH)
	if result != OK:
		push_error("DialogueScene: failed to return to main menu, error code " + str(result))

func _on_exit_game() -> void:
	get_tree().quit()

func _on_enter_battle() -> void:
	var result: int = get_tree().change_scene_to_file(_BATTLE_SCENE_PATH)
	if result != OK:
		push_error("DialogueScene: failed to enter battle scene, error code " + str(result))
