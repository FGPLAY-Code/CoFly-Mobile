extends FlightDynamicsBase
class_name FighterDynamics

## 战斗机/特技机飞控策略
## 适用于 F-16、Su-27、Extra 300 等高机动性飞机。
##
## 核心特征：
## - 低惯性：轻量化结构，加速/转向响应极快
## - 放松静稳定性：飞机天生不稳定（放宽静稳定度），靠飞控保持姿态
##     → 操控极其灵敏，指尖一动飞机就响应
## - 高迎角能力：可飞到 30-40° 迎角不失速（边条翼/鸭翼设计）
## - 加力燃烧室：额外 50-70% 推力，拉烟/超音速
## - 快推力响应：战斗机低涵道比涡扇响应 <1 秒
## - 高滚转率：瞬间横滚，最大可达 300°/秒
## - 极小的地面效应：薄机翼/小翼展
## - 大迎角高 G 转弯：急转弯不掉速度
## - 可螺旋（失速改出是高阶技巧）
##
## 上手感觉："一碰就动，像骑着一颗子弹"

const GROUND_EFFECT_FACTOR: float = 1.0

func calculate_lift(config: AircraftConfig, state: Dictionary) -> Vector3:
	var speed: float = state["airspeed"]
	if speed < 1.0:
		return Vector3.ZERO

	var alpha_rad: float = deg_to_rad(state["alpha"])
	var alpha_zero_rad: float = deg_to_rad(config.zero_lift_aoa)
	var effective_alpha: float = alpha_rad - alpha_zero_rad

	# 战斗机升力曲线：机身本身也产生升力（升力体）
	# 升力坡度更陡，且线性范围更广
	var CL: float = config.lift_slope * effective_alpha * 1.1

	# 高迎角能力：战斗机有边条/前缘襟翼，失速推迟到 30-40°
	var stall_alpha_rad: float = deg_to_rad(config.stall_aoa)

	if abs(effective_alpha) > stall_alpha_rad:
		# 战斗机失速更剧烈（可能进入螺旋），但飞出迎角范围前仍保持部分升力
		var overshoot: float = (abs(effective_alpha) - stall_alpha_rad)
		var stall_factor: float = 1.0 / (1.0 + 4.0 * overshoot)
		CL = config.max_lift_coeff * stall_factor * sign(effective_alpha)
	else:
		# 高迎角下升力保持较好（涡升力效应）
		var alpha_normalized: float = abs(effective_alpha) / stall_alpha_rad
		if alpha_normalized > 0.7:
			# 接近失速时升力曲线略有抬升（涡升力）
			var vortex_lift: float = (alpha_normalized - 0.7) / 0.3 * 0.08
			CL = clamp(CL, config.min_lift_coeff, config.max_lift_coeff * (1.0 + vortex_lift))
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

	# 战斗机阻力：低寄生阻力（干净外形），高诱导阻力（高G转弯时）
	var CD: float = config.parasitic_drag * 0.85

	# 诱导阻力在高迎角时增长更快（战机大迎角产生大量涡阻）
	var high_aoa_factor: float = 1.0
	var alpha_abs: float = abs(state["alpha"] - config.zero_lift_aoa)
	if alpha_abs > config.stall_aoa * 0.6:
		high_aoa_factor = 1.0 + (alpha_abs / config.stall_aoa - 0.6) * 1.5

	var CDi: float = config.induced_drag_factor * CL_approx * CL_approx * high_aoa_factor
	CD += CDi

	# 地面效应：战斗机翼展小，地面效应影响甚微
	if config.wing_span > 0 and state["ground_clearance"] < config.wing_span * GROUND_EFFECT_FACTOR:
		var h_over_b: float = state["ground_clearance"] / config.wing_span
		var ge_factor: float = 1.0
		if h_over_b < 0.5:
			ge_factor = 1.0 - exp(-25.0 * h_over_b)
			CD = config.parasitic_drag + CDi * ge_factor

	# 起落架阻力 (战斗机起落架较小)
	if state["gear_down"] and config.has_gear:
		CD += config.gear_drag_coeff * 0.7

	var drag_magnitude: float = state["dynamic_pressure"] * config.wing_area * CD
	return -state["velocity"].normalized() * drag_magnitude


func calculate_thrust(config: AircraftConfig, state: Dictionary, prev_thrust: float, step: float) -> float:
	# 战斗机：极快推力响应 (低涵道比涡扇 + 加力)
	var thrust: float = move_toward(prev_thrust, config.max_thrust * state["throttle_input"],
		config.max_thrust * step / max(0.5, config.thrust_response_time * 0.6))

	return thrust


func calculate_torques(config: AircraftConfig, state: Dictionary) -> Vector3:
	var dp: float = state["dynamic_pressure"]

	var qSc: float = dp * config.wing_area * (config.wing_span * 0.12)  # 战斗机弦长比小
	var qSb: float = dp * config.wing_area * config.wing_span

	# 俯仰力矩
	# 放松静稳定性：Cm_alpha 很小，甚至可为0或正（不稳定）
	# 这让飞机极其灵敏，但需要飞控补偿
	var alpha_rad: float = deg_to_rad(state["alpha"] - config.zero_lift_aoa)
	var stability_reduction: float = 0.4  # 放松稳定性因子
	var pitch_stability: float = -config.pitch_moment_coeff * qSc * alpha_rad * stability_reduction

	# 高控制力：升降舵/水平尾翼效率极高
	var pitch_control: float = config.pitch_control_power * qSc * state["pitch_input"] * 1.4

	# 配平 (战斗机配平范围大但精细)
	var trim_torque: float = config.pitch_control_power * qSc * state["trim_elevator"] * 0.5

	var pitch_torque: float = pitch_stability + pitch_control + trim_torque

	# 滚转力矩 (战斗机高滚转率！)
	var roll_torque: float = config.roll_control_power * qSb * state["roll_input"] * 1.8

	# 偏航力矩 + 适当阻尼
	var yaw_torque: float = config.yaw_control_power * qSb * state["yaw_input"] * 1.2
	var yaw_rate: float = state["angular_velocity_local"].y
	# 战斗机偏航阻尼可较小（双垂尾/大垂尾）
	yaw_torque += -config.yaw_damping * qSb * yaw_rate * 0.7

	# 协调转弯辅助：滚转时自动带偏航 (模拟真实战机的耦合控制)
	if abs(state["roll_input"]) > 0.1 and abs(state["yaw_input"]) < 0.05:
		var coord_yaw: float = state["roll_input"] * 0.3 * sign(dp)
		yaw_torque += config.yaw_control_power * qSb * coord_yaw * 0.8

	return state["forward"].cross(state["up"]) * roll_torque \
		 + state["up"] * yaw_torque \
		 + state["forward"].cross(state["up"].cross(state["forward"])) * pitch_torque


func auto_trim(_config: AircraftConfig, state: Dictionary, current_trim: float, _step: float) -> float:
	# 战斗机：快速配平，但更依赖飞控而不是手动配平
	var new_trim: float = current_trim

	if abs(state["pitch_input"]) < 0.05:
		var pitch_rate: float = state["angular_velocity_local"].x
		if abs(pitch_rate) > 0.02:
			new_trim -= pitch_rate * 0.6 * _step
			new_trim = clamp(new_trim, -0.5, 0.5)

	return new_trim


func get_stall_warning_threshold() -> float:
	# 战斗机：较晚才给失速警告（飞行员训练有素）
	return 0.92
