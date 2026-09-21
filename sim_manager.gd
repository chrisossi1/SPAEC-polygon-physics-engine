class_name SimManager

# 1. keep track of active chunks and unbuilt chunks

var  player:GameObject
var player_chunk:Vector2i = Vector2i(9999999999,999999999)

var built := {}

var space:PhysicsSpace

var sim_radius = 1 #Length squared in chunks
var sim_offset:Vector2 # physEngine origin offset
var center_chunk:Vector2i

func check_player_chunk(ws:WorldState, notifs:Array[Presentation.notif]):
	assert(player.state != GameObject.STATE.UNREGISTERED)
	var pos:Vector2
	if player.state == GameObject.STATE.REGISTERED:
		pos = player.saved_pstate.get_position()
	else:
		pos = player.physicsShape.get_pstate().get_position()

	var chunk = ws.chunkMap.pos_to_chunk(pos)

	# Floating origin update
	#TODO: The Space reference should live exclusively in rigidBody2D. They are the source of truth about physics state so conversion should be done at earliest possible level

	if (chunk-center_chunk).length_squared() > sim_radius:
		center_chunk = chunk
		var offset = -ws.chunkMap.get_center(chunk)
		update_build_offset(ws, offset)


	if chunk != player_chunk:
		player_chunk = chunk
		for n in [chunk]+ws.chunkMap.get_neighbors(chunk):
			if n in built:continue
			build_chunk(ws, n, notifs)




func build_chunk(ws:WorldState, chunk:Vector2i, notifs:Array[Presentation.notif]):
	if built.has(chunk):return

	var objs = ws.chunkMap.get_objects(chunk)

	for o in objs:
		var body = ws.solidBodyManager.get_body()
		body.space = space
		GameObject.build_object(o, body)
		notifs.append(Presentation.notif_object_created.new(o))

	built[chunk] = true



'''
# Build chunk with OFFSET!
# The All built shapes remember the offset it is given
func update_space(ws:WorldState, new_space:PhysicsSpace):
	space = new_space
	for chunk in built.keys():
		for obj in ws.chunkMap.get_objects(chunk):
			assert(obj.state == GameObject.STATE.BUILT)
			obj.physicsShape.space = new_space
'''



func update_build_offset(ws:WorldState, offset:Vector2):
	var offset_xform = Transform2D(0.,offset + sim_offset)
	var new_space = PhysicsSpace.new(-offset - sim_offset)

	for chunk in built.keys():
		for obj in ws.chunkMap.get_objects(chunk):
			obj = obj as GameObject
			assert(obj.state == GameObject.STATE.BUILT)
			var new_pstate = obj.physicsShape.body.get_pstate()
			new_pstate.transform = space.to_game_transform(new_pstate.transform) # Game coordinaes of body
			new_pstate.transform = offset_xform * new_pstate.transform # offset by specified amount
			obj.physicsShape.body.set_pstate(new_pstate) # writing new pstate with offset
			# So the physEngine position is now equal to the game position plus the offset
	
	space = new_space
	await ws.solidBodyManager.get_tree().physics_frame
	
	# TODO: Track this in a better way
	for chunk in built.keys():
		for obj in ws.chunkMap.get_objects(chunk):
			obj = obj as GameObject
			obj.physicsShape.body.space = new_space


'''
For every object...
get its game position
offset it by the specified offset
set the PE position to the specified offset
adjust physicsSpace to keep game position unchanged


'''
