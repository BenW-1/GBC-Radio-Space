extends RichTextLabel

@export var min_font_size := 4
@export var max_font_size := 128

@export var safety_margin := 1.0

@export var auto_fit_on_text_change := true:
	set(value):
		auto_fit_on_text_change = value
		if is_inside_tree():
			set_process(value)

var _fit_id := 0
var _last_known_text := ""
var _probe: RichTextLabel

func _ready() -> void:
	fit_content = false
	_probe = _make_probe()
	resized.connect(_start_fit)
	set_process(auto_fit_on_text_change)
	_last_known_text = text
	await get_tree().process_frame
	_start_fit()

func _make_probe() -> RichTextLabel:
	var p := RichTextLabel.new()
	p.visible = false
	p.fit_content = false
	p.scroll_active = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)  # child of self — RichTextLabel isn't a Container, so this doesn't affect layout
	return p

func _process(_delta: float) -> void:
	if text != _last_known_text:
		_last_known_text = text
		_start_fit()

func _start_fit() -> void:
	_fit_id += 1
	_fit_font_to_box(_fit_id)

func _sync_probe() -> void:
	_probe.theme = theme
	_probe.bbcode_enabled = bbcode_enabled
	_probe.text = text
	_probe.autowrap_mode = autowrap_mode
	_probe.size = size
	for font_name in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
		if has_theme_font_override(font_name):
			_probe.add_theme_font_override(font_name, get_theme_font(font_name))

func refit() -> void:
	_start_fit()
	
func _fit_font_to_box(my_id: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if my_id != _fit_id:
		return

	_sync_probe()
	var target_height := size.y * safety_margin
	var target_width := size.x * safety_margin
	var lo := min_font_size
	var hi := max_font_size
	var best := lo

	while lo <= hi:
		if my_id != _fit_id:
			return
		var mid := (lo + hi) / 2
		_probe.add_theme_font_size_override("normal_font_size", mid)
		await get_tree().process_frame
		if my_id != _fit_id:
			return

		var fits_height := _probe.get_content_height() <= target_height
		var fits_width := _probe.get_content_width() <= target_width

		if fits_height and fits_width:
			best = mid
			lo = mid + 1
		else:
			hi = mid - 1

	if my_id == _fit_id:
		add_theme_font_size_override("normal_font_size", best)  # the ONLY write to the real, visible node
