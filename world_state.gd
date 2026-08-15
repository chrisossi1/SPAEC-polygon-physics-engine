class_name WorldState

# ## Game Data
# World State
var paused:bool
var frames:int
var time:float

# World entities
var objects:Array[GameObject] = []








func _init():
	time = 0.
	frames = 0
