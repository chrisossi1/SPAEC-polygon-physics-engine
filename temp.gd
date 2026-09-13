extends Node2D




var ws:WorldState

var obj := GameObject.new()


func _ready() -> void:
	
	var mh = $MouseHandler as MouseHandler
	mh.mouse_event.connect(mouse_event)
	mh.mouse_event.connect($Mousefollow.mouse_event)
	
	# Initialize worldState
	ws = WorldState.new()

	initialize_object(obj)
	
	# Set geometry
	var x = Transform2D(PI/4,Vector2())
	
	var poly := PolyFuncs._generate_regular_polygon(4, 100)

	poly = x*poly

	var shape = ClipShape.new()
	shape.add_path(poly)

	obj.geometry.set_shape(shape)
	obj.physicsShape.update_collision_map(obj.geometry.shape)




func initialize_object(o:GameObject):
	# Initialize object
	# Initialize geometry
	o.geometry = GeometryData.new()

	# Initialize physicsShape
	o.physicsShape = PhysicsShape.new()
	o.physicsShape.object = o
	o.physicsShape.body = $SolidBodyManager.get_body()
	o.physicsShape.collisionMap = CollisionShapeMap.new()
	


func _process(_delta):
	queue_redraw()
	var wc:WorldCommand = $WorldCommand
	wc.resolve_commands(ws, _delta)


func mouse_event(event:MouseHandler.MouseEvent):
	if event.type == event.HOVER_CHANGED:
		pass




func _draw():
	obj.geometry.draw(self)
	queue_redraw()
