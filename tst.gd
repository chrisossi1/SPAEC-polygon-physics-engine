extends Node2D


var sim = MouseClicker.new()

var elapsed := 0.
var period := .1

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < period: return
	elapsed = 0
	var pos = Vector2(randi_range(0,DisplayServer.window_get_size().x), randi_range(0,DisplayServer.window_get_size().y))
	sim.click_left_at(get_tree(), pos)




func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
