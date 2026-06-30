extends Node

const CONFIG_PATH: String = "res://config.ini"

## 当前生效的显示设置，外部通过 ConfigManager 访问。
var resolution: Vector2i = Vector2i(1400, 900)
var window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var vsync_enabled: bool = true

func _ready() -> void:
	_setup_default_input_actions()
	_load_config()
	_apply_display()

## 确保基础输入动作存在，缺失则用默认映射创建。
func _setup_default_input_actions() -> void:
	var defaults: Dictionary = {
		"move_up": [
			_create_key_event(KEY_W),
			_create_key_event(KEY_UP),
			_create_joypad_button_event(JOY_BUTTON_DPAD_UP),
			_create_joypad_axis_event(JOY_AXIS_LEFT_Y, -1.0),
		],
		"move_down": [
			_create_key_event(KEY_S),
			_create_key_event(KEY_DOWN),
			_create_joypad_button_event(JOY_BUTTON_DPAD_DOWN),
			_create_joypad_axis_event(JOY_AXIS_LEFT_Y, 1.0),
		],
		"move_left": [
			_create_key_event(KEY_A),
			_create_key_event(KEY_LEFT),
			_create_joypad_button_event(JOY_BUTTON_DPAD_LEFT),
			_create_joypad_axis_event(JOY_AXIS_LEFT_X, -1.0),
		],
		"move_right": [
			_create_key_event(KEY_D),
			_create_key_event(KEY_RIGHT),
			_create_joypad_button_event(JOY_BUTTON_DPAD_RIGHT),
			_create_joypad_axis_event(JOY_AXIS_LEFT_X, 1.0),
		],
	}
	for action: String in defaults:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
			for event: InputEvent in defaults[action]:
				InputMap.action_add_event(action, event)

func _create_key_event(keycode: Key) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.keycode = keycode
	return e

func _create_joypad_button_event(button: JoyButton) -> InputEventJoypadButton:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = button
	return e

func _create_joypad_axis_event(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	return e

## 获取指定动作的键盘按键名，用于 UI 显示。
func get_key_label(action_name: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for event: InputEvent in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
	return "未绑定"

## 将指定动作的键盘绑定替换为新按键。
func rebind_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		return
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	var new_events: Array[InputEvent] = []
	for event: InputEvent in events:
		if not event is InputEventKey:
			new_events.append(event)
	new_events.append(_create_key_event(keycode))
	InputMap.action_erase_events(action_name)
	for event: InputEvent in new_events:
		InputMap.action_add_event(action_name, event)

## 从 config.ini 读取按键绑定。
func _load_input_bindings(config: ConfigFile) -> void:
	if not config.has_section("input"):
		return
	for action: String in config.get_section_keys("input"):
		if InputMap.has_action(action):
			var raw: Variant = config.get_value("input", action)
			if raw is int:
				rebind_key(action, raw)

## 将按键绑定写入 config.ini。
func _save_input_bindings(config: ConfigFile) -> void:
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				config.set_value("input", action, event.keycode)
				break

## 从 config.ini 读取设置，缺失项保持默认值。
func _load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	if err != OK:
		return
	
	if config.has_section_key("display", "resolution"):
		var parts: PackedStringArray = config.get_value("display", "resolution").split("x")
		if parts.size() == 2:
			resolution = Vector2i(int(parts[0]), int(parts[1]))
	
	if config.has_section_key("display", "window_mode"):
		window_mode = config.get_value("display", "window_mode")
	
	if config.has_section_key("display", "vsync"):
		vsync_enabled = config.get_value("display", "vsync")
	
	_load_input_bindings(config)

## 将当前设置写入 config.ini 持久化。
func save_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "resolution", "%dx%d" % [resolution.x, resolution.y])
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "vsync", vsync_enabled)
	_save_input_bindings(config)
	config.save(CONFIG_PATH)

## 将当前显示参数应用到引擎。
func _apply_display() -> void:
	DisplayServer.window_set_mode(window_mode)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)

## 更新分辨率（用于设置界面修改后应用）。
func apply_resolution(size: Vector2i) -> void:
	resolution = size
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(size)

## 更新窗口模式。
func apply_window_mode(mode: int) -> void:
	window_mode = mode
	DisplayServer.window_set_mode(mode)

## 更新垂直同步。
func apply_vsync(enabled: bool) -> void:
	vsync_enabled = enabled
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
