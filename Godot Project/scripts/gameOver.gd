#script: gameOver
extends Control


func _ready():
	updateLabels()
	resetGameData()

func resetGameData():
	globals.scores["score"] = 0
	globals.lives = 3
	globals.ballSpeed = globals.ballSpeedReset
	globals.currentLevel = 0
	globals.gameComplete = false

func updateLabels():
	var textToAdd
	if globals.gameComplete:
		textToAdd = "YOU WON!! You reached level " + str(globals.currentLevel)
	else:
		textToAdd = "You reached level " + str(globals.currentLevel)
		#play game over music
		if globals.soundEnabled:
			get_node("SamplePlayer2D").play("LevelOver")
	get_node("LabelHeading").set_text(textToAdd)
	textToAdd = "Your Score: " + str(globals.scores["score"])
	get_node("LabelCurrentScore").set_text(textToAdd)
	textToAdd = "High Score: " + str(globals.scores["highScore"])
	get_node("LabelHighScore").set_text(textToAdd)

func showScene():
	#show the game over scene
	self.show()
	

func _on_TextureButtonContinue_pressed():
	#hide this menu
	self.hide()
	get_tree().change_scene("levelSelect.tscn")