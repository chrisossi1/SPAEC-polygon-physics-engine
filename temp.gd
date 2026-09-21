extends Node2D


@onready var wc:WorldCommand = $WorldCommand
@onready var pres:Presentation = $Presentation
var ws:WorldState
var gameData:GameData
var simManager:=SimManager.new()

func _ready() -> void:
	$Mousefollow.simManager = simManager
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect($Mousefollow.mouse_event)
	$KeyEventRouter.worldState = ws

	gameData = GameData.new()
	
	simManager.space = PhysicsSpace.new()

	ws = WorldState.new()
	ws.solidBodyManager = $SolidBodyManager
	ws.solidBodyManager.wc = wc


	var objs = WorldGenerator.generate()
	for o in objs:
		GameObject.register_object(ws,o)

	simManager.sim_offset = Vector2.UP*100000
	simManager.update_build_offset(ws, Vector2())

	spawn_player()
	




func spawn_player():
	var o = WorldGenerator.gen_player()
	GameObject.register_object(ws, o)
	ws.playerHelmControl = o.components.get_component(HelmControl.get_type())
	simManager.player = o

	pres.add_notification(Presentation.notif_player_updated.new(o))






func _draw():
	for i in range(30):
		draw_circle(simManager.sim_offset,i*i*10,Color.BLUE, false)






func _process(_delta):
	wc.resolve_commands(ws, _delta)
	pres.resolve_notifications()


func _physics_process(delta: float) -> void:
	var notifs:Array[Presentation.notif] = []
	simManager.check_player_chunk(ws,notifs)
	for n in notifs:pres.add_notification(n)

	wc.add_command(WorldCommand.wc_physics_frame.new())
	if Engine.get_physics_frames() % 128 == 0:
		wc.add_command(WorldCommand.wc_pstate_refresh_all.new())
