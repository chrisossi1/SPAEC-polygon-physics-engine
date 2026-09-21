extends Node2D

var _name = "Boolean"


var color = Color.RED

var poly_small:PackedVector2Array = PolyFuncs._generate_regular_polygon(32, 120)
var poly_large:PackedVector2Array = PolyFuncs._generate_regular_polygon(32, 120)
var poly:PackedVector2Array = poly_small

var shape2D:= ConvexPolygonShape2D.new()

@export var worldCommand:WorldCommand
@export var camera:Camera2D
var simManager:SimManager

func _draw():
	draw_colored_polygon(Transform2D(0,mouse_pos)*poly, color)










# #######		1. DETECT MOUSE EVENT

# Setting flags

var boolean_active:ACTIVE_TYPE = ACTIVE_TYPE.NONE
enum ACTIVE_TYPE {NONE, CLIP, EXTEND, INTERSECT}

func mouse_event(event:MouseHandler.MouseEvent):
	match event.type:
		event.PRESSED:
			boolean_active = ACTIVE_TYPE.EXTEND if event.button == MouseButton.MOUSE_BUTTON_LEFT else ACTIVE_TYPE.CLIP
			poly = poly_small if event.button != MouseButton.MOUSE_BUTTON_LEFT else poly_large
		event.RELEASED:
			boolean_active = ACTIVE_TYPE.NONE




# #### Processing loop

var prev_mouse_pos:Vector2 #Local to camera
var mouse_pos:Vector2 #local to cameran

var elapsed = 0.
var interval = 0.05
func _process(_delta):#_context_process(_delta):
	queue_redraw()
	elapsed += _delta
	if elapsed < interval: return
	elapsed = 0.

	prev_mouse_pos = mouse_pos
	mouse_pos = get_global_mouse_position() # In game coodrdinates
	visible = false
	if boolean_active != ACTIVE_TYPE.NONE:
		boolean_under_mouse(boolean_active)






func boolean_under_mouse(op):
	visible = true
	shape2D.points = get_interpolated_shape()
	await get_tree().physics_frame
	cut_shape(shape2D, op)


func get_interpolated_shape() -> PackedVector2Array:
	var delta = prev_mouse_pos - mouse_pos
	var points = Geometry2D.convex_hull( Transform2D(0.,delta) * poly + poly)
	return points



func cut_shape(shape:Shape2D, op:ACTIVE_TYPE):
	if not shape.points:
		return

	var global_mouse_transform = Transform2D(0., mouse_pos)
	var prev_mouse_transform = Transform2D(0., prev_mouse_pos)

	var overlap_query = PhysicsShapeQueryParameters2D.new()
	overlap_query.shape = shape
	overlap_query.transform = simManager.space.to_physEngine_transform(global_mouse_transform)

	var overlaps = get_world_2d().direct_space_state.intersect_shape(overlap_query)

	var objs = {}

	color = Color.RED
	for result in overlaps:
		var obj = GameObject.from_query_result(result)
#		if obj.state == obj.STATE.DESTROYED:continue
		objs[obj] = true

	for obj in objs.keys():
		color = Color.AQUA
		if not obj:continue
		obj = obj as GameObject

		var body = obj.physicsShape.body


		# ## CALCULATE BOOLEAN PER GEOMETRY
		var obj_transform = obj.physicsShape.get_global_transform()
		var est_prev_origin = obj_transform.origin - (body.linear_velocity * interval) #Todo: What about off-axis physicsShapes that are rotating about COM?
		var est_prev_rotation = obj_transform.get_rotation() - (body.angular_velocity * interval)
		var prev_obj_transform = Transform2D(est_prev_rotation, est_prev_origin)

		var current_local_xform = obj_transform.affine_inverse()*global_mouse_transform
		var prev_local_xform = prev_obj_transform.affine_inverse()*prev_mouse_transform

		var interpolated = Geometry2D.convex_hull(current_local_xform * poly + prev_local_xform * poly)

		var wc = WorldCommand.wc_boolean_object.new()
		wc.object = obj
		wc.shape = interpolated
		wc.op = wc.OP.CLIP if op == ACTIVE_TYPE.CLIP else wc.OP.EXTEND#EXTEND
		worldCommand.add_command(wc)
