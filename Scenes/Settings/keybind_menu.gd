extends Control

const _ACTIONS: Array[String] = ["move_up", "move_down", "move_left", "move_right"]
const _LABELS: Array[String] = ["上", "下", "左", "右"]
const _SETTINGS_PATH: String = "res://Scenes/Settings/settings_menu.tscn"

@onready var bindings_container: VBoxContainer = $BindingsContainer
@onready var back_button: Button = $BottomButtons/BackButton
@onready var save_button: Button = $BottomButtons/SaveButton

var _bind_buttons: Array[Button] = []
var _listening_index: int = -1

func _ready() -> void:
	_create_binding_rows()
	back_button.pressed.connect(_on_back)
	save_button.pressed.connect(_on_save)
	_refresh_labels()

func _create_binding_rows() -> void:
	for i: int in range(_ACTIONS.size()):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		var label: Label = Label.new()
		label.custom_minimum_size = Vector2(60, 30)
		label.text = _LABELS[i]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		
		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_bind_pressed.bind(i))
		_bind_buttons.append(btn)
		row.add_child(btn)
		
		bindings_container.add_child(row)

func _refresh_labels() -> void:
	for i: int in range(_bind_buttons.size()):
		_bind_buttons[i].text = ConfigManager.get_key_label(_ACTIONS[i])

func _on_bind_pressed(index: int) -> void:
	_listening_index = index
	_bind_buttons[index].text = "按下新按键..."
	_bind_buttons[index].disabled = true

func _input(event: InputEvent) -> void:
	if _listening_index < 0:
		return
	
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		ConfigManager.rebind_key(_ACTIONS[_listening_index], event.keycode)
		_bind_buttons[_listening_index].disabled = false
		_listening_index = -1
		_refresh_labels()
	elif event is InputEventMouseButton and event.pressed:
		# 鼠标点击取消监听
		_bind_buttons[_listening_index].disabled = false
		_listening_index = -1
		_refresh_labels()

func _on_back() -> void:
	_return_to_settings()

func _on_save() -> void:
	ConfigManager.save_config()
	_return_to_settings()

func _return_to_settings() -> void:
	var result: int = get_tree().change_scene_to_file(_SETTINGS_PATH)
	if result != OK:
		push_error("KeybindMenu: failed to return to settings, error code " + str(result))
