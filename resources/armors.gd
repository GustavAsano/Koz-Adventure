extends ItemData
class_name Armors

enum ArmorType {
	Cabeca,
	Corpo
}

enum Armor_Weight {
	Leve,
	Pesada
}

@export var Defense:int = 1
@export var HPExtra:int = 0
@export var MPExtra:int = 0
@export var Modifier:int = 0
@export_enum("Físico","Mágico") var ModType:int
@export var Weight: Armor_Weight
@export var Armor_Type: ArmorType
@export var Evasion: int
@export var Resistance:Array[Elemental_Resistance]
