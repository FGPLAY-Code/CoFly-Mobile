extends Control
class_name SettingsMenu

## 设置界面

@onready var back_btn: Button = $VBoxContainer/BackBtn
@onready var sensitivity_slider: HSlider = $VBoxContainer/ControlSettings/SensitivitySlider
@onready var invert_pitch_check: CheckBox = $VBoxContainer/ControlSettings/InvertPitchCheck
@onready var master_vol_slider: HSlider = $VBoxContainer/AudioSettings/MasterVolSlider
@onready var quality_option: OptionButton = $VBoxContainer/GraphicsSettings/QualityOption

func _ready() -> void:
    back_btn.pressed.connect(_on_back)
    _load_current_settings()

func _load_current_settings() -> void:
    var gm = GameManager
    var s = gm.settings
    sensitivity_slider.value = s.get("sensitivity", 1.0)
    invert_pitch_check.button_pressed = s.get("invert_pitch", false)
    master_vol_slider.value = s.get("master_volume", 0.8)
    quality_option.selected = s.get("quality_preset", 1)

func _on_back() -> void:
    _save_settings()
    GameManager.return_to_menu()

func _save_settings() -> void:
    var gm = GameManager
    gm.settings["sensitivity"] = sensitivity_slider.value
    gm.settings["invert_pitch"] = invert_pitch_check.button_pressed
    gm.settings["master_volume"] = master_vol_slider.value
    gm.settings["quality_preset"] = quality_option.selected
    gm.save_settings()
