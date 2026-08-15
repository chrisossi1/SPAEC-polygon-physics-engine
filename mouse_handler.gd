'''
Detects and creates mouse events, sending all to Context Handler.
'''
extends Node2D
class_name MouseHandler


signal mouse_event(event:MouseEvent)



#@export var contextHandler: ContextHandler
@export var camera: Camera2D

var hoveredObj: GameObject
# Track state per button index (1: Left, 2: Right, 3: Middle)
var button_states = {} 

var DRAG_MARGIN_SQ = 2500 # 50 pixels squared for performance

# Enhanced Event Class
class MouseEvent:
	enum {HOVER_CHANGED, PRESSED, RELEASED, CLICK_COMPLETED, DRAG_STARTED, DRAG_HOVER, DRAG_ENDED}
	var type: int
	var button: MouseButton
	var object1: GameObject
	var object2: GameObject
	var pos_start: Vector2
	
	func _init(t: int, btn: MouseButton = MouseButton.MOUSE_BUTTON_NONE, o1 = null, o2 = null, p = Vector2()):
		type = t
		button = btn
		object1 = o1
		object2 = o2
		pos_start = p

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	event = event as InputEventMouseButton
	var btn := event.button_index as MouseButton
	
	if event.pressed:
		_on_button_pressed(btn)
	else:
		_on_button_released(btn)

func _physics_process(_delta):
	var mouse_pos = get_global_mouse_position()
	var new_hoveredObj = _get_obj_under_mouse()

	# Handle Hover Logic (Independent of buttons)
	if new_hoveredObj != hoveredObj:
		hoveredObj = new_hoveredObj
		mouse_event.emit(MouseEvent.new(MouseEvent.HOVER_CHANGED, MouseButton.MOUSE_BUTTON_NONE, hoveredObj))

	# Handle Drag Logic for every button currently held down
	for btn in button_states:
		var state = button_states[btn]
		if not state.is_dragging:
			if mouse_pos.distance_squared_to(state.press_pos) > DRAG_MARGIN_SQ:
				state.is_dragging = true
				mouse_event.emit(MouseEvent.new(MouseEvent.DRAG_STARTED, btn, state.pressed_obj, null, state.press_pos))
		
		if state.is_dragging:
			# Update drag hover if the object under mouse changes while dragging
			mouse_event.emit(MouseEvent.new(MouseEvent.DRAG_HOVER, btn, state.pressed_obj, hoveredObj, state.press_pos))

func _on_button_pressed(btn: MouseButton):
	# Initialize a unique state for this specific button
	button_states[btn] = {
		"pressed_obj": hoveredObj,
		"press_pos": get_global_mouse_position(),
		"is_dragging": false
	}
	mouse_event.emit(MouseEvent.new(MouseEvent.PRESSED, btn, hoveredObj))

func _on_button_released(btn: MouseButton):
	if not button_states.has(btn): return
	
	var state = button_states[btn]
	mouse_event.emit(MouseEvent.new(MouseEvent.RELEASED, btn))

	if state.is_dragging:
		mouse_event.emit(MouseEvent.new(MouseEvent.DRAG_ENDED, btn, state.pressed_obj, hoveredObj, state.press_pos))
	else:
		# Only a click if we released on the same object we started on
		if state.pressed_obj == hoveredObj:
			mouse_event.emit(MouseEvent.new(MouseEvent.CLICK_COMPLETED, btn, state.pressed_obj))
	
	# Clean up state for this button
	button_states.erase(btn)






func mouseDetect_filter_default(result):
	return true


var query_shape = CircleShape2D.new()
func _ready():
	query_shape.radius = 8



func _get_obj_under_mouse() -> GameObject:

	var params = PhysicsShapeQueryParameters2D.new()

	#var max_margin = 200.# / camera.zoom.x

	'''Getting the physics object under mouse'''
	var space_state := get_world_2d().direct_space_state
	var mousePos := get_global_mouse_position()
	params.shape = query_shape
	params.margin = 2 # Adding a small margin to help with precision issues
	params.collision_mask = 1
	params.transform = Transform2D(0,mousePos)
		
	var results = space_state.intersect_shape(params, 5)
	
	#results = results.filter(mouseDetect_filter_default)

	if not results:
		return null

	return GameObject.from_query_result(results[0])
