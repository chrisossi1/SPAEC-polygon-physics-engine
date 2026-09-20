extends Node2D

@onready var wc:WorldCommand = $WorldCommand
@onready var pres:Presentation = $Presentation
var ws:WorldState
var gameData:GameData


func _ready() -> void:
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect($Mousefollow.mouse_event)
	
	gameData = GameData.new()
	
	# Initialize worldState and connect everything
	ws = WorldState.new()
	ws.solidBodyManager = $SolidBodyManager
	ws.events.wc = wc
	$KeyEventRouter.worldState = ws




	#Generate world
	var command = WorldCommand.wc_generate_world.new()
	wc.add_command(command)






func _process(_delta):
	wc.resolve_commands(ws, _delta)
	pres.resolve_notifications()


func _physics_process(delta: float) -> void:
	wc.add_command(WorldCommand.wc_physics_frame.new())
	if Engine.get_physics_frames() % 128 == 0:
		wc.add_command(WorldCommand.wc_pstate_refresh_all.new())
