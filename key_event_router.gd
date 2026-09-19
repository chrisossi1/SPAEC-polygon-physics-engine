extends Node
class_name KeyEventRouter


@export var presentation:Presentation
var worldState:WorldState #read only
@export var worldCommand:WorldCommand



var key_actions = {
	"fullscreen":toggle_fullscreen,
	"zoom in":func():presentation.camera.zoom *= 1.1*Vector2.ONE,
	"zoom out":func():presentation.camera.zoom *= .9*Vector2.ONE,
	"fast_sim":func():Engine.time_scale = 5.0,
	"slow_sim":func():Engine.time_scale = 1.0,
	"map":func():presentation.minimap.visible = not presentation.minimap.visible,
	"pause":func():var wc = WorldCommand.wc_pause.new(not worldState.paused);worldCommand.add_command(wc)
}


const direction_control_keys = {
	"left":Vector2.LEFT,
	"right":Vector2.RIGHT,
	"up":Vector2.UP,
	"down":Vector2.DOWN
}


# ## TODO: Tool context keys, UI interaction contextual keys (press enter to continue...), hotkeys


static func keys_to_dir(currently_pressed:Dictionary) -> Vector2:
		var dir := Vector2.ZERO
		for action in direction_control_keys.keys():
			if currently_pressed[action]:
				dir += direction_control_keys[action]
		if dir != Vector2.ZERO:
			dir = dir.normalized()
		return dir




# Routes the event to appropriate destination

#@export var context:ContextHandler
func key_event(event:KeyboardHandler.KeyEvent):
	
	# Game directional input goes directly to WorldCommand
	if event.action in direction_control_keys.keys():
		var vector := keys_to_dir(event.currently_pressed)
		var wc := WorldCommand.wc_direction_control_input.new()
		wc.control[0] = vector
		worldCommand.add_command(wc)
		return

	'''
	# Contextual input routing (Editor context)
	if event.action in context.context_keys:
		context.key_event(event)
		return
	'''

	# General presentation interaction actions (Camera, dev hotkeys)
	if event.pressed and event.action in key_actions.keys():
		key_actions[event.action].call()

# TODO: Presentation actions should be encapsulated as objects so they can be mapped arbitrarily to keyboard events
# (like reaper)

















var last_toggle_time = 0
var debounce_time = 0.2  # Adjust this value as needed
func toggle_fullscreen():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_toggle_time > debounce_time:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		last_toggle_time = current_time
