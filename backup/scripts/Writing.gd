extends Node

@export var dialogPath = ""
@export var promptPath = ""
@export var encountersPath =  ""
@export var textSpeed = 0.04
@export var PCname = "Koz"
@export var dialogID = 0
@export var promptID = 1

var char1
var char2
var dialog
var nextdialog = 0
var nextD = []
var prompt
var nextPrompt = 0
var nextP = []
var finished = false
var nchoices
var encounter
var encounterID
var encounterArray 
var is_in_combat = 0

@onready var DialogText = $"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/DialogText"
@onready var PromptText = $"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/PromptText"

const LogText = preload("res://log_text.tscn")
@onready var logRows = $"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll/Logs"
@onready var scroll = $"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll"
@onready var scrollbar = scroll.get_v_scroll_bar()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scrollbar.connect("changed",change_scroll)
	$Timer.wait_time = textSpeed
	dialog = getText(dialogPath)
	prompt = getText(promptPath)
	encounter = getText(encountersPath)
	assert(dialog, "Dialogo nao achado")
	assert(dialog, "Prompt nao achado")
	getdialogbyID(dialogID)
	getPromptbyID(promptID)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and $"../BG/MarginContainer/HBoxContainer/Center/DialogueBox".visible == true and is_in_combat == 0:
		if nchoices == 0:
			op_next(-1)
		else:
			if finished == false:
				PromptText.visible_characters = len(PromptText.text)
				DialogText.visible_characters = len(DialogText.text)

func getText(path: String) -> Array:
	var jsonText
	var output
	assert(FileAccess.file_exists(path), "Arquivo inexistente")
		
	jsonText = FileAccess.get_file_as_string(path)
	output = JSON.parse_string(jsonText)
		
	if typeof(output) == TYPE_ARRAY:
		return(output)
	else:
		return []


func getdialogbyID(ID) -> void:
	if (ID == 0):
		DialogText.hide()
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label".hide()
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName".hide()
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName".hide()
		$"../BG/MarginContainer/HBoxContainer/Right/NPC Portrait/NPCName".hide()
	else:
		if dialogID >= len(dialog):
			queue_free()
			return

		finished = false
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer".show()
		nextP = []
		nextD = []
		
		char1 = dialog[dialogID]["Char1"]
		char2 = dialog[dialogID]["Char2"]
		
		$"../BG/MarginContainer/HBoxContainer/Right/NPC Portrait/NPCName".show()
		$"../BG/MarginContainer/HBoxContainer/Right/NPC Portrait/NPCName".text = char2
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName".text = char2
		if (PCname != char1):
			$"../BG/MarginContainer/HBoxContainer/Left/PC Stats/MarginContainer/PC/ID/PCName".text = PCname
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName".text = PCname
			
		else:
			$"../BG/MarginContainer/HBoxContainer/Left/PC Stats/MarginContainer/PC/ID/PCName".text = char1
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName".text = char1
			
		DialogText.bbcode_text = dialog[dialogID]["Text"]
		DialogText.visible_characters = 0
		
		nchoices = len(dialog[dialogID]["Choices"])
		
		if (dialog[dialogID]["Speaker"] == 1):
			addtoLogs("dialog",char1,DialogText.text)
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName".show()
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName".hide()
		else:
			addtoLogs("dialog",char2,DialogText.text)
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName".show()
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName".hide()
		if nchoices == 0:
			hideOptions()
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label".show()
			nextdialog = dialog[dialogID]["Next"]
			nextPrompt = dialog[dialogID]["promptID"]
			dialogID = nextdialog
			if promptID != 0 and nextdialog == 0:
				promptID = nextPrompt
				dialogID = nextdialog
			
		elif nchoices == 1:
			hideOptions()
			
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".hide()

			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".text = "[4] "+dialog[dialogID]["Choices"][3]["TextOP"]
		
		if nchoices != 0:
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label".hide()
			for n in range(nchoices):
				nextD.append(dialog[dialogID]["Choices"][n]["NextD"])
				nextP.append(dialog[dialogID]["Choices"][n]["NextP"])

		while DialogText.visible_characters < len(DialogText.text):
			DialogText.visible_characters += 1
		
			$Timer.start()
			await $Timer.timeout
		
		finished = true
		return

