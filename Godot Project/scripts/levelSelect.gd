#script: levelSelect
extends Node

var numColumns 		= 4  #how many columns of level select icons we'll be drawing
var XPlacement		= 6 #how many pixels across are we placing the icons.  Start with this number
var YPlacement		= 2
var XPadding 		= 66
var YPadding 		= 69
var levelReached	= 0  #how many levels have they played and completed (unlocked)

onready var player = get_node("StreamPlayer")
var introSound
var loopingSound
var currentSound = introSound


func _ready():
	
	#setup the sounds
	introSound = load("res://audio/neonStartup.ogg")
	loopingSound = load("res://audio/loopingHum.ogg")
	set_process_input(true)
	
	set_process(true)
	levelCompleteLoad()
	loadLevelNumbers()
	
	setSoundButtonStatus()
	
func setSoundButtonStatus():
	var spriteTextureOn = load("res://textures/speakerOn.png")
	var spriteTextureOff = load("res://textures/speakerOff.png")
	if globals.soundEnabled:
		get_node("TextureButtonSound").set_normal_texture(spriteTextureOn)
	else:
		get_node("TextureButtonSound").set_normal_texture(spriteTextureOff)


func _process(delta):
	#after initial neon startup sound is played, loop the humm
	if globals.soundEnabled:
		if player.is_playing() != true:
			if player.get_stream() == introSound:
				player.set_stream(loopingSound)
				player.set_loop(true)
			if globals.soundEnabled:
				player.play()
	
func _input(event):

	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	pass


func levelCompleteLoad():
	var dict = {}
	var file = File.new()
	var err = file.open("user://levelComplete.txt", file.READ)
	#if the file exists....
	if err == OK:
		var text = file.get_as_text()
		dict.parse_json(text)
		file.close()
		levelReached = dict["levelCompleteText"]
	else:
		pass
		#do nothing.  If there is no file, then the highscore can stay at '0'


func deleteLevelNumbers():
	var tiles = get_tree().get_nodes_in_group("levelSelectTiles")
	for i in tiles:
		i.free()

func loadLevelNumbers():
	
	#delete any that are showing (in case we're re-loading)
	deleteLevelNumbers()
	
	#grab the file path stuff
	var path = "res://leveldata/"
	var dir = Directory.new()
	
	var levelText = 0	#this will become the text on the icons
	
	#The tile
	var scene = load("res://levelSelectTile.tscn")
	
	#we will keep track of which column we're up to so we can wrap to the next column when drawing icons
	var XCol = 0
	var YCol = 0

	#iterate through the folder and count each file in there
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				#ignore and move on if a directory
				pass
			else:
				levelText += 1 #button text increments each time through loop
				var newTile = scene.instance()  #instance the icon scene
				newTile.set_pos(Vector2(XPlacement,YPlacement))  #position it
				get_node("ScrollContainer/Control").add_child(newTile)	#add it to the tree (make it real)
				
				#only show tiles we can access based on our progress
				if levelText <= levelReached:
					newTile.get_node("Label").set_text(str(levelText))	#name the tile to match what level we're showing
				else:
					#if the file doesn't exist (first play) then show level 1 as accessible
					if levelText == 1:
						newTile.get_node("Label").set_text(str(levelText))	#name the tile to match what level we're showing
					else:
						newTile.get_node("SpriteLock").show() #show lock icon

				newTile.add_to_group("levelSelectTiles")
				#place tile in correct location as we move through loop
				XCol += 1	#increment our column count, this is working
				#if we're still less than the maximum column count, keep drawing from left to right
				if XCol < numColumns:
					XPlacement += XPadding
				#otherwise, move to the next line and start drawing from the left hand side again
				else:
					YPlacement += YPadding
					XPlacement = 6
					XCol = 0
					YCol += 1

			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the saved levels in the directory.")


func _on_TextureButtonUp_button_down():
	var scroller = get_node("ScrollContainer")
	scroller.set_v_scroll(scroller.get_v_scroll()-128)

func _on_TextureButtonDown_button_down():
	var scroller = get_node("ScrollContainer")
	scroller.set_v_scroll(scroller.get_v_scroll()+128)


func _on_AnimationPlayer_finished():
	var player = get_node("AnimationPlayer")
	#if player.get_animation("fadeIn"):
	player.play("flicker")


func _on_TextureButton_pressed():
	#visit the website
	OS.shell_open("http://www.video-games.io")

func _on_TextureButtonSound_pressed():
	var soundPlayer = get_node("SamplePlayer2D")
	var spriteTextureOn = load("res://textures/speakerOn.png")
	var spriteTextureOff = load("res://textures/speakerOff.png")
	if globals.soundEnabled:
		globals.soundEnabled = false
		soundPlayer.play("buttonPress")
		#apply the texture to the sprite
		get_node("TextureButtonSound").set_normal_texture(spriteTextureOff)
		player.stop()
	else:
		globals.soundEnabled = true
		soundPlayer.play("buttonPress")
		#apply the texture to the sprite
		get_node("TextureButtonSound").set_normal_texture(spriteTextureOn)