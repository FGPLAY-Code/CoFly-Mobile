extends Control
class_name AircraftSelect

## 飞机选择界面

@onready var grid: GridContainer = $ScrollContainer/GridContainer
@onready var back_btn: Button = $VBoxContainer/HBoxContainer/BackBtn
@onready var confirm_btn: Button = $VBoxContainer/HBoxContainer/ConfirmBtn

var _selected_index: int = -1

func _ready() -> void:
    back_btn.pressed.connect(_on_back)
    confirm_btn.pressed.connect(_on_confirm)

    _populate_grid()

func _populate_grid() -> void:
    # 移除现有条目
    for child in grid.get_children():
        child.queue_free()

    # 从 GameManager 获取飞机列表
    var gm = GameManager
    for i in gm.aircraft_list.size():
        var ac: AircraftConfig = gm.aircraft_list[i]
        var card: Button = Button.new()
        card.text = ac.display_name
        card.size_flags_horizontal = Control.SIZE_EXPAND
        card.custom_minimum_size = Vector2(200, 80)
        card.pressed.connect(_on_card_selected.bind(i))
        grid.add_child(card)

func _on_card_selected(index: int) -> void:
    _selected_index = index
    # 高亮选中的卡片
    for i in grid.get_child_count():
        var btn: Button = grid.get_child(i) as Button
        if btn:
            btn.disabled = (i == index)

func _on_confirm() -> void:
    if _selected_index >= 0:
        var gm = GameManager
        gm.selected_aircraft = gm.aircraft_list[_selected_index]
        gm.return_to_menu()

func _on_back() -> void:
    GameManager.return_to_menu()
