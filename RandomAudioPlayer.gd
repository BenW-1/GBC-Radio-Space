extends AudioStreamPlayer
class_name RandomAudioPlayer

## Emitted right after a new random track starts playing. With several
## tracks layered at once, this can fire multiple times in quick succession.
signal track_changed(track_name: String)

## Emitted when a specific track finishes playing on its own (not stopped
## early via stop_track()/stop_all_tracks()).
signal track_finished(track_name: String)

## Subfolder name inside the user data directory (i.e. AppData on Windows).
## Full path ends up being e.g. user://custom_sounds/
@export var folder_name: String = "custom_sounds"

## If true, when a given track finishes on its own, that same track starts
## again from the top instead of freeing up its slot. Applies to every
## currently playing track, not just one.
@export var repeat: bool = false

## How many tracks this node can have layered on top of each other at once.
## This is the real polyphony control for this node — the inherited
## "Max Polyphony" field further down the Inspector is a leftover from
## AudioStreamPlayer that no longer does anything here (see the big comment
## on _playback below for why), so it's left alone rather than renamed to
## avoid clashing with the engine's own property of the same name.
@export var polyphony_voices: int = 8

@export var is_theme_specific:bool = false

## Drag your bundled default .mp3 resources here in the Inspector. They're
## copied into the user's custom_sounds folder once, the very first time the
## game runs, so new players hear something before they've added anything of
## their own. After that first copy, the game never touches this again — so
## if a player deletes a default track later, it stays deleted.
@export var default_sounds: Array[AudioStreamMP3] = []

var _files: PackedStringArray = []

# Bag randomizer (same idea as Tetris' 7-bag): every file gets shuffled into
# _bag once, and each play() pops one off. Once the bag runs dry it's
# reshuffled from scratch, so within any run of N plays every file is
# guaranteed to appear, and you never get long unlucky repeat streaks.
var _bag: Array[String] = []

# The user:// path of whatever's currently (or was most recently) loaded,
# e.g. "user://custom_sounds/forest_ambience.mp3". Kept so outside code and
# the getters below can ask what's playing without needing their own copy
# of the file list.
var _current_path: String = ""

# Snapshot of _files as of the last time _pick_next_from_bag() looked.
# Used to tell a genuinely new file (added since last look) apart from one
# that's simply already been played this cycle and is correctly absent from
# _bag — both are "missing from _bag", but only the former should be shuffled in.
var _known_files: PackedStringArray = []

# Setting AudioStreamPlayer.stream while something's playing stops
# everything currently playing — and even without that, max_polyphony only
# ever stacks copies of ONE stream, not several different files. Neither
# works for a node that needs to layer different, randomly-picked tracks.
# AudioStreamPolyphonic is Godot's mechanism for that: `stream` gets set to
# one ONCE, activated with a single super.play(), and every actual track
# after that goes through this playback controller's play_stream() instead —
# which is why r_play() never touches `stream` or calls super.play() again.
var _playback: AudioStreamPlaybackPolyphonic

# Maps each active voice's ID (returned by play_stream) to a small Dictionary
# of {path, stream} — path for reporting/matching by filename, stream (the
# loaded AudioStreamMP3) so callers can still ask things like get_length()
# the way they could when `stream` itself used to hold the playing track.
var _active_voices: Dictionary = {}


var new_volume_linear: float:
	set(value):
		volume_db = linear_to_db(value)
		if _playback != null:
			for id in _active_voices.keys():
				_playback.set_stream_volume(id, volume_db)
	get:
		return db_to_linear(volume_db)

func do_new_seeding():
	var dir_path := "user://%s" % folder_name
	_seed_defaults(dir_path)
	

func get_current_music_track_path() -> String:
	if _active_voices.size() != 1:
		return ""
	return _active_voices.values()[0]["path"]



func _ready() -> void:
	GlobalNode.new_themes_from_on_high.connect(do_new_seeding)
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = polyphony_voices
	stream = poly
	super.play()  # Activates the polyphonic container itself. Only ever called once.
	_playback = get_stream_playback() as AudioStreamPlaybackPolyphonic

	var dir_path := "user://%s" % folder_name
	# Create the folder on first run so there's somewhere for the user to drop files.
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	_seed_defaults(dir_path)
	_scan_folder(dir_path)
	_known_files = _files.duplicate()
	_initiate_bag()


