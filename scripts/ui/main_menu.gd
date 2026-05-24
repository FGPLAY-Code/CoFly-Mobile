extends Control
class_name MainMenu

## 主菜单控制器

@onready var quick_flight_btn: Button = $VBoxContainer/QuickFlightBtn
@onready var aircraft_select_btn: Button = $VBoxContainer/AircraftSelectBtn
@onready var scene_select_btn: Button = $VBoxContainer/SceneSelectBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn

func _ready() -> void:
	quick_flight_btn.pressed.connect(_on_quick_flight)
	aircraft_select_btn.pressed.connect(_on_aircraft_select)
	scene_select_btn.pressed.connect(_on_scene_select)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

func _on_quick_flight() -> void:
	# 快捷飞行：使用默认选中
	var gm = GameManager
	if gm.selected_aircraft and gm.selected_scene:
		gm.start_flight()
	else:
		# 如果无默认选择，先去选飞机
		_on_aircraft_select()

func _on_aircraft_select() -> void:
	get_tree().change_scene_to_file("res://scenes/aircraft_select.tscn")

func _on_scene_select() -> void:
	get_tree().change_scene_to_file("res://scenes/scene_select.tscn")

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit() -> void:
	get_tree().quit()
