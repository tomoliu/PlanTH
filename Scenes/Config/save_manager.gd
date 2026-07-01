extends Node

const _SLOTS: int = 3

## 存档数据
var current_slot: int = 1
var difficulty_level: int = 0
var has_cleared: bool = false

var _save_dir: String = ""
var _save_dir_ready: bool = false

func _ready() -> void:
	_save_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("PlanTH").path_join("Saves")
	DirAccess.make_dir_recursive_absolute(_save_dir)
	_save_dir_ready = true
	_load()

func _get_save_path() -> String:
	return _save_dir.path_join("savedata%d.json" % current_slot)

## 读取当前槽位存档
func _load() -> void:
	var path: String = _get_save_path()
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var raw: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if raw == null or not raw is Dictionary:
		return
	var data: Dictionary = raw as Dictionary
	difficulty_level = data.get("difficulty_level", 0) as int
	has_cleared = data.get("has_cleared", false) as bool

## 保存当前槽位
func save() -> void:
	DirAccess.make_dir_recursive_absolute(_save_dir)
	var data: Dictionary = {
		"difficulty_level": difficulty_level,
		"has_cleared": has_cleared,
	}
	var file: FileAccess = FileAccess.open(_get_save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

## 切换到指定存档槽
func switch_slot(slot: int) -> void:
	current_slot = clamp(slot, 1, _SLOTS)
	loaded_slot_data()

## 重新读取当前槽位数据（切换后调用）
func loaded_slot_data() -> void:
	difficulty_level = 0
	has_cleared = false
	_load()

func increase_difficulty() -> void:
	difficulty_level = mini(difficulty_level + 1, 10)
	save()

func decrease_difficulty() -> void:
	difficulty_level = maxi(difficulty_level - 1, 1)
	save()

## 标记已通关
func mark_cleared() -> void:
	has_cleared = true
	save()
