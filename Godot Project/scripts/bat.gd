extends KinematicBody2D

var touchPos = Vector2(0,0)		#this will be filled from the _on_Area2DTouch_input_event function in the gameLevel.gd file
var batState	=	"normal"		#normal, small, large, shooting, magnet
var scene
var timer



func _ready():
	#preload the bullet scene
	scene = load("res://bullet.tscn")
	#setup the timer
	timer = get_node("Timer")
		
func startTimer():
	timer.start()
	#print("Shoot timer started")
	
#this is set from the fallingPowerup
func setState(state):
	batState = state

#sends the current state to whoever asks for it
func readState():
	return batState
	
#take the touchPos value sent from gameLevel _on_Area2DTouch_input_event and move the bat
func moveDatBat(delta, touchPos):
	move_to(Vector2(touchPos.x, 450))

#once timer has counted down, shoot a/another bullet
func _on_Timer_timeout():
	#current bat position
	var XPlacement = get_pos().x
	var YPlacement = get_pos().y-10
	#Left bullet position
	var leftX = XPlacement - 21
	#Right bullet position
	var rightX = XPlacement + 21
	
	#if we're shooting, let's launch some bullets of course!
	if batState == "shooting":
		#create /instance the new bullet
		var newBulletL = scene.instance()
		var newBulletR = scene.instance()
		#set LEFT bullet Position to be on the bat
		newBulletL.set_pos(Vector2(leftX,YPlacement))
		#create the bullet
		get_tree().get_root().add_child(newBulletL)
		#set RIGHT bullet Position to be on the bat
		newBulletR.set_pos(Vector2(rightX,YPlacement))
		#create the bullet
		get_tree().get_root().add_child(newBulletR)