extends Component
class_name Thruster

static func get_type()->String:return"Thruster" #TODO: Unique Type ID

var pshape:PhysicsShape #Physics shape onto which momentum is applied

var dataInput:=Component.IO.new(Component.IO.DIRECTION.INPUT, Component.IO.TYPE.DATA)
var dataStore:=Component.Store.new(Component.IO.TYPE.DATA)
func _init():
	add_io(dataInput)
	add_store(dataStore)
	
	Component.IO.connect_store(dataInput, dataStore)

	params = Parameters.new()
	params.acceleration = 1
	params.brakeAcceleration = 1
	params.max_impulse = 10000000
	params.max_speed = 10000

func attach_to_object(o:GameObject):
	pshape = o.physicsShape
func detach_from_object():
	pshape = null


func _get_control() -> Vector2:
	if dataStore.contents.values()[0] is Vector2:
		return dataStore.contents.values()[0]
	return Vector2()


# Data is expected to be thrust vector
func physics_process():#_delta):
	if not pshape:return
	if not dataStore.contents:return
	#pshape.body.apply_central_force(pshape.body.mass * 200*control)
	linear_2nd_state(params, self)


var params:Parameters

class Parameters:
	var max_speed:float
	var max_impulse:float
	var acceleration:float
	var brakeAcceleration:float






#TODO: All forces should go thru physicsShape
#2nd state linear control - control velocity
static func linear_2nd_state(params: Parameters, thruster: Thruster) -> void:
	var body := thruster.pshape.body
	var control := thruster._get_control()
	var velocity := body.linear_velocity
	var mass := thruster.pshape.get_mass()

	const INPUT_DEADZONE := 0.01
	const VELOCITY_DEADZONE := 0.5

	# Remove tiny input values caused by controllers or floating-point noise.
	if control.length_squared() < INPUT_DEADZONE * INPUT_DEADZONE:
		control = Vector2.ZERO

	# Snap insignificant residual velocity to zero.
	if control == Vector2.ZERO and velocity.length() < VELOCITY_DEADZONE:
		body.linear_velocity = Vector2.ZERO
		thruster.last_impulse = Vector2.ZERO
		thruster.last_acceleration = Vector2.ZERO
		thruster.last_speed = Vector2.ZERO
		return

	var target_velocity := control * params.max_speed
	var velocity_error := target_velocity - velocity

	var acceleration_gain := (
		params.brakeAcceleration
		if control == Vector2.ZERO
		else params.acceleration
	)

	# This is acceleration, not force.
	var desired_acceleration := velocity_error * acceleration_gain
	desired_acceleration = desired_acceleration.limit_length(
		params.max_impulse / mass
	)

	# F = ma
	var force := desired_acceleration * mass
	body.apply_central_force(force)

	thruster.last_impulse = force
	thruster.last_acceleration = desired_acceleration
	thruster.last_speed = velocity
















var homing_acceleration = 10.
#1st and 2nd state linear control - control velocity and position
static func linear_1st_2nd_state(params:Parameters, thruster:Thruster):
	var state := thruster.pshape.get_pstate()

	#Linear
	var velocity_error:Vector2 = thruster._get_control() * thruster.params.max_speed - state.linear_velocity

	var max_acceleration := thruster.params.max_impulse / thruster.pshape.body.mass
	var selected_acceleration = thruster.params.brakeAcceleration if thruster._get_control() == Vector2.ZERO else thruster.params.acceleration
	var acceleration_vector = selected_acceleration * velocity_error
	acceleration_vector = acceleration_vector.limit_length(max_acceleration)

	thruster.pshape.body.apply_force(acceleration_vector * thruster.pshape.body.mass)

	#var actual_acceleration = pbody.frameAccelerationPrev
	#var a_error = actual_acceleration - acceleration_vector
	#print(a_error)

	thruster.last_impulse = acceleration_vector * thruster.pshape.body.mass
	thruster.last_acceleration = acceleration_vector
	thruster.last_speed = state.linear_velocity

 



static func angular(thruster:Thruster):
	var body := thruster.pshape.body
	body.angular_damp = 5.

	var k_p := 200.0
	var k_d := 50.0

	var target_direction:Vector2 = thruster._get_control()
	if target_direction == Vector2.ZERO:
		return

	# Normalize target direction
	target_direction = target_direction.normalized()

	# Current facing direction
	var current_direction := Vector2.RIGHT.rotated(thruster.pshape.get_global_transform().get_rotation())

	# --- Compute signed angle error (ALWAYS the shortest path) ---
	var angle_to_target := current_direction.angle_to(target_direction)
	angle_to_target = wrapf(angle_to_target, -PI, PI)

	# --- PD controller ---
	var torque := angle_to_target * k_p - body.angular_velocity * k_d

	# Scale by inertia so torque behaves consistently across ships
	torque *= body.inertia

	# Optional: clamp torque
	
	var max_direct_torque := 10000.
	var radius := 1#thruster.pshape.get_global_center_of_mass().distance_to(thruster.pshape.body.get_global_center_of_mass())
	var max_linear_torque := radius * thruster.params.max_impulse
	var max_torque:float = max(max_direct_torque, max_linear_torque)

	if abs(torque) > max_torque:
		torque = clamp(torque, -max_torque, max_torque)

	# Apply torque
	body.apply_torque(torque)
































# Runtime

var last_speed:Vector2
var last_acceleration:Vector2
var last_impulse:Vector2


















# Bonus stuf

static func predict_linear_motion(
		initial_velocity: Vector2,
		thruster_control: Vector2,
		thruster_speed: float,
		thruster_acceleration: float,
		max_impulse: float,
		mass: float,
		length:=300,
		dt: float = 0.1
) -> Array:

	var position:=Vector2()
	var positions = [position]
	var velocity = initial_velocity
	for i in range(length):
		var error = thruster_control * thruster_speed - velocity
		var max_acceleration = max_impulse / mass
		var acceleration_vector = thruster_acceleration * error
		acceleration_vector = acceleration_vector.limit_length(max_acceleration)
	
		velocity += acceleration_vector * dt
		position += velocity * dt
		positions.append(position)

	return positions
