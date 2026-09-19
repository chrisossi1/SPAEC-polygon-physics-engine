extends Node2D


@onready var wc:WorldCommand = $WorldCommand
@onready var pres:Presentation = $Presentation

var ws:WorldState


func _ready() -> void:
	
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect($Mousefollow.mouse_event)
	
	# Initialize worldState
	ws = WorldState.new()
	ws.solidBodyManager = $SolidBodyManager
	ws.events.wc = wc
	$KeyEventRouter.worldState = ws

	var command = WorldCommand.wc_generate_world.new()
	wc.add_command(command)



func _process(_delta):
	wc.resolve_commands(ws, _delta)
	pres.resolve_notifications()

func _physics_process(delta: float) -> void:
	wc.add_command(WorldCommand.wc_physics_frame.new())
