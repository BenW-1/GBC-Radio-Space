extends PanelContainer

var rng = RandomNumberGenerator.new()

func do_color() -> void:
	rng.randomize()
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = Color.from_hsv(rng.randf(), 0.59, 0.58, 1.0)
	add_theme_stylebox_override("panel", style)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	do_color()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
