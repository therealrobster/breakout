#script: gameLevel
extends Node2D

onready var touchArea	=	get_node("Area2DTouch")
var touchPos			=	Vector2(0,0)

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	prepareBall()
	drawLifeIndicators()
	showHighScore()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		#reset score if we're bailing out
		globals.scores["score"] = 0
		#change back to level select scene
		get_tree().change_scene("res://levelSelect.tscn")
	if event.is_action_pressed("debug_newBall"):
		prepareBall()
	if event.is_action_pressed("debug_largeBat"):
		get_node("/root/gameLevel/bat/AnimationPlayer").play("largeBat")
	if event.is_action_pressed("debug_guns"):
		get_node("/root/gameLevel/bat").setState("shooting")
	if event.is_action_pressed("pause"):
		if globals.paused:
			get_tree().set_pause(false)
		else:
			get_tree().set_pause(true)



#TO DO. This is crashing the app (removing all nodes)
func removeLifeIndicators():
	var indicators = get_tree().get_nodes_in_group("lifeIndicators")
	for i in indicators:
		if i != null:
			i.queue_free()

func drawLifeIndicators():
	#first remove any that already exist, in case we're refreshing
	removeLifeIndicators()
	
	#now add the new ones / add them back
	var containerBox = get_node("HUD/HBoxContainer")
	var scene = load("res://batMini.tscn")
	var newBatMini
	for i in range(0, globals.lives):
		newBatMini = scene.instance()
		#containerBox.add_spacer(true)
		containerBox.add_child(newBatMini)
		newBatMini.add_to_group("lifeIndicators")

func prepareBall():
	#instance the ball into the scene
	var ball = load("res://ball.tscn")
	var ballInstance = ball.instance()
	get_node("/root/gameLevel").add_child(ballInstance)	


func _fixed_process(delta):	
	#call the bat move function each frame so we can update its position
	get_node("bat").moveDatBat(delta, touchPos)

func showHighScore():
	#update the high score label, as we're starting from a new game at this point anyway
	var highScoreText = "high score : " + str(globals.scores["highScore"])
	get_node("/root/gameLevel/HUD/LabelHighScore").set_text(highScoreText)


#read in the touch location from "event"" so we can pass it to the bat script
func _on_Area2DTouch_input_event( viewport, event, shape_idx ):
	touchPos = event.pos  #this is a Vector2 with local position of the touch
	get_node("bat").touchPos = touchPos	#moving the value of the touch location to our variable to share to the bat