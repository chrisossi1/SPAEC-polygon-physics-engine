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

func init_pstate(ps:PState):
	transform = ps.transform
	linear_velocity = ps.linear_velocity
	angular_velocity = ps.angular_velocity
	pstate_update.emit(self)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	if pending_pstate:
		state.transform = pending_pstate.transform
		state.linear_velocity = pending_pstate.linear_velocity
		state.angular_velocity = pending_pstate.angular_velocity
		pstate_update.emit(self)
		pending_pstate = null

func _physics_process(delta: float) -> void:
	#if Engine.get_physics_frames() % 100 > 0:return
	if previous_velocity != linear_velocity or previous_angular_velocity != angular_velocity:
		pstate_update.emit(self)


	previous_velocity = linear_velocity
	previous_angular_velocity = angular_velocity



var physicsShapes:Array[PhysicsShape]
func get_physicssShapes():
	return physicsShapes


func get_pstate():
	var ps = PState.new()
	ps.transform = global_transform
	if not sleeping:
		ps.angular_velocity = angular_velocity
		ps.linear_velocity = linear_velocity
	
	return ps



func _ready():
	sleeping_state_changed.connect(on_sleeping_state_changed)
	
func on_sleeping_state_changed():
	pstate_update.emit(self)
