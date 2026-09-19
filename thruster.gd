extends Component
class_name Thruster

static func get_type()->String:return"Thruster" #TODO: Unique Type ID


var dataInput:=Component.IO.new(Component.IO.DIRECTION.INPUT, Component.IO.TYPE.DATA)
var dataStore:=Component.Store.new(Component.IO.TYPE.DATA)
func _init():
	add_io(dataInput)
	add_store(dataStore)
	
	Component.IO.connect_store(dataInput, dataStore)


#func _component_proceess(): # Material processs runs once per tick





# Data is expected to be thrust vector
func physics_process():#_delta):
	if not pshape:return
	if not dataStore.contents:return
	var control := Vector2()
	if dataStore.contents.values()[0] is Vector2:
		control = dataStore.contents.values()[0]
	pshape.body.apply_central_force(pshape.body.mass * 200*control)



var pshape:PhysicsShape


func attach_to_object(o:GameObject):
	pshape = o.physicsShape

func detach_from_object():
	pshape = null
