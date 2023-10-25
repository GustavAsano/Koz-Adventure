extends Resource
class_name SaveGame

var save_path = "user://save.tres"

@export var name:String
@export var level:int
@export var strength:int
@export var agility:int
@export var intelligence:int
@export var constituion:int
@export var current_health:int
@export var current_mp:int
@export var experience:int
@export var statPoints:int
@export var promptID:int
@export var dialogID:int
@export var plevel:int
@export var allocatedStats:int
@export var gold:int
@export var background:String

@export var MartaQ1:Quests
@export var UvloQ1:Quests
@export var quests:Array[Quests]
@export var inventory:InventoryData
@export var equipment:InventoryData
@export var spellList:SpellList
@export var ZukSpells:SpellList

func save_game()->void:
	ResourceSaver.save(self,save_path)

func load_save()->Resource:
	if ResourceLoader.exists(save_path):
		return ResourceLoader.load(save_path) as SaveGame
	else:
		return null
	
