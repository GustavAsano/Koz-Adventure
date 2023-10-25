extends Node

@export var dialogPath = ""
@export var promptPath = ""
@export var encountersPath =  ""
@export var textSpeed = 0.03

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
var is_in_combat = false
var is_in_dialogue = 0
var enemyName
var difficulty
var Enemy:EnemyData
var current_enemyHP
var usedAction
var damage_dealt
var act
var crit = false
var effectiveAttack = 0
var Pcname = Player.pcname
var dialogID 
var promptID
var currentPrompt = Player.promptID
var currentDialog = Player.dialogID
var imgpath
var in_dungeon = false
var no_return = false
@onready var bgpanel = $BG
@onready var DialogText = $BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/DialogText
@onready var PromptText = $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/PromptText
@onready var PC_HP = $BG/MarginContainer/HBoxContainer/Left/PCStats/MarginContainer/PC/HP/HPBar
@onready var PC_MP = $BG/MarginContainer/HBoxContainer/Left/PCStats/MarginContainer/PC/MP/MPBar
@onready var PC_EXP = $BG/MarginContainer/HBoxContainer/Left/PCStats/MarginContainer/PC/EXP/EXPBar
@onready var NPC_HP = $BG/MarginContainer/HBoxContainer/Right/NPCStats/MarginContainer/NPC/HP/HPBar
@onready var NPC_MP = $BG/MarginContainer/HBoxContainer/Right/NPCStats/MarginContainer/NPC/MP/MPBar
@onready var gold: Label = $BG/MarginContainer/HBoxContainer/Center/Options/MarginContainer/Gold

const LogText = preload("res://log_text.tscn")
@onready var logRows = $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll/Logs
@onready var scroll = $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll
@onready var scrollbar = scroll.get_v_scroll_bar()
var Inventory:InventoryData
var Equipment:InventoryData
var PlayerSpells:SpellList
var quests:Array[Quests]
var ZukSpellList:SpellList
signal combatInventory()

var _save: SaveGame
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initPlayer()
	Signals.connect("change_targetHP",change_targetHP)
	Signals.connect("updateMain",updateMain)
	Signals.connect("useItem",use_Item)
	Signals.castSpell.connect(getSpell)
	Signals.characterCasting.connect(character_Casting)
	Signals.nextSegment.connect(_next_Segment)
	Signals.sendQuests.connect(_get_quests)
	scrollbar.connect("changed",change_scroll)
	$Timer.wait_time = textSpeed
	dialog = getText(dialogPath)
	prompt = getText(promptPath)
	encounter = getText(encountersPath)
	assert(dialog, "Dialogo nao achado")
	assert(prompt, "Prompt nao achado")
	assert(encounter, "Encontro nao achado")
	
	loadTexts()

#Passar o texto quando ui_accept e a caixa de dialogo está visivel e se estiver em combate mostrar a tela
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and $BG/MarginContainer/HBoxContainer/Center/DialogueBox.visible == true:
		if is_in_combat == false:
			if nchoices == 0:
				op_next(-1)
			else:
				if finished == false:
					PromptText.visible_characters = len(PromptText.text)
					DialogText.visible_characters = len(DialogText.text)
		if is_in_combat == true and Battle.currentTurn == "":
			if finished:
				battleStart(encounterArray)
			else:
				PromptText.visible_characters = len(PromptText.text)
		if is_in_combat == true and Battle.currentTurn == "Enemy":
			Player.updateBar(PC_HP,Player.current_health,Player.max_health)
			if act == "Evade":
				PromptText.text = "%s desviou do ataque!" % [Pcname]
			else:
				PromptText.text = "%s deu %d de dano no %s!" % [Enemy.Name,Battle.enemydmg,Pcname]
			act = ""
			battleText(PromptText)
			Battle.currentTurn = "Player"
		if is_in_combat == true and Battle.currentTurn == "Player" and current_enemyHP != 0 and Battle.casting == false:
			if finished:
				showBattle()
			else:
				PromptText.visible_characters = len(PromptText.text)
		if is_in_combat == true and Battle.currentTurn == "Player" and current_enemyHP != 0 and Battle.casting == true:
			if finished:
				Battle.castTime -= 1
				if Battle.castTime != 0: 
					character_Casting(Player.pcname,Battle.spell,Battle.castTime)
					Battle.change_Turn()
				else:
					Signals.playerAction.emit("Magic",current_enemyHP,enemyName)
			else:
				PromptText.visible_characters = len(PromptText.text)
		if is_in_combat == true and Battle.currentTurn == "Player" and current_enemyHP == 0:
			PromptText.text = "%s foi derrotado! \n%s ganhou %d EXP. e %d %s"  % [Enemy.Name,Pcname,Enemy.EXPDrop,Enemy.DropQnt,Enemy.enemyDrops(Enemy.Name)]
			battleEnd(PromptText,"Win")
		if is_in_combat == true and Battle.currentTurn == "Player" and Player.current_health == 0:
			PromptText.text = "%s morreu! \nVolte pare um save anterior para continuar." % Pcname
			nextPrompt = 0
			nextdialog = 0
			encounterID = 0
			battleEnd(PromptText)
	Signals.blockEquip.emit(in_dungeon)
		
