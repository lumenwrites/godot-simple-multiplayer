extends Node

const SAVEGAME = "user://savegame.json"

var player_data = {}

func _ready():
	get_data()

func save_data():
	var file = File.new()
	file.open(SAVEGAME, File.WRITE)
	file.store_line(to_json(player_data))

func get_data():
	var file = File.new()
	
	if not file.file_exists(SAVEGAME):
		player_data = {"player_name": "Anonymous"}
		save_data()

	file.open(SAVEGAME, File.READ)
	var content = file.get_as_text()
	var data = parse_json(content)
	player_data = data
	file.close()
	return data
	