# AudioStreamPlaybackPolyphonic doesn't emit a signal when an individual
# voice finishes (a known Godot limitation, not an oversight here), so the
# only way to notice a track ran out on its own is to poll each active
# voice's is_stream_playing() every frame.
func _process(_delta: float) -> void:
	if _playback == null:
		return
	for id in _active_voices.keys():
		if not _playback.is_stream_playing(id):
			var path: String = _active_voices[id]["path"]
			_active_voices.erase(id)
			track_finished.emit(path.get_file())
			if repeat:
				_start_voice(path)

func _initiate_bag() -> void:
	_bag = []
	var path = 'user://bags/'+self.name+'.txt'
	var flag = false
	if not DirAccess.dir_exists_absolute("user://bags"):
		flag=true
	if not FileAccess.file_exists(path):
		flag=true
	if flag:
		_bag = Array(Array(_files), TYPE_STRING, "", null)
		_bag.shuffle()
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var line := file.get_line()
		if not line.is_empty():
			_bag.append(line)
	file.close()
	return

func _write_bag_file(bag) -> void:
	var path = 'user://bags/'+self.name+'.txt'

	# 1. Create the directory if it doesn't exist
	if not DirAccess.dir_exists_absolute('user://bags'):
		var err = DirAccess.make_dir_recursive_absolute('user://bags')
		if err != OK:
			return

	var file = FileAccess.open(path, FileAccess.WRITE)
	for item in bag:
		file.store_line(item)
	file.close()
	return

func _seed_defaults(dir_path: String) -> void:
	var themes:Array[String] = GlobalNode.themes
	var current_theme:String = GlobalNode.current_theme
	
	if not is_theme_specific: themes = ['dummy']
	for theme in themes:
		var marker_path:String
		if is_theme_specific:
			marker_path = (dir_path+'/'+theme).path_join(".seeded")
		else:
			marker_path = dir_path.path_join(".seeded")
		
		var tempStr:String = dir_path
		if is_theme_specific: tempStr = tempStr+'/'+theme
		
		if not DirAccess.dir_exists_absolute(tempStr):
			var err = DirAccess.make_dir_recursive_absolute(tempStr)
			if err != OK:
				return

		if FileAccess.file_exists(tempStr.path_join(".seeded")):
			continue  # Already seeded once. Don't re-add files the player removed.

		for i in default_sounds.size():
			var stream := default_sounds[i]
			if stream == null:
				continue

			# Reuse the imported resource's own filename (e.g. "forest_ambience.mp3")
			# so what lands in user:// matches what's in the project. Fall back to a
			# generic name only if a stream somehow has no resource_path (e.g. one
			# built at runtime rather than dragged in from the FileSystem dock).
			var file_name := stream.resource_path.get_file()
			if file_name.is_empty():
				file_name = "default_%02d.mp3" % i

			var target_path := (tempStr).path_join(file_name)
			var out := FileAccess.open(target_path, FileAccess.WRITE)
			if out == null:
				push_warning("RandomAudioPlayer: could not write %s" % target_path)
				continue
			out.store_buffer(stream.data)
			out.close()

		# Write the marker last, so a failed/interrupted first run tries again next time.
		var marker := FileAccess.open(marker_path, FileAccess.WRITE)
		if marker:
			marker.close()


