extends RigidBody3D
class_name FlightModel

## 半仿真飞行物理模型 - 策略模式版本
## 基于 AircraftConfig 配置的空气动力学参数和飞控策略，
## 在 _integrate_forces 中通过策略对象计算升力/阻力/推力/力矩。
##
## 三套飞控由 config.dynamics_type 自动选择：
## - LARGE_AIRLINER  → LargeAirlinerDynamics  (高惯性·慢响应)
## - MEDIUM_AIRLINER → MediumAirlinerDynamics (均衡响应)
## - FIGHTER         → FighterDynamics        (灵敏·高机动)
##
## 上手简单：默认开了飞行辅助（自动配平）
## 精通难：关闭辅助后需要掌握能量管理、失速改出等

## -- 配置 --
@export var config: AircraftConfig
@export var start_airborne: bool = false     # 是否空中出生
@export var start_altitude: float = 500.0    # 空中出生高度 (m)

## -- 飞行状态（输入系统写入这些变量） --
var throttle: float = 0.0       # 0.0 ~ 1.0
var pitch_input: float = 0.0    # -1.0 (拉杆/抬头) ~ 1.0 (推杆/低头)
var roll_input: float = 0.0     # -1.0 (左滚) ~ 1.0 (右滚)
var yaw_input: float = 0.0      # -1.0 (左偏) ~ 1.0 (右偏)

## -- 飞机系统状态 --
var flap_position: int = 0      # 0=收, 1/2/3=襟翼档位
var gear_down: bool = true      # 起落架放下?
var current_fuel: float = 0.0   # 当前燃油量 (kg)

## -- 辅助系统 --
var auto_trim_active: bool = true
var stall_warning_active: bool = false

## -- 内部状态 --
var _dynamics: FlightDynamicsBase = null     # 当前飞控策略对象
var _current_thrust: float = 0.0            # 当前推力 (实际值, N)
var _trim_elevator: float = 0.0             # 配平量 (-1 ~ 1)
var _airspeed: float = 0.0                  # 当前空速 (m/s)
var _alpha: float = 0.0                     # 当前迎角 (degrees)
var _is_stalled: bool = false
var _altitude: float = 0.0
var _ground_clearance: float = 999.0        # 离地高度 (m)

# Constants
const GRAVITY: float = 9.8
const AIR_DENSITY_SEA_LEVEL: float = 1.225
const SCALE_HEIGHT: float = 8500.0          # 大气密度标高 (m)

func _ready() -> void:
	if not config:
		push_error("FlightModel: No AircraftConfig assigned!")
		return

	# 根据配置选择飞控策略
	_dynamics = _create_dynamics(config.dynamics_type)
	if not _dynamics:
		push_error("FlightModel: Failed to create dynamics strategy!")
		return

	current_fuel = config.max_fuel_mass * 0.8  # 默认80%油量（要在设置质量之前）
	mass = config.mass + current_fuel           # 含燃油的总质量
	gravity_scale = 0.0  # 物理由 _integrate_forces 全权接管
	linear_damp = 0.0
	angular_damp = 0.0

	if start_airborne:
		global_position = Vector3(0, start_altitude, 0)
		# -basis.z = 飞机鼻朝向（scene里rotation=π时，-basis.z指向+Z，即模型前方）
		var fly_dir: Vector3 = -global_transform.basis.z
		linear_velocity = fly_dir * config.cruise_speed * 0.7
		throttle = 0.6  # 初始 60% 油门，防止出生后立即失速

## 创建飞控策略实例
func _create_dynamics(type: int) -> FlightDynamicsBase:
	match type:
		AircraftConfig.DynamicsType.LARGE_AIRLINER:
			return LargeAirlinerDynamics.new()
		AircraftConfig.DynamicsType.MEDIUM_AIRLINER:
			return MediumAirlinerDynamics.new()
		AircraftConfig.DynamicsType.FIGHTER:
			return FighterDynamics.new()
		_:
			push_error("Unknown dynamics type: ", type)
			return null

