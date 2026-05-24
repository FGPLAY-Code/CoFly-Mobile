extends Camera3D

## 追尾摄像机
## 在 _ready() 中主动激活，确保渲染生效。
## 放置在飞机后方时自动跟随飞机运动。

func _ready() -> void:
	make_current()
