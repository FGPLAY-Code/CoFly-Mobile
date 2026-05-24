extends Node

## 全局游戏状态管理器 (AutoLoad 单例)
## 贯穿整个游戏会话，管理选中的飞机/场景/设置等。

## -- 当前选择 --
var selected_aircraft: AircraftConfig = null
var selected_scene: SceneConfig = null

## -- 设置 --
var settings: Dictionary = {
    # 控制设置
    "control_mode": 0,              # InputMode enum (0=JOYSTICK, 1=GESTURE, 2=GYRO)
    "sensitivity": 1.0,
    "invert_pitch": false,

    # 画面设置
    "quality_preset": 1,            # 0=Low, 1=Medium, 2=High
    "texture_quality": 1,           # 0=50%, 1=75%, 2=100%
    "draw_distance": 1000.0,
    "shadows_enabled": true,

    # 音频设置
    "master_volume": 0.8,
    "engine_volume": 0.7,
    "effects_volume": 0.7,
    "ui_volume": 0.6,

    # 辅助
    "auto_trim": true,
    "stall_warning": true,
    "autopilot_available": true,
    "invincible": false,
}

## -- 飞机列表 --
var aircraft_list: Array[AircraftConfig] = []

## -- 场景列表 --
var scene_list: Array[SceneConfig] = []

const SETTINGS_PATH: String = "user://settings.cfg"

func _ready() -> void:
    load_settings()
    _load_default_content()

func _load_default_content() -> void:
    # 扫描可用飞机资源
    _scan_resources("res://resources/aircraft/", ".tres", aircraft_list)
    # 扫描可用场景资源
    _scan_resources("res://resources/scenes/", ".tres", scene_list)

    # 默认选择第一个
    if aircraft_list.size() > 0 and not selected_aircraft:
        selected_aircraft = aircraft_list[0]
    if scene_list.size() > 0 and not selected_scene:
        selected_scene = scene_list[0]

func _scan_resources(dir: String, ext: String, list: Array) -> void:
    var dir_access: DirAccess = DirAccess.open(dir)
    if not dir_access:
        return
    dir_access.list_dir_begin()
    var file_name: String = dir_access.get_next()
    while file_name != "":
        if file_name.ends_with(ext):
            var res: Resource = load(dir + file_name)
            if res:
                list.append(res)
        file_name = dir_access.get_next()

## -- 设置持久化 --
func save_settings() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    for section in settings:
        cfg.set_value("Settings", section, settings[section])
    cfg.save(SETTINGS_PATH)

func load_settings() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    if cfg.load(SETTINGS_PATH) == OK:
        for key in settings.keys():
            if cfg.has_section_key("Settings", key):
                settings[key] = cfg.get_value("Settings", key)

## -- 场景切换 --
func start_flight() -> void:
    if not selected_aircraft or not selected_scene:
        push_error("GameManager: No aircraft or scene selected")
        return

    # 加载飞行场景
    var scene_loader: PackedScene = load("res://scenes/flight_scene.tscn")
    if not scene_loader:
        push_error("GameManager: Cannot load flight_scene.tscn")
        return

    get_tree().change_scene_to_file("res://scenes/flight_scene.tscn")

func return_to_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func quit_game() -> void:
    get_tree().quit()
