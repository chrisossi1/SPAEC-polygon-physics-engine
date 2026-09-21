class_name PhysicsSpace
# Transforms between physEngine coordinates to Game coordinates

var _physEngine_to_game: Transform2D

func _init(offset: Vector2 = Vector2.ZERO) -> void:
	_physEngine_to_game = Transform2D(0.0,offset)


func to_game_transform(physEngine_transform: Transform2D) -> Transform2D:
	return _physEngine_to_game * physEngine_transform


func to_physEngine_transform(game_transform: Transform2D) -> Transform2D:
	return _physEngine_to_game.affine_inverse() * game_transform


func to_game_position(physEngine_position: Vector2) -> Vector2:
	return _physEngine_to_game * physEngine_position


func to_physEngine_position(game_position: Vector2) -> Vector2:
	return _physEngine_to_game.affine_inverse() * game_position