#Carregar dialogos/prompts
func loadTexts():
	dialogID = Player.dialogID
	promptID = Player.promptID
	getdialogbyID(dialogID)
	getPromptbyID(promptID)


#initialização do player
func initPlayer():
	$BG/MarginContainer/HBoxContainer/Left/PCStats/MarginContainer/PC/ID/PCName.text = Player.pcname
	$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName.text = Player.pcname
	$BG/MarginContainer/HBoxContainer/Left/PCPortrait/PCName.text = Player.pcname
	$BG/MarginContainer/HBoxContainer/Left/PCStats/MarginContainer/PC/ID/Level.text = "Lv. "+str(Player.plevel)
	gold.text = str(Player.gold)+" G"
	Player.updateBar(PC_HP,Player.current_health,Player.max_health)
	Player.updateBar(PC_MP,Player.current_mp,Player.max_mp)
	Player.updateBar(PC_EXP,Player.levelEXP,Player.lvRequirements[Player.plevel-1])

#Fazer o parse do arquivo json
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

#Pegar o dialogo ou prompt caso o ID seja diferente de 0. Atualizar a tela comforme o JSON e preparar as referências dos próximos dialogos/prompts.
func getdialogbyID(ID) -> void:
	if (ID == 0):
		DialogText.hide()
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label.hide()
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName.hide()
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName.hide()
		$BG/MarginContainer/HBoxContainer/Right/NPCPortrait.hide()
	else:
		if dialogID >= len(dialog):
			queue_free()
			return
		
		is_in_dialogue = dialog[dialogID]["continue"]
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer.show()
		$BG/MarginContainer/HBoxContainer/Right/NPCStats.hide()
		nextP = []
		nextD = []
		currentDialog = ID
		currentPrompt = 0
		char1 = dialog[dialogID]["Char1"]
		char2 = dialog[dialogID]["Char2"]

		$BG/MarginContainer/HBoxContainer/Right/NPCPortrait.show()
		$BG/MarginContainer/HBoxContainer/Right/NPCPortrait/NPCName.show()
		$BG/MarginContainer/HBoxContainer/Right/NPCPortrait/NPCName.text = char2
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName.text = char2
			
		DialogText.bbcode_text = dialog[dialogID]["Text"]
		
		nchoices = len(dialog[dialogID]["Choices"])
		
		if (dialog[dialogID]["Speaker"] == 1):
			addtoLogs("dialog",char1,DialogText.text)
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName.show()
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName.hide()
		else:
			addtoLogs("dialog",char2,DialogText.text)
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/NPCName.show()
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Names/PCName.hide()
		if nchoices == 0:
			hideOptions()
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label.show()
			nextdialog = dialog[dialogID]["Next"]
			nextPrompt = dialog[dialogID]["promptID"]
			dialogID = nextdialog
			if promptID != 0 and nextdialog == 0:
				promptID = nextPrompt
				dialogID = nextdialog
			
		elif nchoices == 1:
			hideOptions()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.hide()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.hide()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.hide()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+dialog[dialogID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+dialog[dialogID]["Choices"][1]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.text = "[3] "+dialog[dialogID]["Choices"][2]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.text = "[4] "+dialog[dialogID]["Choices"][3]["TextOP"]
		
		if nchoices != 0:
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer/Label.hide()
			for n in range(nchoices):
				nextD.append(dialog[dialogID]["Choices"][n]["NextD"])
				nextP.append(dialog[dialogID]["Choices"][n]["NextP"])

		textEffect(DialogText)
		Signals.sendStoryID.emit(currentDialog,currentPrompt)

#Mesma coisa do anterior, mas esse atualiza o background usando o JSON
func getPromptbyID(ID) -> void:
	if (ID == 0):
		PromptText.hide()
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label.hide()
	else:
		if promptID >= len(prompt):
			queue_free()
			return
		
		if is_in_dialogue == 0:
			$BG/MarginContainer/HBoxContainer/Right/NPCPortrait.hide()
		$BG/MarginContainer/HBoxContainer/Right/NPCStats.hide()
		nextP = []
		nextD = []
		
		var scene = prompt[promptID]["Scene"]
		imgpath = "res://BG/"+scene+".png" 
		if imgpath == "res://BG/cave.png":
			in_dungeon = true
		else:
			in_dungeon = false

		var stylebox =StyleBoxTexture.new()
		stylebox.texture = load(imgpath)
		
		bgpanel.add_theme_stylebox_override("panel", stylebox)
		
		PromptText.bbcode_text = prompt[promptID]["Text"]
		
		nchoices = len(prompt[promptID]["Choices"])
		
		
		if nchoices == 0:
			hideOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label.show()
			
			nextPrompt = prompt[promptID]["Next"]
			nextdialog = prompt[promptID]["dialogID"]
			encounterID = prompt[promptID]["encounterID"]
			promptID = nextPrompt
			if promptID == 0 and nextdialog != 0:
				dialogID = nextdialog
		
		elif nchoices == 1:
			hideOptions()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			
		elif nchoices == 2:
			hideOptions()

			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.show()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
		
		elif nchoices == 3:
			showOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.hide()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.hide()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]

		elif nchoices == 4:
			showOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.hide()
			
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.text = "[4] "+prompt[promptID]["Choices"][3]["TextOP"]
		elif nchoices == 5:
			showOptions()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text = "[1] "+prompt[promptID]["Choices"][0]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text = "[2] "+prompt[promptID]["Choices"][1]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.text = "[3] "+prompt[promptID]["Choices"][2]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.text = "[4] "+prompt[promptID]["Choices"][3]["TextOP"]
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.text = "[5] "+prompt[promptID]["Choices"][4]["TextOP"]
		
		if nchoices != 0:
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label.hide()
			for n in range(nchoices):
				nextP.append(prompt[promptID]["Choices"][n]["NextP"])
				nextD.append(prompt[promptID]["Choices"][n]["NextD"])
				
		addtoLogs("prompt","",PromptText.text)
		
		textEffect(PromptText)
		currentPrompt = ID
		currentDialog = 0
		Signals.sendStoryID.emit(currentDialog,currentPrompt)

