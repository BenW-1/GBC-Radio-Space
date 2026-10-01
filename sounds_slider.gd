extends HSlider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = GlobalNode.read_quickstart['slider3']
	value_changed.connect(funcy)
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	GlobalNode.slider3=value
	
func funcy(value_passed) -> void:
	var volume_db = linear_to_db(value_passed/100)
	var bus_index = AudioServer.get_bus_index('Sounds')
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	get_parent().find_child('soundsTextPer').text = str(int(value_passed))+'%'
