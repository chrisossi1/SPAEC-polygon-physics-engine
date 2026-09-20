class_name WorldGenerator


static func generate(ws:WorldState) -> Array[GameObject]:

	var objs:Array[GameObject]
	var player = gen_player(ws)
	objs.append(player)

	var helm:=HelmControl.new()
	var thruster:=Thruster.new()
	Component.IO.connect_io(helm.dataOutput, thruster.dataInput)
	player.components.add(helm)
	helm.attach_to_object(player)
	player.components.add(thruster)
	thruster.attach_to_object(player)

	for i in range(100):
		objs.append(gen_asteroid(ws))

	return objs





static func gen_player(ws:WorldState) -> GameObject:
	# Set geometry
	var x = Transform2D(PI/4,Vector2())
	var poly := PolyFuncs._generate_regular_polygon(4, 25)
	poly = x*poly
	var shape = ClipShape.new()
	shape.add_path(poly)

	var initData = GameObject.InitData.new("None", shape, PState.new())

	var obj := GameObject.initialize_object(ws, initData)
	GameObject.build_object(ws, obj)

	return obj


static func gen_asteroid(ws:WorldState) -> GameObject:
	var sides = 5+randi_range(0,1)*2
	var radius = randi_range(25,250)
	var poly = PolyFuncs._generate_regular_polygon(sides,radius)

	#poly = Transform2D(0,Vector2.RIGHT* 100) * poly # Test off-origin COM

	var shape = ClipShape.new()
	shape.add_path(poly)

	var xform = Transform2D(randf()*2*PI, randf()*25000.*Vector2.RIGHT.rotated(randf()*2*PI))
	var ps = PState.new(xform,Vector2(),.01)

	var initData = GameObject.InitData.new("Asteroid", shape, ps)
	var obj := GameObject.initialize_object(ws, initData)
	GameObject.build_object(ws, obj)


	return obj
