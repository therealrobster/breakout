#script: fallingPowerup
extends RigidBody2D

var typeOfPowerup = "none"	#will be assigned by ball script

onready var batSoundPlayer = get_node("/root/gameLevel/bat/StreamPlayer")

const STATE_MOVING		= 0
const STATE_BATHUG		= 1
const STATE_LEVELOVER	= 2
const STATE_BATMAGNET	= 3
const STATE_MULTILAUNCH = 4

func _ready():
	set_fixed_process(true)
	
	#play a sound when we're created
	if globals.soundEnabled:
		get_node("/root/gameLevel/SamplePlayer2D").play("powerup02")


#used in case we need to do a few things on the ball after changing powerups
func ballCleanup():
	globals.ballState = "normal"
	for ball in get_tree().get_nodes_in_group("balls"):
		ball.changeBallSpeed(1)
		ball.resetBallSpeed()
		ball.removePowerBall()

func _fixed_process(delta):
	#check if we're on screen or not
	if !self.get_node("VisibilityNotifier2D").is_on_screen():
		killPowerup()
		#play a sound
		if globals.soundEnabled:
			get_node("/root/gameLevel/SamplePlayer2D").play("powerupMissed")
		
		
#when the powerup is created, this function is called from bat.gd to set the powerup type
func setPowerupType(type):
	typeOfPowerup = type

func killPowerup():
	self.queue_free()
	
func _on_fallingPowerup_body_enter( body ):
	pass

func checkHighScore():
	var highScoreText
	if (globals.scores["score"] > globals.scores["highScore"]):
		#update he dictionary
		globals.scores["highScore"] = globals.scores["score"]
		#update the high score label
		highScoreText = "high score : " + str(globals.scores["highScore"])
		get_node("/root/gameLevel/HUD/LabelHighScore").set_text(highScoreText)
		#write the file
		globals.highScoreSave()


func _on_fallingPowerup_body_enter_shape( body_id, body, body_shape, local_shape ):

	var bat = get_node("/root/gameLevel/bat")
	
	if body.get_parent().get_name() == "bat":
		#clean up the bat, make sure none of its powerups are in action
		get_node("/root/gameLevel/HUD/powerupTimer")._on_Timer_timeout()	
		
		#play a cool sound
		if globals.soundEnabled:
			get_node("/root/gameLevel/SamplePlayer2D").play("powerup01")
			
		#set the score dictionary
		globals.scores["score"] += 10
		#write the high score if we're at the high score
		checkHighScore()
		#set the score label
		var scoreText = "Score: "+str(globals.scores["score"])
		get_node("/root/gameLevel/HUD/LabelScore").set_text(scoreText)

		if typeOfPowerup == "powerupFastBall":
			#if we're not fast
			if globals.ballState != "fast":
				#make it fast
				globals.ballState = "fast"
				#do so for all of them
				for ball in get_tree().get_nodes_in_group("balls"):
					ball.changeBallSpeed(1.5)
			else:
				pass


		elif typeOfPowerup == "powerupExtraLife":
			globals.lives += 1
			get_node("/root/gameLevel").drawLifeIndicators()
			#play the sound
			#get_node("/root/gameLevel/SamplePlayer2D").play("ExtraLife")


		elif typeOfPowerup == "powerupSlowBall":
			#if we're not slow
			if globals.ballState != "slow":
				#make it slow
				globals.ballState = "slow"
				#do so for all of them
				
				for ball in get_tree().get_nodes_in_group("balls"):
					ball.changeBallSpeed(.5)
			else:
				pass
			


		elif typeOfPowerup == "powerupBunchOBalls":
			#the ball scene we will instance
			var scene = load("res://ball.tscn")
			
			for ball in get_tree().get_nodes_in_group("balls"):
				#get the position of each of the balls
				var ballPos = Vector2(ball.get_pos().x+10,ball.get_pos().y-10)
				var newBall = scene.instance()
				newBall.set_global_pos(ballPos)
				get_node("/root/gameLevel").add_child(newBall)
				newBall.add_to_group("balls")
				#random direction
				newBall.set_state(STATE_MULTILAUNCH)


		elif typeOfPowerup == "powerupBatGuns":
			#set ball to normal
			ballCleanup()

			#resize the bat to normal
			if bat.batState == "large":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("largeToNormal")
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsUp")
			elif bat.batState == "small":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("smallToNormal")
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsUp")
			elif bat.batState == "shooting":
				#do nothing
				pass
			else:
				#show the guns
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsUp")
					
			#set the current state
			bat.setState("shooting")
			#let the bat know we're shooting.  I SHOULD be using signals, but ...
			get_node("/root/gameLevel/bat").startTimer()



		elif typeOfPowerup == "powerupMagnetBat":
			#set ball to normal
			ballCleanup()
			
			#the sticking of the ball to the bat will be handled in bat.gd based on the state being "magnet" here
			#we will however, to reduce issues elsewhere, make the bat normal sized
			if bat.batState == "large":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("largeToNormal")
			elif bat.batState == "small":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("smallToNormal")
			elif bat.batState == "shooting":
				#hide the guns
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsDown")
			elif bat.batState != "magnet":
				#play the magnet animation			
				get_node("/root/gameLevel/bat/AnimationPlayer3").play("showMagnet")
				#play the magnet sound
				if globals.soundEnabled:
					batSoundPlayer.play()
				

			#set the state
			bat.setState("magnet")



		elif typeOfPowerup == "powerupPowerBall":
			#set ball to normal
			ballCleanup()
			
			for ball in get_tree().get_nodes_in_group("balls"):
				ball.makePowerBall()



		elif typeOfPowerup == "powerupLargeBat":
			#set ball to normal
			ballCleanup()

			if bat.batState == "normal":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToLarge")
			elif bat.batState == "small":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("smallToLarge")
			elif bat.batState == "large":
				#do nothing, we're already large
				pass
			elif bat.batState == "shooting":
				#hide the guns and make bat large
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsDown")
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToLarge")
			else:
				#for all others, assume we're normal size and go large
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToLarge")
				pass
			bat.setState("large")


		elif typeOfPowerup == "powerupSmallBat":
			#set ball to normal
			ballCleanup()
			
			if bat.batState == "normal":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToSmall")
			elif bat.batState == "large":
				get_node("/root/gameLevel/bat/AnimationPlayer").play("largeToSmall")	
			elif bat.batState == "small":
				#do nothing, we're already small
				pass
			elif bat.batState == "shooting":
				#hide the guns and make bat small
				get_node("/root/gameLevel/bat/AnimationPlayer2").play("gunsDown")
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToSmall")
			else:
				#for all others, assume we're normal size and go small
				get_node("/root/gameLevel/bat/AnimationPlayer").play("normalToSmall")
				pass
			bat.setState("small")


		#Start the timer to count down so the powerup only last X length
		var powerTimer = get_node("/root/gameLevel/HUD/powerupTimer/Timer")
		powerTimer.start()
		#now destroy this powerup
		killPowerup()