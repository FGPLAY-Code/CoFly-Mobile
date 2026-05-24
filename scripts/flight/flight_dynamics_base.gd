extends RefCounted
class_name FlightDynamicsBase

## 飞控策略基类
## 定义所有飞控策略必须实现的接口方法。
## 每个方法接收飞行状态字典，返回对应计算结果。
##
## 状态字典字段：
##   airspeed, alpha(deg), altitude, ground_clearance,
##   throttle_input, pitch_input, roll_input, yaw_input,
##   flap_position, gear_down, current_thrust, total_mass,
##   density, dynamic_pressure, step, velocity, forward, up,
##   angular_velocity_local, trim_elevator

## 升力计算
## 返回升力向量 (世界坐标系)
func calculate_lift(_config: AircraftConfig, _state: Dictionary) -> Vector3:
	return Vector3.ZERO

## 阻力计算
## 返回阻力向量 (世界坐标系)
func calculate_drag(_config: AircraftConfig, _state: Dictionary) -> Vector3:
	return Vector3.ZERO

## 推力计算
## 返回实际推力值(N)
func calculate_thrust(_config: AircraftConfig, _state: Dictionary, _prev_thrust: float, _step: float) -> float:
	return 0.0

## 力矩计算
## 返回力矩向量 (世界坐标系)
func calculate_torques(_config: AircraftConfig, _state: Dictionary) -> Vector3:
	return Vector3.ZERO

## 自动配平
## 返回新的配平量 (-1 ~ 1)
func auto_trim(_config: AircraftConfig, _state: Dictionary, current_trim: float, _step: float) -> float:
	return current_trim

## 失速警告阈值 (返回迎角比例, 0~1, 达到该值触发警告)
func get_stall_warning_threshold() -> float:
	return 0.85
