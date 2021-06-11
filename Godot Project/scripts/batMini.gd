#script: batMini
extends Control

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func _on_batMini_exit_tree():
	#a life is over, so let's play a sound to drum that home
	if globals.soundEnabled:
		get_node("/root/gameLevel").get_node("SamplePlayer2D").play("lifeGone")
	
	#let's set the bat back to its standard state by using the same code as the timer's time out!  Easy
	if get_node("/root/gameLevel/HUD/powerupTimer"):
		get_node("/root/gameLevel/HUD/powerupTimer")._on_Timer_timeout()
	
	#let's set the timer to maximum and stopped
	var timer = get_node("/root/gameLevel/HUD/powerupTimer/Timer")
	timer.stop()
	var progressIndicator = get_node("/root/gameLevel/HUD/powerupTimer/ProgressBar")
	progressIndicator.set_value(globals.powerupTimeout)
	
	#destroy all the falling Powerups, no fair to collect them after dying I say!
	var powerups = get_tree().get_nodes_in_group("powerups")
	for i in powerups:
		if i != null:
			i.queue_free()