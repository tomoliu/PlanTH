extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var version_label: Label = $VersionLabel
@onready var quit_confirm_panel: ColorRect = $QuitConfirmPanel
@onready var quit_yes_button: Button = $QuitConfirmPanel/QuitYesButton
@onready var quit_no_button: Button = $QuitConfirmPanel/QuitNoButton
@onready var save_switch_button: Button = $SaveSwitchButton
@onready var save_slot_panel: ColorRect = $SaveSlotPanel
@onready var slot_1_btn: Button = $SaveSlotPanel/SaveSlotVBox/Slot1Btn
@onready var slot_2_btn: Button = $SaveSlotPanel/SaveSlotVBox/Slot2Btn
@onready var slot_3_btn: Button = $SaveSlotPanel/SaveSlotVBox/Slot3Btn
@onready var slot_cancel_btn: Button = $SaveSlotPanel/SaveSlotVBox/SlotCancelBtn
@onready var save_confirm_panel: ColorRect = $SaveConfirmPanel
@onready var confirm_label: Label = $SaveConfirmPanel/ConfirmLabel
@onready var confirm_yes_btn: Button = $SaveConfirmPanel/ConfirmYesBtn
@onready var confirm_no_btn: Button = $SaveConfirmPanel/ConfirmNoBtn
@onready var gm_panel: ColorRect = $GMPanel
@onready var gm_close_btn: Button = $GMPanel/GMCloseBtn
@onready var gm_increase_btn: Button = $GMPanel/GMGrid/GMIncreaseBtn
@onready var gm_decrease_btn: Button = $GMPanel/GMGrid/GMDecreaseBtn
@onready var toast_container: VBoxContainer = $ToastContainer

var _pending_slot: int = 0

const _FADE_IN_DURATION: float = 0.5
const _FADE_IN_VOLUME_DB: float = -80.0
const _FADE_IN_TARGET_DB: float = 0.0
const _FADE_OUT_DURATION: float = 0.5
const _FADE_OUT_VOLUME_DB: float = -80.0
const _CHARACTER_SELECT_SCENE_PATH: String = "res://Scenes/CharacterSelect/character_select.tscn"
const _SETTINGS_SCENE_PATH: String = "res://Scenes/Settings/settings_menu.tscn"
const _ESC_COOLDOWN: float = 0.2

var _is_transitioning: bool = false
var _esc_cooldown_remaining: float = 0.0

func _ready() -> void:
	start_button.pressed.connect(_on_start_game)
	continue_button.pressed.connect(_on_continue_game)
	settings_button.pressed.connect(_on_open_settings)
	quit_button.pressed.connect(_on_exit_game)
	
	continue_button.visible = not ConfigManager.last_scene_path.is_empty()
	version_label.text = _get_version_text()
	save_switch_button.text = "存档 " + str(SaveManager.current_slot)
	save_switch_button.pressed.connect(_show_save_slots)
	slot_1_btn.pressed.connect(_on_slot_selected.bind(1))
	slot_2_btn.pressed.connect(_on_slot_selected.bind(2))
	slot_3_btn.pressed.connect(_on_slot_selected.bind(3))
	slot_cancel_btn.pressed.connect(_hide_save_slots)
	confirm_yes_btn.pressed.connect(_on_confirm_save_switch)
	confirm_no_btn.pressed.connect(func(): save_confirm_panel.visible = false)
	ConfigManager.gm_toggled.connect(_toggle_gm)
	gm_close_btn.pressed.connect(func(): gm_panel.visible = false)
	gm_increase_btn.pressed.connect(ConfigManager.gm_increase_difficulty)
	gm_decrease_btn.pressed.connect(ConfigManager.gm_decrease_difficulty)
	ConfigManager.toast_shown.connect(_show_toast)
	quit_yes_button.pressed.connect(_on_quit_confirmed)
	quit_no_button.pressed.connect(_hide_quit_dialog)
	_fade_in_music(_FADE_IN_DURATION)

