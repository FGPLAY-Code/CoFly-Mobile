extends Control
class_name VirtualJoystick

## 虚拟摇杆输入
## 左半屏：触摸摇杆（俯仰/滚转）
## 右半屏：油门垂直滑块 + 偏航左右按钮
##
## 所有触摸区域采用透明 Control 覆盖层，
## 与 HUD CanvasLayer 分离。

## -- 摇杆参数 --
@export var joystick_radius: float = 60.0      # 摇杆最大拖动半径 (像素)
@export var joystick_deadzone: float = 8.0     # 摇杆死区 (像素)
@export var throttle_slider_height: float = 200.0  # 油门滑块高度
@export var yaw_button_size: float = 60.0      # 偏航按钮尺寸

## -- 输出值 --
var throttle: float = 0.0    # 0.0 ~ 1.0
var pitch: float = 0.0       # -1.0 (抬头) ~ 1.0 (低头)
var roll: float = 0.0        # -1.0 (左滚) ~ 1.0 (右滚)
var yaw: float = 0.0         # -1.0 (左偏) ~ 1.0 (右偏)
var gear_toggle: bool = false
var flap_up_signal: bool = false
var flap_down_signal: bool = false
var pause_signal: bool = false

## -- 内部状态 --
var _joystick_touch_id: int = -1
var _joystick_center: Vector2   # 摇杆基线位置 (屏幕坐标)
var _joystick_offset: Vector2 = Vector2.ZERO

var _throttle_touch_id: int = -1
var _throttle_base_y: float = 0.0
var _throttle_value: float = 0.5  # 初始50%油门

var _yaw_left_touch_id: int = -1
var _yaw_right_touch_id: int = -1

var _screen_size: Vector2
var _left_region: Rect2   # 左半屏区域
var _right_region: Rect2  # 右半屏区域

# 防止脉冲信号重复触发
var _last_gear: bool = false
var _last_flap_up: bool = false
var _last_flap_down: bool = false
var _last_pause: bool = false

func _ready() -> void:
    _screen_size = get_viewport_rect().size
    var half_w: float = _screen_size.x * 0.5
    _left_region = Rect2(0, 0, half_w, _screen_size.y)
    _right_region = Rect2(half_w, 0, half_w, _screen_size.y)
    _joystick_center = Vector2(half_w * 0.5, _screen_size.y * 0.5)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        _handle_touch(event as InputEventScreenTouch)
    elif event is InputEventScreenDrag:
        _handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
    # 起落架：双指双击（简单实现：双击屏幕中央区域）
    if event.double_tap:
        gear_toggle = true
        return

    if event.pressed:
        var pos: Vector2 = event.position
        # 左半屏 → 摇杆
        if _left_region.has_point(pos) and _joystick_touch_id == -1:
            _joystick_touch_id = event.index
            _joystick_center = pos
            _joystick_offset = Vector2.ZERO

        # 右半屏 → 油门滑块或偏航按钮
        elif _right_region.has_point(pos):
            var right_x: float = _screen_size.x * 0.75  # 油门滑块在右半屏中间偏右
            var slider_left: float = _screen_size.x * 0.6
            var slider_right: float = _screen_size.x * 0.9
            var yaw_btn_y: float = _screen_size.y * 0.75

            if pos.x >= slider_left and pos.x <= slider_right and pos.y < yaw_btn_y:
                # 油门区域
                if _throttle_touch_id == -1:
                    _throttle_touch_id = event.index
                    _throttle_base_y = pos.y
                    _throttle_value = throttle
            elif pos.y >= yaw_btn_y - yaw_button_size * 0.5:
                # 偏航按钮区域
                var btn_center_x: float = _screen_size.x * 0.75
                if pos.x < btn_center_x:
                    # 左偏航
                    if _yaw_left_touch_id == -1:
                        _yaw_left_touch_id = event.index
                else:
                    # 右偏航
                    if _yaw_right_touch_id == -1:
                        _yaw_right_touch_id = event.index

    else:
        # 触摸抬起
        if event.index == _joystick_touch_id:
            _joystick_touch_id = -1
            _joystick_offset = Vector2.ZERO
            pitch = 0.0
            roll = 0.0
        elif event.index == _throttle_touch_id:
            _throttle_touch_id = -1
        elif event.index == _yaw_left_touch_id:
            _yaw_left_touch_id = -1
        elif event.index == _yaw_right_touch_id:
            _yaw_right_touch_id = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
    if event.index == _joystick_touch_id:
        var delta: Vector2 = event.position - _joystick_center
        var dist: float = delta.length()
        if dist > joystick_deadzone:
            if dist > joystick_radius:
                delta = delta / dist * joystick_radius
            _joystick_offset = delta
            # Pitch: Y轴 (上=抬头=-1, 下=低头=1)
            pitch = -delta.y / joystick_radius
            # Roll: X轴 (左=左滚=-1, 右=右滚=1)
            roll = delta.x / joystick_radius
        else:
            pitch = 0.0
            roll = 0.0

    elif event.index == _throttle_touch_id:
        var delta_y: float = _throttle_base_y - event.position.y
        _throttle_value = clamp(_throttle_value + delta_y / throttle_slider_height, 0.0, 1.0)
        _throttle_base_y = event.position.y

    elif event.index == _yaw_left_touch_id:
        yaw = -1.0

    elif event.index == _yaw_right_touch_id:
        yaw = 1.0

func _process(delta: float) -> void:
    # 每帧更新输出值
    throttle = _throttle_value

    # 偏航: 如果没有触摸偏航按钮则归零
    if _yaw_left_touch_id == -1 and _yaw_right_touch_id == -1:
        yaw = 0.0

    # 脉冲信号上升沿检测
    if gear_toggle:
        gear_toggle = false

## -- 绘制调试可视化 --
func _draw() -> void:
    # 摇杆基座
    if _joystick_touch_id != -1:
        draw_circle(_joystick_center - global_position, joystick_radius, Color(1, 1, 1, 0.15))
        draw_circle(_joystick_center + _joystick_offset - global_position, 15, Color(1, 1, 1, 0.5))
