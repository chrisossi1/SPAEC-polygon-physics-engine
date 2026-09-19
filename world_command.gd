extends Node
class_name WorldCommand

class wc:pass

class wc_generate_world:
	extends wc
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		var objs = WorldGenerator.generate(worldState)
		WorldCommand.player_updated(worldState, objs[0], notifs)
		for o in objs:
			notifs.append(Presentation.notif_object_created.new(o))


static func player_updated(worldState:WorldState, o:GameObject, notifs:Array[Presentation.notif]):
		worldState.playerHelmControl = o.components.get_component(HelmControl.get_type())
		notifs.append(Presentation.notif_player_updated.new(o))






class wc_boolean_object:
	extends wc
	var object:GameObject
	var shape:PackedVector2Array
	var op:OP
	enum OP {CLIP, EXTEND, INTERSECT}
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		#assert(object.state != object.STATE.DESTROYED)

		var incoming_clipShape := ClipShape.new()
		incoming_clipShape.add_path(shape)

		var result:ClipShape
		
		match op:
			OP.CLIP:
				result = object.geometry.shape.clip(incoming_clipShape)
			OP.EXTEND:
				incoming_clipShape.add_paths(object.geometry.shape.to_packed_paths())
				result = incoming_clipShape.merge_contents() #TODO: gdext clipper2 MERGE
				#result = object.geometry.shape.merge(incoming_clipShape)
			OP.INTERSECT:
				result = object.geometry.shape.intersect(incoming_clipShape)

		var final = ClipShape.new()
		for path in result.to_packed_paths():
			if PolyFuncs._calc_area(path) < 100:continue #Filter out very small pieces
			final.add_path(path)

		if final.size() == 0:
			#destroy_object(ws, obj, notifs)
			return

		object.geometry.set_shape(final)
		#if not success:
		#	GameObject.renormalize_COM(obj)

		# Manually recalculate all derived data
		object.physicsShape.update_collision_map(object.geometry.shape, shape) # Updates collision shape 

		#obj.physicsShape.update_inertiaData(WorldState.calculate_inertiaData(obj, ws.gameData))

		var notif = Presentation.notif_object_geometry_updated.new(object)
		notif.shape = object.geometry.shape
		notifs.append(notif)


class wc_direction_control_input:
	extends wc
	var control = {}
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		if not worldState.playerHelmControl:return
		worldState.playerHelmControl.dataStore.contents = control





# Data travels every frame
class wc_physics_frame:
	extends wc
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		for o in worldState.objects:
			WorldCommand.tick_data_io(o)
		for o in worldState.objects:
			WorldCommand.tick_component(o)
			WorldCommand.tick_component_physics(o)



static func tick_data_io(o:GameObject):
	for c in o.components.get_components():
		c = c as Component
		for io in c.IOs:
			io = io as Component.IO
			if not io.type == Component.IO.TYPE.DATA:continue
			if io.direction == Component.IO.DIRECTION.INPUT:continue
			if not io.store:continue
			if not io.connection:continue
			io.connection.store.contents = io.store.contents


# Machinery frames
static func tick_component(o:GameObject):
	for c in o.components.get_components():
		c = c as Component
		c.tick()

# Physics Frame
static func tick_component_physics(o:GameObject):
	for c in o.components.get_components():
		c = c as Component
		c.physics_process()







class wc_pause:
	extends wc
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		return
	func _init(a):pass


class wc_pstate_refresh_all:
	extends wc
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		for obj in worldState.objects:
			notifs.append(Presentation.notif_pstate_update.new(obj.physicsShape.body))



class event_contact:
	extends wc
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		pass

class event_body_pstate_updated:
	extends wc
	var body:SolidBody
	func resolve(worldState:WorldState, notifs:Array[Presentation.notif]):
		notifs.append(Presentation.notif_pstate_update.new(body))














@export var pres:Presentation


signal queue_completed

var commands = []
var physics_commands = []

func add_command(c:wc):
	commands.append(c)

func resolve_commands(worldState:WorldState, delta:float):
	pre_resolve(worldState, delta)
	var notifs:Array[Presentation.notif] = []
	for c in commands:
		c.resolve(worldState, notifs)
	commands.clear()
	queue_completed.emit()

	for n in notifs:
		pres.add_notification(n)


func pre_resolve(worldState:WorldState, delta:float): #TODO: Make this a world command that goes at the start of the queue every fraem?
	#worldState.collisions_handled.clear()
	worldState.time += delta
	worldState.frames += 1






# TODO: HOW DOES PRESENTATION WORK FOR MULTIPLAYER?
# EACH CLIENT HAS ITS OWN PRESENTATION
# PLAYER ACTIONS SEND WORLDCOMMANDS TO SERVER
# PHYSICS EVENTS IN SERVER + PLAYER INPUTS CREATE PRESENTATION UPDATE NOTIFS
# THESE NOTIFS GO BACK TO THE CLIENT PRESENTATION LAYERS
# BUT DIFFERENT PLAYERS ARE VIEWING DIFFERENT PARTS OF THE MAP. HOW DO I KNOW WHICH NOTIFS TO SEND TO WHICH CLIENTS?
# I GUESS EACH HAS THEIR OWN 'AREA' I CAN TRACK OBJECTS OF
# EACH NOTIF IS ASSOCIATED WITH A SINGLE 'AREA'?
