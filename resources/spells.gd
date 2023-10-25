extends Resource
class_name Spells

enum SpellLevel {
	Basica,
	Iniciante,
	Intermediaria,
	Avancada
	
}

enum ElementType {
	None,
	Fire,
	Water,
	Thunder,
	Earth,
	Physical
	
}

@export var Name: String
@export_multiline var Description: String
@export var MP_Cost:int
@export var Level:SpellLevel
@export var Damage: int
@export var Multiplier: int
@export var Modifier: int
@export var Element:ElementType
@export var CastTime:int = 0
@export var IntRequirement:int = 0
@export var LearnCost:int = 0


func get_Type(number):
	if number == 0:
		return "Básica"
	if number == 1:
		return "Iniciante"
	if number == 2:
		return "Intermediária"
	if number == 3:
		return "Avançada"
		
func damage_range()-> Array:
	var minDmg = Multiplier + Modifier*Player.magMod
	var maxDmg = Damage*Multiplier + Modifier*Player.magMod
	return [minDmg,maxDmg]

func get_element(number):
	if number == 0:
		return "Nenhum"
	if number == 1:
		return "Fogo"
	if number == 2:
		return "Água"
	if number == 3:
		return "Trovão"
	if number == 4:
		return "Físico"
