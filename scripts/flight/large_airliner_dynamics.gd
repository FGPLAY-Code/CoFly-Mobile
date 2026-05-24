extends FlightDynamicsBase
class_name LargeAirlinerDynamics

## 大型客机飞控策略
## 适用于 MD-11、Boeing 747/777、Airbus A330/380 等重型客机。
##
## 核心特征：
## - 高惯性：加速/减速/转向都慢，转弯半径大
## - 慢响应：控制舵面相对飞机质量偏小，需要更大的操纵量
## - 强荷兰滚倾向：需要强偏航阻尼器
## - 强地面效应：大型机翼近地时诱导阻力大幅降低
## - 慢推力响应：大涵道比涡扇发动机需要 3-5 秒从慢车到最大
## - 高静稳定性：飞机天然有强烈的回正趋势
## - 温和失速：失速前抖杆抖脚警告明显，改出容易
##
## 上手感觉："像在推一座山，但一切都很稳"

const GROUND_EFFECT_FACTOR: float = 1.5  # 地面效应高度阈值 = 翼展 * 此值

func calculate_lift(config: AircraftConfig, state: Dictionary) -> Vector3:
	var speed: float = state["airspeed"]
	if speed < 1.0:
		return Vector3.ZERO

	var alpha_rad: float = deg_to_rad(state["alpha"])
	var alpha_zero_rad: float = deg_to_rad(config.zero_lift_aoa)
	var effective_alpha: float = alpha_rad - alpha_zero_rad

	# 大型客机升力曲线 - 线性段更平缓，失速后更温和
	var CL: float = config.lift_slope * effective_alpha * 0.95

	# 襟翼升力增量 (大型客机襟翼非常有效)
	if config.has_flaps and state["flap_position"] > 0:
		var flap_ratio: float = float(state["flap_position"]) / max(1, config.flap_positions)
		CL += config.max_flap_lift_increase * flap_ratio * 1.1

	# 大型客机失速模型 - 温和且可预测
	var stall_alpha_rad: float = deg_to_rad(config.stall_aoa)
	if abs(effective_alpha) > stall_alpha_rad:
		# 大型客机失速：平缓下降，不是突然掉升力
		var overshoot: float = (abs(effective_alpha) - stall_alpha_rad)
		var stall_factor: float = 1.0 / (1.0 + 2.5 * overshoot)
		CL = config.max_lift_coeff * stall_factor * sign(effective_alpha)
	else:
		CL = clamp(CL, config.min_lift_coeff, config.max_lift_coeff)

	# 地面效应：大型客机近地时升力略微增加
	if config.wing_span > 0 and state["ground_clearance"] < config.wing_span * GROUND_EFFECT_FACTOR:
		var h_over_b: float = state["ground_clearance"] / config.wing_span
		var ge_lift_factor: float = 1.0 + exp(-20.0 * h_over_b) * 0.08
		CL *= ge_lift_factor

	var lift_magnitude: float = state["dynamic_pressure"] * config.wing_area * CL
	return state["up"] * lift_magnitude


func calculate_drag(config: AircraftConfig, state: Dictionary) -> Vector3:
	var speed: float = state["airspeed"]
	if speed < 0.1:
		return Vector3.ZERO

	# 大型客机基础阻力 - 寄生阻力更低(流线型)，诱导阻力更高(大翼载荷)
	var CL_approx: float = config.lift_slope * deg_to_rad(state["alpha"] - config.zero_lift_aoa)
	CL_approx = clamp(CL_approx, -config.max_lift_coeff, config.max_lift_coeff)

	var CD: float = config.parasitic_drag * 0.95  # 更好的气动设计
	var CDi: float = config.induced_drag_factor * CL_approx * CL_approx * 1.1

	CD += CDi

	# 地面效应：大型客机近地时诱导阻力大幅降低
	if config.wing_span > 0 and state["ground_clearance"] < config.wing_span * GROUND_EFFECT_FACTOR:
		var h_over_b: float = state["ground_clearance"] / config.wing_span
		var ge_factor: float = 1.0 - exp(-33.0 * h_over_b)
		CD = config.parasitic_drag + CDi * ge_factor

	# 襟翼阻力 (大型客机襟翼放下时阻力较大)
	if config.has_flaps and state["flap_position"] > 0:
		var flap_ratio: float = float(state["flap_position"]) / max(1, config.flap_positions)
		CD += config.max_flap_drag_increase * flap_ratio * 1.15

	# 起落架阻力 (重型起落架)
	if state["gear_down"] and config.has_gear:
		CD += config.gear_drag_coeff * 1.2

	var drag_magnitude: float = state["dynamic_pressure"] * config.wing_area * CD
	return -state["velocity"].normalized() * drag_magnitude


