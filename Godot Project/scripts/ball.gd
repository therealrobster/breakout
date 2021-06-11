extends KinematicBody2D

onready var state 	= BatHugState.new(self)	# this creates a new instance of the state.  It will call the states _init function of course kicking it all off
onready var camera	= get_node("/root/gameLevel/Camera2D")

var ballDiameter						# we need this right?  Course we do
var _gravity 			= .5			#  Gravity
var _movement 			= Vector2()		#  Movement
var bounce 				= 1				#  Bounce reduction
var shakeAmount 		= 2				#  for screen shake
var timer								#  for screen shake
var timerLength 		= .15			#  for screen shake
var shakeAllowed 		= false			#  for screen shake
var initialBallSpeed	= -5			#  how fast is this ball anyway?
var speedIncrement		= 1				#  speed up when using powerup
var powerBall			= false			#  can we smash bricks like butter?!

var batOffset 			= Vector2(0,0)	# find the difference between the bat's centre and where the ball hit it

const STATE_MOVING		= 0
const STATE_BATHUG		= 1
const STATE_LEVELOVER	= 2
const STATE_BATMAGNET	= 3
const STATE_MULTILAUNCH = 4
const MAXBOUNCEANGLE	= deg2rad(160)	# the max bounce angle (in radians) of the ball when hitting the edge of the bat

signal levelOver
signal hitWall

func _ready():
	
	# setup the timer for camera shakey shake!
	timer = Timer.new()					# create an instance of the timer
	timer.set_one_shot(true)			# only count down once then stop
	timer.set_wait_time(timerLength)	# how long the timer runs for
	add_child(timer) 					# make it a child of this ball instance
	
	set_process_input(true)
	set_fixed_process(true)

	ballDiameter = get_node("Sprite").get_texture().get_width()	# good to know how large this sprite is
	add_to_group("balls")	# so we can bulk process them later if required

	# force bathug for now
	state = BatHugState.new(self)


func _fixed_process(delta):
	
	# call the update function within the state class.  Very cool
	# It doesn't matter which state we're in, this will call the function with the same name in each class that is "state" as per the onready above
	state.update(delta)
	
func _input(event):
	# call the input function from within the state class. Clevs
	state.input(event)

# dust puff off wallls
func makeDust():
	var scene = load("res://dustBall.tscn")
	var sceneInstance = scene.instance()
	get_node("/root/gameLevel").add_child(sceneInstance)	

# powerup changes this to make ball faster
func changeBallSpeed(newSpeed):
	if globals.ballState == "fast":
		speedIncrement = newSpeed
	elif globals.ballState == "slow":
		speedIncrement = newSpeed


# total reset of ball speed
func resetBallSpeed():
	speedIncrement = 1
	
# make ball powerupBall
func makePowerBall():
	powerBall = true
	
# take away powerBall powers
func removePowerBall():
	powerBall = false


func shakeTheCamera():
	# camera shake!
	if timer.get_time_left() > 0:
		camera.set_offset(Vector2(rand_range(-1.0, 1.0) * shakeAmount, rand_range(-1.0, 1.0) * shakeAmount))
	else:
		camera.set_offset(Vector2(0, 0))


func set_state(new_state):
	# first exit the current state
	state.exit()
	
	# now choose the next state
	if new_state == STATE_BATHUG:
		state = BatHugState.new(self)
	elif new_state == STATE_MOVING:
		state = MoveState.new(self)
	elif new_state == STATE_LEVELOVER:
		state = LevelOverState.new(self)
	elif new_state == STATE_BATMAGNET:
		state = BatMagnetState.new(self)
	elif new_state == STATE_MULTILAUNCH:
		state = MultiLaunchState.new(self)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  class Move State --------------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
