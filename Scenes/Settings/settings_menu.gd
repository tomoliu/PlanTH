extends Control

const _RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1366, 768),
	Vector2i(1400, 900),
	Vector2i(1024, 1080),
	Vector2i(1920, 1080),
]
const _MAIN_MENU_PATH: String = "res://Scenes/MainMenu/main_menu.tscn"
const _KEYBIND_PATH: String = "res://Scenes/Settings/keybind_menu.tscn"

@onready var resolution_dropdown: OptionButton = $SettingsContainer/ResolutionRow/ResolutionDropdown
@onready var fullscreen_btn: Button = $SettingsContainer/WindowModeRow/WindowModeButtons/FullscreenBtn
@onready var borderless_btn: Button = $SettingsContainer/WindowModeRow/WindowModeButtons/BorderlessBtn
@onready var windowed_btn: Button = $SettingsContainer/WindowModeRow/WindowModeButtons/WindowedBtn
@onready var vsync_check: CheckBox = $SettingsContainer/VsyncRow/VsyncCheck
@onready var keybind_button: Button = $SettingsContainer/KeybindRow/KeybindButton
@onready var cancel_button: Button = $SettingsContainer/ButtonsRow/CancelButton
@onready var save_button: Button = $SettingsContainer/ButtonsRow/SaveButton

var _temp_window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED

func _ready() -> void:
	_populate_resolutions()
	_load_current_settings()
	
	fullscreen_btn.pressed.connect(_on_window_mode_pressed.bind(DisplayServer.WINDOW_MODE_FULLSCREEN))
	borderless_btn.pressed.connect(_on_window_mode_pressed.bind(DisplayServer.WINDOW_MODE_WINDOWED))
	windowed_btn.pressed.connect(_on_window_mode_pressed.bind(DisplayServer.WINDOW_MODE_WINDOWED))
	keybind_button.pressed.connect(_on_open_keybinds)
	cancel_button.pressed.connect(_on_cancel)
	save_button.pressed.connect(_on_save)

func _populate_resolutions() -> void:
	for i: int in range(_RESOLUTIONS.size()):
		var res: Vector2i = _RESOLUTIONS[i]
		resolution_dropdown.set_item_text(i, "%dx%d" % [res.x, res.y])

func _load_current_settings() -> void:
	# 分辨率
	var current_res: Vector2i = ConfigManager.resolution
	for i: int in range(_RESOLUTIONS.size()):
		if _RESOLUTIONS[i] == current_res:
			resolution_dropdown.select(i)
			break
	
	# 窗口模式
	_temp_window_mode = ConfigManager.window_mode
	_refresh_window_mode_buttons()
	
	# 垂直同步
	vsync_check.button_pressed = ConfigManager.vsync_enabled

func _on_window_mode_pressed(mode: int) -> void:
	_temp_window_mode = mode
	ConfigManager.apply_window_mode(mode)
	_refresh_window_mode_buttons()

func _refresh_window_mode_buttons() -> void:
	fullscreen_btn.disabled = (_temp_window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	borderless_btn.disabled = (_temp_window_mode == DisplayServer.WINDOW_MODE_WINDOWED)
	windowed_btn.disabled = (_temp_window_mode == DisplayServer.WINDOW_MODE_WINDOWED)

## 点击保存：将临时设置写入 ConfigManager 并持久化到 config.ini。
func _on_save() -> void:
	var idx: int = resolution_dropdown.get_selected_id()
	if idx >= 0 and idx < _RESOLUTIONS.size():
		ConfigManager.apply_resolution(_RESOLUTIONS[idx])
	
	ConfigManager.apply_window_mode(_temp_window_mode)
	ConfigManager.apply_vsync(vsync_check.button_pressed)
	ConfigManager.save_config()
	
	_return_to_main_menu()

## 取消：丢弃临时设置，直接返回。
func _on_cancel() -> void:
	ConfigManager.apply_window_mode(ConfigManager.window_mode)
	ConfigManager.apply_vsync(ConfigManager.vsync_enabled)
	if ConfigManager.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(ConfigManager.resolution)
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	var result: int = get_tree().change_scene_to_file(_MAIN_MENU_PATH)
	if result != OK:
		push_error("SettingsMenu: failed to return to main menu, error code " + str(result))

func _on_open_keybinds() -> void:
	var result: int = get_tree().change_scene_to_file(_KEYBIND_PATH)
	if result != OK:
		push_error("SettingsMenu: failed to open keybinds, error code " + str(result))
