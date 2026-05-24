extends Node

## 音频管理器 (AutoLoad 单例)
## 管理所有音频总线、引擎音效和环境音效。

## -- 音频总线索引 --
enum Bus {MASTER, ENGINE, EFFECTS, UI, AMBIENT}

var _wind_player: AudioStreamPlayer = null
var _stall_player: AudioStreamPlayer = null

func _ready() -> void:
	# 创建音频播放器
	_setup_buses()

func _setup_buses() -> void:
	# 如果总线不存在则创建
	for bus_name in ["Master", "Engine", "Effects", "UI", "Ambient"]:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)

func play_engine_sound(_type: int, _throttle: float, _airspeed: float) -> void:
	# Phase 3 完整实现
	# 使用 AudioStreamGenerator 程序化生成引擎声
	pass

func play_stall_warning() -> void:
	if not _stall_player:
		_stall_player = AudioStreamPlayer.new()
		_stall_player.bus = "Effects"
		add_child(_stall_player)
	if _stall_player.playing:
		return
	# TODO: 加载 stall_warning.ogg

func play_wind(airspeed: float) -> void:
	if not _wind_player:
		_wind_player = AudioStreamPlayer.new()
		_wind_player.bus = "Engine"
		_wind_player.volume_db = -20
		add_child(_wind_player)
	# 风速越高音量越大
	var vol: float = -40 + airspeed * 0.1
	_wind_player.volume_db = clamp(vol, -40, -10)

func play_ui_click() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = "UI"
	add_child(player)
	# TODO: 加载 ui_click.ogg
	player.play()
	# 自动清理
	await get_tree().create_timer(1.0).timeout
	player.queue_free()

func set_bus_volume(bus: Bus, volume: float) -> void:
	var idx: int = AudioServer.get_bus_index(["Master", "Engine", "Effects", "UI", "Ambient"][bus])
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))

func get_bus_volume(bus: Bus) -> float:
	var idx: int = AudioServer.get_bus_index(["Master", "Engine", "Effects", "UI", "Ambient"][bus])
	if idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 0.0