func _scan_folder(path: String) -> void:
	var themes:Array[String] = GlobalNode.themes
	var current_theme:String = GlobalNode.current_theme
	
	_files.clear()
	var dir:DirAccess
	if is_theme_specific:
		dir = DirAccess.open(path+'/'+current_theme)
	else:
		dir = DirAccess.open(path)
	if dir == null:
		push_warning("RandomAudioPlayer: could not open folder %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "mp3":
			if is_theme_specific:
				_files.append((path+'/'+current_theme).path_join(file_name))
			else:
				_files.append((path).path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()


# Picks the next track from the bag and layers it in as a new polyphonic
# voice — every other track currently playing is left completely alone.
func r_play(from_position: float = 0.0) -> void:
	# Re-scan every call so files added/removed mid-session are respected.
	_scan_folder("user://%s" % folder_name)

	if _files.is_empty():
		push_warning("RandomAudioPlayer: no .mp3 files found in user://%s" % folder_name)
		return

	var choice := _pick_next_from_bag()
	_start_voice(choice, from_position)


# Loads an mp3 from disk and starts it as a new voice. Shared by r_play()
# (a fresh bag pick) and the repeat path in _process() (replaying the same
# path again), so both go through identical bookkeeping.
func _start_voice(path: String, from_position: float = 0.0) -> void:
	var loaded := _load_mp3(path)
	if loaded == null:
		return

	var id := _playback.play_stream(loaded, from_position, volume_db, pitch_scale, AudioServer.PLAYBACK_TYPE_DEFAULT, bus)
	_active_voices[id] = {"path": path, "stream": loaded}
	_current_path = path
	track_changed.emit(get_current_track_name())


func _pick_next_from_bag() -> String:
	# Drop any bagged entries whose files have since been deleted by the user.
	_bag = _bag.filter(func(path: String) -> bool: return path in _files)

	# Mirror case: shuffle in any files the user has added since we last
	# looked, so a new track doesn't have to wait for a full bag reset
	# before it's eligible to play.
	var added_new := false
	for path in _files:
		if path not in _known_files:
			_bag.append(path)
			added_new = true
	if added_new:
		_bag.shuffle()

	_known_files = _files.duplicate()

	# Refill and reshuffle once the bag is empty (first run, or just emptied).
	# Note: like Tetris' own bag, this means the last pick of one bag and the
	# first pick of the next CAN occasionally be the same file — that's
	# expected, correct bag-randomizer behavior, not a bug.
	if _bag.is_empty():
		_bag = Array(Array(_files), TYPE_STRING, "", null)
		_bag.shuffle()

	var val = _bag.pop_back()
	_write_bag_file(_bag) 
	return val


## Filename of the most recently started track, e.g. "forest_ambience.mp3".
## With several tracks layered at once this is only the newest one — see
## get_playing_track_names() for everything currently playing.
func get_current_track_name() -> String:
	return _current_path.get_file()


## Same as get_current_track_name(), but with the ".mp3" extension stripped,
## e.g. "forest_ambience".
func get_current_track_title() -> String:
	return _current_path.get_file().get_basename()


## Filenames of every track currently layered/playing at once, e.g.
## ["forest_ambience.mp3", "rain.mp3"]. Empty array if nothing is playing.
func get_playing_track_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for entry in _active_voices.values():
		names.append(entry["path"].get_file())
	return names


## Length in seconds of the currently playing track — the polyphony-safe
## replacement for the old `$node.stream.get_length()`. Only meaningful
## when exactly one track is playing, since "the current length" isn't a
## well-defined question with zero or several tracks active; both of those
## cases just return 0.0 rather than erroring.
func get_current_track_length() -> float:
	if _active_voices.size() != 1:
		return 0.0
	var entry = _active_voices.values()[0]
	return entry["stream"].get_length()


## Stops one specific playing track by filename (as returned by
## get_current_track_name() / get_playing_track_names()) before it finishes
## naturally. Deliberately does NOT go through the same code path
## _process() uses to detect natural completion, so this never triggers
## `repeat` — this is "stopped early", same distinction the old finished-
## signal version used to enforce. Prefer this over the inherited stop(),
## which stops every track at once and bypasses this distinction entirely.
func stop_track(track_name: String) -> void:
	for id in _active_voices.keys():
		var path: String = _active_voices[id]["path"]
		if path.get_file() == track_name:
			_playback.stop_stream(id)
			_active_voices.erase(id)


## Stops every currently playing track early. See stop_track() — same
## "doesn't trigger repeat" guarantee applies here.
func stop_all_tracks() -> void:
	for id in _active_voices.keys():
		_playback.stop_stream(id)
	_active_voices.clear()


func _load_mp3(path: String) -> AudioStreamMP3:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("RandomAudioPlayer: could not open %s" % path)
		return null

	# --- Godot 4.0–4.3 ---
	var sound := AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound

	# --- Godot 4.4+ shortcut (comment out the block above and use this instead) ---
	# return AudioStreamMP3.load_from_buffer(file.get_buffer(file.get_length()))
