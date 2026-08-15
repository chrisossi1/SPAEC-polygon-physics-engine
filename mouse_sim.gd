# MouseClicker.gd
extends Node
class_name MouseClicker

# Optional: tweak if your project needs slightly different timings.
static var delay_seconds: float = 0.05

static func click_left_at(tree:SceneTree, screen_pos: Vector2, post_wait: bool = false) -> void:
	# Move mouse cursor to the target position.
	DisplayServer.warp_mouse(screen_pos)

	await tree.create_timer(delay_seconds).timeout

	# Press left mouse button.
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = screen_pos
	e.global_position = screen_pos
	Input.parse_input_event(e)

	# Hold briefly (or effectively immediate if brief_hold=false).
	await tree.create_timer(delay_seconds).timeout

	# Press left mouse button.
	e = InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = screen_pos
	e.global_position = screen_pos
	Input.parse_input_event(e)


	if post_wait:
		await tree.create_timer(delay_seconds).timeout
