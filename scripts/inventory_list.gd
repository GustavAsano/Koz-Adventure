extends PanelContainer

@onready var item_slots: VBoxContainer = $MarginContainer/Inventory/ScrollContainer/ItemSlots
@onready var use_button: Button = $MarginContainer/Inventory/Buttons/UseButton
@onready var change_button: Button = $MarginContainer/Inventory/Buttons/ChangeButton

const Slot = preload("res://inventory_slot.tscn")
var Equips
var inv_data:InventoryData
var selected_slot
var previous = 0
var start = 0
var indx = 0
var item 
var itemType
var combat = false
var vendor:InventoryData
var is_buying = false
var is_selling = false
var in_dungeon = false
var conect = 0

var indexesPlayer
var indexesVendor
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.connect("combatActive",_combatActive)
	Signals.connect("openInventory",_openInventory)
	Signals.sendVendor.connect(_get_Vendor)
	Signals.closeShop.connect(_close_Shop)
	Signals.blockEquip.connect(_blockEquip)
	Player.Inventory.inventory_interact.connect(on_inventory_interact)
	

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


func on_inventory_interact(inventory_data:InventoryData, index:int) -> void:
	indx = index
	selected_slot = inventory_data.slotDatas[indx-1]
	indexesPlayer = inv_data.indexesBackup
	if (is_buying == false or is_selling == true) and len(indexesPlayer) != 0:
		select_item(indx-indexesPlayer[indx-1])
	if is_buying == true and is_selling == false:
		indexesVendor = vendor.indexesBackup
		if len(indexesVendor) != 0 and index <= len(indexesVendor):
			select_item(indx-indexesVendor[indx-1])
	item = selected_slot.baseItem
	itemType = item.get_Type(item.ItemType)
	if is_buying == false and is_selling == false:
		if itemType == "Consumível":
			use_button.text = "Usar"
			use_button.show()

		if (itemType == "Arma" or itemType == "Armadura") and combat == false and in_dungeon == false:
			use_button.text = "Equipar"
			use_button.show()
		
		if (itemType == "Arma" or itemType == "Armadura") and combat == true:
			use_button.hide()
			
		if itemType == "Outros" or itemType == "Chave":
			use_button.hide()
	if is_buying == true and is_selling == false:
		use_button.text = "Comprar"
		use_button.show()
	if is_buying == false and is_selling == true and itemType != "Chave":
		use_button.text = "Vender"
		use_button.show()
		for equip in Player.Equips.slotDatas:
			if equip != null:
				if selected_slot.baseItem.Name == equip.baseItem.Name:
					use_button.hide()

func select_item(index:int):
	if index >= item_slots.get_child_count():
		index -= 1
	var inventory_slot = item_slots.get_child(index) 
	var styleBox = StyleBoxFlat.new()
	styleBox.bg_color = Color.hex(0x171717)
	if inventory_slot.has_theme_stylebox_override("panel") == false:
		styleBox.border_width_bottom = 2
		styleBox.border_width_left = 2
		styleBox.border_width_right = 2
		styleBox.border_width_top = 2
		inventory_slot.add_theme_stylebox_override("panel",styleBox)
		
	if previous != index and start != 0:
		inventory_slot = item_slots.get_child(previous)
		if inventory_slot != null:
			inventory_slot.remove_theme_stylebox_override("panel")
	previous = index
	start += 1
	

func _on_use_button_pressed() -> void:
	Equips = Player.Equips
	if selected_slot != null:
		if is_buying == false and is_selling == false:
			if itemType == "Consumível":
				if (Battle.currentTurn == "Player" or Battle.currentTurn == "") and Battle.casting == false:
					if combat:
						self.get_parent().get_parent().get_parent().get_parent().hide()
					selected_slot.qnt -= 1
					Signals.useItem.emit(selected_slot.baseItem)
					if selected_slot.qnt < 1:
						selected_slot = null
					consumeItem(indx)
					if combat:
						self.get_parent().get_parent().get_parent().get_parent().hide()
			if itemType == "Armadura":
				if selected_slot.baseItem.Armor_Type == 0:
					if Equips.slotDatas[0] != null:
						Equips.slotDatas[0].baseItem = selected_slot.baseItem
					else:
						Equips.slotDatas[0] = selected_slot.duplicate()
				if selected_slot.baseItem.Armor_Type == 1:
					Equips.slotDatas[1].baseItem = selected_slot.baseItem
			if itemType == "Arma":
				Equips.slotDatas[2].baseItem = selected_slot.baseItem
			Signals.updatePlayerEq.emit()
		if is_buying == true and is_selling == false:
			if Player.gold >= selected_slot.baseItem.BuyPrice:
				Signals.gainItem.emit(selected_slot.baseItem,1)
				Player.gold -= selected_slot.baseItem.BuyPrice
				Signals.updateMain.emit()
		if is_buying == false and is_selling == true:
			Player.gold += selected_slot.baseItem.SellPrice
			selected_slot.qnt -= 1
			if selected_slot.qnt < 1:
				selected_slot = null
			consumeItem(indx)
			Signals.updateMain.emit()
				
			
func consumeItem(index:int):
	if selected_slot != null and len(inv_data.indexesBackup) != 0:
		var select_itemSlot = item_slots.get_child(index-inv_data.indexesBackup[indx-1]).get_child(0)
		var qnt = select_itemSlot.get_child(0).get_child(0)
		qnt.text = "x%s"%selected_slot.qnt
	
	else:
		if len(inv_data.indexesBackup) != 0:
			indx = index -inv_data.indexesBackup[indx-1]
		var select_itemSlot = item_slots.get_child(indx)
		select_itemSlot.queue_free()
		itemType = null
		previous = 1
		indx += 1

func _combatActive(is_in_combat):
	combat = is_in_combat
	addItems(Player.Inventory)

func _openInventory():
	addItems(Player.Inventory)

func _get_Vendor(vendorName):
	var vendor_path = "res://inventory/"+vendorName+"Inventory.tres"
	if ResourceLoader.exists(vendor_path):
		vendor = load(vendor_path)
	if vendor:
		if conect == 0:
			vendor.inventory_interact.connect(on_inventory_interact)
			conect = 1
		addItems(vendor)
		is_buying = true
		is_selling = false
		change_button.show()
		change_button.text = "Vender"

func _on_change_button_pressed() -> void:
	if is_buying == true:
		is_buying = false
		is_selling = true
		change_button.text = "Comprar"
		use_button.hide()
		addItems(Player.Inventory)
		inv_data.correction = 0
		start = 0
		previous = 0
		indx = 0
	else:
		is_buying = true
		is_selling = false
		change_button.text = "Vender"
		use_button.hide()
		addItems(vendor)
		vendor.correction = 0
		start = 0
		previous = 0
		indx = 0

func _close_Shop():
	if is_buying == true or is_selling == true:
		conect = 0
		vendor.inventory_interact.disconnect(on_inventory_interact)
		is_buying = false
		is_selling = false


func _blockEquip(dungeon):
	in_dungeon = dungeon
