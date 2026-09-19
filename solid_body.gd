extends RigidBody2D
class_name SolidBody

var previous_velocity:Vector2
var previous_angular_velocity:float

signal contact
signal pstate_update

var pending_pstate:PState = null

func set_pstate(ps:PState):
	assert(not pending_pstate)
	pending_pstate = ps

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	if pending_pstate:
		state.transform = pending_pstate.transform
		state.linear_velocity = pending_pstate.linear_velocity
		state.angular_velocity = pending_pstate.angular_velocity
		pstate_update.emit(self)
		pending_pstate = null
	
	if previous_velocity != state.linear_velocity or previous_angular_velocity != state.angular_velocity:
		pstate_update.emit(self)
	
	
	
	
	
	
	
	previous_velocity = state.linear_velocity
	previous_angular_velocity = state.angular_velocity



var physicsShapes:Array[PhysicsShape]
func get_physicssShapes():
	return physicsShapes


func get_pstate():
	var ps = PState.new()
	ps.transform = global_transform
	ps.angular_velocity = angular_velocity
	ps.linear_velocity = linear_velocity
	
	return ps
