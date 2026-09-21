class_name ChunkMap

var map = {}

static var CHUNK_RADIUS = 8000


'''Save object data to the data map'''
# Assuming saved_pstate is already set
func save_object(obj:GameObject):
	var chunk = pos_to_chunk(obj.saved_pstate.get_position())

	#Write data
	if chunk in map.keys():
		map[chunk].append(obj)
	else:
		map[chunk] = [obj]


func get_objects(chunk:Vector2i):
	if not map.has(chunk):return[]
	return map[chunk]





func _draw(c:CanvasItem):
	for i in range(-30,30):
		c.draw_line(Vector2(i*CHUNK_RADIUS,-100000),Vector2(i*CHUNK_RADIUS,100000), Color.WHITE)
		c.draw_line(Vector2(-100000, i*CHUNK_RADIUS),Vector2(100000, i*CHUNK_RADIUS), Color.WHITE)
		
	




# ### Chunk Coordinate Funcs
static func pos_to_chunk(p: Vector2) -> Vector2i:
	return Vector2i(round(.5*float(p.x)/CHUNK_RADIUS), round(.5*float(p.y)/CHUNK_RADIUS))

static func get_center(coords: Vector2i) -> Vector2:
	# Multiply back to world space and offset by half the chunk size
	# TODO ????? ?? ?? ???? 
	return Vector2(coords) * CHUNK_RADIUS * 2


static func get_neighbors(coords:Vector2i) -> Array[Vector2i]:
	var neighborhood:Array[Vector2i] = []
	for offs in neighborhood_offsets:
		neighborhood.append(coords+offs)
	return neighborhood



















static var neighborhood_offsets:Array[Vector2i] = []
static var nhood_size = 1
static var init_hack=0:
	get():
		init_nhood_offsets()
		return 0
static var init_hack_1=init_hack
static func init_nhood_offsets():
	for i in range(-nhood_size,nhood_size+1):
		for j in range(-nhood_size,nhood_size+1):
			neighborhood_offsets.append(Vector2i(i,j))
