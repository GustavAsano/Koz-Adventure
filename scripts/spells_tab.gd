extends PanelContainer

@onready var spell_slots: VBoxContainer = $Margin/Columns/PanelContainer/MarginContainer/SpellList/ScrollContainer/SpellSlots
@onready var use_button: Button = $Margin/Columns/PanelContainer/MarginContainer/SpellList/Buttons/UseButton
@onready var back_button: Button = $Margin/Columns/PanelContainer/MarginContainer/SpellList/Buttons/BackButton
@onready var spellName: Label = $Margin/Columns/Other/Right/Spell/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/Name
@onready var mp_cost: Label = $Margin/Columns/Other/Right/Spell/MarginContainer/VBoxContainer/PanelContainer3/MarginContainer/HBoxContainer/MPCost
@onready var damage: Label = $Margin/Columns/Other/Right/Spell/MarginContainer/VBoxContainer/PanelContainer3/MarginContainer/HBoxContainer/Damage
@onready var description: RichTextLabel = $Margin/Columns/Other/Right/Spell/MarginContainer/VBoxContainer/PanelContainer2/MarginContainer/Description

const Slot = preload("res://spellSlot.tscn")
var vendor:SpellList
var indx = 0
var spell:Spells
var previous = 0
var start = 0
var conect = 0
var combat = false
var is_in_chartab = false
var is_buying = false
var in_dungeon = false
var indexesVendor = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spells = Player.PlayerSpells
	spells.spell_interact.connect(_on_spell_interact)
	Signals.connect("combatActive",_combatActive)
	Signals.characterSpells.connect(_from_char_tab)
	Signals.sendVendor.connect(_get_Vendor_SpellList)
	addSpells(Player.PlayerSpells)

func addSpells(spell_data: SpellList):
	for child in spell_slots.get_children():
		if child != $Margin/Columns/PanelContainer/MarginContainer/SpellList/ScrollContainer/SpellSlots/Spell:
			child.queue_free()
	for slot_data in spell_data.slotDatas:
		var slot = Slot.instantiate()
		
		if slot_data != null:
			spell_slots.add_child(slot)
			slot.slot_clicked.connect(spell_data.on_slot_clicked)
			slot.set_slot_data(slot_data)
		else:
			slot.queue_free()

func _on_spell_interact(spell_data:SpellList, index:int) -> void:
	indx = index
	spell = spell_data.slotDatas[indx-1]
	if spell != null:
		spellInfo()
		select_spell(indx)
		if is_buying == false:
			if combat == false or Player.current_mp < spell.MP_Cost:
				use_button.hide()
			else:
				use_button.text = "Usar"
				use_button.show()
		else:
			if Player.intelligence >= spell.IntRequirement and Player.gold >= spell.LearnCost:
				use_button.text = "Aprender"
				use_button.show()
				for playerspell in Player.PlayerSpells.slotDatas:
					if spell == playerspell:
						use_button.hide()
			else:
				use_button.hide()


func select_spell(index:int):
	if index >= spell_slots.get_child_count():
		index -= 1
	var spell_slot = spell_slots.get_child(index) 
	var styleBox = StyleBoxFlat.new()
	styleBox.bg_color = Color.hex(0x171717)
	
	if spell_slot.has_theme_stylebox_override("panel") == false:
		styleBox.border_width_bottom = 2
		styleBox.border_width_left = 2
		styleBox.border_width_right = 2
		styleBox.border_width_top = 2
		spell_slot.add_theme_stylebox_override("panel",styleBox)
		
	if previous != index and start != 0:
		spell_slot = spell_slots.get_child(previous)
		if spell_slots != null:
			spell_slot.remove_theme_stylebox_override("panel")
	previous = index
	start += 1

func _on_exit_button_pressed() -> void:
	is_buying = false
	use_button.hide()
	if is_in_chartab == true:
		self.get_parent().get_parent().hide()
	else:
		get_parent().hide()
		
func _on_use_button_pressed() -> void:
	if is_buying == false:
		Signals.castSpell.emit(spell)
	else:
		Player.gold -= spell.LearnCost
		Player.PlayerSpells.slotDatas.append(spell)
		use_button.hide()
		Signals.updateMain.emit()
			

func _combatActive(is_in_combat):
	combat = is_in_combat
	is_buying = false
	is_in_chartab = false
	addSpells(Player.PlayerSpells)
	back_button.hide()
	
func _from_char_tab():
	is_in_chartab = true
	is_buying = false
	addSpells(Player.PlayerSpells)
	back_button.show()

func _on_back_button_pressed() -> void:
	self.hide()

func spellInfo():
	spellName.text = spell.Name
	description.text = spell.Description
	var dmg_range = spell.damage_range()
	mp_cost.text = "MP: %d" % spell.MP_Cost
	damage.text = "Dano: %d~%d"%[dmg_range[0],dmg_range[1]]

func _get_Vendor_SpellList(NPCName):
	back_button.hide()
	var vendor_path = "res://spells/"+NPCName+"SpellList.tres"
	if ResourceLoader.exists(vendor_path) and vendor == null:
		vendor = load(vendor_path)
		if conect == 0:
			conect = 1
			vendor.spell_interact.connect(_on_spell_interact)
		addSpells(vendor)
		is_buying = true

