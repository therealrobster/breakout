#script: button.tscn  
#Should have called it  BRICKS.TSCN but oh well. Mistakes were made.
extends Node2D

export var numOfHitsRequired 	= 1				#default to 1
var nameOfTexture		= "ERASE.png"	#default to grey/transparent
var powerupName			= "none"		#what powerup, if any, is assigned to this brick

#signal brickColour

func _ready():
	set_process_input(true)

func setNumHitsRequired(number):
	numOfHitsRequired = number
	
func setPowerUpName(name):
	powerupName = name

func destroyThisBrick():
	#set the score dictionary
	globals.scores["score"] += 1
	#write the high score if we're at the high score
	checkHighScore()
	#set the score label
	var scoreText = "Score: "+str(globals.scores["score"])
	get_node("/root/gameLevel/HUD/LabelScore").set_text(scoreText)
	#play random destroy brick sound
	randomize()
	if globals.soundEnabled:
		get_parent().get_parent().get_node("SamplePlayer2D").play("brickBreak" + str(randi() % 3))
	#now we must go... it's been a great life. farewell
	self.queue_free()

	#tell the particles what brick colour we're using	
	#print("getting texture")
	globals.particleTexture = get_node("TextureButton").get_normal_texture().get_path()
	#print("globals.particleTexture = ", str(globals.particleTexture))
	#var currentTexture = get_node("TextureButton").get_normal_texture()
	#globals.particleTexture = currentTexture.get_path()

	#play the brick destroy animation effect
	#the brickBreak animation scene we will instance
	var scene = load("res://brickBreak.tscn")
	#add an offset to the position to centre it
	var breakPos = Vector2(get_pos().x+15, get_pos().y+10)
	var newBrickBreak = scene.instance()
	newBrickBreak.set_global_pos(breakPos)
	get_node("/root/gameLevel").add_child(newBrickBreak)

func checkHighScore():
	var highScoreText
	if (globals.scores["score"] > globals.scores["highScore"]):
		#update he dictionary
		globals.scores["highScore"] = globals.scores["score"]
		#update the high score label
		highScoreText = "high score : " + str(globals.scores["highScore"])
		get_node("/root/gameLevel/HUD/LabelHighScore").set_text(highScoreText)
		#write the file
		globals.highScoreSave()