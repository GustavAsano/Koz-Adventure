extends Resource
class_name Quests

enum type_objectives {
	Collect,
	Defeat
}

#Flag = -1 -> Quest ainda não pega
#Flag = 0 -> Quest pega mais ainda não completada.
#Flag = 1 -> Quest com requerimentos completos, mas ainda não entregada
#Flag > 1 -> Quest completada

@export var Character:String = ""
@export var Objective:type_objectives = 0
@export var RequiredItem:ItemData = null
@export var Enemy:EnemyData = null
@export var Number:int = 0
@export var Progress:int
@export var Flag:int
@export var GoldReward:int = 0
@export var ItemQnt:int = 0
@export var ItemReward:ItemData = null

