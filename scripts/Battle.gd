extends Node

@export var defRed = 50

var Enemy:EnemyData
var defend = 0
var enemydefend = 0
var evading = 0
var castTime = 0
var casting = false
var playerAction
var spell:Spells
var enemyHP
var difficulty
var currentTurn = ""
var playerdamage
var enemydmg
var enemyName
var playerHP
var resistance = 0
var turn = 0
func _ready() -> void:
	Signals.connect("which_Enemy",_set_Enemy)
	Signals.connect("playerAction",_get_playerAction)

func _set_Enemy(path,diff):
	Enemy = load(path).duplicate()
	difficulty = diff

func _get_playerAction(action,current_enemyHP,target,usedSpell=null):
	playerAction = action
	if usedSpell != null:
		spell = usedSpell
	enemyHP = current_enemyHP
	enemyName = target
	turnAction(currentTurn,playerAction,spell,enemyName)
	
func damage_dealt(wpn_damage,multiplier,modifier,defense,multiMod = 1,defending = 0,type_resistence = 0)-> int:
	var dmg = randi_range(1,wpn_damage)*multiplier+modifier*multiMod
	var mitigatedDmg = dmg/((defense+defRed)/defRed) * (1-0.5*defending) * (1-float(type_resistence)/100)
	return int(round(mitigatedDmg))

func turnAction(character,action,_usedSpell,_target):
	var enemyDamage = Enemy.Damage
	var enemyMulti = Enemy.Multiplier
	var enemyMod = Enemy.Modifier
	var playerDefense = Player.defense
	if character == "Player":
		var playerCrit = critical(Player.critChance)
		if action == "Defend":
			defend = 1
			change_Turn() 
		if action == "Attack":
			playerdamage = damage_dealt(Player.weapon_damage,Player.weapon_multiplier,Player.physMod,Enemy.Defense)
			if playerCrit == false:
				enemyHP = max(0,enemyHP-playerdamage)
				Signals.change_targetHP.emit(enemyName,enemyHP,"Attack")
			else:
				playerdamage *= 2
				enemyHP = max(0,enemyHP-playerdamage)
				Signals.change_targetHP.emit(enemyName,enemyHP,"critAttack")
			if enemyHP > 0:
				change_Turn() 
		if action == "Magic":
			if casting == false:
				castTime = max(0,spell.CastTime-Player.castHaste)
				Player.current_mp = max(0,Player.current_mp-spell.MP_Cost)
			if castTime == 0:
				if len(Enemy.Resistance) != 0:
					for i in range(len(Enemy.Resistance)):
						var res = Enemy.Resistance[i]
						if res.get_element(res.element) == spell.get_element(spell.Element):
							resistance = res.percentage
				playerdamage = damage_dealt(spell.Damage,spell.Multiplier,Player.magMod,Enemy.Defense,spell.Modifier,enemydefend,resistance)
				enemyHP = max(0,enemyHP-playerdamage)
				if casting == true:
					Player.evasion += 30
					casting = false
				Signals.change_targetHP.emit(enemyName,enemyHP,spell.Name)
			if castTime > 0 and casting == false:
				casting = true
				Player.evasion = max(0,Player.evasion-30)
				Signals.characterCasting.emit(Player.pcname,spell,castTime)
			change_Turn() 
		if action == "Evade":
			evading = 1
			Player.evasion += 20
			change_Turn() 
			
	if character == "Enemy":
		if difficulty == 0:
			enemyDamage *= 0.75
		if action == "Attack":
			if defend == 1:
				enemydmg = damage_dealt(enemyDamage,enemyMulti,enemyMod,playerDefense,1,defend)
				defend = 0
			if evading == 1:
				Player.evasion -= 20
				enemydmg = damage_dealt(enemyDamage,enemyMulti,enemyMod,playerDefense)
				evading = 0
			else:
				enemydmg = damage_dealt(enemyDamage,enemyMulti,enemyMod,playerDefense)
			var playerEvade = evade(Player.evasion)
			if playerEvade == false:
				playerHP = max(0,Player.current_health-enemydmg)
				Signals.change_targetHP.emit(Player.pcname,playerHP,"Attack")
			else:
				Signals.change_targetHP.emit(Player.pcname,Player.current_health,"Evade")

func change_Turn():
	if currentTurn == "Player":
		currentTurn = "Enemy"
		if Enemy.Boss_enemy == false:
			turnAction(currentTurn,"Attack","",Player.pcname)

func evade(evade_chance):
	var evade_roll = randi_range(1,100)
	if evade_roll < evade_chance:
		return true
	else:
		return false

func critical(crit_chance):
	var crit_roll = randi_range(1,100)
	if crit_roll < crit_chance:
		return true
	else:
		return false
