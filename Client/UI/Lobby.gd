extends Control

onready var player_name = $CenterContainer/VBoxContainer/PlayerName
onready var error = $CenterContainer/VBoxContainer/Error

func _ready():
	player_name.placeholder_text = Data.player_data["player_name"]
	error.text = ""

func _on_StartGame_pressed():
	Server.connect_to_server()

func _on_PlayerName_text_changed(new_text):
	Data.player_data["player_name"] = new_text
	Data.save_data()

func display_error(text):
	error.text = text
