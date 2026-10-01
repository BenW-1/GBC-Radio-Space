extends LineEdit

@export var copyNode:Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	text_submitted.connect(doris)

func doris(text):
	release_focus()

func _process(delta: float) -> void:
	add_theme_font_size_override("font_size", copyNode.get_theme_font_size("normal_font_size", "RichTextLabel"))
