extends PanelContainer

@onready var pc_name: Label = $Margin/Columns/Stats/Left/PCStats/MarginContainer/PC/ID/PCName
@onready var level: Label = $Margin/Columns/Stats/Left/PCStats/MarginContainer/PC/ID/Level
@onready var hp_bar: ProgressBar = $Margin/Columns/Stats/Left/PCStats/MarginContainer/PC/HP/HPBar
@onready var mp_bar: ProgressBar = $Margin/Columns/Stats/Left/PCStats/MarginContainer/PC/MP/MPBar
@onready var exp_bar: ProgressBar = $Margin/Columns/Stats/Left/PCStats/MarginContainer/PC/EXP/EXPBar
@onready var str_score: Label = $Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/GridContainer/Str/HBoxContainer/StrScore
@onready var int_score: Label = $Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/GridContainer/Int/HBoxContainer/IntScore
@onready var con_score: Label = $Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/GridContainer/Con/HBoxContainer/ConScore
@onready var points: Label = $Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/AttPoints/Label/Points
@onready var phys_damage: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Phys/PhysDamage
@onready var wpn_dmg: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/HBoxContainer/Weapon/WpnDmg
@onready var phys_mod: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/HBoxContainer/Mod/PhysMod
@onready var mag_mod: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Mag/MagMod
@onready var defense: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Def/Defense
@onready var evasion: Label = $Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Eva/Evasion
@onready var agi_score: Label = $Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/GridContainer/Agi/HBoxContainer/AgiScore
@onready var cast_haste: Label = $"Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Combat Agility/Haste/CastHaste"
@onready var critical: Label = $"Margin/Columns/Other/Right/CombatStats/MarginContainer/VBoxContainer/Combat Agility/Crit/Critical"


