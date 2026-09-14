extends Node2D




var ws:WorldState


func _ready() -> void:
	
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect($Mousefollow.mouse_event)
	
	# Initialize worldState
	ws = WorldState.new()

	$WorldGenerator.generate(ws, $SolidBodyManager)




func _process(_delta):
	var wc:WorldCommand = $WorldCommand
	wc.resolve_commands(ws, _delta)
