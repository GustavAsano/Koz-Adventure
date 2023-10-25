extends EnemyData
class_name Boss1

@export var current_hp:int
@export var spells:SpellList

func get_behavior():
	if current_hp > 0.8*HP:
		return "Attack"
	if current_hp < 0.8*HP:
		var rnd = randi_range(1,10)
		if rnd < 4:
			return "Fireball" 
		else:
			return "Attack"
	if current_hp < 0.6*HP:
		return "Start Flare"
