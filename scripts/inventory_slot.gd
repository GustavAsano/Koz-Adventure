extends PanelContainer

@onready var quantity: Label = $HBoxContainer/MarginContainer/Quantity
@onready var item: Label = $HBoxContainer/Item
@onready var inventory_slot: PanelContainer = $"."

signal slot_clicked(index:int)

func set_slot_data(slot_data: ItemSlots)-> void:
	if slot_data.qnt >= 1:
		var item_data = slot_data.baseItem
		item.text = item_data.Name
		quantity.text = "x%d"%slot_data.qnt


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT) and event.is_pressed():
		slot_clicked.emit(get_index())
	