class MoveState:
	var ball
		
	# init gets called when an object of this class gets created
	func _init(ball):
		self.ball = ball
		# choose a random launch angle
		randomize()
		var direction = range(-3,5)[randi()%range(-3,5).size()] 
		# send it skyward
		launch(Vector2(direction,ball.initialBallSpeed)) # directional force

	#  Initialize shot from another script after adding it to the scene
	func launch(directional_force):
		ball._movement = directional_force
		# play launch sound
		if globals.soundEnabled:
			ball.get_parent().get_node("SamplePlayer2D").play("launchBall02")

	# frame by frame update
	func update(delta):
		#  Simulate gravity
		ball._movement.y += delta * ball._gravity
		
		# do screen shake (triggered below if we colide)
		if ball.timer.is_active():
			ball.shakeTheCamera()

		#  Check if we have collided
		if(ball.is_colliding()):
			
			# check if we're colliding at high speed as we only want to shake camera when ball is fast
			if globals.ballState == "fast" or ball.powerBall == true:
				# shake the camera
				ball.timer.start()
				ball.shakeAllowed = true
			#  Get node that we are colliding with
			var entity = ball.get_collider()
			# if there is a ball
			if entity:
				# if this is a hit against the bat
				if entity.get_name() == "bat":
					# first check if we're in magnet bat powerup state
					var bat = ball.get_node("/root/gameLevel/bat")
					if bat.readState() == "magnet":
						# store the location the ball hit the bat, so the hug state knows how much to offset
						ball.batOffset = ball.get_pos()
						# change the ball state to be magnetic to the bat
						ball.set_state(STATE_BATMAGNET)
					else:
						# play a sound
						if globals.soundEnabled:
							ball.get_parent().get_node("SamplePlayer2D").play("ballHit01")
						# reflect ball angle depending on where we hit it with the bat
						findCollisionAreaOnBat("bat", delta)
						
			    #  Apply physics
				var remaining = ball.move(ball._movement*ball.speedIncrement)
				var normal = ball.get_collision_normal()
				remaining = normal.reflect(remaining)
	
			
				# reduce 1 from the number of hits remaining on the brick, so as we might DESTROY said brick!
				if entity.get_parent().is_in_group("bricks"):

					# reduce number of hits the brick has, as we just hit it.
					var brickNumHits = int((entity.get_parent().get("numOfHitsRequired") -1))
					entity.get_parent().numOfHitsRequired = brickNumHits

					# do we have powerBall
					if ball.powerBall:

						# If the brick still has some strength left in it
						if brickNumHits >= 1:
							# play a hit sound
							if globals.soundEnabled:
								ball.get_node("/root/gameLevel").get_node("SamplePlayer2D").play("brickHit0")

						# otherwise, the brick must be destroyed
						elif brickNumHits <= 0:

							# create a powerup as we break the brick
							if entity.get_parent().powerupName != "none":	# there must be a powerup if it doesn't equal "none"

								# create /instance the new powerup
								var powerupScene = load("res://fallingPowerup.tscn")
								var newpowerup = powerupScene.instance()
								# set the type of powerup
								newpowerup.setPowerupType(entity.get_parent().powerupName)
								# set powerup texture
								var textureString = "res://textures/"+entity.get_parent().powerupName+".png"
								var textureToUse = load(textureString)
								newpowerup.get_node("Sprite").set_texture(textureToUse)
								# set powerup Position to where ball is now
								newpowerup.set_pos(Vector2(ball.get_pos().x,ball.get_pos().y))
								# create the powerup
								ball.get_tree().get_root().add_child(newpowerup)
								# add it to a group
								newpowerup.add_to_group("powerups")
								# move it downward, so we might catch it!
								newpowerup.set_linear_velocity(Vector2(0,0))

							# then destroy the brick
							if entity.get_parent().has_method("destroyThisBrick"):

								if brickNumHits <= 0:
									entity.get_parent().destroyThisBrick()
									# check if there are no bricks left and if not, level over

									if ball.get_tree().get_nodes_in_group("bricks").size() <= 1:
										# change the ball state, we don't want it moving or showing anymore
										ball.set_state(STATE_LEVELOVER)
										# show the congrats scene
										ball.get_parent().get_node("levelFinished").showScene()
										ball.get_parent().get_node("levelFinished").updateLabels()
										# remove any leftover balls
										var ballList = ball.get_tree().get_nodes_in_group("balls")
										for i in ballList:
											i.queue_free()
					else:
						# create a powerup as we break the brick
						if entity.get_parent().powerupName != "none":	# there must be a powerup if it doesn't equal "none"

							if entity.get_parent().get("numOfHitsRequired") <= 0:

								# create /instance the new powerup
								var powerupScene = load("res://fallingPowerup.tscn")
								var newpowerup = powerupScene.instance()
								# set the type of powerup
								newpowerup.setPowerupType(entity.get_parent().powerupName)
								# set powerup texture
								var textureString = "res://textures/"+entity.get_parent().powerupName+".png"
								var textureToUse = load(textureString)
								newpowerup.get_node("Sprite").set_texture(textureToUse)
								# set powerup Position to where ball is now
								newpowerup.set_pos(Vector2(ball.get_pos().x,ball.get_pos().y))
								# create the powerup
								ball.get_tree().get_root().add_child(newpowerup)
								# add it to a group
								newpowerup.add_to_group("powerups")
								# move it downward, so we might catch it!
								newpowerup.set_linear_velocity(Vector2(0,0))

						# then destroy the brick
						if entity.get_parent().has_method("destroyThisBrick"):

							if brickNumHits <= 0:

								entity.get_parent().destroyThisBrick()
								# check if there are no bricks left and if not, level over
								if ball.get_tree().get_nodes_in_group("bricks").size() <= 1:

									# change the ball state, we don't want it moving or showing anymore
									ball.set_state(STATE_LEVELOVER)
									# show the congrats scene
									ball.get_parent().get_node("levelFinished").showScene()
									ball.get_parent().get_node("levelFinished").updateLabels()
									# remove any leftover balls
									var ballList = ball.get_tree().get_nodes_in_group("balls")
									for i in ballList:
										i.queue_free()
							else:
								# play the almost broken sound
								if globals.soundEnabled:
									ball.get_node("/root/gameLevel/SamplePlayer2D").play("stoneHit")
								# change sprite to a cracked version
								var textureToUse
								if entity.get_parent().get_node("TextureButton").get_normal_texture().get_path() == "res://textures/bricks/stone01.png":
									textureToUse = load("res://textures/bricks/stone01Cracked.png")
								elif entity.get_parent().get_node("TextureButton").get_normal_texture().get_path() == "res://textures/bricks/stone02.png":
									textureToUse = load("res://textures/bricks/stone02Cracked.png")
								elif entity.get_parent().get_node("TextureButton").get_normal_texture().get_path() == "res://textures/bricks/stone03.png":
									textureToUse = load("res://textures/bricks/stone03Cracked.png")
								entity.get_parent().get_node("TextureButton").set_normal_texture(textureToUse)
	
						#  Apply bounce physics, simply use normal.reflect x the bounce strength variable
						ball._movement = normal.reflect(ball._movement) * ball.bounce	



				# did we hit a wall?
				elif entity.get_parent().is_in_group("walls"):
					# so bad I know, but am storing the ball X and Y for dust ball creation and placement. Over it, just doing this to get it done.
					globals.ballX = ball.get_pos().x
					globals.ballY = ball.get_pos().y
					#  Apply bounce physics, simply use normal.reflect x the bounce strength variable
					# ball._movement.y+=.0005
					ball._movement = normal.reflect(Vector2(ball._movement.x, ball._movement.y)) * ball.bounce
					# play the wall hit sound
					if globals.soundEnabled:
						ball.get_parent().get_node("SamplePlayer2D").play("hitWall")
					# find out which wall so the dust plays correctly
					# top wall
					if ball.get_pos().y < 20:  
						globals.whichWallWasHit = "top"
						# emit_signal("hitWall", "top")
					if ball.get_pos().x < 20:  
						globals.whichWallWasHit = "left"
						# emit_signal("hitWall", "left")
					if ball.get_pos().x > 280:  
						globals.whichWallWasHit = "right"
						# emit_signal("hitWall", "right")
					# make some dust!
					ball.makeDust()
					
					
					
			
					
				# did we hit another ball?
				elif entity.is_in_group("balls"):
					#  Apply bounce physics, simply use normal.reflect x the bounce strength variable
					ball._movement = normal.reflect(ball._movement) * ball.bounce
					# play the wall hit sound
					if globals.soundEnabled:
						ball.get_parent().get_node("SamplePlayer2D").play("hitBall")
				
				elif entity.get_name() == "bat":
					#  Apply bounce physics, simply use normal.reflect x the bounce strength variable
					ball._movement = normal.reflect(ball._movement) * ball.bounce*1.2  #  add 20% as the gravity requires a bit more power to keep the ball playing well
	

		# check if we're on screen or not
		if !ball.get_node("VisibilityNotifier2D").is_on_screen():
			# play a ball leaving sound
			if globals.soundEnabled:
				ball.get_parent().get_node("SamplePlayer2D").play("ballOut")	
			ball.queue_free()			
			# now check if we need to remove a life of not (there may be many balls on screen after all)
			var ballsRemaining = ball.get_tree().get_nodes_in_group("balls").size()
			if ballsRemaining <= 1:
				globals.lives -= 1
				# now refresh the visual indicators
				ball.get_parent().drawLifeIndicators()
				# if we still have at least one life left, place a new ball on the bat
				if globals.lives >=1:
					ball.get_node("/root/gameLevel").prepareBall()
				# otherwise it's game over... let's display the finish stuff
				else:
					# disable ball
					ball.set_state(STATE_LEVELOVER)
					# show the game over scene
					ball.get_tree().change_scene("gameOver.tscn")

		#  Move
		ball.move(ball._movement*ball.speedIncrement)
	
	# finds where the ball/s hits the bat and deflects off at the correct angle based on the collission location
	func findCollisionAreaOnBat(bat, delta):
		var newMovement = Vector2(0,0) # used below to determine which direction we'll be pushing the ball
		# Where is the bat pos?
		var batLocString = str("/root/gameLevel/",bat)
		var batLoc = ball.get_node(batLocString).get_transform().get_origin()
		# Where is the ball pos?
		var ballLoc = ball.get_transform().get_origin()
		# what is the bat width?
		var batWidth = ball.get_node("/root/gameLevel/bat/Sprite").get_texture().get_width()
		# work out where the ball has hit the bat by subtracting the location of each (bat and ball) origins
		# hitLocation will have a negative or positive number, based on how many pixels from bat centre we are
		var hitLocation = ballLoc.x - batLoc.x	
		# The line below turns the +- pixel count into a normalised value.  So it's between -1 and +1 at each extreme of the bat, depending on where it hits
		# This gives me a specific number I can work with each time, regardless of bat size.  Nice!
		var normalisedhitLocationX = (hitLocation/(batWidth/2));
		# now multiply by the maximum bounce angle we want the ball to go off at when hitting edge of bat
		var bounceAngle = normalisedhitLocationX * MAXBOUNCEANGLE;
		# the new vector to pass to the move command
		newMovement = Vector2(bounceAngle*2, globals.ballSpeed)		
		# change the direction
		ball._movement = newMovement


	# it's good to be able to handle input from within the state... sometimes :-)
	func input(event):
		# once we have a click, touch or keypress, set ball in action, move out of this state, into moving state
		if (event.type == InputEvent.MOUSE_BUTTON):
			pass

	# so we know when it's the end of the state, and we can perform some actions before going to another state
	func exit():
		pass



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  class BatHugState -------------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
class BatHugState:
	var ball
	
	# init gets called when an object of this class gets created
	func _init(ball):
		self.ball = ball
		ball.get_node("AnimationPlayer").play("fadeIn")

	# frame by frame update
	func update(delta):
		var batPos = ball.get_tree().get_root().get_node("gameLevel/bat").get_pos()
		# Move ball to bat centre, we're hugging the bat after all
		ball.set_global_pos(Vector2(batPos.x,batPos.y-ball.ballDiameter))

	# it's good to be able to handle input from within the state... sometimes :-)
	func input(event):
		# once we have a click, touch or keypress, set ball in action, move out of this state, into moving state
		if (event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT and event.pressed):
			ball.set_state(STATE_MOVING)


	# so we know when it's the end of the state, and we can perform some actions before going to another state
	func exit():
		pass

		
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  class BatMagnetState -------------------------------------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
class BatMagnetState:
	var ball
	
	# init gets called when an object of this class gets created
	func _init(ball):
		self.ball = ball
		ball.get_node("AnimationPlayer").play("fadeIn")

	# frame by frame update
	func update(delta):
		var batPos = ball.get_tree().get_root().get_node("gameLevel/bat").get_pos()
		# Leave ball in the same X location that it hit the bat.  It's a magnet after all.
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
		#  This is where the proper offset should happen so magnet bat doesn't have the ball dead centre
		#  rather it should be where it hits the bat.  Must do this
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
		# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# 		var ballOffset = ball.batOffset.x - batPos.x