var strScore = Player.strength
var agiScore = Player.agility
var intScore = Player.intelligence
var conScore = Player.constituion
var statPoints
var plevel = Player.plevel
var wpnpMod
var wpnmMod
var lvrequirement
var accumulatedEXP
var def = Player.defense
var allocatedStats
var combat = false
var equipType
var head
var armor
var weapon
var eva
const equipText = preload("res://text.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.connect("combatActive",_combatActive)
	Signals.connect("updateCharTab",_updateCharTab)
	Signals.updateEquips.connect(_update_Equips)
	Signals.characterCasting.connect(_updateEvasion)
	Signals.reload.connect(_load)
	Signals.updateMain.connect(_updateHealth)
	pc_name.text = Player.pcname
	lvrequirement = Player.lvRequirements
	accumulatedEXP = Player.accumulatedExp
	initPC()

func initPC():
	showButtons()
	updateEquips()
	update(plevel,strScore,agiScore,intScore,conScore)
	Player.updateBar(exp_bar,Player.levelEXP,lvrequirement[plevel-1])
	allocatedStats = Player.allocatedStats
	statPoints = Player.statPoints
	points.text = str(statPoints)
	
	
func updateEquips():
	armor = Player.armor
	weapon = Player.weapon
	head = Player.head
	
	equipType = Player.equiptype
	
	wpnpMod = Player.physMod - Player.strength
	wpnmMod = Player.magMod - Player.intelligence

func changeStat(stat,statlabel,opsign):
	if Player.statPoints == 0:
		return stat
	if opsign == 0 and statPoints > 0 and plevel < 10:
		if stat == 5 and plevel < 5:
			return stat
		if allocatedStats >= 5:
			plevel += 1
			allocatedStats += 1
		else:
			allocatedStats += 1
		if stat < 5 and plevel < 5:
			stat += 1
		if plevel >= 5:
			stat += 1
		statlabel.text = str(stat)
		statPoints -= 1
		points.text = str(statPoints)
		return stat
	elif opsign != 0 and stat-1 > 0:
		if allocatedStats > 5 and plevel > 1:
			plevel -= 1
			allocatedStats -= 1
		else:
			allocatedStats -= 1
		stat -= 1
		statlabel.text = str(stat)
		statPoints += 1
		points.text = str(statPoints)
		return stat
	else:
		return stat
	


func _on_reset_button_pressed() -> void:
	strScore = Player.strength
	agiScore = Player.agility
	intScore = Player.intelligence
	conScore = Player.constituion
	statPoints = Player.statPoints
	allocatedStats = Player.allocatedStats
	points.text = str(statPoints)
	plevel = Player.plevel
	update(plevel,strScore,agiScore,intScore,conScore)


func _on_int_plus_button_pressed() -> void:
	intScore = changeStat(intScore,int_score,0)
	update(plevel,strScore,agiScore,intScore,conScore)

func _on_con_plus_button_pressed() -> void:
	conScore = changeStat(conScore,con_score,0)
	update(plevel,strScore,agiScore,intScore,conScore)

func _on_str_plus_button_pressed() -> void:
	strScore = changeStat(strScore,str_score,0)
	update(plevel,strScore,agiScore,intScore,conScore)

func _on_str_minus_button_pressed() -> void:
	strScore = changeStat(strScore,str_score,1)
	update(plevel,strScore,agiScore,intScore,conScore)
	
func _on_int_minus_button_pressed() -> void:
	intScore = changeStat(intScore,int_score,1)
	update(plevel,strScore,agiScore,intScore,conScore)
	
func _on_con_minus_button_pressed() -> void:
	conScore = changeStat(conScore,con_score,1)
	update(plevel,strScore,agiScore,intScore,conScore)

func update(lv,strength,agility,intelligence,constitution):
	level.text = "Lv. "+str(lv)
	str_score.text = str(strength)
	agi_score.text = str(agility)
	int_score.text = str(intelligence)
	con_score.text = str(constitution)
	var damage_var = dmgVar(strength)
	phys_damage.text = "%d~%d" % [damage_var[0],damage_var[1]]
	phys_mod.text = str(wpnpMod + strength)
	mag_mod.text = str(wpnmMod + intelligence)
	defense.text = str(updateDef(lv,constitution))
	evasion.text = str(updateEvasion(agility))+"%"
	cast_haste.text = str(castHaste(agility))
	critical.text = str(criticalHit(agility))+"%"
	Player.updateBar(hp_bar,Player.current_health,maxhp(lv,constitution))
	Player.updateBar(mp_bar,Player.current_mp,maxmp(lv,intelligence))
	

func _updateCharTab():
	Player.updateBar(exp_bar,Player.levelEXP,lvrequirement[plevel-1])
	statPoints = Player.statPoints
	points.text = str(statPoints)
	
func maxhp(lv,constitution):
	var hp = 15 + 5*(lv-1) + 5*constitution + armor.HPExtra + Player.head_hp
	return hp

func maxmp(lv,intelligence):
	var mp =  5 + 5*(lv-1) + 5*intelligence + armor.MPExtra + Player.head_mp
	return mp

func updateDef(lv,constitution):
	var d = armor.Defense + 2*constitution + (lv-1)
	return d

func updateEvasion(agility):
	var evs = max(0,5*agility + weapon.Evasion + armor.Evasion + Player.head_evasion)
	return evs

func castHaste(agility):
	var haste = int(round(agility/5))
	return haste

func criticalHit(agility):
	var crit = 2.5 + 2.5*agility
	return crit

func dmgVar(strength):
	var minDmg = Player.weapon_multiplier + wpnpMod + strength
	var maxDmg = Player.weapon_multiplier * Player.weapon_damage + wpnpMod + strength
	var variance = [minDmg,maxDmg]
	return variance

func _on_confirm_button_pressed() -> void:
	Signals.updateStats.emit(plevel,strScore,agiScore,intScore,conScore)
	Player.allocatedStats = allocatedStats
	Player.statPoints = statPoints
	update(Player.level,Player.strength,Player.agility,Player.intelligence,Player.constituion)
	Player.updateBar(exp_bar,Player.levelEXP,lvrequirement[plevel-1])
	showButtons()

func showButtons():
	if Player.statPoints != 0 and combat == false:
		$Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/Buttons/ResetButton.show()
		$Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/Buttons/ConfirmButton.show()
	else:
		$Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/Buttons/ResetButton.hide()
		$Margin/Columns/Stats/Left/AttributesBox/MarginContainer/VBoxContainer/Buttons/ConfirmButton.hide()

func _combatActive(is_in_combat):
	combat = is_in_combat
	showButtons()
	
func _on_exit_button_pressed() -> void:
	Signals.updateMain.emit()
	_on_reset_button_pressed()
	get_parent().hide()

func _on_spell_list_button_pressed() -> void:
	$SpellsTab.show()
	Signals.characterSpells.emit()

func _update_Equips():
	initPC()


func _on_agi_minus_button_pressed() -> void:
	agiScore = changeStat(agiScore,agi_score,1)
	update(plevel,strScore,agiScore,intScore,conScore)


func _on_agi_plus_button_pressed() -> void:
	agiScore = changeStat(agiScore,agi_score,0)
	update(plevel,strScore,agiScore,intScore,conScore)

func _updateEvasion(_charName,_spell,_castTime):
	evasion.text = str(Player.evasion)+"%"

func _load():
	get_tree().reload_current_scene()

func _updateHealth():
	Player.updateBar(hp_bar,Player.current_health,Player.max_health)
	Player.updateBar(mp_bar,Player.current_mp,Player.max_mp)