## 从项目配置读取版本号并格式化为显示文本。
func _get_version_text() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version") as String
	return "v" + version

## 检查是否存在存档数据。后续接入 SaveManager 时替换为真正的保存状态查询。
func _has_save_data() -> bool:
	return FileAccess.file_exists("user://savegame.save")

func _process(delta: float) -> void:
	if _esc_cooldown_remaining > 0.0:
		_esc_cooldown_remaining = maxf(0.0, _esc_cooldown_remaining - delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gm_toggle"):
		get_viewport().set_input_as_handled()
		ConfigManager.gm_toggled.emit()
		return
	
	if _is_transitioning:
		return
	
	var dialog_visible: bool = quit_confirm_panel.visible
	
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _esc_cooldown_remaining > 0.0:
			return
		if dialog_visible:
			_hide_quit_dialog()
		else:
			_show_quit_dialog()
		_esc_cooldown_remaining = _ESC_COOLDOWN
	
	if dialog_visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_quit_confirmed()

func _show_quit_dialog() -> void:
	quit_confirm_panel.visible = true

func _hide_quit_dialog() -> void:
	quit_confirm_panel.visible = false

func _on_quit_confirmed() -> void:
	_hide_quit_dialog()
	_on_exit_game()

func _on_start_game() -> void:
	if _is_transitioning:
		return
	ConfigManager.last_scene_path = ""
	_is_transitioning = true
	_disable_buttons()
	_fade_out_music(_FADE_OUT_DURATION, _go_to_character_select)

func _on_continue_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	_fade_out_music(_FADE_OUT_DURATION, _go_to_last_scene)

func _go_to_last_scene() -> void:
	var path: String = ConfigManager.last_scene_path
	if path.is_empty():
		return
	var result: int = get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("MainMenu: failed to continue to %s, error code %d" % [path, result])

## 临时功能：除开始游戏外，其余按钮均触发退出游戏。
func _on_exit_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	_fade_out_music(_FADE_OUT_DURATION, _do_exit_game)

func _disable_buttons() -> void:
	start_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true

## 主菜单进入时，从无声淡入背景音乐。
func _fade_in_music(duration: float) -> void:
	music_player.volume_db = _FADE_IN_VOLUME_DB
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(music_player, "volume_db", _FADE_IN_TARGET_DB, duration)

## 在指定时长内淡出背景音乐，结束后执行传入的回调。
func _fade_out_music(duration: float, on_finished: Callable) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(music_player, "volume_db", _FADE_OUT_VOLUME_DB, duration)
	tween.finished.connect(on_finished, CONNECT_ONE_SHOT)

func _go_to_character_select() -> void:
	var result: int = get_tree().change_scene_to_file(_CHARACTER_SELECT_SCENE_PATH)
	if result != OK:
		push_error("MainMenu: failed to change scene to character select, error code " + str(result))

func _on_open_settings() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_disable_buttons()
	_fade_out_music(_FADE_OUT_DURATION, _go_to_settings)

func _go_to_settings() -> void:
	var result: int = get_tree().change_scene_to_file(_SETTINGS_SCENE_PATH)
	if result != OK:
		push_error("MainMenu: failed to change scene to settings, error code " + str(result))

func _do_exit_game() -> void:
	get_tree().quit()

## 存档选择
func _show_save_slots() -> void:
	save_slot_panel.visible = true

func _hide_save_slots() -> void:
	save_slot_panel.visible = false

func _on_slot_selected(slot: int) -> void:
	_pending_slot = slot
	confirm_label.text = "是否切换到存档 %d？" % slot
	save_confirm_panel.visible = true

func _on_confirm_save_switch() -> void:
	save_confirm_panel.visible = false
	_save_slot_panel_visible(false)
	SaveManager.switch_slot(_pending_slot)
	save_switch_button.text = "存档 " + str(SaveManager.current_slot)

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

func _save_slot_panel_visible(v: bool) -> void:
	save_slot_panel.visible = v
