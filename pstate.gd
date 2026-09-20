class_name PState
var transform:Transform2D
var linear_velocity:Vector2
var angular_velocity:float
func get_position()->Vector2:return transform.get_origin()
func get_rotation()->float:return transform.get_rotation()

func duplicate()->PState:
	return PState.new(transform, linear_velocity, angular_velocity)



func _init(t:Transform2D=Transform2D(),lv:Vector2=Vector2(),av:float=0.0):
	transform = t
	linear_velocity = lv
	angular_velocity = av


func project_transform(t: float) -> Transform2D:
	return Transform2D(get_rotation() + angular_velocity*t, get_position() + linear_velocity*t)


#PState + axis between transform origin and axis of rotation
class axis_PState:
	extends PState
	var axis:Vector2
	func _init(t:Transform2D=Transform2D(),lv:Vector2=Vector2(),av:float=0.0, o:=Vector2()):
		super(t,lv,av)
		axis = o

	func project_transform(time: float) -> Transform2D:
		var old_rotation := get_rotation()
		var new_rotation := old_rotation + angular_velocity * time

		var old_axis_world := axis.rotated(old_rotation)
		var new_axis_world := axis.rotated(new_rotation)

		# The rotation center moves linearly according to linear_velocity.
		var rotation_center := get_position() + old_axis_world
		rotation_center += linear_velocity * time

		# The object's origin remains offset from the rotation center by
		# the rotated axis.
		var new_position := rotation_center - new_axis_world

		return Transform2D(new_rotation, new_position)


func serialize():
	var dict = {
		"transform":transform,
		"linear_velocity":linear_velocity,
		"angular_velocity":angular_velocity
	}
	return dict

static func deserialize(dict:Dictionary) -> PState:
	var pstate = PState.new()
	pstate.transform = dict["transform"]
	pstate.linear_velocity = dict["linear_velocity"]
	pstate.angular_velocity = dict["angular_velocity"]
	return pstate
