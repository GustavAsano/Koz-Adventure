extends PanelContainer

@export var dialogPath = ""
@export var textSpeed = 0.04
@export var PCname = "Koz"
@export var dialogID = 1
@export var promptID = 0


var char1
var char2
var dialog
var nextdialog = 0
var nextD = []
var finished = false
var nchoices

const LogText = preload("res://log_text.tscn")
@onready var logRows = $"../Prompt/MarginContainer/Scroll/Logs"
@onready var scroll = $"../Prompt/MarginContainer/Scroll"
@onready var scrollbar = scroll.get_v_scroll_bar()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scrollbar.connect("changed",change_scroll)
	$MarginContainer/Timer.wait_time = textSpeed
	dialog = getdialog()
	assert(dialog, "Dialogo nao achado")
	getdialogbyID(dialogID)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and nchoices == 0 and $MarginContainer/VBoxContainer.visible == true:
		if finished:
			getdialogbyID(nextdialog)
		else:
			$MarginContainer/VBoxContainer/DialogText.visible_characters = len($MarginContainer/VBoxContainer/DialogText.text)

func getdialog() -> Array:
	assert(FileAccess.file_exists(dialogPath), "Arquivo inexistente")
	
	var jsonText = FileAccess.get_file_as_string(dialogPath)
	var output = JSON.parse_string(jsonText)
	
	if typeof(output) == TYPE_ARRAY:
		return(output)
	else:
		return []

func getdialogbyID(ID) -> void:
	if (ID == 0):
		$MarginContainer/VBoxContainer/DialogText.hide()
		$MarginContainer/VBoxContainer/Label.hide()
		$MarginContainer/VBoxContainer/Names/NPCName.hide()
		$MarginContainer/VBoxContainer/Names/PCName.hide()
		$"../../Right/NPC Portrait/NPCName".hide()
	else:
		if dialogID >= len(dialog):
			queue_free()
			return

		finished = false
		nextD = []
		
		char1 = dialog[dialogID]["Char1"]
		char2 = dialog[dialogID]["Char2"]
		
		$"../../Right/NPC Portrait/NPCName".text = char2
		$MarginContainer/VBoxContainer/Names/NPCName.text = char2
		if (PCname != char1):
			$"../../Left/PC Portrait/PCName".text = PCname
			$MarginContainer/VBoxContainer/Names/PCName.text = PCname
			
		else:
			$"../../Left/PC Portrait/PCName".text = char1
			$MarginContainer/VBoxContainer/Names/PCName.text = char1
			
		$MarginContainer/VBoxContainer/DialogText.bbcode_text = dialog[dialogID]["Text"]
		$MarginContainer/VBoxContainer/DialogText.visible_characters = 0
		
		nchoices = len(dialog[dialogID]["Choices"])
		
		if (dialog[dialogID]["Speaker"] == 1):
			addtoLogs(char1,$MarginContainer/VBoxContainer/DialogText.text)
			$MarginContainer/VBoxContainer/Names/PCName.show()
			$MarginContainer/VBoxContainer/Names/NPCName.hide()
		else:
			addtoLogs(char2,$MarginContainer/VBoxContainer/DialogText.text)
			$MarginContainer/VBoxContainer/Names/NPCName.show()
			$MarginContainer/VBoxContainer/Names/PCName.hide()
			
		if nchoices == 0:
			hideOptions()
			$MarginContainer/VBoxContainer/Label.show()
			nextdialog = dialog[dialogID]["Next"]
			dialogID = nextdialog
			
		elif nchoices == 1:
			hideOptions()
			
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".show()
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".hide()

			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]
			$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".text = "[4] "+dialog[dialogID]["Choices"][3]["TextOP"]
		
		if nchoices != 0:
			$MarginContainer/VBoxContainer/Label.hide()
			for n in range(nchoices):
				nextD.append(dialog[dialogID]["Choices"][n]["nextD"])
				
		
		
		while $MarginContainer/VBoxContainer/DialogText.visible_characters < len($MarginContainer/VBoxContainer/DialogText.text):
			$MarginContainer/VBoxContainer/DialogText.visible_characters += 1
		
			$MarginContainer/Timer.start()
			await $MarginContainer/Timer.timeout
		finished = true
		
		return


func _on_op_1_button_pressed() -> void:
	if finished:
		nextdialog = nextD[0]
		dialogID = nextdialog
		getdialogbyID(dialogID)
		if dialogID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/DialogText.visible_characters = len($MarginContainer/VBoxContainer/DialogText.text)


func _on_op_2_button_pressed() -> void:
	if finished:
		nextdialog = nextD[1]
		dialogID = nextdialog
		getdialogbyID(dialogID)
		if dialogID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/DialogText.visible_characters = len($MarginContainer/VBoxContainer/DialogText.text)


func _on_op_3_button_pressed() -> void:
	if finished:
		nextdialog = nextD[2]
		dialogID = nextdialog
		getdialogbyID(dialogID)
		if dialogID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/DialogText.visible_characters = len($MarginContainer/VBoxContainer/DialogText.text)


func _on_op_4_button_pressed() -> void:
	if finished:
		nextdialog = nextD[3]
		dialogID = nextdialog
		getdialogbyID(dialogID)
		if dialogID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/DialogText.visible_characters = len($MarginContainer/VBoxContainer/DialogText.text)

func hideOptions() -> void:
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".hide()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".hide()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".hide()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".hide()

func showOptions() -> void:
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button".show()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button".show()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button".show()
	$"../Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button".show()

func addtoLogs(speaker,dialogText: String):
	var logpanel = LogText.instantiate()
	var log_text = logpanel.get_child(0)
	log_text.text = speaker+": "+dialogText
	logRows.add_child(logpanel)
	
	if logRows.get_child_count() > 500:
		var removeChild = logRows.get_child_count() - 500
		for i in range(removeChild):
			logRows.get_child(i).queue_free()
	

func _on_logs_button_toggled(button_pressed: bool):
	if button_pressed == true:
		$"../Prompt/MarginContainer/Scroll".show()
		$"../Prompt/MarginContainer/PromptText".hide()
		$MarginContainer/VBoxContainer.hide()
	else:
		$"../Prompt/MarginContainer/Scroll".hide()
		$"../Prompt/MarginContainer/PromptText".show()
		$MarginContainer/VBoxContainer/DialogText.show()
		$MarginContainer/VBoxContainer.show()

func change_scroll():
	scroll.scroll_vertical = scrollbar.max_value
	
