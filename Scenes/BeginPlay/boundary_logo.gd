extends Control

func _ready() -> void:
	var t: Tween = create_tween()
	t.tween_interval(1.0)                              # 停留 1 秒
	t.tween_property(self, "modulate:a", 0.0, 1.0)   # 淡出 1 秒
	t.tween_callback(_goto_main)

func _goto_main() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu/main_menu.tscn")
