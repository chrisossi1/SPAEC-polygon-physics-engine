extends RigidBody2D
class_name SolidBody

var space:PhysicsSpace

var previous_velocity:Vector2
var previous_angular_velocity:float

signal contact
signal pstate_update

var pending_pstate:PState = null

func _ready():
	sleeping_state_changed.connect(on_sleeping_state_changed)
func on_sleeping_state_changed():
	pstate_update.emit(self)

func set_pstate(ps:PState):
	assert(not pending_pstate)
	pending_pstate = ps
	sleeping = false

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


# In physEngine coordinates
func get_axis_pstate():
	var ps = PState.axis_PState.new(global_transform)
	ps.axis = center_of_mass
	if not sleeping:
		ps.angular_velocity = angular_velocity
		ps.linear_velocity = linear_velocity
	
	return ps


# In physEngine coordinates
func get_pstate():
	var ps = PState.new(global_transform)
	if not sleeping:
		ps.angular_velocity = angular_velocity
		ps.linear_velocity = linear_velocity
	
	return ps






# inertiaData argument is supplied relative to body origin. Inertia needs to be shifted to COM
# TODO: Collapse the 2 parallel axis shifts into one (One performed by physicsShape to shift from Geometry Origin to Body Origin, one performed by PhysicsBody to move from Body Origin to COM reference)
# TODO: Queue physics updates and : Sum mass + COM (normalize COM after pass)
# local transform: of physicsShape
func set_inertiaData(data:InertiaData):
	#var com_length = data.center_of_mass.length_squared()
	#if com_length > 500000:
	#	var relative = Transform2D(0.,data.center_of_mass)
	#	data.center_of_mass = Vector2()
	#	transform = relative * transform
	#	for shape in get_physicsShapes():
	#		shape.set_transform(relative.affine_inverse() * shape.transform)
	assert(data.valid()) #TODO: Add prod only invalid data fallback to recalculate from start
	assert(center_of_mass_mode == CENTER_OF_MASS_MODE_CUSTOM)
	mass = data.mass
	center_of_mass = data.center_of_mass
	inertia = data.moment
	pstate_update.emit(self) # Because of moved COM
	queue_redraw()



func _draw():
	draw_circle(center_of_mass, 12, Color.BLUE)
	draw_circle(Vector2(), 12, Color.CYAN, false)
	
	for pshape in physicsShapes:
		draw_circle(pshape.transform * pshape.inertiaData.center_of_mass, 12, Color.RED)
		draw_circle(pshape.transform.get_origin(), 12, Color.ORANGE, false)
