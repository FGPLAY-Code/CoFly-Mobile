extends CanvasLayer
class_name PauseMenu

## 暂停菜单

@onready var resume_btn: Button = $VBoxContainer/ResumeBtn
@onready var restart_btn: Button = $VBoxContainer/RestartBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn

func _ready() -> void:
    resume_btn.pressed.connect(_on_resume)
    restart_btn.pressed.connect(_on_restart)
    quit_btn.pressed.connect(_on_quit)

func _on_resume() -> void:
    get_tree().paused = false
    queue_free()

func _on_restart() -> void:
    get_tree().paused = false
    GameManager.start_flight()

func _on_quit() -> void:
    get_tree().paused = false
    GameManager.return_to_menu()
