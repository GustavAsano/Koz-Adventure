extends Resource
class_name SpellList

@export var slotDatas: Array[Spells]
var correction = 0
var indexes = []
var indexesBackup = []

signal spell_interact(spell_data:Spells,index:int)

func on_slot_clicked(index:int)->void:
	returnIndex()
	spell_interact.emit(self,index)
	correction = 0
	indexes = []


func returnIndex():
	for i in range(len(slotDatas)):
		if slotDatas[i] != null:
			indexes.append(correction)
		if slotDatas[i] == null:
			correction+=1
			indexes.append(correction)
	indexesBackup = indexes
	for i in range(len(slotDatas)-1):
		if indexesBackup[i] != 0 and indexesBackup[i+1] > indexesBackup[i]:
			indexesBackup[i] = indexesBackup[i+1]
	
