extends LineEdit

signal new_time(seconds:int)
signal texty(string:String)

@export var copyNode:Node
var oldText:String
var flag=true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_submitted.connect(funcyB)
	oldText=text
	#funcyB(text)
	pass # Replace with function body.
	
func funcyB(sub_text):
	release_focus()
	var flag=true
	var decomposed_sub_text = sub_text.split(':')
	if len(decomposed_sub_text)==2:
		if decomposed_sub_text[0].is_valid_int():
			if decomposed_sub_text[1].is_valid_int():
				if int(decomposed_sub_text[1]) < 60:
					if len(decomposed_sub_text[0])==1: decomposed_sub_text[0]= '0'+decomposed_sub_text[0]
					if len(decomposed_sub_text[1])==1: decomposed_sub_text[1]= '0'+decomposed_sub_text[1]
					oldText=':'.join(decomposed_sub_text)
					new_time.emit( (int(decomposed_sub_text[0])*60)+int(decomposed_sub_text[1])  )
					texty.emit(oldText)
					text = oldText
					flag=false
	if flag:
		text = oldText
	

func funcy():
	print('ooh ah')
	flag=true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	add_theme_font_size_override("font_size", copyNode.get_theme_font_size("normal_font_size", "RichTextLabel"))
