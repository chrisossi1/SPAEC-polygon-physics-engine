extends Node2D
class_name SolidBodyManager

#Todo: Pooling

var solidBody = preload("res://solid_body.tscn")
func get_body(ws:WorldState) -> SolidBody:
	var body:SolidBody = solidBody.instantiate()
	add_child(body)

	#body.contact.connect
	body.pstate_update.connect(ws.events._on_pstate_updated)

	return body
