extends Panel

@export var promptPath = ""
@export var textSpeed = 0.04
@export var promptID = 0
@export var dialogID = 0

var prompt
var nextPrompt = 0
var nextP = []
var finished = false
var nchoices

const LogText = preload("res://log_text.tscn")
@onready var logRows = $"../Scroll/Logs"
@onready var scroll = $"../Scroll"
@onready var scrollbar = scroll.get_v_scroll_bar()

@onready var dialogInstance = preload("res://scripts/DialogText.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scrollbar.connect("changed",change_scroll)
	$MarginContainer/Timer.wait_time = textSpeed
	prompt = getPrompt()
	assert(prompt, "Prompt nao achado")
	getPromptbyID(promptID)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and nchoices == 0:
		if finished:
			getPromptbyID(nextPrompt)
		else:
			$MarginContainer/VBoxContainer/PromptText.visible_characters = len($MarginContainer/VBoxContainer/PromptText.text)

func getPrompt() -> Array:
	assert(FileAccess.file_exists(promptPath), "Arquivo inexistente")
	
	var jsonText = FileAccess.get_file_as_string(promptPath)
	var output = JSON.parse_string(jsonText)
	
	if typeof(output) == TYPE_ARRAY:
		return(output)
	else:
		return []

func getPromptbyID(ID) -> void:
	if (ID == 0):
		$MarginContainer/VBoxContainer/PromptText.hide()
		$MarginContainer/VBoxContainer/Label.hide()
	else:
		if promptID >= len(prompt):
			queue_free()
			return

		finished = false
		nextP = []
		
		var scene = prompt[promptID]["Scene"]
		var imgpath = "res://BG/"+scene+".png" 
		
		var bgpanel = $"../../../../../.."
		
		var stylebox =StyleBoxTexture.new()
		stylebox.texture = load(imgpath)
		
		bgpanel.add_theme_stylebox_override("panel", stylebox)
		
		$MarginContainer/VBoxContainer/PromptText.bbcode_text = prompt[promptID]["Text"]
		$MarginContainer/VBoxContainer/PromptText.visible_characters = 0
		
		nchoices = len(prompt[promptID]["Choices"])

		if nchoices == 0:
			hideOptions()
			$MarginContainer/VBoxContainer/Label.show()
			nextPrompt = prompt[promptID]["Next"]
			promptID = nextPrompt
			
		elif nchoices == 1:
			hideOptions()
			
			$MarginContainer/VBoxContainer/Op1Button.show()
			$MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$MarginContainer/VBoxContainer/Op1Button.show()
			$MarginContainer/VBoxContainer/Op2Button.show()
			$MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$MarginContainer/VBoxContainer/Op4Button.hide()

			$MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$MarginContainer/VBoxContainer/Op3Button.text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			
			$MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$MarginContainer/VBoxContainer/Op3Button.text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]
			$MarginContainer/VBoxContainer/Op4Button.text = "[4] "+prompt[promptID]["Choices"][3]["TextOP"]
		
		if nchoices != 0:
			$MarginContainer/VBoxContainer/Label.hide()
			for n in range(nchoices):
				nextP.append(prompt[promptID]["Choices"][n]["NextP"])

		addtoLogs($MarginContainer/VBoxContainer/PromptText.text)
		
		while $MarginContainer/VBoxContainer/PromptText.visible_characters < len($MarginContainer/VBoxContainer/PromptText.text):
			$MarginContainer/VBoxContainer/PromptText.visible_characters += 1
		
			$MarginContainer/Timer.start()
			await $MarginContainer/Timer.timeout
		
		finished = true
		return


func _on_op_1_button_pressed() -> void:
	if finished:
		nextPrompt = nextP[0]
		promptID = nextPrompt
		getPromptbyID(promptID)
		if promptID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/PromptText.visible_characters = len($MarginContainer/VBoxContainer/PromptText.text)


func _on_op_2_button_pressed() -> void:
	if finished:
		nextPrompt = nextP[1]
		promptID = nextPrompt
		getPromptbyID(promptID)
		if promptID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/PromptText.visible_characters = len($MarginContainer/VBoxContainer/PromptText.text)


func _on_op_3_button_pressed() -> void:
	if finished:
		nextPrompt = nextP[2]
		promptID = nextPrompt
		getPromptbyID(promptID)
		if promptID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/PromptText.visible_characters = len($MarginContainer/VBoxContainer/PromptText.text)


func _on_op_4_button_pressed() -> void:
	if finished:
		nextPrompt = nextP[3]
		promptID = nextPrompt
		getPromptbyID(promptID)
		if promptID == 0:
			hideOptions()
	else:
		$MarginContainer/VBoxContainer/PromptText.visible_characters = len($MarginContainer/VBoxContainer/PromptText.text)

func hideOptions() -> void:
	$MarginContainer/VBoxContainer/Op1Button.hide()
	$MarginContainer/VBoxContainer/Op2Button.hide()
	$MarginContainer/VBoxContainer/Op3Button.hide()
	$MarginContainer/VBoxContainer/Op4Button.hide()

func showOptions() -> void:
	$MarginContainer/VBoxContainer/Op1Button.show()
	$MarginContainer/VBoxContainer/Op2Button.show()
	$MarginContainer/VBoxContainer/Op3Button.show()
	$MarginContainer/VBoxContainer/Op4Button.show()

func addtoLogs(promptText: String):
	var logpanel = LogText.instantiate()
	var log_text = logpanel.get_child(0)
	log_text.text = promptText
	logRows.add_child(logpanel)
	
	if logRows.get_child_count() > 500:
		var removeChild = logRows.get_child_count() - 500
		for i in range(removeChild):
			logRows.get_child(i).queue_free()
	
func change_scroll():
	scroll.scroll_vertical = scrollbar.max_value

func _on_logs_button_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		$"../Scroll".show()
		$".".hide()

	else:
		$"../Scroll".hide()
		$".".show()
