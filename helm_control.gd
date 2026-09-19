extends Component
class_name HelmControl

static func get_type()->String:return"Helm Control" #TODO: Unique Type ID


func set_control(d:Dictionary):
	dataStore.contents = d

var dataStore:=Component.Store.new(Component.IO.TYPE.DATA)
var dataOutput:=Component.IO.new(Component.IO.DIRECTION.OUTPUT, Component.IO.TYPE.DATA)

func _init():
	Component.IO.connect_store(dataOutput, dataStore)
	add_io(dataOutput)
	add_store(dataStore)
