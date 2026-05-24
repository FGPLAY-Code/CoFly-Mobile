extends Resource
class_name SceneConfig

## 场景配置资源
## 每个飞行场景对应一个 .tres 文件，定义环境/地形/跑道等参数。

## -- 基本信息 --
@export var scene_id: String = ""
@export var display_name: String = "Unknown Scene"
@export var description: String = ""
@export var thumbnail: Texture2D
@export var scene_path: String = ""          # PackedScene 路径

## -- 环境 --
@export var sky_top_color: Color = Color(0.3, 0.5, 0.8)
@export var sky_horizon_color: Color = Color(0.7, 0.8, 0.9)
@export var sky_ground_color: Color = Color(0.3, 0.25, 0.2)
@export var sun_direction: Vector3 = Vector3(-0.5, -0.8, -0.3)
@export var sun_energy: float = 1.0
@export var ambient_energy: float = 0.5

## -- 地形 --
enum TerrainType {FLAT, HILLY, MOUNTAIN, WATER_ONLY}
@export var terrain_type: TerrainType = TerrainType.FLAT
@export var terrain_size: Vector2 = Vector2(4000, 4000)
@export var terrain_color: Color = Color(0.35, 0.55, 0.25)
@export var terrain_material: Material

## -- 水面 --
@export var has_water: bool = true
@export var water_color: Color = Color(0.1, 0.3, 0.5)
@export var water_level: float = 0.0

## -- 跑道 --
class RunwayData:
    var name: String = ""
    var position: Vector3 = Vector3.ZERO
    var orientation: float = 0.0               # 跑道方向 (度，磁航向)
    var length: float = 2000.0
    var width: float = 45.0
    var ils_frequency: float = 0.0             # ILS 频率 (可选)

@export var runways: Array = []

## -- 起始位置 --
@export var start_position: Vector3 = Vector3(0, 100, 0)
@export var start_rotation: Vector3 = Vector3(0, 0, 0)  # (yaw, pitch, roll) 度
@export var start_airborne: bool = false
@export var start_airspeed: float = 0.0        # 初始空速 (m/s), 0=静止

## -- 场景音效 --
@export var ambient_sound: AudioStream
@export var ambient_volume: float = 0.5

## -- 光照参数 --
@export var time_of_day: float = 12.0          # 0-24 小时
@export var fog_color: Color = Color(0.6, 0.65, 0.7)
@export var fog_density: float = 0.0005
