class_name Property
var propertyType:Type
var level:int
func _init(p:Type, l:int=1):
	# If propertyType is binary, enforce level == 1? Level == 0? (is this relevant for calculation)
	if p.binary:
		l = 1
	propertyType = p
	level = l




class Type:
	var name:StringName = "UNKNOWN PROPERTY"
	var opposite:StringName = ""
	var binary:bool
