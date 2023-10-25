extends Resource
class_name ItemData

enum Type {
	Weapon,
	Armor,
	Consumable,
	Misc,
	Key
}

@export var Name: String = ""
@export_multiline var Description: String = ""
@export var BuyPrice: int = 1
@export var SellPrice: int = 1
@export var Stackable: bool = true
@export var ItemType:Type

func get_Type(number):
	if number == 0:
		return "Arma"
	if number == 1:
		return "Armadura"
	if number == 2:
		return "Consumível"
	if number == 3:
		return "Outros"
	if number == 4:
		return "Chave"
