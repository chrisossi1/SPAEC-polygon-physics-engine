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
