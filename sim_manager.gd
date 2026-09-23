class_name SimManager

# 1. keep track of active chunks and unbuilt chunks


var  player:GameObject
var player_chunk:Vector2i = Vector2i(9999999999,999999999)

var space:PhysicsSpace

var built_chunks := {} #TODO: AVOID BUILDING CHUNK BUILT BY ANOTHER SIMMANAGER (Handled higher up)
var bodies := {} # Built bodies owned by the handler

var sim_radius = 36 #Length squared in chunks
var sim_offset:Vector2 # physEngine origin offset
var center_chunk:Vector2i

var current_nhood:Array[Vector2i]


var log:=[]
func add_log(s:String):
	log.append( str(Engine.get_process_frames()) +": "+ s )








func get_player_position() -> Vector2:
	assert(player.state != GameObject.STATE.UNREGISTERED)
	if player.state == GameObject.STATE.REGISTERED:
		return player.saved_pstate.get_position()
	return player.physicsShape.get_pstate().get_position()





# check_player_chunk_neighborhood
func check_player_chunk(ws:WorldState, notifs:Array[Presentation.notif]) -> Array:
	var pos = get_player_position()
	var chunk = ws.chunkMap.pos_to_chunk(pos)

	# Load new chunk
	if chunk == player_chunk:return []

	add_log("Player chunk changed from " + str(player_chunk) + " to " + str(chunk))

	player_chunk = chunk

	var new_nhood:= ws.chunkMap.get_neighbors(chunk)
	var to_load = []
	var to_unload = []
	for n in new_nhood:
		if n in current_nhood: continue
		to_load.append(n)
	for n in current_nhood:
		if n in new_nhood: continue
		to_unload.append(n)

	current_nhood = new_nhood

	assert(to_load or to_unload)

	return [to_load, to_unload]



# Dynamic object unbuilding is handled by loading area
# only Static objects are loaded/unloaded here?
# Built dynamic objects are no longer in the chunks data struct 
func unbuild_chunk(n:Vector2i):
	add_log("Unbuilding static chunk " + str(n))
	assert(n in built_chunks.keys())
	built_chunks.erase(n) #Is built_chunks redundant with current_nhood? 


func build_chunk(ws:WorldState, chunk:Vector2i, notifs:Array[Presentation.notif]):
	if built_chunks.has(chunk):return

	var objs = ws.chunkMap.get_objects(chunk)

	add_log("Building static + dynamic chunk " + str(chunk) + ", building " + str(objs.size()) + "objects")

	ws.chunkMap.clear_chunk(chunk)

	for o in objs: #TODO: This can't load assemblies!
		o.add_log("Parent chunk"+str(chunk)+"being built")
		var body = ws.solidBodyManager.get_body()
		body.add_log("Getting new body from sbm")
		bodies[body] = true
		body.space = space
		GameObject.build_object(o, body)
		notifs.append(Presentation.notif_object_created.new(o))

	built_chunks[chunk] = true









func _check_and_rebase_origin(ws:WorldState):
	# Floating origin update
	# Todo: Not length squared check, but sim boundary rect check

	if (player_chunk-center_chunk).length_squared() > sim_radius:
		center_chunk = player_chunk
		var offset = -ws.chunkMap.get_center(player_chunk)
		_update_build_offset(ws, offset)



func _update_build_offset(ws:WorldState, offset:Vector2):
	var offset_xform = Transform2D(0.,offset + sim_offset)
	var new_space = PhysicsSpace.new(-offset - sim_offset)
	add_log("Rebasing origin. Moving " + str(bodies.size()) + " bodies")
	for body in bodies:
		for ps in body.get_physicsShapes():assert(ps._owner.state == GameObject.STATE.BUILT)
		body.add_log("Rebasing origin!")
		var new_pstate = body.get_pstate()
		new_pstate.transform = space.to_game_transform(new_pstate.transform) # Game coordinaes of body
		new_pstate.transform = offset_xform * new_pstate.transform # offset by specified amount
		body.set_pstate(new_pstate) # writing new pstate with offset
		# So the physEngine position is now equal to the game position plus the offset
		#body.space = new_space

	# Update simManager space
	space = new_space
	await ws.solidBodyManager.get_tree().physics_frame
	for body in bodies:
		body.space = new_space
	


'''
For every object...
get its game position
offset it by the specified offset
set the PE position to the specified offset
adjust physicsSpace to keep game position unchanged


'''





func draw(c:CanvasItem, cm:ChunkMap):
	var rect = cm.chunk_rect(center_chunk)
	c.draw_rect(rect,Color.GREEN,false)
	
	var sim_radius_px = Vector2.ONE * ( 5 + (2*sqrt(sim_radius)) ) * cm.CHUNK_RADIUS
	var sim_rect = Rect2(cm.get_center(center_chunk) - sim_radius_px, 2*sim_radius_px) #???
	c.draw_rect(sim_rect,Color.CYAN,false)











func _init(ws):pass

func sync_loading_area_position():pass

func check_loading_area(ws:WorldState, notifs:Array[Presentation.notif]):
	
	var BUILD_AREA_RADIUS = ws.chunkMap.CHUNK_RADIUS*4
	var center_pos_physEng = space.to_physEngine_position(ws.chunkMap.get_center(player_chunk))
	for body in bodies.keys():
		body = body as SolidBody
		if body.global_position.distance_squared_to(center_pos_physEng) > BUILD_AREA_RADIUS*BUILD_AREA_RADIUS:
			unbuild_body(ws, body, notifs)

	

# LOADING AREA



func unbuild_body(ws:WorldState, body:SolidBody, notifs:Array[Presentation.notif]):

	for ps in body.physicsShapes:
		if ps == player.physicsShape:return
	assert(bodies.has(body))

	for ps in body.physicsShapes:
		var o = ps._owner
		o.add_log("Unbuilding parent body")
		assert(o.state == GameObject.STATE.BUILT)
		o.state = GameObject.STATE.REGISTERED

		o.saved_pstate = o.physicsShape.get_pstate()
		var ch = ws.chunkMap.save_object(o)

		if o.components:
			for component in o.components.get_components():
				component = component as Component
				component.detach_from_object()
	
		o.physicsShape = null
		o.add_log("Saved to chunk "+str(ch))
	
		var notif = Presentation.notif_object_destroyed.new(o)
		notifs.append(notif)

	bodies.erase(body)
	ws.solidBodyManager.remove_body(body)


'''

var area_preload = preload("res://area_2d.tscn")

var area:Area2D_
func check_loading_area(ws:WorldState, notifs:Array[Presentation.notif]):
	assert(area)
	area.manual_check_bodies()
	#for body in area.exited:
	#	body.add_log("UNBUILDING BODY! U got lefted")
	#	unbuild_body(ws, body, notifs)

func sync_loading_area_position():
	area.position = player.physicsShape.body.global_transform.get_origin()


func _init(ws:WorldState):
	init_loading_area(ws)

func init_loading_area(ws):
	area = area_preload.instantiate()
	ws.solidBodyManager.add_child(area)
	var rect = RectangleShape2D.new()
	rect.size = Vector2.ONE*ws.chunkMap.CHUNK_RADIUS*8
	area.collisionShape.shape = rect

'''
'''
Dynamic object Unloading Strategies

Position Based
Position + AABB based
Position + Diameter based
Area2D square based (Signal or get_overlapping_bodies)
Area2D boundaries based
PhysicsServer2D based



'''
