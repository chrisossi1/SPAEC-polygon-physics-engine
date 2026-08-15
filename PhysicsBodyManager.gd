extends Node2D
class_name SolidBodyManager

#Todo: Pooling

var solidBody = preload("res://solid_body.tscn")
func get_body() -> SolidBody:
	var body := solidBody.instantiate()
	add_child(body)
	return body
