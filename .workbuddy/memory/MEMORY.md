# CoFly 项目长期记忆

## 项目概要
- 名称：CoFly（飞行模拟器项目）
- 引擎：Godot 4.6.2
- 渲染器：Mobile（Vulkan 驱动，ETC2/ASTC 纹理压缩）
- 物理引擎：Jolt Physics
- 视口：854×480（canvas_items + keep）
- 仓库：本地 Git 已初始化，GitHub 仓库待创建（需安装 gh CLI）

## 项目结构
- `models/` 目录已存在（未纳入 Git）
- `scripts/`：飞行物理（simple_flight.gd）和输入处理（input_handler.gd）
- `scripts/tail_camera.gd`：摄像头激活脚本（用 make_current() 确保渲染）
- `scenes/demo.tscn`：Demo 主场景（天空+地面+MD-11+摄像机+飞行控制）
- `scenes/test_flight.tscn`：开发测试场景（与 demo.tscn 结构相同）

## 输入映射（已定义，events 待绑定）
- throttle_up / throttle_down
- pitch_up / pitch_down
- roll_left / roll_right
- yaw_left / yaw_right

## 注意事项
- 编辑 project.godot 时 Godot 编辑器会锁定文件，需通过编辑器关闭后修改或用命令行写入
- `icon.svg.import` 应提交到 Git，不能被 .gitignore 排除
- `simple_flight.gd` 禁用 gravity_scale=0，由 _integrate_forces 全权控制物理
- `simple_flight.gd` 默认参数调优为 MD-11 大型客机（mass=500, thrust=4000），含重心偏移
- `input_handler.gd` 在 _ready 中程序化绑定键盘按键到输入动作，便于后续替换为触摸/陀螺仪
- MD-11 GLB 模型由 simple_flight.gd 代码加载（preload + instantiate + 180°Y旋转），避免编辑器意外移除实例
- 追尾摄像机 Camera3D @ (0, 5, 18)，使用 tail_camera.gd 脚本激活（不用 tscn current=true）
- Environment ambient_light_source=2（从天空采样环境光），避免暗面全黑
