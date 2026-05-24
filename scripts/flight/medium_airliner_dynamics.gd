extends FlightDynamicsBase
class_name MediumAirlinerDynamics

## 中小型客机/通航飞机飞控策略
## 适用于 Boeing 737、Airbus A320、CRJ、Cessna 172 等中小型飞机。
##
## 核心特征：
## - 中等惯性：转向响应适中，有分量感但不会觉得推不动
## - 均衡响应：控制舵面效率与飞机质量匹配良好
## - 适当荷兰滚倾向：需要偏航阻尼但不如大型客机强迫
## - 中等地面效应：翼展适中，近地时有一定影响
## - 中速推力响应：涡扇/涡桨发动机响应 1-3 秒
## - 适当静稳定性：稳定但不僵硬，有操控反馈
## - 清晰的失速预警：失速前有足够警告，改出修正直接
##
## 上手感觉："灵活但稳重，反应听你的"

const GROUND_EFFECT_FACTOR: float = 1.5

func calculate_lift(config: AircraftConfig, state: Dictionary) -> Vector3:
	var speed: float = state["airspeed"]
	if speed < 1.0:
		return Vector3.ZERO

	var alpha_rad: float = deg_to_rad(state["alpha"])
	var alpha_zero_rad: float = deg_to_rad(config.zero_lift_aoa)
	var effective_alpha: float = alpha_rad - alpha_zero_rad

	# 中小型客机：标准升力曲线，线性段正常
	var CL: float = config.lift_slope * effective_alpha

	# 襟翼升力增量 (标准)
	if config.has_flaps and state["flap_position"] > 0:
		var flap_ratio: float = float(state["flap_position"]) / max(1, config.flap_positions)
		CL += config.max_flap_lift_increase * flap_ratio

	# 失速模型 - 中等烈度，失速后升力明显但可恢复
	var stall_alpha_rad: float = deg_to_rad(config.stall_aoa)
	if abs(effective_alpha) > stall_alpha_rad:
		var overshoot: float = (abs(effective_alpha) - stall_alpha_rad)
		var stall_factor: float = exp(-3.0 * overshoot)
		CL = config.max_lift_coeff * stall_factor * sign(effective_alpha)
	else:
		CL = clamp(CL, config.min_lift_coeff, config.max_lift_coeff)

	var lift_magnitude: float = state["dynamic_pressure"] * config.wing_area * CL
	return state["up"] * lift_magnitude


func calculate_drag(config: AircraftConfig, state: Dictionary) -> Vector3:
	var speed: float = state["airspeed"]
	if speed < 0.1:
		return Vector3.ZERO

	var CL_approx: float = config.lift_slope * deg_to_rad(state["alpha"] - config.zero_lift_aoa)
	CL_approx = clamp(CL_approx, -config.max_lift_coeff, config.max_lift_coeff)

	var CD: float = config.parasitic_drag
	var CDi: float = config.induced_drag_factor * CL_approx * CL_approx

	CD += CDi

	# 地面效应 (中等强度)
	if config.wing_span > 0 and state["ground_clearance"] < config.wing_span * GROUND_EFFECT_FACTOR:
		var h_over_b: float = state["ground_clearance"] / config.wing_span
		var ge_factor: float = 1.0 - exp(-30.0 * h_over_b)
		CD = config.parasitic_drag + CDi * ge_factor

	# 襟翼阻力
	if config.has_flaps and state["flap_position"] > 0:
		var flap_ratio: float = float(state["flap_position"]) / max(1, config.flap_positions)
		CD += config.max_flap_drag_increase * flap_ratio

	# 起落架阻力
	if state["gear_down"] and config.has_gear:
		CD += config.gear_drag_coeff

	var drag_magnitude: float = state["dynamic_pressure"] * config.wing_area * CD
	return -state["velocity"].normalized() * drag_magnitude


func calculate_thrust(config: AircraftConfig, state: Dictionary, prev_thrust: float, step: float) -> float:
	# 中小型客机：中速推力响应
	var target_thrust: float = config.max_thrust * state["throttle_input"]
	var rate: float = config.max_thrust * step / config.thrust_response_time

	return move_toward(prev_thrust, target_thrust, rate)


func calculate_torques(config: AircraftConfig, state: Dictionary) -> Vector3:
	var dp: float = state["dynamic_pressure"]

	var qSc: float = dp * config.wing_area * (config.wing_span * 0.16)
	var qSb: float = dp * config.wing_area * config.wing_span

	# 俯仰力矩 - 标准静稳定性，操控反馈清晰
	var alpha_rad: float = deg_to_rad(state["alpha"] - config.zero_lift_aoa)
	var pitch_stability: float = -config.pitch_moment_coeff * qSc * alpha_rad

	var pitch_control: float = config.pitch_control_power * qSc * state["pitch_input"]
	var trim_torque: float = config.pitch_control_power * qSc * state["trim_elevator"] * 0.3

	var pitch_torque: float = pitch_stability + pitch_control + trim_torque

	# 滚转力矩 (标准)
	var roll_torque: float = config.roll_control_power * qSb * state["roll_input"]

	# 偏航力矩 + 适当偏航阻尼
	var yaw_torque: float = config.yaw_control_power * qSb * state["yaw_input"]
	var yaw_rate: float = state["angular_velocity_local"].y
	yaw_torque += -config.yaw_damping * qSb * yaw_rate

	return state["forward"].cross(state["up"]) * roll_torque \
		 + state["up"] * yaw_torque \
		 + state["forward"].cross(state["up"].cross(state["forward"])) * pitch_torque


func auto_trim(_config: AircraftConfig, state: Dictionary, current_trim: float, _step: float) -> float:
	# 中小型客机：正常配平速度
	var new_trim: float = current_trim

	if abs(state["pitch_input"]) < 0.1:
		var pitch_rate: float = state["angular_velocity_local"].x
		if abs(pitch_rate) > 0.01:
			new_trim -= pitch_rate * 0.4 * _step
			new_trim = clamp(new_trim, -0.5, 0.5)

	return new_trim


func get_stall_warning_threshold() -> float:
	return 0.85
