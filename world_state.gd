class_name WorldState

# ## Gameplay Interface Data
var playerHelmControl:HelmControl

# ## Game Data
# World State
var paused:bool
var frames:int
var time:float

# World entities
var objects:Array[GameObject] = []
var has_components:Array[GameObject] = []

var solidBodyManager:SolidBodyManager #Used to add new bodies to physicsState
var chunkMap:=ChunkMap.new()





func _init():
	time = 0.
	frames = 0



# ## OBJ UUID GEN

var uuid_index:int = -1
func get_uuid():
	uuid_index += 1
	return uuid_index
