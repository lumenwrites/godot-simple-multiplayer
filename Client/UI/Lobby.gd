extends Control

onready var player_name = $CenterContainer/VBoxContainer/PlayerName
onready var color_picker = $CenterContainer/VBoxContainer/ColorPicker
onready var error = $CenterContainer/VBoxContainer/Error

func _ready():
	player_name.placeholder_text = Data.player_data["player_name"]
	color_picker.color = Data.player_data["color"]
	error.text = ""

func _on_StartGame_pressed():
	Server.connect_to_server()


func _on_PlayerName_text_changed(new_text):
	Data.player_data["player_name"] = new_text
	Data.save_data()


func _on_ColorPicker_color_changed(color):
	print(color.to_html())
	Data.player_data["color"] = color.to_html()
	Data.save_data()

func display_error(text):
	error.text = text

