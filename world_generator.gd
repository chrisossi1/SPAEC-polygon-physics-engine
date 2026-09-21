class_name WorldGenerator


static func generate() -> Array[GameObject]:

	var objs:Array[GameObject]

	for i in range(10000):
		var o = gen_asteroid()
		var xform = Transform2D(randf()*2*PI, randf()*250000.*Vector2.RIGHT.rotated(randf()*2*PI))
		o.saved_pstate = PState.new(xform,Vector2(),.01)
		objs.append(o)

	return objs





static func gen_player() -> GameObject:
	# Set geometry
	var x = Transform2D(PI/4,Vector2())
	var poly := PolyFuncs._generate_regular_polygon(4, 25)
	poly = x*poly
	var shape = ClipShape.new()
	shape.add_path(poly)

	var o = GameObject.new()
	o.name = "None"
	o.shape = shape
	o.saved_pstate = PState.new()

	var helm:=HelmControl.new()
	var thruster:=Thruster.new()
	Component.IO.connect_io(helm.dataOutput, thruster.dataInput)
	o.components = GameObject.Components.new(o)
	o.components.add(helm)
	o.components.add(thruster)

	return o



static func gen_asteroid() -> GameObject:
	var sides = 5+randi_range(0,1)*2
	var radius = randi_range(25,250)
	var poly = PolyFuncs._generate_regular_polygon(sides,radius)

	#poly = Transform2D(0,Vector2.RIGHT* 100) * poly # Test off-origin COM

	var shape = ClipShape.new()
	shape.add_path(poly)

	var o = GameObject.new()
	o.name = "Asteroid"
	o.shape = shape

	return o
