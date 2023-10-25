extends Resource
class_name Elemental_Resistance

enum Element {
	Fire,
	Water,
	Wind,
	Earth,
	Physical,
	All
}

@export var element:Element
@export var percentage:int

func get_element(number):
	if number == 0:
		return "Fogo"
	if number == 1:
		return "Água"
	if number == 2:
		return "Ar"
	if number == 3:
		return "Terra"
	if number == 4:
		return "Físico"
	if number == 5:
		return "Todos"
