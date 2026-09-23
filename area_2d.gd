extends Area2D
class_name Area2D_

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_bodies = {}
var entered = []
var exited = []

func manual_check_bodies():
	entered = []
	exited = []
	var new_overlapping = {}
	
	# 1. Grab everything Godot successfully tracking this frame
	var overlapping = get_overlapping_bodies()
	for body in overlapping:
		new_overlapping[body] = true
		if not body in current_bodies:
			entered.append(body)
			
	# 2. Fix the gaps: Check bodies that were tracking but Godot momentarily dropped
	var space_state = get_world_2d().direct_space_state
	
	for body in current_bodies.keys():
		if not is_instance_valid(body):
			exited.append(body)
			continue
			
		if not body in new_overlapping:
			# If the body is missing from get_overlapping_bodies, run a real-time math query
			if _force_instant_collision_test(space_state, body):
				# The shapes still geometrically touch; retain tracking and ignore the false exit
				new_overlapping[body] = true
			else:
				# It has genuinely left the area
				exited.append(body)
				
	current_bodies = new_overlapping

## Uses DirectSpaceState2D to run a direct narrow-phase collision test on a specific body
func _force_instant_collision_test(space_state: PhysicsDirectSpaceState2D, body: PhysicsBody2D) -> bool:
	if not collision_shape or not collision_shape.shape:
		return false
		
	# Setup query parameters mirroring our Area2D configuration
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = global_transform
	query.collision_mask = collision_mask
	
	# Force-test against this specific body's RID to see if they overlap right now
	var results = space_state.intersect_shape(query)
	for result in results:
		if result.get("collider") == body:
			return true
			
	return false
