extends PanelContainer

@onready var spell_name: Label = $SpellName

signal slot_clicked(index:int)

func set_slot_data(slot_data: Spells)-> void:
	spell_name.text = slot_data.Name


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT) and event.is_pressed():
		slot_clicked.emit(get_index())
