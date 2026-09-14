extends CollisionPolygon2D
class_name CollisionPolygon2D_

var physicsShape:PhysicsShape

# Debug
var cell:CollisionShapeMap.Cell



@export var recalculate:bool = false:
	set(v):
		physicsShape.collisionMap._sync_index(physicsShape.object.geometry.shape, cell.index, physicsShape.body)
