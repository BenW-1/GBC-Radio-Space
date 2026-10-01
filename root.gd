extends Node2D

@export var ident_transition_seconds:float = 1
@export var chatter_breath:float = 1
@export var main_backing_vol_linear:float = 0.2
@export var backing_to_music_transition:float = 1
@export var minimum_time_between_radio_segments = 0*60
@export var minimum_time_between_ads = 20*60

var currently:String
var time_of_last_segment:float
var time_of_last_ad:float

var force_now:String = ''

var boolface:bool = false

var music_countdown:float
var ad_countdown:float
var show_countdown:float
var event_countdown:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	force_now='music'
	music_countdown = -100.0
	ad_countdown = -100.0
	show_countdown = -100.0
	event_countdown = -100.0
	time_of_last_segment = Time.get_ticks_msec() / 1000.0
	time_of_last_ad = Time.get_ticks_msec() / 1000.0
	
	quick_start()
	#new_thing()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	GlobalNode.time_of_last_ad = time_of_last_ad
	GlobalNode.time_of_last_segment = time_of_last_segment
	music_countdown -=delta
	ad_countdown -= delta
	show_countdown -= delta
	event_countdown -= delta
	pass
	if currently=='music':
		GlobalNode.isMusic = true
		GlobalNode.track_path = $Music.get_current_music_track_path()
		GlobalNode.time_in = $Music.get_current_track_length() - music_countdown 
	else:
		GlobalNode.isMusic = false



func _on_ident_timer_timeout() -> void:
	$"Ident transition timer".wait_time = ident_transition_seconds
	$"Ident transition timer".start()
	var tween = get_tree().create_tween()
	$Backing.new_volume_linear = 0
	tween.tween_property($Backing, "new_volume_linear", 0.8, ident_transition_seconds/2)
	$Backing.r_play()


func _on_ident_transition_timer_timeout() -> void:
	pass # do chatter
	$chatter.r_play()


func _on_chatter_finished(s) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($Backing, "volume_linear", main_backing_vol_linear, chatter_breath/2)
	$"Chatter breath".wait_time = chatter_breath
	$"Chatter breath".start()

func _on_chatter_breath_timeout() -> void:
	boolface=false
	$Segment.r_play()
	show_countdown = $Segment.get_current_track_length()
	read_appdata_text()


func _on_segment_finished(s) -> void:
	#var tween = get_tree().create_tween()
	#$Music.volume_linear = 0
	#tween.tween_property($Backing, "volume_linear", 0, backing_to_music_transition)
	#tween.tween_property($Music, "volume_linear", 1, backing_to_music_transition)
	#$Music.r_play()
	$Backing.stop_all_tracks()
	$"Starting hiss".play()


func _on_hiss_1_finished() -> void:
	
	$Intro.r_play()


func _on_hiss_2_finished() -> void:
	$Ident.r_play()
	var ident_time = $Ident.get_current_track_length() - ident_transition_seconds
	$"Ident timer".wait_time = ident_time
	$"Ident timer".start()



func _on_intro_finished(s) -> void:
	$hiss2.play()

func read_appdata_text():
	var file_path = "user://" + $silences.local_path
	
	# Check if file exists
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var i = 0
			while not file.eof_reached():
				var line = file.get_line() # Newline is automatically removed
				if i%3==0:
					if $Segment.get_current_track_title() == line:
						$"begin silence".wait_time = float(file.get_line())
						$"end silence".wait_time = float(file.get_line())
						$"begin silence".start()
						$"end silence".start()
						file.close()
						return
				i+=1
			file.close()
			return
		else:
			print("Failed to open file")
	else:
		print("File not found in user directory")
	return null   


func _on_begin_silence_timeout() -> void:
	$Backing.new_volume_linear = 0

func stopstopstop():
	boolface=false
	$Ident.stop_all_tracks()
	$"Ident timer".stop()
	$Backing.stop_all_tracks()
	$"Ident transition timer".stop()
	$chatter.stop_all_tracks()
	$"Chatter breath".stop()
	$Segment.stop_all_tracks()
	$Music.stop_all_tracks()
	$Intro.stop_all_tracks()
	$Broadcast.stop_all_tracks()
	$hiss1.stop()
	$hiss2.stop()
	$"begin silence".stop()
	$"end silence".stop()
	$"Starting hiss".stop()
	$Ad.stop_all_tracks()
	music_countdown = -1.0
	ad_countdown = -1.0
	show_countdown = -1.0
	event_countdown = -1.0
	new_thing()

func _on_end_silence_timeout() -> void:
	$Backing.new_volume_linear = main_backing_vol_linear

func new_thing()-> void:
	var time_now = Time.get_ticks_msec() / 1000.0
	if (force_now=='' and time_now - time_of_last_segment >= minimum_time_between_radio_segments) or force_now=='radio':
		force_now=''
		currently='radio'
		boolface=true
		time_of_last_segment = time_now
		$hiss1.play()
		#radio segment
	elif (force_now=='' and time_now - time_of_last_ad >= minimum_time_between_ads) or force_now=='ad':
		force_now=''
		currently='ad'
		time_of_last_ad = time_now
		$Ad.r_play()
		ad_countdown = $Ad.get_current_track_length()
		#ad
	elif force_now=='event':
		force_now=''
		currently='event'
		$Broadcast.r_play()
	else:
		force_now=''
		currently='music'
		$Music.r_play()
		music_countdown = $Music.get_current_track_length()

func quick_start():
	var finished_read= GlobalNode.read_quickstart['finished_read']
	var was_music= GlobalNode.read_quickstart['was_music']
	var path= GlobalNode.read_quickstart['path']
	var seconds_in= GlobalNode.read_quickstart['seconds_in']
	var seconds_since_ad= GlobalNode.read_quickstart['seconds_since_ad']
	var seconds_since_segment= GlobalNode.read_quickstart['seconds_since_segment']
	if was_music and finished_read:
		force_now=''
		currently='music'
		$Music._start_voice(path, seconds_in)
		music_countdown = $Music.get_current_track_length() - seconds_in
		time_of_last_segment = (Time.get_ticks_msec() / 1000.0) - seconds_since_segment
		time_of_last_ad = (Time.get_ticks_msec() / 1000.0) - seconds_since_ad
		
		print('moolah')
	elif was_music:
		print('was music. Was not read??')
		new_thing()
	elif finished_read:
		print('was read. was not music')
		new_thing()
	else:
		print('was not read. was not music')
		new_thing()

func _on_starting_hiss_finished() -> void:
	time_of_last_segment = Time.get_ticks_msec() / 1000.0
	new_thing()


func _on_music_finished(s) -> void:
	new_thing()


func _on_ad_finished(s) -> void:
	time_of_last_ad = Time.get_ticks_msec() / 1000.0
	new_thing()


func _on_broadcast_track_finished(track_name: String) -> void:
	$embarasmentHiss.play()
	new_thing()