#Efeito no texto de mostrar o texto letra por letra
func textEffect(text):
	finished = false
	text.visible_characters = 0
	while text.visible_characters < len(text.text):
		text.visible_characters += 1
		
		$Timer.start()
		await $Timer.timeout
	finished = true
	return

func _on_op_1_button_pressed() -> void:
	if $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text == "[1] Comprar/Vender":
		if promptID == 21:
			Signals.sendVendor.emit("Mern")
			_on_item_button_pressed()
		if promptID == 22:
			Signals.sendVendor.emit("Uvlo")
			_on_item_button_pressed()
	if $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text == "[1] Explorar a área":
		if promptID == 25:
			Signals.checkQuestState.emit("Alchemists")
	if $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text == "[1] Aprender":
		if promptID == 23:
			Signals.sendVendor.emit("Zuk")
			_on_cast_button_pressed()
	if $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.text == "[1] Sim":
		if promptID == 37:
			no_return = true
	op_next(0)

func _on_op_2_button_pressed() -> void:
	if $BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.text == "[2] Quest":
		if promptID == 21:
			Signals.checkQuestState.emit("Alchemists")
		if promptID == 22:
			Signals.checkQuestState.emit("Uvlo")
	op_next(1)

func _on_op_3_button_pressed() -> void:
	op_next(2)

func _on_op_4_button_pressed() -> void:
	op_next(3)

func hideOptions() -> void:
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.hide()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.hide()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.hide()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.hide()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.hide()

func showOptions() -> void:
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op1Button.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op2Button.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op3Button.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op4Button.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Op5Button.show()

#Usando uma instancia de um container com um texto, adicionar na tabela de logs
func addtoLogs(type,speaker,Text: String):
	var logpanel = LogText.instantiate()
	var log_text = logpanel.get_child(0)
	if (type == "dialog"):
		log_text.text = speaker+": "+Text
		logRows.add_child(logpanel)
	else:
		log_text.text = Text
		logRows.add_child(logpanel)
		
	remove_old_child(500)