func calculate_thrust(config: AircraftConfig, state: Dictionary, prev_thrust: float, step: float) -> float:
	# 大型客机：慢推力响应 (大涵道比涡扇)
	# 在地面/低速时推力响应更慢 (涡轮迟滞)
	var response_time: float = config.thrust_response_time
	if state["airspeed"] < 30.0 and prev_thrust < config.max_thrust * 0.3:
		response_time *= 1.5  # 地面低速时响应更慢

	# 使用惯性更大的推力变化
	var target_thrust: float = config.max_thrust * state["throttle_input"]
	var rate: float = config.max_thrust * step / response_time

	# 推力变化速率带死区：微调油门时推力不变
	if abs(target_thrust - prev_thrust) < config.max_thrust * 0.02:
		return prev_thrust

	return move_toward(prev_thrust, target_thrust, rate)


func calculate_torques(config: AircraftConfig, state: Dictionary) -> Vector3:
	var dp: float = state["dynamic_pressure"]

	# 大型客机力矩 - 控制力相对飞机惯性偏小，阻尼强
	var qSc: float = dp * config.wing_area * (config.wing_span * 0.18)  # 平均气动弦长 ~ 翼展 * 0.18
	var qSb: float = dp * config.wing_area * config.wing_span

	# 俯仰力矩
	# 高静稳定性：强烈的回正力矩
	var alpha_rad: float = deg_to_rad(state["alpha"] - config.zero_lift_aoa)
	var pitch_stability: float = -config.pitch_moment_coeff * qSc * alpha_rad * 1.2

	# 升降舵控制 (大型客机控制力有限，转大弯需要大力)
	var pitch_control: float = config.pitch_control_power * qSc * state["pitch_input"] * 0.9

	# 配平
	var trim_torque: float = config.pitch_control_power * qSc * state["trim_elevator"] * 0.3

	var pitch_torque: float = pitch_stability + pitch_control + trim_torque

	# 滚转力矩 (大型客机滚转慢)
	var roll_torque: float = config.roll_control_power * qSb * state["roll_input"] * 0.85

	# 偏航力矩 + 强偏航阻尼 (抑制荷兰滚)
	var yaw_torque: float = config.yaw_control_power * qSb * state["yaw_input"]

	# 大型客机需要强偏航阻尼
	var yaw_rate: float = state["angular_velocity_local"].y
	var yaw_damping_torque: float = -config.yaw_damping * qSb * yaw_rate * 1.5

	# 荷兰滚抑制：检测滚转率耦合到偏航
	var roll_rate: float = state["angular_velocity_local"].z
	yaw_damping_torque += -config.yaw_damping * qSb * roll_rate * 0.3 * sign(dp)

	yaw_torque += yaw_damping_torque

	# 局部力矩 → 世界坐标系
	return state["forward"].cross(state["up"]) * roll_torque \
		 + state["up"] * yaw_torque \
		 + state["forward"].cross(state["up"].cross(state["forward"])) * pitch_torque


func auto_trim(_config: AircraftConfig, state: Dictionary, current_trim: float, _step: float) -> float:
	# 大型客机：慢速配平调整，平滑稳定
	var new_trim: float = current_trim

	# 检测非零俯仰输入时暂停配平
	if abs(state["pitch_input"]) < 0.08:
		var pitch_rate: float = state["angular_velocity_local"].x
		if abs(pitch_rate) > 0.005:
			new_trim -= pitch_rate * 0.3 * _step
			new_trim = clamp(new_trim, -0.5, 0.5)

	return new_trim


func get_stall_warning_threshold() -> float:
	# 大型客机：提前警告 (82% 迎角就开始抖杆)
	return 0.82
