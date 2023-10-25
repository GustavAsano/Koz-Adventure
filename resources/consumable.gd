extends ItemData
class_name Consumables

enum Type_Reduction {
	None,
	Fire,
	Water,
	Wind,
	Earth,
	Physical,
	All
}

@export var HP_Restored: int = 1
@export var MP_Restored: int = 1
@export var TypeReduction: Type_Reduction
@export var DamageReduction: int = 0
@export var Damage: int = 0
@export var Defense: int = 0
@export var EffectTurns:int = 0
@export var BattleRequired:bool = false
