class_name Substance

var name: String = "UNKNOWN"
var description: String = ""
var type: String = ""
var dominant_form: String = ""
var forms:Dictionary = {} #FormType:Substance.Form
var properties:Array[Property] = []

func add_property(p:Property):
	assert(not p in properties)
	properties.append(p)



class Form:
	var substance: Substance
	var form_type: String = ""
	var display_name: String = ""
	var color_desc: String = ""
	var color: Color
	var overrides:Array[Property]
	var suppress:Array[Property.Type]
