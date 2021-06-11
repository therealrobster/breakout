extends Node2D

onready var animPlayer = get_node("AnimationPlayer")
onready var player = get_node("SamplePlayer2D")
var pressed = false	#has the button been pressed yet?

func _ready():
	#animate the tile loading
	animPlayer.play("fadeIn")
	set_process(true)

func _process(delta):
	if pressed:
		#only move forward if no sound playing
		if(!player.is_voice_active(0)):
			moveToLevel()

func _on_TextureButton_pressed():
	#only allow button press if lock not in place
	if !get_node("SpriteLock").is_visible():
		#play a sound first
		if globals.soundEnabled:
			player.play("buttonPress")
		#set pressed to true for the process function
		pressed = true
		#turn on light to show button selected
		get_node("Light2D").set_enabled(true)
	else:
		#TODO play a not allowed sound effect
		if globals.soundEnabled:
			player.play("buttonFail")

func moveToLevel():
	#set the global current level to the text on this button.  To ensure we load the correct level
	globals.currentLevel = int(get_node("Label").get_text())
	#print("level chosen : ", str(globals.currentLevel))
	
	#move to the game scene
	get_tree().change_scene("gameLevel.tscn")