extends CanvasLayer

func _ready():
	$PlayerList.clear()
	
func update_players(player_list):
	$PlayerList.clear()
	for player_id in player_list:
		var player_name = player_list[player_id]["player_name"]
		$PlayerList.add_item(player_name, null, false)
