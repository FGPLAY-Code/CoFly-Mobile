extends Resource
class_name AircraftConfig

## 飞机配置资源
## 每款飞机一个 .tres 文件，定义全部的空气动力学参数。
## 在 Godot 编辑器中可以直接编辑。

## -- 基本信息 --
@export var display_name: String = "Unknown Aircraft"
@export var description: String = ""
@export var model_scene: PackedScene        # GLB/PackedScene 模型引用
@export var thumbnail: Texture2D             # 选择界面缩略图

## -- 质量参数 --
@export var mass: float = 1000.0             # 空机质量 (kg)
@export var max_fuel_mass: float = 500.0     # 最大燃油质量 (kg)

## -- 机翼参数 --
@export var wing_area: float = 100.0         # 参考机翼面积 (m^2)
@export var wing_span: float = 30.0          # 翼展 (m)
@export var aspect_ratio: float = 9.0        # 展弦比 AR = b^2/S

## -- 升力参数 --
@export var max_lift_coeff: float = 1.6      # CL_max (失速前)
@export var min_lift_coeff: float = -1.2     # CL_min (负升力)
@export var lift_slope: float = 5.5          # dCL/dAlpha (per radian, 典型值 ~2π)
@export var stall_aoa: float = 15.0          # 临界迎角 (degrees)
@export var zero_lift_aoa: float = -2.0      # CL=0 时的迎角 (degrees)

## -- 阻力参数 --
@export var parasitic_drag: float = 0.025    # CD0 (零升阻力)
@export var induced_drag_factor: float = 0.04 # 诱导阻力因子 k = 1/(π * AR * e)
@export var oswald_efficiency: float = 0.8   # 奥斯瓦尔德效率因子 e

## -- 推力参数 --
@export var max_thrust: float = 4000.0       # 最大推力 (N)
@export var thrust_response_time: float = 2.0 # 推力响应时间 (秒，从0到最大)

## -- 襟翼参数 --
@export var max_flap_lift_increase: float = 0.5  # 襟翼最大升力增量 dCL_flaps
@export var max_flap_drag_increase: float = 0.10 # 襟翼最大阻力增量 dCD_flaps
@export var flap_positions: int = 3              # 襟翼档位数 (0=收, 1=1档, 2=2档, 3=全放)

## -- 起落架参数 --
@export var has_gear: bool = true
@export var gear_drag_coeff: float = 0.05    # 起落架阻力系数

## -- 力矩/操控参数 --
@export var pitch_moment_coeff: float = 0.8  # Cm_alpha (纵向稳定性)
@export var pitch_control_power: float = 1.0 # 升降舵控制力
@export var roll_control_power: float = 1.2  # 副翼控制力
@export var yaw_control_power: float = 0.6   # 方向舵控制力
@export var yaw_damping: float = 0.8         # 偏航阻尼

## -- 性能参数 --
@export var cruise_speed: float = 250.0      # 巡航速度 (m/s, ~900km/h)
@export var max_speed: float = 300.0         # 最大平飞速度 (m/s)
@export var stall_speed: float = 60.0        # 失速速度 (m/s, 襟翼收)

## -- 发动机类型 --
enum EngineType {PISTON, JET, TURBOFAN}
@export var engine_type: EngineType = EngineType.TURBOFAN

## -- 飞控策略 --
enum DynamicsType {LARGE_AIRLINER, MEDIUM_AIRLINER, FIGHTER}
@export var dynamics_type: DynamicsType = DynamicsType.MEDIUM_AIRLINER

## -- 辅助功能 --
@export var has_flaps: bool = true
@export var has_autopilot: bool = true
