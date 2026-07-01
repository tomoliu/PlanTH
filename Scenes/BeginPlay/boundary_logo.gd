extends Control

func _ready() -> void:
	$SplashContent.modulate.a = 0.0                      # 初始不可见
	var t: Tween = create_tween()
	t.tween_property($SplashContent, "modulate:a", 1.0, 0.5)  # 0.5s 淡入
	t.tween_interval(1.0)                                # 停留 1 秒
	t.tween_property($SplashContent, "modulate:a", 0.0, 1.0)  # 整页内容淡出
	t.tween_callback(_goto_main)

func _goto_main() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu/main_menu.tscn")
