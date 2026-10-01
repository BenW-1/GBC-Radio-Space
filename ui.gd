extends Control

@export var spin_period:float = 1

var radio_max_time := 1.0
var ad_max_time := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$'HBoxContainer/Controlls Pannel/VBoxContainer/Themer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TextureButton'.pressed.connect(GlobalNode.increment)
	$'HBoxContainer/Controlls Pannel/VBoxContainer/Themer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TextureButton3'.pressed.connect(GlobalNode.decrement)
	
	dofields()
	var spinny = find_child('Vinyl')
	var tween = create_tween().set_loops()
	tween.tween_property(spinny, "rotation_degrees", 360, spin_period).from(0)
	$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer3/Panel3/ShowRemaining/sneekyButton".disabled = true

func dofields():
	var file_path = "user://configs/fields.txt" 
	
	# Check if file exists
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			#while not file.eof_reached():
			#	var line = file.get_line() # Newline is automatically removed
			#	print(line)
			$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox1/timeEnter1".funcyB(file.get_line())
			$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox2/timeEnter2".funcyB(file.get_line())
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle".text = file.get_line()
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle2".text = file.get_line()
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle3".text = file.get_line()
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle4".text = file.get_line()
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle5".text = file.get_line()
			$"HBoxContainer/Sounds Pannel/MarginContainer/VBoxContainer/VBoxContainer/SoundbankTitle6".text = file.get_line()

func anify(seconds:int) -> String:
	if seconds/60 >= (100*60) or seconds<0:
		return '--:--'
	var l = str(seconds/60)
	var r = str(seconds%60)
	if len(l)==1: l = '0'+l
	if len(r)==1: r = '0'+r
	return l+':'+r

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"HBoxContainer/Controlls Pannel/VBoxContainer/Themer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/theme name".text = GlobalNode.current_theme
	var m_count = int(floor($root.music_countdown))
	var a_count = int(floor($root.ad_countdown))
	var s_count = int(floor($root.show_countdown))
	var e_count = int(floor($root.event_countdown))
	$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer/Panel/MusicRemaining".text = anify(m_count)
	$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer2/Panel2/AdRemaining".text = anify(a_count)
	if not $root.boolface:
		$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer3/Panel3/ShowRemaining/sneekyButton".disabled = true
		$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer3/Panel3/ShowRemaining".text = anify(s_count)
	else:
		$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer3/Panel3/ShowRemaining/sneekyButton".disabled = false
		$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer3/Panel3/ShowRemaining".text = '[rainbow]--:--'
	$"HBoxContainer/Controlls Pannel/VBoxContainer/HBoxContainer/MarginContainer4/Panel4/EventRemaining".text = anify(e_count)
	
	var timeStr = Time.get_time_string_from_system()
	var timeComps = timeStr.split(':')
	var post = ' AM'
	var hour = int(timeComps[0])
	if hour >12:
		hour-=12
		timeComps[0] = str(hour)
		post = ' PM'
	timeStr = ':'.join(timeComps)
	find_child('Time').text = timeStr+post
	
	var mm
	var ss
	var time_now = Time.get_ticks_msec() / 1000.0
	var color_tag: String
	
	color_tag = '[color=white]'
	var time_since_ad = time_now - $root.time_of_last_ad
	
	if time_since_ad >= ad_max_time:
		color_tag = '[color=green]'

	mm = str(int(floor(time_since_ad/60)))
	if len(mm)==1: mm='0'+mm
	ss = str(int(floor(time_since_ad))%60)
	if len(ss)==1: ss='0'+ss
	if $"root".currently!='ad':
		$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox2/left".text = color_tag+':'.join([mm,ss]) +'[/color] /'
	else:
		$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox2/left".text = '--:-- /'
	
	color_tag = '[color=white]'
	var time_since_segment = time_now - $root.time_of_last_segment
	
	if time_since_segment >= radio_max_time:
		color_tag = '[color=green]'
	
	mm = str(int(floor(time_since_segment/60)))
	if len(mm)==1: mm='0'+mm
	ss = str(int(floor(time_since_segment))%60)
	if len(ss)==1: ss='0'+ss
	if $"root".currently!='radio':
		$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox1/left".text = color_tag+':'.join([mm,ss]) +'[/color] /'
	else:
		$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2/MarginContainer/VBoxContainer/hbox1/left".text = '--:-- /'
	
func _on_secret_buton_pressed() -> void:
	$"HBoxContainer/Sounds Pannel".do_color()
	$"HBoxContainer/Info Pannel/VBoxContainer/PanelContainer2".do_color()
	$"HBoxContainer/Controlls Pannel".do_color()


func _on_time_enter_1_new_time(seconds: int) -> void:
	print(seconds)
	radio_max_time = float(seconds)
	$root.minimum_time_between_radio_segments=seconds

func _on_time_enter_2_new_time(seconds: int) -> void:
	print(seconds)
	ad_max_time = float(seconds)
	$root.minimum_time_between_ads = seconds


func _on_skipto_music_pressed() -> void:
	$root.force_now='music'
	$root.stopstopstop()
	$AudioStreamPlayer2.play()
	pass # Replace with function body.


func _on_skipto_ad_pressed() -> void:
	$root.force_now='ad'
	$root.stopstopstop()
	$AudioStreamPlayer2.play()
	pass # Replace with function body.


func _on_skipto_show_pressed() -> void:
	$root.force_now='radio'
	$root.stopstopstop()
	$AudioStreamPlayer2.play()
	pass # Replace with function body.


func _on_skipto_event_pressed() -> void:
	$root.force_now='event'
	$root.stopstopstop()
	$AudioStreamPlayer2.play()
	pass # Replace with function body.


func _on_text_update(new_text: String, extra_arg_0: int) -> void:
	print(new_text, ' ', extra_arg_0)
	var file = FileAccess.open("user://configs/fields.txt", FileAccess.READ)
	var lines = file.get_as_text().split("\n", true)
	file.close()
	lines[extra_arg_0]=new_text
	var new_content = "\n".join(lines)
	file = FileAccess.open("user://configs/fields.txt", FileAccess.WRITE)
	file.store_string(new_content)
	file.close()


func _on_fullscr_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_minimise_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _on_close_pressed() -> void:
	get_tree().quit()
