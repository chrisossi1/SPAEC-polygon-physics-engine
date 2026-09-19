'''
Detects keyboard input and packages events into KeyEvents, sending them to KeyEventRouter Presentation

'''

extends Node
class_name KeyboardHandler

@export var keyEventRouter: KeyEventRouter



class KeyEvent:
	var action:String
	var pressed:bool
	var currently_pressed:Dictionary
	func _init(a:String, p:bool, c:Dictionary):
		action = a
		pressed = p
		currently_pressed = c








''' Keyboard mapping data '''

const directions_wasd = {
	"left":KEY_A,
	"right":KEY_D,
	"up":KEY_W,
	"down":KEY_S
}
const directions_arrow = {
	"left":KEY_LEFT,
	"right":KEY_RIGHT,
	"up":KEY_UP,
	"down":KEY_DOWN
}

const directions_to_use = directions_arrow

#Todo: Move to presControl and have a top down controller pass the key_inputs names to KbdHandler
const key_inputs = {
	"left": directions_to_use["left"],
	"right": directions_to_use["right"],
	"up": directions_to_use["up"],
	"down": directions_to_use["down"],
	"fullscreen": KEY_F4,
	"toggle context": KEY_TAB,
	"alternate": KEY_SHIFT,
	"action": KEY_ENTER,
	"fast_sim": KEY_1,
	"slow_sim": KEY_2,
	"pause": KEY_BACKSPACE,
	"map": KEY_M
}

const scroll_inputs = {
	"zoom in": MOUSE_BUTTON_WHEEL_UP,
	"zoom out": MOUSE_BUTTON_WHEEL_DOWN
}


































''' Current keyboard state '''
var currently_pressed = key_inputs.duplicate()


''' Init keyboard mapping and build currently_pressed dictionary keys '''
func _ready():
	for action in key_inputs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.keycode = key_inputs[action]
		InputMap.action_add_event(action, key_event)

	for action in scroll_inputs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = scroll_inputs[action]
		InputMap.action_add_event(action, mouse_event)

	for key in currently_pressed.keys():
		currently_pressed[key] = false



''' Package and send events to Presentation '''
func _input(event):
	for action in key_inputs.keys():
		var pressed = event.is_action_pressed(action)
		if pressed or event.is_action_released(action):
			currently_pressed[action] = pressed
			var keyEvent = KeyEvent.new(action, pressed, currently_pressed)
			keyEventRouter.key_event(keyEvent)

	for action in scroll_inputs.keys():
		if event.is_action_pressed(action):
			var keyEvent = KeyEvent.new(action, true, currently_pressed)
			keyEventRouter.key_event(keyEvent)
	#TODO: QUUEEUE
