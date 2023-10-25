extends Node

var currentPrompt
var currentDialog

@onready var MartaQ1:Quests = preload("res://quests/MartaQ1.tres")
@onready var UvloQ1:Quests = preload("res://quests/UvloQ1.tres")
var defeatCount = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.sendStoryID.connect(_get_storyID)
	Signals.checkQuestState.connect(_check_quest_state)
	Signals.enemyDefeat.connect(_enemy_defeated)
	Signals.requestQuests.connect(_requestQuests)
	if len(Global.quests) > 0:
		MartaQ1 = Global.quests[0]
		UvloQ1 = Global.quests[1]

	
func _get_storyID(dialogID,promptID):
	currentDialog = dialogID
	currentPrompt = promptID
	martaQuest1(currentDialog,currentPrompt)
	uvloQuest1(currentDialog,currentPrompt)


func martaQuest1(dialog,prompt):
	if dialog == 48:
		MartaQ1.Flag = 0
		
	if prompt == 32:
		MartaQ1.Flag = 1
		MartaQ1.Progress = 1
		var herb = load("res://items/FireHerb.tres")
		Player._gainItem(herb,1)
	if dialog == 77:
		Signals.updateMain.emit()

func uvloQuest1(dialog,_prompt):
	if dialog == 59:
		UvloQ1.Flag = 0
	if dialog == 82:
		Signals.updateMain.emit()

func _check_quest_state(NPCName):
	if NPCName == "Alchemists":
		if MartaQ1.Flag == 0:
			Signals.nextSegment.emit(70, 0)
		if MartaQ1.Flag == 1:
			MartaQ1.Flag = 2
			Player.gold += MartaQ1.GoldReward
			Player._gainItem(MartaQ1.ItemReward,MartaQ1.ItemQnt)
			for child in Player.Inventory.slotDatas:
				if child.baseItem.Name == "Erva de fogo":
					child.qnt -= 1
			Signals.nextSegment.emit(76, 0)
		if MartaQ1.Flag > 1 and currentPrompt == 25:
			Signals.nextSegment.emit(0, 34)
	if NPCName == "Uvlo":
		if UvloQ1.Flag == 0:
			Signals.nextSegment.emit(73, 0)
		if UvloQ1.Flag == 1:
			UvloQ1.Flag = 2
			Player.gold += UvloQ1.GoldReward
			Player._gainItem(UvloQ1.ItemReward,UvloQ1.ItemQnt)
			Signals.nextSegment.emit(81, 0)
		if UvloQ1.Flag > 1 and currentPrompt == 22:
			Signals.nextSegment.emit(85, 0)
	
func _enemy_defeated(Enemy:EnemyData):
	if UvloQ1.Enemy == Enemy:
		UvloQ1.Progress += 1
	if UvloQ1.Progress == UvloQ1.Number:
		UvloQ1.Flag = 1
		
func _requestQuests():
	Signals.sendQuests.emit(Global.quests)

