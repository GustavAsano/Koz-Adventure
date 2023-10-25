extends Node

@export var pcname = "Koz"
@export var level = 1
@export var strength = 1
@export var agility = 1
@export var intelligence = 1
@export var constituion = 1
@export var current_health = 30
@export var current_mp = 20
@export var experience = 0
@export var statPoints = 5
@export var promptID = 1
@export var dialogID = 0
@export var plevel = 1
@export var allocatedStats = 0
@export var gold:int = 50
@onready var Equips = preload("res://inventory/InventoryEquip.tres")
@onready var Inventory = preload("res://inventory/Inventory.tres")
@onready var PlayerSpells = preload("res://spells/PlayerSpellList.tres")

var MaxLv = 10
var max_health
var max_mp
var defense
var damage_variance
var equipments
var equiptype
var weapon
var armor
var head:Armors
var physMod
var magMod
var evasion
var lvRequirements = expRequirements(MaxLv)
var accumulatedExp = totalExp(lvRequirements)
var levelEXP
var weapon_damage
var weapon_multiplier
var head_mod = 0
var head_evasion = 10
var head_hp = 0
var head_mp = 0
var castHaste = 0
var critChance = 0

func _ready() -> void:
	Signals.connect("updateStats",_updateStats)
	Signals.connect("callLevelUp",levelUp)
	Signals.connect("gainEXP",_gainEXP)
	Signals.connect("useItem",_use_Item)
	Signals.updatePlayerEq.connect(_updatePlayerEq)
	Signals.loadEquipment.connect(_loadEquips)
	Signals.loadInventory.connect(_loadInventory)
	Signals.loadSpells.connect(_loadSpells)
	Signals.sendStoryID.connect(_recover)
	Signals.gainItem.connect(_gainItem)
	get_Equip(Equips.slotDatas)
	statsCalc()

func get_Equip(slots_data: Array[ItemSlots]):
	equipments = []
	equiptype = []
	for equips in slots_data:
		if equips != null:
			equipments.append(equips)
			equiptype.append(typeof(equips))
		else:
			equipments.append(0)
			equiptype.append(typeof(0))
	for i in range(len(equiptype)):
		if equiptype[i] != 2:
			if i == 0:
				head = equipments[0].baseItem
				head_mod = head.Modifier
				head_evasion = head.Evasion
				head_hp = head.HPExtra
				head_mp = head.MPExtra
			if i == 1:
				armor = equipments[1].baseItem
			if i == 2:
				weapon = equipments[2].baseItem
				weapon_damage = weapon.Damage
				weapon_multiplier = weapon.Multiplier

func statsCalc():
	if level > 1:
		levelEXP = max(0,experience - accumulatedExp[plevel-2])
	else:
		levelEXP = experience
	physMod = strength
	magMod = intelligence
	equipMods()
	max_health = 15 + 5*(level-1) + 5*constituion + armor.HPExtra + head_hp
	max_mp = 5 + 5*(level-1) + 5*intelligence + armor.MPExtra + head_mp
	defense = armor.Defense + 2*constituion
	var minDmg = weapon_multiplier + physMod
	var maxDmg = weapon_multiplier * weapon_damage + physMod
	damage_variance = [minDmg,maxDmg]
	evasion = max(0,5*agility + weapon.Evasion + armor.Evasion + head_evasion)
	castHaste = round(float(agility)/5)
	critChance = 2.5+2.5*agility
		
	
func expRequirements(lv)-> Array:
	var baseExperience = 20 
	var experienceMultiplier = 1.5
	var expArray = []
	for i in range(1, lv):
		expArray.append(int(baseExperience * (experienceMultiplier ** (i - 1))))
	return expArray
	
func totalExp(lvReq):
	var sumExp = lvReq[0]
	var total = [sumExp] 
	for i in range(1,MaxLv-1):
		sumExp +=  lvReq[i]
		total.append(sumExp)
	return total

func levelUp():
	if level < MaxLv:
		for i in range(len(accumulatedExp)-level):
			if experience >= accumulatedExp[level - 1 + i]:
				statPoints += 1
				level += 1


func updateBar(progressBar ,currentValue, maxValue):
	progressBar.value = currentValue
	progressBar.max_value = maxValue
	var progressLabel = progressBar.get_child(0)
	if currentValue <= maxValue:
		progressLabel.text = "%d/%d" % [currentValue,maxValue]
	if currentValue > maxValue:
		progressLabel.text = "%d/%d+" % [maxValue,maxValue]
		progressBar.tooltip_text = "Aperte C para distribuir seus pontos de atributos!"

func _updateStats(lv,stren,agi,intel,con):
	plevel = lv
	strength = stren
	agility = agi
	intelligence = intel
	constituion = con
	statsCalc()

func _gainEXP(expValue):
	experience += expValue
	if plevel > 1:
		levelEXP = experience - accumulatedExp[plevel-2] 
	else:
		levelEXP = experience
	levelUp()
	
func _use_Item(item:Consumables):
	var hpRec = item.HP_Restored
	current_health = min(current_health+hpRec,max_health)
	var mpRec = item.MP_Restored
	current_mp = min(current_mp+mpRec,max_mp)
	
func _updatePlayerEq():
	get_Equip(Equips.slotDatas)
	statsCalc()
	if current_health > max_health:
		current_health = max_health
	if current_mp > max_mp:
		current_mp = max_mp
	Signals.updateEquips.emit()

func equipMods():
	if weapon.Weapon_Type == 0:
		physMod += weapon.Modifier 
	if weapon.Weapon_Type == 1:
		magMod += weapon.Modifier
	if armor.ModType == 0:
		physMod += armor.Modifier
	if armor.ModType == 1:
		magMod += armor.Modifier
	if head_mod != 0:
		if head.ModType == 0:
			physMod += head_mod
		if head.ModType == 1:
			magMod += head_mod

func _loadEquips(equipment:InventoryData):
	Equips = equipment
	get_Equip(Equips.slotDatas)
	statsCalc()


func _loadInventory(inv:InventoryData):
	Inventory = inv
	
func _loadSpells(playerSpells:SpellList):
	PlayerSpells = playerSpells

func _recover(_dialog,prompt):
	if prompt == 20:
		current_health = max_health
		current_mp = max_mp
		Signals.updateMain.emit()
		Signals.updateCharTab.emit()

func _gainItem(item:ItemData,qnt:int):
	var is_in_inventory = false
	for child in Inventory.slotDatas:
		if child.baseItem.Name == item.Name:
			is_in_inventory = true
			child.qnt += qnt
	if is_in_inventory == false:
		var obtained = ItemSlots.new()
		obtained.baseItem = item
		obtained.qnt = qnt
		Inventory.slotDatas.append(obtained)
