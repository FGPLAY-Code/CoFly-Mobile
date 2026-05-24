extends Node
class_name SceneLoader

## 场景加载器
## 根据选中的 AircraftConfig 和 SceneConfig 构建完整的飞行场景。

signal scene_ready(flight_model: FlightModel)

@export var flight_scene_root: PackedScene   # flight_scene.tscn 的 PackedScene

var _aircraft_config: AircraftConfig
var _scene_config: SceneConfig

func load_scene(aircraft_cfg: AircraftConfig, scene_cfg: SceneConfig) -> void:
    _aircraft_config = aircraft_cfg
    _scene_config = scene_cfg

    # 加载飞行场景根节点
    if not flight_scene_root:
        push_error("SceneLoader: flight_scene_root is null")
        return
    var scene_instance: Node = flight_scene_root.instantiate()
    add_child(scene_instance)

    # 应用场景配置
    _apply_environment(scene_instance)
    _apply_terrain(scene_instance)
    _apply_water(scene_instance)
    _apply_scenery(scene_instance)

    # 加载飞机
    var flight_model: FlightModel = _spawn_aircraft(scene_instance)

    # 加载输入
    _setup_input(scene_instance, flight_model)

    # 加载 HUD
    _setup_hud(scene_instance, flight_model)

    scene_ready.emit(flight_model)

func _apply_environment(scene_instance: Node) -> void:
    if not _scene_config:
        return

    var env_node: WorldEnvironment = scene_instance.get_node_or_null("WorldEnvironment")
    if not env_node or not env_node.environment:
        return

    var env: Environment = env_node.environment

    # 设置天空颜色
    env.sky.sky_material.set("sky_top_color", _scene_config.sky_top_color)
    env.sky.sky_material.set("sky_horizon_color", _scene_config.sky_horizon_color)
    env.sky.sky_material.set("ground_bottom_color", _scene_config.sky_ground_color)

    # 雾
    env.fog_color = _scene_config.fog_color
    env.fog_density = _scene_config.fog_density

    # 环境光
    env.ambient_light_color = _scene_config.sky_horizon_color
    env.ambient_light_energy = _scene_config.ambient_energy

    # 太阳方向
    var sun: DirectionalLight3D = scene_instance.get_node_or_null("DirectionalLight3D")
    if sun:
        sun.light_energy = _scene_config.sun_energy
        # 太阳方向从场景配置计算
        var hour_angle: float = (_scene_config.time_of_day / 24.0) * 360.0
        var sun_rot: Vector3 = Vector3(
            deg_to_rad(30 + 20 * sin(deg_to_rad(hour_angle))),
            deg_to_rad(hour_angle),
            0
        )
        sun.rotation = sun_rot

func _apply_terrain(scene_instance: Node) -> void:
    if not _scene_config:
        return

    var terrain: MeshInstance3D = scene_instance.get_node_or_null("Terrain")
    if not terrain:
        return

    # 简单的平面地形 + 颜色
    if terrain.material_override:
        terrain.material_override.set("albedo_color", _scene_config.terrain_color)

    # 地形碰撞体
    var collision: StaticBody3D = scene_instance.get_node_or_null("TerrainCollision")
    if collision:
        # 根据场景配置调整碰撞体大小
        pass

func _apply_water(scene_instance: Node) -> void:
    if not _scene_config:
        return

    var water: MeshInstance3D = scene_instance.get_node_or_null("Water")
    if water:
        water.visible = _scene_config.has_water
        if water.material_override:
            water.material_override.set("albedo_color", _scene_config.water_color)

func _apply_scenery(scene_instance: Node) -> void:
    # 场景装饰物（建筑/树木/灯光等）- Phase 2 实现
    pass

func _spawn_aircraft(scene_instance: Node) -> FlightModel:
    if not _aircraft_config or not _aircraft_config.model_scene:
        push_error("SceneLoader: No aircraft config or model scene")
        return null

    # 创建飞机节点
    var plane_node: RigidBody3D = RigidBody3D.new()
    plane_node.name = "Aircraft"

    # 添加飞行模型脚本
    var flight_model: FlightModel = FlightModel.new()
    plane_node.set_script(flight_model.get_script())
    flight_model = plane_node as FlightModel
    flight_model.config = _aircraft_config

    # 实例化模型
    var model_instance: Node3D = _aircraft_config.model_scene.instantiate()
    model_instance.name = "Model"
    # MD-11 模型需要 180° Y 旋转（记得项目之前的要求）
    model_instance.rotation_degrees = Vector3(0, 180, 0)
    plane_node.add_child(model_instance)

    # 碰撞体（简化为包围盒）
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(26, 5.5, 22)
    collision.shape = shape
    plane_node.add_child(collision)

    # 设置起始位置
    if _scene_config:
        plane_node.position = _scene_config.start_position
        plane_node.rotation_degrees = _scene_config.start_rotation
        flight_model.start_airborne = _scene_config.start_airborne
        if _scene_config.start_airspeed > 0:
            plane_node.linear_velocity = -plane_node.global_transform.basis.z * _scene_config.start_airspeed

    # 添加到场景
    scene_instance.add_child(plane_node)

    return flight_model

func _setup_input(scene_instance: Node, flight_model: FlightModel) -> void:
    if not flight_model:
        return

    # 创建输入管理器
    var input_mgr: InputManager = InputManager.new()
    input_mgr.name = "InputManager"
    input_mgr.flight_model = flight_model

    # 创建虚拟摇杆 UI
    var joystick: VirtualJoystick = VirtualJoystick.new()
    joystick.name = "VirtualJoystick"
    joystick.anchor_right = Control.ANCHOR_END
    joystick.anchor_bottom = Control.ANCHOR_END
    input_mgr.add_child(joystick)

    # 如果场景有 CanvasLayer，将摇杆放到 CanvasLayer 上
    var hud_layer: CanvasLayer = scene_instance.get_node_or_null("HUD")
    if hud_layer:
        # 输入覆盖层在 HUD 同级但更高深度
        var input_layer: CanvasLayer = CanvasLayer.new()
        input_layer.name = "InputOverlay"
        input_layer.layer = 128  # 在 HUD 之上
        scene_instance.add_child(input_layer)
        input_layer.add_child(input_mgr)
    else:
        scene_instance.add_child(input_mgr)

    input_mgr.switch_mode(InputManager.InputMode.JOYSTICK)

func _setup_hud(scene_instance: Node, flight_model: FlightModel) -> void:
    if not flight_model:
        return

    # HUD 由 HUD 场景提供，我们需要实例化 hud.tscn
    var hud_scene: PackedScene = preload("res://scenes/hud.tscn")
    if not hud_scene:
        return

    var hud_instance: CanvasLayer = hud_scene.instantiate()
    hud_instance.name = "HUDInstance"
    scene_instance.add_child(hud_instance)

    # HUD 脚本直接挂载在根节点上
    if hud_instance.has_method("set_flight_model"):
        hud_instance.set_flight_model(flight_model)
