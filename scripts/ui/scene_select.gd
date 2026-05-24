extends Control
class_name SceneSelect

## 场景选择界面

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_btn: Button = $VBoxContainer/HBoxContainer/BackBtn
@onready var confirm_btn: Button = $VBoxContainer/HBoxContainer/ConfirmBtn

var _selected_index: int = -1

func _ready() -> void:
    back_btn.pressed.connect(_on_back)
    confirm_btn.pressed.connect(_on_confirm)
    _populate_grid()

func _populate_grid() -> void:
    for child in grid.get_children():
        child.queue_free()

    var gm = GameManager
    for i in gm.scene_list.size():
        var sc: SceneConfig = gm.scene_list[i]
        var card: Button = Button.new()
        card.text = sc.display_name
        card.size_flags_horizontal = Control.SIZE_EXPAND
        card.custom_minimum_size = Vector2(200, 80)
        card.pressed.connect(_on_card_selected.bind(i))
        grid.add_child(card)

func _on_card_selected(index: int) -> void:
    _selected_index = index
    for i in grid.get_child_count():
        var btn: Button = grid.get_child(i) as Button
        if btn:
            btn.disabled = (i == index)

func _on_confirm() -> void:
    if _selected_index >= 0:
        var gm = GameManager
        gm.selected_scene = gm.scene_list[_selected_index]
        gm.return_to_menu()

func _on_back() -> void:
    GameManager.return_to_menu()
