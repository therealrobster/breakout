#script: Powerup Timer
extends Control

onready var timer = get_node("Timer")
onready var bar = get_node("ProgressBar")

func _ready():
	bar.set_value(globals.powerupTimeout)
	set_fixed_process(true)

func _fixed_process(delta):
	setBarValue(timer.get_time_left())

func setBarValue(value):
	bar.set_value(value)
	
func restartTimer():
	pass

func _on_Timer_timeout():
	#reset the bat to its default
	var bat = get_node("/root/gameLevel/bat")
	var animPlayer = get_node("/root/gameLevel/bat/AnimationPlayer")
	var animPlayer2 = get_node("/root/gameLevel/bat/AnimationPlayer2")
	var animPlayer3 = get_node("/root/gameLevel/bat/AnimationPlayer3")
	if bat:
		if bat.batState == "large":
			animPlayer.play("largeToNormal")
		elif bat.batState == "small":
			animPlayer.play("smallToNormal")
		elif bat.batState == "shooting":
			animPlayer2.play("gunsDown")
		elif bat.batState == "magnet":
			animPlayer3.play("hideMagnet")
			get_node("/root/gameLevel/bat/StreamPlayer").stop()
			
		elif bat.batState == "normal":
			pass	
		#we're resetting the bat, so make its state to be normal
		bat.setState("normal")
	
	#reset the ball to its defaults
	globals.ballState = "normal"
	if is_inside_tree():
		if get_tree().get_nodes_in_group("balls").size() <= 1:
			for ball in get_tree().get_nodes_in_group("balls"):
				if ball:
					ball.changeBallSpeed(1)
					ball.resetBallSpeed()
					ball.removePowerBall()