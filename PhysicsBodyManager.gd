extends Node2D
class_name SolidBodyManager

'''
Manages and pools SolidBodies
Organizes by available CollisionPolygon2Ds to minimize node overhead
TODO: OR just use physics server directly! really I think this should be policy becaues it minimizes 

'''

#Todo: Pooling

var solidBody = preload("res://solid_body.tscn")
func get_body() -> SolidBody:
	var body:SolidBody = solidBody.instantiate()
	add_child(body)

	#body.contact.connect
	body.pstate_update.connect(_on_pstate_updated) # TODO: This should definitely live in SBM not WS..
	body.active = true
	return body



func remove_body(body:SolidBody):
	body.active = false
	body.queue_free() #Todo: Pool
	#body.freeze = true



var wc:WorldCommand #Connection to WC to send events

func _on_pstate_updated(body:SolidBody):
	var command = WorldCommand.event_body_pstate_updated.new()
	command.body = body
	wc.add_command(command)
