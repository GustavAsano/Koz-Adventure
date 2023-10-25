extends ItemData
class_name Weapons

enum Wpn_Type {
	Espada,
	Cajado
}

@export var Damage: int
@export var Multiplier: int
@export var Modifier:int
@export var Weapon_Type : Wpn_Type
@export var Evasion = 0
