extends Node
class_name InputManager

## 输入管理器
## 在 InputInterface 各实现间切换，并将标准化输入传递给 FlightModel。
## 同时保持键盘输入作为调试后备。

enum InputMode {JOYSTICK, GESTURE, GYRO}

@export var flight_model: FlightModel
@export var current_mode: InputMode = InputMode.JOYSTICK

## -- 灵敏度设置 (可在运行时修改) --
var sensitivity: float = 1.0    # 0.5 ~ 2.0
var invert_pitch: bool = false

var _joystick: VirtualJoystick = null
var _keyboard_pitch: float = 0.0
var _keyboard_roll: float = 0.0
var _keyboard_yaw: float = 0.0
var _keyboard_throttle: float = 0.5

func _ready() -> void:
    # 查找虚拟摇杆
    _joystick = get_node_or_null("VirtualJoystick") as VirtualJoystick
    if not _joystick:
        # 可能是脚本挂在别处，尝试从子节点找起
        for child in get_children():
            if child is VirtualJoystick:
                _joystick = child
                break

    # 套接键盘输入（调试后备）
    _bind_debug_keys()

func _bind_debug_keys() -> void:
    # 确保输入映射存在
    var key_actions := {
        "throttle_up": KEY_W,
        "throttle_down": KEY_S,
        "pitch_up": KEY_UP,
        "pitch_down": KEY_DOWN,
        "roll_left": KEY_LEFT,
        "roll_right": KEY_RIGHT,
        "yaw_left": KEY_A,
        "yaw_right": KEY_D
    }
    for action in key_actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for event in InputMap.action_get_events(action):
            InputMap.action_erase_event(action, event)
        var ev := InputEventKey.new()
        ev.keycode = key_actions[action]
        InputMap.action_add_event(action, ev)

func _process(delta: float) -> void:
    if not is_instance_valid(flight_model):
        return

    # -- 从当前输入模式读取 --
    var t: float = 0.0
    var p: float = 0.0
    var r: float = 0.0
    var y: float = 0.0

    match current_mode:
        InputMode.JOYSTICK:
            if _joystick:
                t = _joystick.throttle
                p = _joystick.pitch
                r = _joystick.roll
                y = _joystick.yaw
        # GESTURE 和 GYRO 在 Phase 2 实现

    # -- 键盘叠加（调试用，覆盖触控值） --
    _handle_debug_keyboard(delta)
    if abs(_keyboard_pitch) > 0.01:
        p = _keyboard_pitch
    if abs(_keyboard_roll) > 0.01:
        r = _keyboard_roll
    if abs(_keyboard_yaw) > 0.01:
        y = _keyboard_yaw
    if abs(_keyboard_throttle - 0.5) > 0.01:
        t = _keyboard_throttle

    # -- 灵敏度处理 --
    p *= sensitivity
    r *= sensitivity
    y *= sensitivity

    # -- 反转俯仰 --
    if invert_pitch:
        p = -p

    # -- 写入飞行模型 --
    flight_model.set_throttle(t)
    flight_model.set_controls(p, r, y)

    # -- 系统控制 --
    if _joystick and _joystick.gear_toggle:
        flight_model.toggle_gear()

    # -- 键盘系统控制 --
    if Input.is_key_pressed(KEY_G):
        flight_model.toggle_gear()
    if Input.is_key_pressed(KEY_F):
        flight_model.flap_up()
    if Input.is_key_pressed(KEY_V):
        flight_model.flap_down()

func _handle_debug_keyboard(delta: float) -> void:
    # 油门 (W/S 平滑增减)
    if Input.is_action_pressed("throttle_up"):
        _keyboard_throttle = move_toward(_keyboard_throttle, 1.0, delta * 0.5)
    if Input.is_action_pressed("throttle_down"):
        _keyboard_throttle = move_toward(_keyboard_throttle, 0.0, delta * 0.5)

    # 俯仰 (上/下箭头)
    _keyboard_pitch = 0.0
    if Input.is_action_pressed("pitch_up"):
        _keyboard_pitch = -1.0
    elif Input.is_action_pressed("pitch_down"):
        _keyboard_pitch = 1.0

    # 滚转 (左/右箭头)
    _keyboard_roll = 0.0
    if Input.is_action_pressed("roll_left"):
        _keyboard_roll = -1.0
    elif Input.is_action_pressed("roll_right"):
        _keyboard_roll = 1.0

    # 偏航 (A/D)
    _keyboard_yaw = 0.0
    if Input.is_action_pressed("yaw_left"):
        _keyboard_yaw = -1.0
    elif Input.is_action_pressed("yaw_right"):
        _keyboard_yaw = 1.0

func switch_mode(mode: InputMode) -> void:
    current_mode = mode
