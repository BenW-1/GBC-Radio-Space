extends VBoxContainer

var radio:float=1
var inteference:float=0

func update_busses():
	var volume_db
	var bus_index
	volume_db = linear_to_db(radio*(1-inteference))
	bus_index = AudioServer.get_bus_index('Radio')
	AudioServer.set_bus_volume_db(bus_index, volume_db)

	volume_db = linear_to_db(radio*inteference)
	bus_index = AudioServer.get_bus_index('Inteference')
	AudioServer.set_bus_volume_db(bus_index, volume_db)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	$SliderStack1/RadSlide.value = GlobalNode.read_quickstart['slider1']
	$SliderStack2/IntefSlider.value = GlobalNode.read_quickstart['slider2']
	update_busses()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	GlobalNode.slider1=radio*100
	GlobalNode.slider2=inteference*100


func _on_intef_slider_value_changed(value: float) -> void:
	pass # Replace with function body.
	$SliderStack2/IntefText.text = str(int(value))+'%'
	inteference = value/100.0
	update_busses()

func _on_rad_slide_value_changed(value: float) -> void:
	pass # Replace with function body.
	$SliderStack1/RadText.text = str(int(value))+'%'
	radio = value/100.0
	update_busses()
