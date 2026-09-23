extends Node2D


@onready var wc:WorldCommand = $WorldCommand
@onready var pres:Presentation = $Presentation
var ws:WorldState
var gameData:GameData

#One per player
var simManagers:Array[SimManager] = []
var built = {} # Vector2i : simManager pairs

func _ready() -> void:
	$KeyEventRouter.worldState = ws
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect($Mousefollow.mouse_event)

	#	gameData = GameData.new()

	ws = WorldState.new()
	ws.solidBodyManager = $SolidBodyManager
	ws.solidBodyManager.wc = wc

	var objs = WorldGenerator.generate()
	for o in objs:
		GameObject.register_object(ws,o)



	# Simulate 2 players connecting
	simManagers.append(SimManager.new(ws))
	#simManagers.append(SimManager.new(ws))

	$Mousefollow.simManager = simManagers[0] # Players Control input

	#var sim_radius = simManagers[0].sim_radius * ws.chunkMap.CHUNK_RADIUS
	#simManagers[0].sim_offset = Vector2.UP*1000000 # A sim offset is chosen to keep the two physicsWorlds separate

	for mgr in simManagers:
		mgr.space = PhysicsSpace.new()
		# Initial build offset update. What does this do physics engine wise?
		mgr._update_build_offset(ws, Vector2())


	# Assign player objects
	simManagers[0].player = spawn_player()
	#simManagers[1].player = ws.objects[-2]
	

#TODO: Alternate mode where all are flying around an open un-simboxed area?



func spawn_player():
	var o = WorldGenerator.gen_player()
	GameObject.register_object(ws, o)
	ws.playerHelmControl = o.components.get_component(HelmControl.get_type())

	pres.add_notification(Presentation.notif_player_updated.new(o))

	return o






func _draw():
	for mgr in simManagers:
		mgr.draw(self, ws.chunkMap)




func _process(_delta):
	wc.resolve_commands(ws, _delta)
	pres.resolve_notifications()


func _physics_process(delta: float) -> void:
	var notifs:Array[Presentation.notif] = []
	for mgr in simManagers:
		var to_update = mgr.check_player_chunk(ws,notifs)
		if to_update:
			mgr._check_and_rebase_origin(ws)

			for chunk in to_update[0]:
				mgr.build_chunk(ws, chunk, notifs)
			for chunk in to_update[1]:
				mgr.unbuild_chunk(chunk)

		mgr.sync_loading_area_position()
		if Engine.get_physics_frames() % 64 == 0:
			mgr.check_loading_area(ws, notifs)

	# TODO: Each notif is local to a certain sim?

	for n in notifs:pres.add_notification(n)

	wc.add_command(WorldCommand.wc_physics_frame.new())
	if Engine.get_physics_frames() % 128 == 0:
		wc.add_command(WorldCommand.wc_pstate_refresh_all.new())
