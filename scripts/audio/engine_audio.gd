extends Node
class_name EngineAudio

## 引擎音效播放器
## 放置在飞机模型上的引擎节点位置，根据油门和空速实时调整音高/音量。

@export var engine_type: int = 2  # 0=PISTON, 1=JET, 2=TURBOFAN

var _player: AudioStreamPlayer = null

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.bus = "Engine"
    add_child(_player)
    # TODO: 加载对应的引擎类型音效

func update(throttle: float, airspeed: float) -> void:
    if not _player:
        return

    # 油门映射到音高 (0.5 ~ 1.5)
    var pitch: float = 0.5 + throttle * 1.0
    _player.pitch_scale = pitch

    # 音量随空速调整
    var vol: float = -30 + throttle * 20 + airspeed * 0.02
    _player.volume_db = clamp(vol, -40, -3)
