extends Camera3D

## 追尾摄像机
## 放置在飞机后方时自动跟随飞机运动。
## 作为 Aircraft 的子节点，通过父子变换自动跟随。
## 在 _ready() 中主动激活确保渲染生效。

func _ready() -> void:
	make_current()