#Remover as entradas mais antigas
func remove_old_child(number):
	if logRows.get_child_count() > number:
		var removeChild = logRows.get_child_count() - number
		for i in range(removeChild):
			logRows.get_child(i).queue_free()

#Ao pressionar o botão, esconder os outros textos para mostrar a janela de log e ao apertar novamente voltar ao estado anterior
func _on_logs_button_toggled(button_pressed: bool):
	if button_pressed == true:
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll.show()
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText.hide()
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox.hide()
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel.hide()
	else:
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Scroll.hide()
		$BG/MarginContainer/HBoxContainer/Center/DialogueBox.show()
		if is_in_combat == true:
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel.show()
		else:
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText.show()

#Fazer com que a barra dos logs seja sempre no fim
func change_scroll():
	scroll.scroll_vertical = scrollbar.max_value

#Caso o número dado seja => 0 significa que há opcao a ser escolhida logo utiliza os dados coletados no vetor que armazena a direcao da opcao.
#A direcao é determinada se um deles for != 0 e == 0, indo para o != 0. Caso ambos sejam 0 mas o proximo tenha um encounterID ele pega as informaçoes do encontro e entra em combate 
func op_next(chosenNumber) -> void:
	if chosenNumber >= 0 and (len(nextD) != 0 or len(nextP) != 0):
		nextdialog = nextD[chosenNumber]
		nextPrompt = nextP[chosenNumber]
	
	dialogID = nextdialog
	promptID = nextPrompt
	if nextdialog != 0 and nextPrompt == 0:
		if finished:
			getdialogbyID(dialogID)
			DialogText.show()
			PromptText.hide()
			$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText/MarginContainer/VBoxContainer/Label.hide()
			if dialogID == 0:
				hideOptions()
		else:
			DialogText.visible_characters = len(DialogText.text)
			PromptText.visible_characters = len(PromptText.text)
	if nextPrompt != 0 and nextdialog == 0:
		if finished:
			DialogText.hide()
			PromptText.show()
			$BG/MarginContainer/HBoxContainer/Center/DialogueBox/MarginContainer/VBoxContainer.hide()
			getPromptbyID(promptID)
			if promptID == 0:
				hideOptions()
		else:
			PromptText.visible_characters = len(PromptText.text)
			DialogText.visible_characters = len(DialogText.text)
	if nextPrompt == 0 and nextdialog == 0 and encounterID != 0:
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText.show()
		encounterArray = encounter[encounterID]
		is_in_combat = true
		

#initialização do combate, pegando os dados e com o nome procurar o resource na pasta de inimigos e atualizar a tela
func battleStart(array):
	enemyName = array["Enemy"]
	difficulty = array["Difficulty"]
	nextPrompt = array["promptID"]
	nextdialog = array["dialogID"]
	
	var enemyPath = "res://enemies/"+enemyName+".tres" 
	Enemy = load(enemyPath)
	Signals.which_Enemy.emit(enemyPath,difficulty)
	Signals.combatActive.emit(is_in_combat)
	current_enemyHP = Enemy.HP
	
	$BG/MarginContainer/HBoxContainer/Right/NPCPortrait/NPCName.text = Enemy.Name
	$BG/MarginContainer/HBoxContainer/Right/NPCStats/MarginContainer/NPC/ID/NPCName.text = Enemy.Name
	$BG/MarginContainer/HBoxContainer/Right/NPCStats/MarginContainer/NPC/ID/Level.text = "Lv. "+Enemy.Level
	Battle.currentTurn = "Player"
	Player.updateBar(NPC_HP,Enemy.HP,Enemy.HP)
	Player.updateBar(NPC_MP,Enemy.MP,Enemy.MP)
	showBattle()
	if array["Story"] == true:
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel/BattleCommands/RunButton.hide()
	else:
		$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel/BattleCommands/RunButton.show()
	
#Botao simples para sair do combate	
func _on_run_button_pressed() -> void:
	PromptText.text = "%s escapou de %s!" % [Pcname,Enemy.Name]
	battleEnd(PromptText)

