extends Node

@export var themes:Array[String] = ['Earth', 'Mars', 'Moon']
@export var current_theme:String = 'Moon':
	get:
		return themes[themeIndex]

var themeIndex:int = 0

var time_of_last_segment:float
var time_of_last_ad:float

signal new_themes_from_on_high

var slider1:float = 100
var slider2:float = 100
var slider3:float = 100

var modifyTime:int

var isMusic:bool
var track_path:String
var time_in: float

var read_quickstart = {
	'finished_read':false,
	'was_music':false,
	'path':'f',
	'seconds_in':0.0,
	'seconds_since_ad':0.0,
	'seconds_since_segment':0.0,
	'slider1':0.0,
	'slider2':0.0,
	'slider3':0.0,
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$stateSave.start()
	modifyTime = FileAccess.get_modified_time('user://configs/themes.txt')
	var file_path = 'user://configs/index.txt'
	var file = FileAccess.open(file_path, FileAccess.READ)
	themeIndex=int(file.get_line())
	file.close()
	fileStuff()
	_read_quick_start()

func fileStuff():
	var file_path = 'user://configs/themes.txt'
	var file = FileAccess.open(file_path, FileAccess.READ)
	themes = []
	while file.get_position()< file.get_length():
		themes.append(file.get_line())
	file.close()
	if themeIndex >= len(themes):
		themeIndex = len(themes)-1

func store_index():
	var file_path = 'user://configs/index.txt'
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(str(themeIndex))
	file.close()

func decrement():
	print('Increment')
	fileStuff()
	themeIndex += 1
	if themeIndex >= len(themes):
		themeIndex=0
	store_index()

func increment():
	print('Decrement')
	fileStuff()
	themeIndex -= 1
	if themeIndex <0:
		themeIndex = len(themes)-1
	store_index()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if modifyTime != FileAccess.get_modified_time('user://configs/themes.txt'):
		modifyTime = FileAccess.get_modified_time('user://configs/themes.txt')
		print('changed')
		fileStuff()
		new_themes_from_on_high.emit()

'''
var read_quickstart = {
	'finished_read':false,
	'was_music':false,
	'path':'f',
	'seconds_in':0.0,
	'seconds_since_ad':0.0,
	'seconds_since_segment':0.0,
	'slider1':0.0,
	'slider2':0.0,
	'slider3':0.0,
	}
'''
func _read_quick_start():
	var file = FileAccess.open("user://configs/quick_start.txt", FileAccess.READ)
	if file:
		read_quickstart['finished_read'] = true
		read_quickstart['was_music'] = file.get_line()=='true'
		read_quickstart['path'] = file.get_line()
		read_quickstart['seconds_in'] = float(file.get_line())
		read_quickstart['seconds_since_ad'] = float(file.get_line())
		read_quickstart['seconds_since_segment'] = float(file.get_line())
		read_quickstart['slider1'] = float(file.get_line())
		read_quickstart['slider2'] = float(file.get_line())
		read_quickstart['slider3'] = float(file.get_line())
	else:
		print("Failed to open file")
	if not FileAccess.file_exists(read_quickstart['path']):
		read_quickstart['finished_read'] = false

func _on_state_save_timeout() -> void:
	var now_time = Time.get_ticks_msec() / 1000.0
	var file_path = 'user://configs/quick_start.txt'
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(str(isMusic)+'\n')
	file.store_string(str(track_path)+'\n')
	file.store_string(str(time_in)+'\n')
	file.store_string(str(now_time-time_of_last_ad)+'\n')
	file.store_string(str(now_time-time_of_last_segment)+'\n')
	file.store_string(str(slider1)+'\n')
	file.store_string(str(slider2)+'\n')
	file.store_string(str(slider3)+'\n')
	file.close()