# 		print("bat offset  = ", str(ball.batOffset.x))
# 		print("ball offset = ", str(ball.batOffset.x))
# 		# track the bat, so we're always "stuck" to it
		ball.set_global_pos(Vector2(batPos.x,batPos.y-ball.ballDiameter))

	# it's good to be able to handle input from within the state... sometimes :-)
	func input(event):
		# once we have a click, touch or keypress, set ball in action, move out of this state, into moving state
		if (event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT and event.pressed):
			ball.set_state(STATE_MOVING)


	# so we know when it's the end of the state, and we can perform some actions before going to another state
	func exit():
		pass
				
		
		
		
		
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  class levelOverState - do nothing basically -----------------------------------------
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
class LevelOverState:
	var ball
	
	# init gets called when an object of this class gets created
	func _init(ball):
		self.ball = ball
		ball.get_node("AnimationPlayer").play("fadeOut")

	# frame by frame update
	func update(delta):
		pass

	# it's good to be able to handle input from within the state... sometimes :-)
	func input(event):
		pass

	# so we know when it's the end of the state, and we can perform some actions before going to another state
	func exit():
		pass
		
		
		
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  class multi Ball launch State
#  we want to start the ball near the existing ball and move it randomly
#  passing control then to the movestate so it can then behave like normal
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
class MultiLaunchState:
	var ball
		
	# init gets called when an object of this class gets created
	func _init(ball):
		self.ball = ball
		# choose a random launch angle
		randomize()
		var direction = range(-3,5)[randi()%range(-3,5).size()] 
		# send it skyward
		launch(Vector2(direction,ball.initialBallSpeed)) # directional force
# 		print("I want to change to moving state from multi ball state now")
		ball.set_state(STATE_MOVING)

	#  Initialize shot from another script after adding it to the scene
	func launch(directional_force):
		ball._movement = directional_force
		# play launch sound
		if globals.soundEnabled:
			ball.get_parent().get_node("SamplePlayer2D").play("launchBall02")


	# frame by frame update
	func update(delta):
		ball.move(ball._movement*ball.speedIncrement)
		ball.set_state(STATE_MOVING)
	

	# it's good to be able to handle input from within the state... sometimes :-)
	func input(event):
		# once we have a click, touch or keypress, set ball in action, move out of this state, into moving state
		if (event.type == InputEvent.MOUSE_BUTTON):
			pass

	# so we know when it's the end of the state, and we can perform some actions before going to another state
		pass
	func exit():
		pass