## 构建飞行状态字典
func _build_state(state: PhysicsDirectBodyState3D) -> Dictionary:
	return {
		"airspeed": _airspeed,
		"alpha": _alpha,
		"altitude": _altitude,
		"ground_clearance": _ground_clearance,
		"throttle_input": throttle,
		"pitch_input": pitch_input,
		"roll_input": roll_input,
		"yaw_input": yaw_input,
		"flap_position": flap_position,
		"gear_down": gear_down,
		"current_thrust": _current_thrust,
		"trim_elevator": _trim_elevator,
		"total_mass": config.mass + current_fuel,
		"density": 0.0,  # 在 _integrate_forces 中填充
		"dynamic_pressure": 0.0,
		"step": state.step,
		"velocity": state.linear_velocity,
		"forward": -global_transform.basis.z,
		"up": global_transform.basis.y,
		"angular_velocity_local": global_transform.basis.inverse() * state.angular_velocity
	}

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not config or not _dynamics:
		return

	# ---- 更新状态变量 ----
	var forward: Vector3 = -global_transform.basis.z
	var up: Vector3 = global_transform.basis.y
	var velocity: Vector3 = state.linear_velocity
	var speed: float = velocity.length()
	_airspeed = speed

	# 高度和离地高度
	_altitude = global_position.y
	_ground_clearance = max(0, _altitude)

	# ---- 空气密度 (随高度指数衰减) ----
	var rho: float = AIR_DENSITY_SEA_LEVEL * exp(-_altitude / SCALE_HEIGHT)
	var dynamic_pressure: float = 0.5 * rho * speed * speed  # q = 0.5 * rho * V^2

	# ---- 迎角计算 ----
	if speed > 1.0:
		var local_vel: Vector3 = global_transform.basis.inverse() * velocity
		_alpha = rad_to_deg(atan2(local_vel.y, -local_vel.z))
	else:
		_alpha = 0.0

	# ---- 构建状态字典 ----
	var flight_state: Dictionary = {
		"airspeed": _airspeed,
		"alpha": _alpha,
		"altitude": _altitude,
		"ground_clearance": _ground_clearance,
		"throttle_input": throttle,
		"pitch_input": pitch_input,
		"roll_input": roll_input,
		"yaw_input": yaw_input,
		"flap_position": flap_position,
		"gear_down": gear_down,
		"current_thrust": _current_thrust,
		"trim_elevator": _trim_elevator,
		"total_mass": config.mass + current_fuel,
		"density": rho,
		"dynamic_pressure": dynamic_pressure,
		"step": state.step,
		"velocity": velocity,
		"forward": forward,
		"up": up,
		"angular_velocity_local": global_transform.basis.inverse() * state.angular_velocity
	}

	# ---- 委托给飞控策略计算 ----
	var lift_force: Vector3 = _dynamics.calculate_lift(config, flight_state)
	var drag_force: Vector3 = _dynamics.calculate_drag(config, flight_state)
	_current_thrust = _dynamics.calculate_thrust(config, flight_state, _current_thrust, state.step)
	var thrust_force: Vector3 = forward * _current_thrust

	# ---- 重力 ----
	var total_mass: float = config.mass + current_fuel
	var gravity_force: Vector3 = Vector3.DOWN * total_mass * GRAVITY

	# ---- 合力 ----
	state.apply_force(thrust_force + drag_force + lift_force + gravity_force)

	# ---- 力矩（委托给策略） ----
	var torque: Vector3 = _dynamics.calculate_torques(config, flight_state)
	state.apply_torque(torque)

	# ---- 自动配平 ----
	if auto_trim_active:
		_trim_elevator = _dynamics.auto_trim(config, flight_state, _trim_elevator, state.step)

	# ---- 失速警告（策略可自定义阈值） ----
	var stall_threshold: float = _dynamics.get_stall_warning_threshold()
	stall_warning_active = _alpha > config.stall_aoa * stall_threshold

	# ---- 更新失速状态 ----
	# 简单失速检测：迎角超过临界迎角且升力不足
	_is_stalled = _alpha > config.stall_aoa

## -- 公共 API (供输入系统和 HUD 使用) --

func set_throttle(value: float) -> void:
	throttle = clamp(value, 0.0, 1.0)

func set_controls(pitch: float, roll: float, yaw: float) -> void:
	pitch_input = clamp(pitch, -1.0, 1.0)
	roll_input = clamp(roll, -1.0, 1.0)
	yaw_input = clamp(yaw, -1.0, 1.0)

func toggle_gear() -> void:
	if config.has_gear:
		gear_down = not gear_down

func set_flaps(flap_idx: int) -> void:
	if config.has_flaps:
		flap_position = clampi(flap_idx, 0, config.flap_positions)

func flap_up() -> void:
	set_flaps(flap_position - 1)

func flap_down() -> void:
	set_flaps(flap_position + 1)

## -- HUD 数据查询 --

func get_airspeed_knots() -> float:
	return _airspeed * 1.94384  # m/s → knots

func get_altitude_feet() -> float:
	return _altitude * 3.28084  # m → feet

func get_vertical_speed() -> float:
	return linear_velocity.y

func get_heading() -> float:
	var forward: Vector3 = -global_transform.basis.z
	var heading: float = rad_to_deg(atan2(forward.x, -forward.z))
	if heading < 0:
		heading += 360.0
	return heading

func get_angle_of_attack() -> float:
	return _alpha

func is_stalled() -> bool:
	return _is_stalled

func get_throttle_percent() -> float:
	return throttle * 100.0

func get_trim_percent() -> float:
	return _trim_elevator * 100.0

func get_ground_clearance() -> float:
	return _ground_clearance

func get_flap_percent() -> float:
	if config.flap_positions <= 0:
		return 0.0
	return float(flap_position) / config.flap_positions * 100.0

## -- 飞控策略信息 --

func get_dynamics_name() -> String:
	match config.dynamics_type:
		AircraftConfig.DynamicsType.LARGE_AIRLINER:
			return "大型客机飞控"
		AircraftConfig.DynamicsType.MEDIUM_AIRLINER:
			return "中小型客机飞控"
		AircraftConfig.DynamicsType.FIGHTER:
			return "战斗机飞控"
	return "未知"
