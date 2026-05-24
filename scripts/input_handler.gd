extends Node

## 输入处理脚本
## 将键盘输入（临时）映射到飞机的飞行控制变量。
## W/S → 油门 | ↑/↓ → 俯仰 | ←/→ → 滚转 | A/D → 偏航
## 
## 后续可替换为触摸/陀螺仪输入源。

@export var plane: RigidBody3D


func _ready() -> void:
	# 自动找到父节点上的飞机
	if not plane:
		plane = get_parent() as RigidBody3D

	# 将键盘按键绑定到已定义的输入动作
	_bind_key("throttle_up", KEY_W)
	_bind_key("throttle_down", KEY_S)
	_bind_key("pitch_up", KEY_UP)
	_bind_key("pitch_down", KEY_DOWN)
	_bind_key("roll_left", KEY_LEFT)
	_bind_key("roll_right", KEY_RIGHT)
	_bind_key("yaw_left", KEY_A)
	_bind_key("yaw_right", KEY_D)


func _bind_key(action: String, keycode: Key) -> void:
	## 确保输入动作存在并绑定指定按键。
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# 清空已有事件避免重复绑定
	for event in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, event)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	if not is_instance_valid(plane):
		return

	# ---- 油门（平滑增减，0.5/s 速率） ----
	if Input.is_action_pressed("throttle_up"):
		plane.throttle = move_toward(plane.throttle, 1.0, delta * 0.5)
	if Input.is_action_pressed("throttle_down"):
		plane.throttle = move_toward(plane.throttle, 0.0, delta * 0.5)

	# ---- 俯仰 ----
	plane.pitch_input = 0.0
	if Input.is_action_pressed("pitch_up"):
		plane.pitch_input = -1.0  # 拉杆（机头抬升）
	elif Input.is_action_pressed("pitch_down"):
		plane.pitch_input = 1.0   # 推杆（机头下降）

	# ---- 滚转 ----
	plane.roll_input = 0.0
	if Input.is_action_pressed("roll_left"):
		plane.roll_input = -1.0
	elif Input.is_action_pressed("roll_right"):
		plane.roll_input = 1.0

	# ---- 偏航 ----
	plane.yaw_input = 0.0
	if Input.is_action_pressed("yaw_left"):
		plane.yaw_input = -1.0
	elif Input.is_action_pressed("yaw_right"):
		plane.yaw_input = 1.0
