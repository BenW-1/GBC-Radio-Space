extends TextureButton

@export var destination:String =''
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	pressed.connect(_on_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	var path := OS.get_user_data_dir()  # e.g. AppData/Roaming/Godot/app_userdata/YourProject on Windows
	OS.shell_open(path+'/'+destination)
	print(path)
