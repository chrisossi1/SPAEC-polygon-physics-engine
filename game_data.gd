class_name GameData

var magnitudes = ["Super", "Mega", "Giga", "Tera"]

var property_types:Dictionary # {name : Property.Type}
var substances:Dictionary # {name : Substance}
var substances_by_form: Dictionary = {} # { "Solid": [SolidSubstance, ...], "Liquid": [...], ... }

func _init():
	load_substance_data() 
	build_substance_form_index()




'''String -> Ptype object'''
func get_ptype(n:StringName)->Property.Type:
	assert(n in property_types.keys()) #PROPERTY TYPE n NOT FOUND
	assert(property_types[n] is Property.Type)
	return property_types[n]

'''String name -> Substance object'''
func get_substance(n:StringName)->Substance:
	assert(n in substances.keys())
	assert(substances[n] is Substance)
	return substances[n]

func substance_has_form(substance: Substance, form_type: StringName) -> bool:
	for f in substance.forms:
		if f.form_type == form_type:
			return true
	return false

func get_substances_with_form(form_type: StringName) -> Array:#[Substance]:
	return substances_by_form.get(form_type, []).duplicate()




#Post processing extra categorizations
func build_substance_form_index():
	substances_by_form.clear()

	for s in substances.values():
		for f in s.forms.values():
			if not substances_by_form.has(f.form_type):
				substances_by_form[f.form_type] = []
			if not s in substances_by_form[f.form_type]:
				substances_by_form[f.form_type].append(s)





























func load_substance_data():
	var data = parse_csv("res://data/SPAEC_data - PropertyTypes.csv")
	property_types = load_property_types_from_csv(data)
	data = parse_csv("res://data/SPAEC_data - Substances.csv")
	substances = load_substances_from_csv(data)
	data = parse_csv("res://data/SPAEC_data - Properties.csv")
	load_properties_from_csv(data, substances, property_types)
	data = parse_csv("res://data/SPAEC_data - Forms.csv")
	load_forms_from_csv(data, substances)











static func load_property_types_from_csv(data:Array) -> Dictionary:
	var types := {}

	var header = true
	for cols in data:
		if header: #Skip header
			header = false
			continue

		cols = cols as Array[String]

		# Ensure we have at least Name column
		if cols.size() < 1:
			continue

		#Extract column string data
		var name:String = cols[0].strip_edges()
		var boolean_val:String = cols[1].strip_edges() if cols.size() > 1 else ""
		var opposite:String = cols[2].strip_edges() if cols.size() > 2 else ""

		if name == "":
			continue

		# convert data types
		var is_binary := (boolean_val == "1")

		var ptype := Property.Type.new()
		ptype.name = name
		ptype.binary = is_binary
		ptype.opposite = opposite
		types[name] = ptype

	return types




static func load_properties_from_csv(
	data:Array,
	substances: Dictionary,
	property_types: Dictionary
) -> void:
	var header := true

	for cols in data:
		if header:
			header = false
			continue

		if cols.size() < 3:
			continue

		var material_name:String = cols[0].strip_edges()
		var prop_name:String = cols[1].strip_edges()
		var level := int(cols[2])

		if not substances.has(material_name):
			push_warning("Property references unknown substance: " + material_name)
			continue

		if not property_types.has(prop_name):
			push_warning("Unknown property type: " + prop_name)
			continue

		var p := Property.new(property_types[prop_name], level)
		substances[material_name].add_property(p)



static func load_substances_from_csv(data:Array) -> Dictionary:
	var substances := {}

	var header := true
	for cols in data:
		if header:
			header = false
			continue

		if cols.size() < 4:
			continue

		var s := Substance.new()
		s.name = cols[0].strip_edges()
		s.description = cols[1].strip_edges()
		s.dominant_form = cols[2].strip_edges() #TODO: Enums for forms?
		s.type = cols[3].strip_edges()

		substances[s.name] = s

	return substances




static func load_forms_from_csv(
	data: Array,
	substances: Dictionary
) -> void:
	var header := true

	for cols in data:
		if header:
			header = false
			continue

		if cols.size() < 5:
			continue

		var material_name:String= cols[0].strip_edges()
		if not substances.has(material_name):
			push_warning("Form references unknown substance: " + material_name)
			continue

		var f := Substance.Form.new()
		f.substance = substances[material_name]
		f.form_type = cols[1].strip_edges()
		f.display_name = cols[2].strip_edges()
		f.color_desc = cols[3].strip_edges()
		f.color = Color.html(cols[4].strip_edges())

		f.overrides = []
		f.suppress = []

		var key = f.form_type
		assert(not f.substance.forms.has(key))
		f.substance.forms[key] = f

















static func parse_csv(
	file_path: String,
	start_column: int = 0,
	end_column: int = -1
) -> Array:
	var rows: Array = []

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		assert(false, "Failed to open CSV: " + file_path)
		return rows

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line == "" or line.begins_with("#"):
			continue

		var columns := line.split(",") # change to "," if needed

		if end_column == -1:
			rows.append(columns.slice(start_column))
		else:
			rows.append(columns.slice(start_column, end_column + 1))

	file.close()
	return rows
