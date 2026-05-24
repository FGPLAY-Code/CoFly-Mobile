extends Resource
class_name InputInterface

## 输入接口 — 策略模式基类
## 所有输入方式（虚拟摇杆/手势/陀螺仪）都实现这个接口，
## flight_model.gd 通过统一 API 读取输入，不关心来源。

## -- 主控制值 (每帧读取) --
func get_throttle() -> float:
    return 0.0           # 0.0 ~ 1.0

func get_pitch() -> float:
    return 0.0            # -1.0 (抬头) ~ 1.0 (低头)

func get_roll() -> float:
    return 0.0            # -1.0 (左滚) ~ 1.0 (右滚)

func get_yaw() -> float:
    return 0.0            # -1.0 (左偏) ~ 1.0 (右偏)

## -- 脉冲/开关信号 (上升沿触发) --
func get_gear_toggle() -> bool:
    return false

func get_flap_up() -> bool:
    return false

func get_flap_down() -> bool:
    return false

func get_pause() -> bool:
    return false

func get_autopilot_toggle() -> bool:
    return false

func get_view_switch() -> bool:
    return false
