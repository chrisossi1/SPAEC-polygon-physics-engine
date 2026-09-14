extends Node
class_name WorldCommand

class wc:pass

class wc_clip_object:
	extends wc
	var object:GameObject
	var shape:PackedVector2Array
	var op:OP = OP.CLIP
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

		#var notif = Presentation.notif_object_geometry_updated.new(obj)
		#notifs.append(notif)




















#@export var pres:Presentation


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

#	for n in notifs:
#		pres.add_notification(n)
	

func pre_resolve(worldState:WorldState, delta:float): #TODO: Make this a world command that goes at the start of the queue every fraem?
	#worldState.collisions_handled.clear()
	worldState.time += delta
	worldState.frames += 1



class Presentation:
	class notif:
		pass
