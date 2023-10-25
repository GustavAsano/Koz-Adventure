extends Resource
class_name EnemyData

@export var Name: String = ""
@export var Level: String = ""
@export var HP: int = 1
@export var MP: int = 1
@export var EXPDrop: int = 1
@export var ItemDrop: ItemData = null
@export var DropQnt: int = 1
@export var Damage: int = 1
@export var Modifier: int = 0
@export var Multiplier: int = 1
@export var Defense: int = 1
@export var Boss_enemy:bool = false
@export var Resistance:Array[Elemental_Resistance]

func enemyDrops(enemy):
	if enemy == "Slime":
		return "Muco verde"
	if enemy == "Javali Selvagem":
		return "Chifre de Javali"
	if enemy == "Planta Carnivora":
		return "Vinhas Venonosas"
	if enemy == "Bandido":
		return "Ferramentas de Bandido"
	if enemy == "Golem de Cristal":
		return "Cristal"
