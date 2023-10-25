extends PanelContainer

@onready var equipped: GridContainer = $MarginContainer/Equipped

var equipType
var head
var armor
var weapon
const equipText = preload("res://text.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.updateEquips.connect(_update_Equips)
	Signals.reload.connect(_load)
	get_equips()
	addtoEquip()

func get_equips():
	armor = Player.armor
	weapon = Player.weapon
	head = Player.head
	equipType = Player.equiptype

func addtoEquip():
	var eqText
	var empty = ["Type","Vazio","0","0","0","0","0","10%"]
	var weaponStats = ["Arma",weapon.Name,str(weapon.Multiplier)+"d"+str(weapon.Damage),str(weapon.Modifier),"0","0","0","0%"]
	var armorStats = ["Corpo",armor.Name,"0",str(armor.Modifier),str(armor.Defense),str(armor.HPExtra),str(armor.MPExtra),"%d"%armor.Evasion+"%"]
	var child_count = equipped.get_child_count()
	if child_count > 8:
		for i in range(8,child_count):
			equipped.get_child(i).queue_free()
	if equipType[0] == 2:
		for i in range(8):
			eqText = equipText.instantiate()
			empty[0] = "Cabeça"
			eqText.text = empty[i]
			equipped.add_child(eqText)
	if equipType[0] != 2:
		var headStats = ["Cabeça",head.Name,"0",str(head.Modifier),str(head.Defense),str(head.HPExtra),str(head.MPExtra),"%d"%head.Evasion+"%"]
		for i in range(8):
			eqText = equipText.instantiate()
			eqText.text = headStats[i]
			equipped.add_child(eqText)
	if equipType[1] != 2:
		for i in range(8):
			eqText = equipText.instantiate()
			eqText.text = armorStats[i]
			equipped.add_child(eqText)
	if equipType[2] != 2:
		for i in range(8):
			eqText = equipText.instantiate()
			eqText.text = weaponStats[i]
			equipped.add_child(eqText)

func _update_Equips():
	get_equips()
	addtoEquip()

func _load():
	#get_tree().reload_current_scene()
	pass
