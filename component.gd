class_name Component

static func get_type()->String:return"None"

var IOs:Array[IO]= []
func add_io(io:IO):
	assert(not IOs.has(io))
	IOs.append(io)

func get_IOs():
	return IOs

var stores:Array[Store] = []
func add_store(s:Store):
	assert(not stores.has(s))
	stores.append(s)

func get_stores():
	return stores







func physics_process():pass
func tick():pass
func attach_to_object(o:GameObject):pass
func detach_from_object():pass








class Store:
	var type:IO.TYPE
	var connectedInput:IO
	var connectedOutput:IO

	func _init(t:IO.TYPE):
		type = t

	var contents:Dictionary



class IO:
	enum TYPE{DATA}
	enum DIRECTION{INPUT,OUTPUT}
	var type:TYPE
	var direction:DIRECTION
	func opposite_direction():
		return DIRECTION.OUTPUT if direction==DIRECTION.INPUT else DIRECTION.INPUT

	func _init(d:DIRECTION, t:TYPE):
		direction = d
		type = t

	var connection:IO

	static func can_connect_io(a:IO, b:IO) -> bool:
			if a.connection or b.connection:return false
			return a.type == b.type and a.direction != b.direction
	static func connect_io(a:IO, b:IO):
			assert(can_connect_io(a,b))
			a.connection = b
			b.connection = a


	var store:Store
	static func can_connect_store(io:IO, s:Store)->bool:
		if io.store:return false
		if io.direction == DIRECTION.INPUT and s.connectedInput:return false
		if io.direction == DIRECTION.OUTPUT and s.connectedOutput:return false
		return true
	static func connect_store(io:IO, s:Store):
		assert(can_connect_store(io,s))
		io.store = s
		if io.direction == DIRECTION.INPUT:
			s.connectedInput = io
		else:
			s.connectedOutput = io