#Sair do combate mostrando o texto dado e se outcome for run simplesmente sair do combate, caso outro (Win) dar exp.
func battleEnd(endText,outcome = "Run"):
	battleText(endText)
	if outcome != "Run":
		Signals.gainItem.emit(Enemy.ItemDrop,Enemy.DropQnt)
		Signals.gainEXP.emit(Enemy.EXPDrop)
		Player.updateBar(PC_EXP,Player.levelEXP,Player.lvRequirements[Player.plevel-1])
		Signals.enemyDefeat.emit(Enemy)
		
	op_next(-1)
	is_in_combat = false
	Battle.currentTurn = ""
	Signals.combatActive.emit(is_in_combat)
	Signals.updateCharTab.emit()
	
#Texto de batalha
func battleText(bText):
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel.hide()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText.show()
	hideOptions()
	addtoLogs("prompt","",bText.text)
	textEffect(bText)

#Mostrar os elementos de batalha
func showBattle():
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/PromptText.hide()
	$BG/MarginContainer/HBoxContainer/Right/NPCStats.show()
	$BG/MarginContainer/HBoxContainer/Right/NPCPortrait.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/BattlePanel.show()

#Funcão de ataque que manda um sinal e atualiza a vida do inimigo
func _on_attack_button_pressed() -> void:
	Signals.playerAction.emit("Attack",current_enemyHP,enemyName)
	if crit == false:
		PromptText.text = "%s deu %d de dano no %s!" % [Pcname,Battle.playerdamage,Enemy.Name]
	else:
		PromptText.text = "Golpe Crítico!\n%s deu %d de dano no %s" % [Pcname,Battle.playerdamage,Enemy.Name]
		crit = false
	battleText(PromptText)

#Funcão que de um signal que muda a hp do target
func change_targetHP(target,new_HP,action):
	if target == enemyName:
		current_enemyHP = new_HP
		Player.updateBar(NPC_HP,current_enemyHP,Enemy.HP)	
		if action == "critAttack":
			crit = true
		if Battle.spell != null and action == Battle.spell.Name:
			if Battle.resistance < 0:
				effectiveAttack = 1
			elif Battle.resistance > 0:
				effectiveAttack = -1
			else: 
				effectiveAttack = 0
			spellAction(action)
	if target == Pcname:
		Player.current_health = new_HP
		act = action

#Abre a window de personagem se não estiver em combate
func _on_char_button_pressed() -> void:
	$BG/MarginContainer2.show()
	$BG/MarginContainer2/CharacterTab.show()
	$BG/MarginContainer2/InventoryTab.hide()

#Atualiza os dados para quando o player faz level up na tela de personagem ou equipa um item diferente que altera hp/mp
func updateMain():
	initPlayer()

func _on_inv_button_pressed() -> void:
	$BG/MarginContainer2.show()
	$BG/MarginContainer2/InventoryTab.show()
	$BG/MarginContainer2/CharacterTab.hide()
	Signals.openInventory.emit()

func _on_defend_button_pressed() -> void:
	Signals.playerAction.emit("Defend",current_enemyHP,enemyName)
	PromptText.text = "%s se preparou para defender!" % Pcname
	battleText(PromptText)

func _on_item_button_pressed() -> void:
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows/InventoryTab.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows/SpellsTab.hide()
	
func use_Item(item:Consumables):
	if is_in_combat:
		var hpRec = item.HP_Restored
		var mpRec = item.MP_Restored
		PromptText.text = "Koz usou um %s e recuperou " % item.Name
		if hpRec != 0 and mpRec == 0:
			PromptText.text += "%d HP!" % hpRec
		if hpRec == 0 and mpRec != 0:
			PromptText.text = PromptText.text+"%d MP!" % mpRec
		battleText(PromptText)
		initPlayer()
		Battle.change_Turn()


func _on_cast_button_pressed() -> void:
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows/SpellsTab.show()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows/InventoryTab.hide()

func getSpell(spell:Spells):
	Signals.playerAction.emit("Magic",current_enemyHP,enemyName,spell)

func spellAction(spellName):
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows.hide()
	initPlayer()
	if effectiveAttack == 0:
		PromptText.text =  "%s usou %s!\n%d de dano foi causado em %s." % [Pcname,spellName,Battle.playerdamage,Enemy.Name]
	elif effectiveAttack > 0:
		PromptText.text =  "%s usou %s!\n%d de dano (+%d"%[Pcname,spellName,Battle.playerdamage,abs(Battle.resistance)]+"%"+") foi causado em %s."%Enemy.Name
	elif effectiveAttack < 0:
		PromptText.text =  "%s usou %s!\n%d de dano (-%d"%[Pcname,spellName,Battle.playerdamage,abs(Battle.resistance)]+"%"+") foi causado em %s." % Enemy.Name
	battleText(PromptText)

