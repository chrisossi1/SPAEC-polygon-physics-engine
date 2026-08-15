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
		match op:
			OP.CLIP:
				WorldCommand.clip_object(worldState, object, shape, notifs)
			OP.EXTEND:
				WorldCommand.extend_object(worldState, object, shape, notifs)
			OP.INTERSECT:
				WorldCommand.intersect_object(worldState, object, shape, notifs)



static func clip_object(ws:WorldState, obj:GameObject, interpolated:PackedVector2Array, notifs:Array[Presentation.notif]):
		# ## CALCULATE CLIP RESULT
		var new_shapes:Array[ShapeWithHoles]
		var updates:Array[GeometryData.GeometryUpdate] = []

		var update = GeometryData.GeometryUpdate_SWH.new() #TODO: This update deletes all shapes and adds all new shapes. I should have clip_polygon to return a list of changed shapes only.

		for swh in obj.geometry.shapes:
			# Calculate clip results
			var clipped = ShapeWithHoles.clip_polygon(swh, interpolated)

			var filtered:Array[ShapeWithHoles]= []
			for clipped_ms in clipped:
				if PolyFuncs._calc_area(clipped_ms.solid) < 100:continue #Filter out very small pieces
				filtered.append(clipped_ms)

			new_shapes.append_array(filtered)

			# Log geometry update events to update GameObject shapeData
			update.removed.append(swh)
			update.added.append_array(filtered)

		updates.append(update)



		# Log clipping operation event to update ChunkShape
		update = GeometryData.GeometryUpdate_ChunkShape.new()
		update.points = interpolated
		updates.append(update)


		# ANTI INVALID GEOMETRY SHIELD
		# NO INVALID GEOMETRY BEYOND THIS POINT

		# ## ASSIGN CLIP RESULT
		if new_shapes.size() == 0:
			#destroy_object(ws, obj, notifs)
			return

		#obj.multiShapes = new_shapes # Assigns new shape ideneity
		var success = obj.geometry.update_geometry(updates) # Calculates updated chunkShape and ShapeWithHoles data
		#if not success:
		#	GameObject.renormalize_COM(obj)

		# Manually recalculate all derived data
		obj.physicsShape.update_collision_map(obj.geometry.chunkShape) # Updates collision shape 



		#obj.physicsShape.update_inertiaData(WorldState.calculate_inertiaData(obj, ws.gameData))

		#var notif = Presentation.notif_object_geometry_updated.new(obj)
		#notifs.append(notif)



static func intersect_object(ws:WorldState, obj:GameObject, interpolated:PackedVector2Array, notifs:Array[Presentation.notif]):
		# ## CALCULATE CLIP RESULT
		var new_shapes:Array[ShapeWithHoles]
		var updates:Array[GeometryData.GeometryUpdate] = []

		var update = GeometryData.GeometryUpdate_SWH.new() #TODO: This update deletes all shapes and adds all new shapes. I should have clip_polygon to return a list of changed shapes only.

		for swh in obj.geometry.shapes:
			# Calculate clip results
			var clipped = ShapeWithHoles.intersect_polygon(swh, interpolated)

			var filtered:Array[ShapeWithHoles]= []
			for clipped_ms in clipped:
				if PolyFuncs._calc_area(clipped_ms.solid) < 100:continue #Filter out very small pieces
				filtered.append(clipped_ms)

			new_shapes.append_array(filtered)

			# Log geometry update events to update GameObject shapeData
			update.removed.append(swh)
			update.added.append_array(filtered)

		updates.append(update)


		'''
		# Log clipping operation event to update ChunkShape
		update = GeometryData.GeometryUpdate_ChunkShape.new()
		update.points = interpolated
		updates.append(update)
		'''

		# ANTI INVALID GEOMETRY SHIELD
		# NO INVALID GEOMETRY BEYOND THIS POINT

		# ## ASSIGN CLIP RESULT
		if new_shapes.size() == 0:
			#destroy_object(ws, obj, notifs)
			return

		#obj.multiShapes = new_shapes # Assigns new shape ideneity
		var success = obj.geometry.update_geometry(updates) # Calculates updated chunkShape and ShapeWithHoles data
		#if not success:
		#	GameObject.renormalize_COM(obj)

		# Manually recalculate all derived data
		obj.physicsShape.update_collision_map(obj.geometry.chunkShape) # Updates collision shape 



		#obj.physicsShape.update_inertiaData(WorldState.calculate_inertiaData(obj, ws.gameData))

		#var notif = Presentation.notif_object_geometry_updated.new(obj)
		#notifs.append(notif)








static func extend_object(ws:WorldState, obj:GameObject, interpolated:PackedVector2Array, notifs:Array[Presentation.notif]):
		# ## CALCULATE EXTEND RESULT
		var new_shapes:Array[ShapeWithHoles]
		var updates:Array[GeometryData.GeometryUpdate] = []

		var update = GeometryData.GeometryUpdate_SWH.new() #TODO: This update deletes all shapes and adds all new shapes. I should have clip_polygon to return a list of changed shapes only.

		for swh in obj.geometry.shapes:
			# Calculate clip results
			var merged = ShapeWithHoles.merge_polygon(swh, interpolated)

			var filtered:Array[ShapeWithHoles]= []
			for merged_swh in merged:
				if PolyFuncs._calc_area(merged_swh.solid) < 100:continue #Filter out very small pieces
				filtered.append(merged_swh)

			new_shapes.append_array(filtered)

			# Log geometry update events to update GameObject shapeData
			update.removed.append(swh)
			update.added.append_array(filtered)

		updates.append(update)



		# Log clipping operation event to update ChunkShape

		update = GeometryData.GeometryUpdate_ChunkShape.new()
		update.points = interpolated
		update.operation = update.OP.EXTEND
		updates.append(update)


		# ANTI INVALID GEOMETRY SHIELD
		# NO INVALID GEOMETRY BEYOND THIS POINT

		# ## ASSIGN CLIP RESULT
		if new_shapes.size() == 0:
			#destroy_object(ws, obj, notifs)
			return

		#obj.multiShapes = new_shapes # Assigns new shape ideneity
		var success = obj.geometry.update_geometry(updates) # Calculates updated chunkShape and ShapeWithHoles data
		#if not success:
		#	GameObject.renormalize_COM(obj)

		# Manually recalculate all derived data
		obj.physicsShape.update_collision_map(obj.geometry.chunkShape) # Updates collision shape 



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
