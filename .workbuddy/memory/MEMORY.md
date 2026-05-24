# CoFly 项目长期记忆

## 项目概要
- 名称：CoFly（低配安卓飞行模拟器）
- 引擎：Godot 4.6.2
- 渲染器：Mobile（Vulkan 驱动，ETC2/ASTC 纹理压缩）
- 物理引擎：Jolt Physics
- 视口：854×480（canvas_items stretch）
- 仓库：本地 Git 已初始化（MIT 开源），GitHub 待推送
- 目标安装包：基础包 ~500MB，DLC 通过 GitHub Releases 游戏内下载
- 计划总计 ~5GB（多款高精度飞机模型）

## 架构总览 (Phase 1 MVP)

### 核心文件结构
- `scripts/flight/`：飞控系统
  - `aircraft_config.gd` - AircraftConfig Resource（空气动力学参数）
    - 含 `DynamicsType` 枚举 {LARGE_AIRLINER, MEDIUM_AIRLINER, FIGHTER}
  - `flight_model.gd` - 策略模式使用者（RigidBody3D）
    - 在 _ready 中根据 config.dynamics_type 实例化对应策略
    - 构建状态字典 → 委托给策略对象计算力/力矩
  - `flight_dynamics_base.gd` - 飞控策略基类 (RefCounted, class_name FlightDynamicsBase)
    - 接口：calculate_lift / calculate_drag / calculate_thrust / calculate_torques / auto_trim
  - `large_airliner_dynamics.gd` - 大型客机飞控策略
    - 高惯性/慢响应/强荷兰滚阻尼/强地面效应/提前抖杆(82%)
  - `medium_airliner_dynamics.gd` - 中小型客机飞控策略
    - 中等惯性/均衡响应/标准阻尼/正常失速预警(85%)
  - `fighter_dynamics.gd` - 战斗机飞控策略
    - 低惯性/快响应/放松静稳定性(40%)/高AoA(35°)/高滚转率(1.8x)/协调转弯辅助
- `scripts/input/`：输入系统
  - `input_interface.gd` - 策略模式基类
  - `virtual_joystick.gd` - 虚拟摇杆（左摇杆+右油门+偏航按钮）
  - `input_manager.gd` - 输入管理（模式切换+键盘后备）
- `scripts/scene/`：场景系统
  - `scene_config.gd` - SceneConfig Resource
  - `scene_loader.gd` - 场景加载器
- `scripts/audio/`：音频系统
  - `audio_manager.gd` - AutoLoad 音频管理器
  - `engine_audio.gd` - 引擎音效
- `scripts/ui/`：UI 系统
  - `main_menu.gd` / `aircraft_select.gd` / `scene_select.gd` / `settings_menu.gd`
  - `hud.gd`（含人工地平仪）/ `pause_menu.gd`
- `scripts/game_manager.gd`：AutoLoad 全局状态管理器

### 资源文件
- `resources/aircraft/`：AircraftConfig .tres 文件
  - `md_11.tres` (130t, 338.9m², 80000N 推力, LARGE_AIRLINER)
  - `boeing_737_sample.tres` (示例配置, MEDIUM_AIRLINER)
  - `f16_sample.tres` (示例配置, FIGHTER)
- `resources/scenes/`：SceneConfig .tres 文件
  - `tropical_island.tres`

### 场景文件
- `scenes/main_menu.tscn` - 主菜单
- `scenes/aircraft_select.tscn` - 飞机选择
- `scenes/scene_select.tscn` - 场景选择
- `scenes/settings.tscn` - 设置
- `scenes/flight_scene.tscn` - 飞行场景根节点（含环境/地形/水面/灯光）
- `scenes/hud.tscn` - HUD 叠加层
- `scenes/demo.tscn` - 旧 Demo（待清理）
- `scenes/test_flight.tscn` - 旧测试场景（待清理）

### 项目配置
- `project.godot`：主场景=main_menu.tscn，AutoLoad: game_manager / audio_manager

## 设计决策
- 飞行物理使用策略模式（FlightDynamicsBase + 3个子类），每架飞机通过 config.dynamics_type 自动选择对应飞控
- 三个飞控各有不同的升力曲线、阻力特征、推力响应、力矩特性和配平风格
- 战斗机飞控使用放松静稳定性（stability_reduction=0.4），让飞机更灵活
- 输入采用策略模式，支持运行时切换 JOYSTICK/GESTURE/GYRO
- Phase 1 仅实现 JOYSTICK，其他 Phase 2
- 尾随摄像机使用 lerp 平滑跟随，配置化 offset
- 3 阶段开发：MVP(1机1景) → 完整(4机4景+全输入) → 打磨(5机5景+全音频+成就)

## 注意事项
- `flight_model.gd` 禁用 gravity_scale=0，由 _integrate_forces 全权控制
- 场景加载由 scene_loader.gd 在运行时构建，flight_scene.tscn 仅为根节点模板
- 虚拟摇杆需要挂载在 CanvasLayer 上（layer=128）以获得触控事件
- 设置通过 ConfigFile 持久化到 user://settings.cfg
- 旧版 simple_flight.gd / input_handler.gd 保留作为参考，不再使用
- MD-11 GLB 模型需在 Godot 编辑器中绑定到 md_11.tres 的 model_scene 字段
