class_name WorldGenerator


static func generate(ws:WorldState) -> Array[GameObject]:

	var objs:Array[GameObject]

	# Set geometry
	var x = Transform2D(PI/4,Vector2())
	var poly := PolyFuncs._generate_regular_polygon(4, 100)
	poly = x*poly	

	var shape = ClipShape.new()
	shape.add_path(poly)

	var ps = PState.new()

	#initData: PState, geometry, composition, name
	var initData = GameObject.InitData.new("None", shape, ps)

	var obj := GameObject.initialize_object(ws, initData)
	objs.append(obj)

	obj.geometry.set_shape(shape)


	GameObject.build_object(ws, obj)
	
	
	var helm:=HelmControl.new()
	var thruster:=Thruster.new()
	Component.IO.connect_io(helm.dataOutput, thruster.dataInput)
	obj.components.add(helm)
	helm.attach_to_object(obj)
	obj.components.add(thruster)
	thruster.attach_to_object(obj)
	

	return objs
