#script: bricks
extends Node2D

var level 		= "1.txt"	#just a default value for now, will be filled in later
var XPlacement 	= 3			#how many pixels from the left do we start drawing
var YPlacement 	= 2			#how many pixels from the top do we start drawing
var YPadding	= 12
var XPadding	= 31
var XTiles		= 9			#how many tiles across we draw

func _ready():
	#get the name of the file we'll be loading
	var fileToLoad = str(globals.currentLevel)+".txt"
	loadBricks(fileToLoad)
	
	
#select a random powerup based on rules in this fuction
#returns the powerup name to be used
func powerupPicker():
	
	#create a dictionary of powerups and their chance of being picked (their frequency)
	var powerups = { 'types': ["powerupExtraLife", "powerupFastBall", "powerupSlowBall", "powerupLargeBat", "powerupSmallBat", "powerupPowerBall", "powerupBatGuns", "powerupBunchOBalls", "powerupMagnetBat"],
						'frequency': [1, 2, 2, 3, 1, 2, 2, 3, 2] }
	
	# Calculate the sum of the frequencies of all the powerups
	# this will be used in the calculation of when a powerup has to be picked randomly
	powerups.sum_frequency = 0
	for frequency in powerups.frequency:
		powerups.sum_frequency += frequency


	# Determine the powerup type based on their individual frequencies
	# by picking a number in range of the cumulated frequencies, and then checking
	# each interval until the corresponding one is found
	randomize()
	var index = randi() % powerups.sum_frequency
	var sum = powerups.frequency[0]
	for i in range(powerups.types.size()):
		if index <= sum:
			index = i
			return powerups.types[index]  #return the name of the chosen powerup
			break
		sum += powerups.frequency[i + 1]
	#var powerupChosen = powerups.types[index]
	#print("powerup chosen : ", powerupChosen)

	
	
func loadBricks(level):
	#clear away the old  bricks
	removeBricks()	
	
	#reset the start placement for the new bricks
	XPlacement = 3
	YPlacement = 2

	#we will keep track of which column we're up to so we can wrap to the next column
	var XCol = 0
	var YCol = 0

	#create the filename to load based on the selected level in the drop down menu. Example: "user://1.txt"
	var filenameToLoad = str("res://leveldata/") + level

	#Load her up
	var levelFile = File.new()
	if !levelFile.file_exists(filenameToLoad):
		print("File is not here.  This level does not exist")
		return

	#prep the array and open the file
	var current_line = {}
	levelFile.open(filenameToLoad, File.READ)
	
	#Loop through file until EOF
	while(!levelFile.eof_reached()):
		#grab the first line
		var line = levelFile.get_line()
		#if at end of file, stop
		if line.empty():
			break
		#otherwise let's work through each line
		#clear the array
		current_line.clear()
		#add the current line to the array
		current_line.parse_json(line)
		#create /instance the new bick
		var scene = load("res://button.tscn")
		var newBrick = scene.instance()
		#name Brick
		var newName = str(XCol,"-",YCol)
		newBrick.set_name(newName)
		#set Brick texture
		var textureString = "res://textures/bricks/"+current_line["texture"]
		var textureToUse = load(textureString)
		newBrick.get_node("TextureButton").set_normal_texture(textureToUse)
		newBrick.nameOfTexture = current_line["texture"]
		#set Brick Position
		newBrick.set_pos(Vector2(XPlacement,YPlacement))

		#set Brick NumHits, this works
		newBrick.numOfHitsRequired = current_line["numOfHits"]

		#Only allow a % of bricks to have powerups:
		var chanceOfPowerup = randi()%11+1 #returns an int from 1 to 10
		#If we hit the 1 out of 10
		if chanceOfPowerup == 1:
			#Choose a random powerup for the brick and assign it
			var powerupChosen = powerupPicker()
			newBrick.setPowerUpName(powerupChosen)
		#check if the brick is an empty (ERASE) brick or not
		if newBrick.nameOfTexture == "ERASE.png":
			pass
		else:
			#Now place the brick in the scene
			add_child(newBrick)
			#add the brick to the group so we can deal with it in bulk
			newBrick.add_to_group("bricks")

		#place brick in correct location as we move through loop
		XCol += 1	#increment our column count, this is working
		#if we're still less than the maximum column count, keep drawing from left to right
		if XCol < XTiles:
			XPlacement += XPadding
		#otherwise, move to the next line and start drawing from the left hand side again
		else:
			YPlacement += YPadding
			XPlacement = 3
			XCol = 0
			YCol += 1

	levelFile.close()
	
	#play the new level sound
	if globals.soundEnabled:
		get_parent().get_node("SamplePlayer2D").play("levelStart01")

func removeBricks():
	#delete all the old bricks
	var bricks = get_tree().get_nodes_in_group("bricks")
	for i in bricks:
		i.free()