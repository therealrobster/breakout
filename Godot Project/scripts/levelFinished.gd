extends Control

var pressed = false
onready var player = get_node("SamplePlayer2D")

func _ready():
	set_process(true)

func _process(delta):
	if pressed:
		if !player.is_voice_active(0):
			nextLevel()
			pressed = false

func updateLabels():
	
	var buttonImageLevelSelect = load("res://textures/Button-Large-levelSelect.png")
	var buttonImageLevelNext = load("res://textures/Button-Large-nextLevel.png")
	
	if globals.totalLevels == globals.currentLevel-1:
		#we finished the game
		#show the fireworks
		get_node("Particles2D").show()
		#play the music
		if globals.soundEnabled:
			get_node("SamplePlayer2D").play("game won")
		#udpate the labels
		get_node("LabelHeading").set_text("CONGRATULATIONS! YOU WON!!")
		var textToAdd = "Your Score: " + str(globals.scores["score"])
		get_node("LabelCurrentScore").set_text(textToAdd)
		levelCompleteSave()
		get_node("TextureButtonContinue").set_normal_texture(buttonImageLevelSelect)
	else:
		#make sure fireworks are hidden
		get_node("Particles2D").hide()
		#play a sound
		if globals.soundEnabled:
			get_node("SamplePlayer2D").play("level won")
		#update the labels
		var textToAdd = "Level " + str(globals.currentLevel) + " unlocked!"
		get_node("LabelHeading").set_text(textToAdd)
		textToAdd = "Current Score: " + str(globals.scores["score"])
		get_node("LabelCurrentScore").set_text(textToAdd)
		levelCompleteSave()
		get_node("TextureButtonContinue").set_normal_texture(buttonImageLevelNext)

	
func showScene():
	#show the next level menu
	self.show()
	#increment the level we're up to
	globals.currentLevel += 1


func levelCompleteSave():
	var levelCompleteText
	var levelToWrite
	# Open a file
	var file = File.new()	
	var fileToUse = str("user://levelComplete.txt")
	if file.open(fileToUse, File.WRITE) != 0:
		#print("Error opening file")
		return	
	else:
		var newLevel = globals.currentLevel
		levelToWrite = { 
			levelCompleteText = newLevel
		}
		file.store_line(levelToWrite.to_json())
		file.close()	

func _on_TextureButtonContinue_pressed():
	pressed = true
	if globals.soundEnabled:
		player.play("buttonPress")
	
	
func nextLevel():
	#hide this menu
	self.hide()
	
	if globals.totalLevels == globals.currentLevel-1:
		#we finished, let's go back to main level selection
		get_tree().change_scene("levelSelect.tscn")
	else:
		#create next level
		var fileToLoad = str(globals.currentLevel)+".txt"
		get_node("/root/gameLevel/bricks").loadBricks(fileToLoad)
		#remove any balls that may be hidden from the ending of the last level
		var ballList = get_tree().get_nodes_in_group("balls")
		for i in ballList:
			i.queue_free()
		#set the ball onto the bat, ready to go
		get_node("/root/gameLevel").prepareBall()
		#make sure the bat is visible in case we've already hidden it elsewhere
		get_node("/root/gameLevel/bat").show()