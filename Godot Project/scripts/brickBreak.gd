#script: brickBreak.gd
extends Node2D

func _ready():
	# Called every time the node is added to the scene.

	#preload the texture
	var particleTexture = load(globals.particleTexture)

	#change the texture
	get_node("Particles2D").set_texture(particleTexture)

		
	#start the particles
	get_node("Particles2D").set_emitting(true)
	
	set_fixed_process(true)


func _fixed_process(delta):
	
	#check if the particles have stopped, if so, destroy ourselves to keep the scene clean
	if !get_node("Particles2D").is_emitting():
		queue_free()
		