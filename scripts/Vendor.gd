extends PanelContainer

@onready var item: Label = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/Item
@onready var type: Label = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer3/MarginContainer/Type
@onready var description: RichTextLabel = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer2/MarginContainer/Description
@onready var item_slots: VBoxContainer = $Margin/Columns/PanelContainer/MarginContainer/Inventory/ScrollContainer/ItemSlots

const Slot = preload("res://inventory_slot.tscn")
var inv_data:InventoryData
var selected_slot

func _on_use_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	pass # Replace with function body.

func addItems(inventory_data: InventoryData):
	inv_data = inventory_data
	for child in item_slots.get_children():
		if child != $MarginContainer/Inventory/ScrollContainer/ItemSlots/Names:
			child.queue_free()
	for slot_data in inventory_data.slotDatas:
		var slot = Slot.instantiate()
		if  slot_data.qnt > 0:
			item_slots.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data != null:
			slot.set_slot_data(slot_data)
		else:
			slot.queue_free()
