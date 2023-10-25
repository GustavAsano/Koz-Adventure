extends Node

var quests:Array[Quests]
var quests_dir = "res://quests/"

func _ready() -> void:
	Signals.loadQuests.connect(_loadQuests)
	loadQuests()

func dir_contents(path):
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				files.append(path+file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		return files
	else:
		print("Diretório não encontrado.")


func _loadQuests(loadquests):
	quests = loadquests

func loadQuests():
	var files = dir_contents(quests_dir)
	for file in files:
		if file == "res://quests/MartaQ1.tres":
			var MartaQ1 = load(file)
			quests.append(MartaQ1)
			
		if file == "res://quests/UvloQ1.tres":
			var UvloQ1 = load(file)
			quests.append(UvloQ1)
