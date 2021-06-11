#script: bullet
extends KinematicBody2D

var _movement 			= Vector2()		# Movement
var _gravity 			= .1

func _ready():
	set_fixed_process(true)
	add_to_group("bullets")		#so we can bulk process them later if required

	#send it skyward
	launch(Vector2(0,-5)) #directional force

func _fixed_process(delta):
	#make the bullet move
	_movement.y += delta * _gravity
	move(_movement)
	
	#find out if we hit a brick
	if is_colliding():
		var entity = get_collider()
		if entity.get_parent().is_in_group("bricks"):
			#destroy the brick
			entity.get_parent().destroyThisBrick()			
			#destroy ourselves
			queue_free()
			#check if the level is over or not (we shot the last brick)
			if get_tree().get_nodes_in_group("bricks").size() <= 1:
				#show the congrats scene
				get_node("/root/gameLevel/levelFinished").showScene()
				get_node("/root/gameLevel/levelFinished").updateLabels()
				#remove any leftover balls
				if self.is_inside_tree():
					var ballList = get_tree().get_nodes_in_group("balls")
					if ballList.size() >= 1:
						for i in ballList:
							i.queue_free()
				#hide the bat and turn off the bullets
				get_node("/root/gameLevel/bat").hide()
				get_node("/root/gameLevel/bat/Timer").stop()
				if get_node("/root/gameLevel/HUD/powerupTimer"):
					get_node("/root/gameLevel/HUD/powerupTimer")._on_Timer_timeout()


	#if we leave the screen, destroy ourselves
	if !get_node("VisibilityNotifier2D").is_on_screen():
		queue_free()

func launch(directional_force):
	_movement = directional_force
	#play launch sound
	if globals.soundEnabled:
		get_node("SamplePlayer2D").play("shoot1")