func character_Casting(charName,spell,castTime):
	initPlayer()
	$BG/MarginContainer/HBoxContainer/Center/Prompt/MarginContainer/Windows.hide()
	if charName == Player.pcname:
		PromptText.text = "%s está conjurando %s por %d turnos!" % [Pcname,spell.Name,castTime]
		battleText(PromptText)
		
		
func _on_load_button_pressed() -> void:
	_save = SaveGame.new()
	_save = _save.load_save()
	if _save != null:
		Player.pcname = _save.name
		Player.level = _save.level
		Player.strength = _save.strength
		Player.agility = _save.agility
		Player.intelligence = _save.intelligence
		Player.constituion = _save.constituion 
		Player.current_health = _save.current_health 
		Player.current_mp = _save.current_mp
		Player.experience = _save.experience
		Player.statPoints = _save.statPoints
		Player.promptID = _save.promptID
		Player.dialogID = _save.dialogID 
		Player.plevel = _save.plevel
		Player.gold = _save.gold
		imgpath = _save.background
		var stylebox = StyleBoxTexture.new()
		stylebox.texture = load(imgpath)
		bgpanel.add_theme_stylebox_override("panel", stylebox)
		
		Inventory = _save.inventory
		Equipment = _save.equipment
		PlayerSpells = _save.spellList
		Global.quests = _save.quests
		for i in range(len(Global.quests)):
			Global.quests[i].Flag = _save.quests[i].Flag
		Signals.loadEquipment.emit(Equipment)
		Signals.loadSpells.emit(PlayerSpells)
		Signals.loadInventory.emit(Inventory)
		Signals.loadQuests.emit(_save.quests)
		Signals.loadZukSL.emit(_save.ZukSpells)
		Signals.reload.emit()
		
		get_tree().reload_current_scene()
	
func _on_save_button_pressed() -> void:
	if Inventory == null and Equipment == null and PlayerSpells == null:
		Inventory = load("res://inventory/Inventory.tres")
		Equipment = load("res://inventory/InventoryEquip.tres")
		PlayerSpells = load("res://spells/PlayerSpellList.tres")
	
	Signals.requestQuests.emit()
	_save = SaveGame.new()
	_save.name = Player.pcname
	_save.level = Player.level
	_save.strength = Player.strength
	_save.agility = Player.agility
	_save.intelligence = Player.intelligence
	_save.constituion = Player.constituion
	_save.current_health = Player.current_health
	_save.current_mp = Player.current_mp
	_save.experience = Player.experience
	_save.statPoints = Player.statPoints
	if no_return == false:
		_save.promptID = currentPrompt
		_save.dialogID = currentDialog
	else:
		_save.promptID = 28
		_save.dialogID = 0
	_save.plevel = Player.plevel
	_save.allocatedStats = Player.allocatedStats
	_save.inventory = InventoryData.new()
	_save.equipment = InventoryData.new()
	_save.spellList = SpellList.new()
	_save.gold = Player.gold
	_save.background = imgpath
	
	for i in range(len(Player.Inventory.slotDatas)):
		if Player.Inventory.slotDatas[i].qnt != 0:
			_save.inventory.slotDatas.append(Player.Inventory.slotDatas[i])
	for i in range(len(Player.Equips.slotDatas)):
		_save.equipment.slotDatas.append(Player.Equips.slotDatas[i])
	for i in range(len(Player.PlayerSpells.slotDatas)):
		_save.spellList.slotDatas.append(Player.PlayerSpells.slotDatas[i])
	_save.quests = Global.quests
	for i in range(len(Global.quests)):
		_save.quests[i].Flag = Global.quests[i].Flag
		if i == 0:
			_save.MartaQ1 = Global.quests[i]
		if i == 1:
			_save.UvloQ1 = Global.quests[i]
	
		
	_save.save_game()

func _next_Segment(getDialog,getPrompt):
	nchoices = 0
	nextdialog = getDialog
	nextPrompt = getPrompt
	op_next(-1)

func _on_op_5_button_pressed() -> void:
	op_next(4)


func _on_evade_button_pressed() -> void:
	Signals.playerAction.emit("Evade",current_enemyHP,enemyName)
	PromptText.text = "%s se preparou para desviar!" % Pcname
	battleText(PromptText)

func _get_quests(questsArray):
	quests = questsArray

func _get_ZukSL(ZukSL):
	ZukSpellList = ZukSL
