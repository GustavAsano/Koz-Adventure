extends PanelContainer

@onready var item: Label = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/Item
@onready var description: RichTextLabel = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer2/MarginContainer/Description
@onready var type: Label = $Margin/Columns/Other/Right/Item/MarginContainer/VBoxContainer/PanelContainer3/MarginContainer/Type
@onready var equips: PanelContainer = $Margin/Columns/Other/Right/Equips

var selected_item
var combat
var vendor
var conect = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.connect("openInventory",_openInventory)
	Signals.connect("combatActive",_combatActive)
	Signals.sendVendor.connect(_get_Vendor)
	Player.Inventory.inventory_interact.connect(on_inventory_interact)
	

func on_inventory_interact(inventory_data:InventoryData, index:int)->void:
	selected_item = inventory_data.slotDatas[index-1].baseItem
	item.text = selected_item.Name
	description.text = selected_item.Description
	type.text = selected_item.get_Type(selected_item.ItemType)

func _on_exit_button_pressed() -> void:
	Signals.updateMain.emit()
	Signals.closeShop.emit()
	get_parent().hide()

func _openInventory():
	if combat == true:
		equips.hide()
	else:
		equips.show()

func _combatActive(is_in_combat):
	combat = is_in_combat

func _get_Vendor(vendorName):
	var vendor_path = "res://inventory/"+vendorName+"Inventory.tres"
	if ResourceLoader.exists(vendor_path):
		vendor = load(vendor_path)
	if vendor:
		if conect == 0:
			vendor.inventory_interact.connect(on_inventory_interact)
			conect = 1
		$Margin/Columns/Other/Right/Equips.hide()
