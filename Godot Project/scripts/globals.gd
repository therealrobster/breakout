#script: globals
extends Node

var ballX				= 0
var ballY				= 0
var whichWallWasHit		= "top"
var powerupTimeout		= 10 	#how many seconds does the powerup last
var lives				= 3		#how many lives / bats do we get?
var currentLevel		= 0		#which level are we playing or are about to play
var scores				= {"score" : 0, "highScore" : 0}	#score and highScore will live here
var ballSpeed			= 4.5
var ballSpeedReset		= 4.5
var ballState			= "normal"	#normal, fast, slow, plough, multi
var particleTexture		= "res://textures/bricks/blue01.png"
var gameComplete		= false
var totalLevels			= 34 #BAD BAD hack to hard code max levels rather than checking filenames.  BAD Rob!
var paused				= false
var soundEnabled		= true	#sound is on when the game starts

func _ready():
	highScoreLoad()	#game is starting, load any high scores we may have

func highScoreLoad():
	var dict = {}
	var file = File.new()
	var err = file.open("user://highScore.txt", file.READ)
	#if the file exists....
	if err == OK:
		var text = file.get_as_text()
		dict.parse_json(text)
		file.close()
		scores["highScore"] = dict["highScore"]
	else:
		pass
		#do nothing.  If there is no file, then the highscore can stay at '0'



func highScoreSave():
	var highScoreText
	var scoresToWrite
	# Open a file
	var file = File.new()	
	var fileToUse = str("user://highScore.txt")
	if file.open(fileToUse, File.WRITE) != 0:
		print("Error opening file")
		return	
	else:
		scoresToWrite = { 
			highScore = scores["highScore"]
		}
		file.store_line(scoresToWrite.to_json())
		file.close()