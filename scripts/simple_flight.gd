extends RigidBody3D

## 简易飞行物理 — 升力 / 推力 / 阻力 / 重力 / 力矩

@export var max_thrust := 4000.0
@export var lift_coeff := 0.4
@export var drag_coeff := 0.25
@export var aircraft_mass := 500.0
@export var pitch_sensitivity := 8.0
@export var roll_sensitivity := 12.0
@export var yaw_sensitivity := 6.0

var throttle := 0.0       # 0.0 ~ 1.0
var pitch_input := 0.0    # -1.0 ~ 1.0
var roll_input := 0.0     # -1.0 ~ 1.0
var yaw_input := 0.0      # -1.0 ~ 1.0


func _ready() -> void:
	mass = aircraft_mass
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var forward: Vector3 = -global_transform.basis.z
	var up: Vector3 = global_transform.basis.y

	var velocity: Vector3 = state.linear_velocity
	var speed: float = velocity.length()

	# 推力
	var thrust_force: Vector3 = forward * max_thrust * throttle

	# 阻力
	var drag_force := Vector3.ZERO
	if speed > 0.01:
		drag_force = -velocity.normalized() * drag_coeff * speed

	# 升力
	var lift_force := Vector3.ZERO
	if speed > 0.01:
		lift_force = up * lift_coeff * speed * speed

	# 重力
	var gravity_force: Vector3 = Vector3.DOWN * aircraft_mass * 9.8

	# 合力
	state.apply_force(thrust_force + drag_force + lift_force + gravity_force)

	# 力矩（俯仰 / 偏航 / 滚转）
	var torque_local := Vector3(
		pitch_input * pitch_sensitivity,
		yaw_input * yaw_sensitivity,
		roll_input * roll_sensitivity
	)
	state.apply_torque(transform.basis * torque_local)
