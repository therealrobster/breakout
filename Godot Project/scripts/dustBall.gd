extends Node2D

func _ready():
	placeAgainstWall(globals.whichWallWasHit)
	playDust();  #when this node is created, play the animation already
	
func placeAgainstWall(whichWall):
	#initial texture.  Just to be safe and all
	var spriteTexture = load("res://textures/dustBalls01.png")
	#apply the texture to the sprite
	get_node("Sprite").set_texture(spriteTexture)
	
	#depending on top or bottom wall, place ourselves in the correct spot			
	if whichWall == "top":
		self.set_pos(Vector2(globals.ballX,25)) #position the sprite 
		get_node("Sprite").set_flip_v(true)	#flip the sprite
	elif whichWall == "left":
		self.set_pos(Vector2(10,globals.ballY)) #position the sprite 
		self.set_rot(deg2rad(270))	#rotate it to look correct against wall
	elif whichWall == "right":
		self.set_pos(Vector2(290,globals.ballY)) #position the sprite 
		self.set_rot(deg2rad(90))	#rotate it to look correct against wall
	
func playDust():
	get_node("AnimationPlayer").play("dustPlay")
	
#when the animation is finished, destroy the node, save RAM etc
func _on_AnimationPlayer_finished():
	self.queue_free()