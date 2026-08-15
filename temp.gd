extends Node2D




var ws:WorldState

var obj := GameObject.new()


func _ready() -> void:
	
	Performance.add_custom_monitor("Index Range", func():return ChunkShape.index_range)
	Performance.add_custom_monitor("Shape Merges", func():return ChunkShape.shape_merges)
	Performance.add_custom_monitor("% Merges per Index", func():return 100*ChunkShape.shape_merges/ChunkShape.index_range if ChunkShape.index_range else 0)
	Performance.add_custom_monitor("Max CPI", func():return obj.geometry.chunkShape.get_max_chunks_per_index())

	
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

	#for i in range(30):
	#	poly.append(Vector2(randi_range(-100,100),randi_range(-100,100)))
	var swhs:Array[ShapeWithHoles]= [ShapeWithHoles.new(poly)]
	#[ShapeWithHoles.new(x*PolyFuncs._generate_regular_polygon(4, 100), [PolyFuncs._generate_regular_polygon(4,10)])]
	obj.geometry.set_shapes(swhs)

	# Update collision shapes
	obj.physicsShape.update_collision_map(obj.geometry.chunkShape)




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
