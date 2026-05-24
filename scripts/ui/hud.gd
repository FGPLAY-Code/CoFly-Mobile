extends CanvasLayer
class_name HUD

## 飞行仪表 HUD
## 显示空速、高度、航向、垂直速度、人工地平仪、油门等。

var flight_model: FlightModel = null

@onready var airspeed_label: Label = $Control/VBoxContainer/TopBar/Airspeed/Value
@onready var altitude_label: Label = $Control/VBoxContainer/TopBar/Altitude/Value
@onready var heading_label: Label = $Control/VBoxContainer/TopBar/Heading/Value
@onready var vs_label: Label = $Control/VBoxContainer/TopBar/VertSpeed/Value
@onready var throttle_bar: TextureProgressBar = $Control/VBoxContainer/BottomBar/ThrottleBar
@onready var flaps_label: Label = $Control/VBoxContainer/BottomBar/FlapsLabel
@onready var gear_label: Label = $Control/VBoxContainer/BottomBar/GearLabel
@onready var aircraft_name: Label = $Control/VBoxContainer/BottomBar/AircraftName
@onready var pause_btn: Button = $Control/PauseBtn
@onready var stall_warning: Label = $Control/StallWarning

# 人工地平仪绘制
@onready var horizon_container: Control = $Control/HorizonContainer

var _pause_menu: CanvasLayer = null

func _ready() -> void:
    pause_btn.pressed.connect(_on_pause)
    # 获取内嵌的暂停菜单
    _pause_menu = $PauseMenu as CanvasLayer
    if _pause_menu:
        _pause_menu.visible = false

func _process(delta: float) -> void:
    if not is_instance_valid(flight_model):
        return

    # 空速 (kn)
    airspeed_label.text = "%03.0f" % flight_model.get_airspeed_knots()

    # 高度 (ft)
    altitude_label.text = "%05.0f" % flight_model.get_altitude_feet()

    # 航向
    heading_label.text = "%03.0f" % flight_model.get_heading()

    # 垂直速度 (ft/min)
    var vs_fpm: float = flight_model.get_vertical_speed() * 196.85
    vs_label.text = "%+04.0f" % vs_fpm

    # 油门
    throttle_bar.value = flight_model.get_throttle_percent()

    # 襟翼
    flaps_label.text = "FLAP %d" % flight_model.flap_position

    # 起落架
    gear_label.text = "GEAR " + ("DOWN" if flight_model.gear_down else "UP")

    # 飞机名称
    if flight_model.config:
        aircraft_name.text = flight_model.config.display_name

    # 失速警告
    stall_warning.visible = flight_model.stall_warning_active

    # 人工地平仪
    horizon_container.queue_redraw()

func set_flight_model(model: FlightModel) -> void:
    flight_model = model

func _on_pause() -> void:
    get_tree().paused = true
    if _pause_menu:
        _pause_menu.visible = true

func _draw_horizon(canvas: Control) -> void:
    # 人工地平仪绘制（在 _draw 中实现）
    if not is_instance_valid(flight_model):
        return

    var c: Vector2 = canvas.size * 0.5
    var radius: float = min(c.x, c.y) - 10

    # 获取姿态
    var pitch: float = 0.0
    var roll: float = 0.0
    if is_instance_valid(flight_model):
        # 从飞行模型的 transform 获取姿态
        var basis: Basis = flight_model.global_transform.basis
        var euler: Vector3 = basis.get_euler()
        pitch = rad_to_deg(euler.x)
        roll = rad_to_deg(-euler.z)  # 滚转角

    var draw: Control = canvas
    var center: Vector2 = draw.size * 0.5

    # 绘制地平仪背景（圆）
    draw.draw_circle(center, radius, Color(0.1, 0.1, 0.15, 0.85))
    draw.draw_arc(center, radius, 0, TAU, 32, Color(0.3, 0.3, 0.4), 1.5)

    # 地平线
    var horizon_y: float = -pitch * 1.5  # 俯仰偏移
    var line_length: float = radius * 0.7

    # 天/地分界
    var sky_color: Color = Color(0.2, 0.4, 0.7)
    var ground_color: Color = Color(0.4, 0.3, 0.2)

    # 俯仰刻度线
    for angle in range(-20, 21, 5):
        var y_off: float = -angle * 1.5 + horizon_y
        if abs(y_off) > radius:
            continue
        var line_w: float = line_length * (0.5 if angle % 10 == 0 else 0.3)
        var col: Color = Color(1, 1, 1, 0.6) if angle == 0 else Color(1, 1, 1, 0.3)
        draw.draw_line(
            center + Vector2(-line_w, y_off),
            center + Vector2(line_w, y_off),
            col, 1.0
        )

    # 飞机参考符号（三角形）
    var ref_size: float = 15.0
    var ref_points: PackedVector2Array = [
        center + Vector2(0, -ref_size),
        center + Vector2(-ref_size * 0.5, ref_size * 0.5),
        center + Vector2(ref_size * 0.5, ref_size * 0.5)
    ]
    draw.draw_colored_polygon(ref_points, Color(1, 1, 0, 0.8))
