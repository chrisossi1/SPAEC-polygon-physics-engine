extends Node2D




func generate(ws:WorldState, solidBodyManager:SolidBodyManager):

	var obj = GameObject.new()

	GameObject.initialize_object(obj, solidBodyManager)

	# Set geometry
	var x = Transform2D(PI/4,Vector2())
	var poly := PolyFuncs._generate_regular_polygon(4, 100)
	poly = x*poly

	var shape = ClipShape.new()
	shape.add_path(poly)

	obj.geometry.set_shape(shape)
	obj.physicsShape.update_collision_map(obj.geometry.shape)
