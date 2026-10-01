extends Control

enum Edge { TOP, BOTTOM, LEFT, RIGHT, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, DRAG }

@export var edge: Edge = Edge.BOTTOM_RIGHT

const MIN_SIZE := Vector2i(300, 200)

var dragging := false
var start_mouse_pos: Vector2i
var start_window_size: Vector2i
var start_window_pos: Vector2i

func _ready() -> void:
	mouse_default_cursor_shape = _cursor_for_edge(edge)

func _cursor_for_edge(e: Edge) -> Control.CursorShape:
	match e:
		Edge.LEFT, Edge.RIGHT:
			return Control.CURSOR_HSIZE
		Edge.TOP, Edge.BOTTOM:
			return Control.CURSOR_VSIZE
		Edge.TOP_LEFT, Edge.BOTTOM_RIGHT:
			return Control.CURSOR_FDIAGSIZE
		Edge.TOP_RIGHT, Edge.BOTTOM_LEFT:
			return Control.CURSOR_BDIAGSIZE
		Edge.DRAG:
			return Control.CURSOR_MOVE
	return Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			start_mouse_pos = DisplayServer.mouse_get_position()
			start_window_size = DisplayServer.window_get_size()
			start_window_pos = DisplayServer.window_get_position()
		else:
			dragging = false

func _process(_delta: float) -> void:
	if not dragging:
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		dragging = false
		return
	var mouse_pos := DisplayServer.mouse_get_position()
	var diff := mouse_pos - start_mouse_pos

	if edge == Edge.DRAG:
		DisplayServer.window_set_position(start_window_pos + diff)
		return

	var new_size := start_window_size
	var new_pos := start_window_pos

	var wants_left := edge in [Edge.LEFT, Edge.TOP_LEFT, Edge.BOTTOM_LEFT]
	var wants_right := edge in [Edge.RIGHT, Edge.TOP_RIGHT, Edge.BOTTOM_RIGHT]
	var wants_top := edge in [Edge.TOP, Edge.TOP_LEFT, Edge.TOP_RIGHT]
	var wants_bottom := edge in [Edge.BOTTOM, Edge.BOTTOM_LEFT, Edge.BOTTOM_RIGHT]

	if wants_right:
		new_size.x = max(start_window_size.x + diff.x, MIN_SIZE.x)
	elif wants_left:
		new_size.x = max(start_window_size.x - diff.x, MIN_SIZE.x)
		new_pos.x = start_window_pos.x + (start_window_size.x - new_size.x)

	if wants_bottom:
		new_size.y = max(start_window_size.y + diff.y, MIN_SIZE.y)
	elif wants_top:
		new_size.y = max(start_window_size.y - diff.y, MIN_SIZE.y)
		new_pos.y = start_window_pos.y + (start_window_size.y - new_size.y)

	DisplayServer.window_set_size(new_size)
	DisplayServer.window_set_position(new_pos)