func getPromptbyID(ID) -> void:
	if (ID == 0):
		PromptText.hide()
		$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label".hide()
	else:
		if promptID >= len(prompt):
			queue_free()
			return
		$"../BG/MarginContainer/HBoxContainer/Right/NPC Portrait/NPCName".hide()
		finished = false
		nextP = []
		nextD = []
		
		var scene = prompt[promptID]["Scene"]
		var imgpath = "res://BG/"+scene+".png" 
		var bgpanel = $"../BG"

		var stylebox =StyleBoxTexture.new()
		stylebox.texture = load(imgpath)
		
		bgpanel.add_theme_stylebox_override("panel", stylebox)
		
		PromptText.bbcode_text = prompt[promptID]["Text"]
		PromptText.visible_characters = 0
		
		nchoices = len(prompt[promptID]["Choices"])
		
		
		if nchoices == 0:
			hideOptions()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label".show()
			
			nextPrompt = prompt[promptID]["Next"]
			nextdialog = prompt[promptID]["dialogID"]
			encounterID = prompt[promptID]["encounterID"]
			promptID = nextPrompt
			if promptID == 0 and nextdialog != 0:
				promptID = nextPrompt
				dialogID = nextdialog
		
		elif nchoices == 1:
			hideOptions()
			
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".show()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".hide()

			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".text = "[4] "+prompt[promptID]["Choices"][3]["TextOP"]
		
		if nchoices != 0:
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label".hide()
			for n in range(nchoices):
				nextP.append(prompt[promptID]["Choices"][n]["NextP"])
				nextD.append(prompt[promptID]["Choices"][n]["NextD"])
				
		addtoLogs("prompt","",PromptText.text)
		
		while PromptText.visible_characters < len(PromptText.text):
			PromptText.visible_characters += 1
		
			$Timer.start()
			await $Timer.timeout
		finished = true
		return

func _on_op_1_button_pressed() -> void:
	op_next(0)

func _on_op_2_button_pressed() -> void:
	op_next(1)

func _on_op_3_button_pressed() -> void:
	op_next(2)

func _on_op_4_button_pressed() -> void:
	op_next(3)

func hideOptions() -> void:
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".hide()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".hide()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".hide()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".hide()

func showOptions() -> void:
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".show()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".show()
	$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".show()

func addtoLogs(type,speaker,Text: String):
	var logpanel = LogText.instantiate()
	var log_text = logpanel.get_child(0)
	if (type == "dialog"):
		log_text.text = speaker+": "+Text
		logRows.add_child(logpanel)
	else:
		log_text.text = Text
		logRows.add_child(logpanel)
		
	remove_old_child()

func remove_old_child():
	if logRows.get_child_count() > 500:
		var removeChild = logRows.get_child_count() - 500
		for i in range(removeChild):
			logRows.get_child(i).queue_free()

func _on_logs_button_toggled(button_pressed: bool):
	if button_pressed == true:
		$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll".show()
		$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText".hide()
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox".hide()
	else:
		$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll".hide()
		$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText".show()
		$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox".show()

func change_scroll():
	scroll.scroll_vertical = scrollbar.max_value
	
func op_next(chosenNumber) -> void:
	if chosenNumber >= 0:
		nextdialog = nextD[chosenNumber]
		nextPrompt = nextP[chosenNumber]
	dialogID = nextdialog
	promptID = nextPrompt
	if nextdialog != 0 and nextPrompt == 0:
		if finished:
			getdialogbyID(dialogID)
			DialogText.show()
			PromptText.hide()
			$"../BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label".hide()
			if dialogID == 0:
				hideOptions()
		else:
			DialogText.visible_characters = len(DialogText.text)
			PromptText.visible_characters = len(PromptText.text)
	if nextPrompt != 0 and nextdialog == 0:
		if finished:
			DialogText.hide()
			PromptText.show()
			$"../BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer".hide()
			getPromptbyID(promptID)
			if promptID == 0:
				hideOptions()
		else:
			PromptText.visible_characters = len(PromptText.text)
			DialogText.visible_characters = len(DialogText.text)
	if nextPrompt == 0 and nextdialog == 0 and encounterID != 0:
		encounterArray = encounter[encounterID]
		is_in_combat = 1
		print(encounterArray)
