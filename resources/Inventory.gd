extends Resource
class_name InventoryData

signal inventory_interact(inventory_data:InventoryData,index:int)

@export var slotDatas: Array[ItemSlots]
var correction = 0
var indexes = []
var indexesBackup = []

func on_slot_clicked(index:int)->void:
	returnIndex()
	inventory_interact.emit(self,index + indexes[index-1])
	correction = 0
	indexes = []
	
	

func returnIndex():
	for i in range(len(slotDatas)):
		if slotDatas[i].qnt != 0:
			indexes.append(correction)
		if slotDatas[i].qnt == 0:
			correction+=1
			indexes.append(correction)
	indexesBackup = indexes
	for i in range(len(slotDatas)-1):
		if indexesBackup[i] != 0 and indexesBackup[i+1] > indexesBackup[i]:
			indexesBackup[i] = indexesBackup[i+1]
	
