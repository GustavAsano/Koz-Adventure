extends Node

var story_dir = "res://story/"
@onready var prologue:Story = load("res://story/prologue.tres")
@onready var dungeon:Story = load("res://story/dungeon.tres")
var currentPrompt
var currentDialog
var currentChapter
var head:Armors
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.sendStoryID.connect(_get_storyID)
	"""
	var files = Global.dir_contents(story_dir)
	for file in files:
		if file == "res://story/prologue.tres":
			prologue = load(file)
		if file == "res://story/dungeon.tres":
			dungeon = load(file)
	"""
	get_chapter()
	
func _get_storyID(dialogID,promptID):
	currentDialog = dialogID
	currentPrompt = promptID
	if currentChapter == "Prologue":
		#As tres flags se referem ao ver determinado dialogos.
		if currentDialog == 52:
			prologue.Flags[0] = 1
		if currentDialog == 60:
			prologue.Flags[1] = 1
		if currentDialog == 68:
			prologue.Flags[2] = 1
		if prologue.Flags == [1,1,1]:
			Signals.nextSegment.emit(0,16)
			get_chapter()
	if currentPrompt == 38:
		check_playerHead()
		if head:
			if head.Name == "Laço Branco":
				dungeon.Flags[0] = 2
			if head.Name == "Gorro do Ladrão":
				dungeon.Flags[0] = 1
	if currentDialog == 105 and dungeon.Flags[0] == 2:
		Signals.nextSegment.emit(107,0)

func get_chapter():
	if prologue.Flags != [1,1,1]:
		currentChapter = "Prologue"
	if prologue.Flags == [1,1,1]:
		currentChapter = "Ch.1"

func check_playerHead():
	if Player.head:
		head = Player.head


