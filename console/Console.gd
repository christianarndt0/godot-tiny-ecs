extends Control


const HISTORY_LENGTH = 10
const RESIZE_ICON_OFFSET = Vector2(-5, 40)


var _command_history = [""]
var _command_history_idx = 0

var _dragging = false
var _resizing = false


func _print(txt: String):
	$VBoxContainer/ScrollContainer/LabelPrint.text += txt + "\n"
	yield(get_tree().create_timer(0.1), "timeout")
	$VBoxContainer/ScrollContainer.set_v_scroll(1000)


func _parse_command(cmd: String):
	_command_history.append(cmd)
	_command_history_idx = len(_command_history)
	if _command_history_idx >= HISTORY_LENGTH:
		_command_history.remove(0)
		_command_history_idx -= 1
		
	# echo
	_print("< echo " + cmd)


func _on_LineEdit_text_entered(new_text):
	_print("> " + new_text)
	_parse_command(new_text)
	
	$VBoxContainer/HBoxContainer/LineEdit.text = ""
	

func _input(event):
	var load_from_history = false
	
	if event.is_action_pressed("ui_up"):
		_command_history_idx -= 1
		load_from_history = true
	elif event.is_action_pressed("ui_down"):
		_command_history_idx += 1
		load_from_history = true
	elif event.is_action_pressed("ui_cancel"):
		_command_history_idx = 0
		$VBoxContainer/HBoxContainer/LineEdit.text = ""
		
	if load_from_history:
		if _command_history_idx < 0:
			_command_history_idx = len(_command_history) - 1
		elif _command_history_idx > len(_command_history) - 1:
			_command_history_idx = 0
		$VBoxContainer/HBoxContainer/LineEdit.text = _command_history[_command_history_idx]
		
	# move or resize console window
	if _dragging:
		if event is InputEventMouseMotion:
			set_position(rect_position + event.relative)
	elif _resizing:
		if event is InputEventMouseMotion:
			rect_size += event.relative
			$ColorRect.rect_position = rect_size + RESIZE_ICON_OFFSET
			$VBoxContainer.rect_size = rect_size
			$VBoxContainer/ScrollContainer.rect_min_size.y = rect_size.y


func _on_LabelHeader_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
		else:
			_dragging = false


func _on_ColorRect_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			_resizing = true
		else:
			_resizing = false
