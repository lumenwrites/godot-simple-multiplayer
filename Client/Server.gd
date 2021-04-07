extends Node

var net


func _ready():
	# Start the game automatically, without going through the lobby
	connect_to_server()
	# Connect signals
	net.connect("connection_failed", self, "_connection_failed")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	#net.connect("network_peer_connected", self, "_network_peer_connected")
	#net.connect("network_peer_disconnected", self, "_network_peer_disconnected")
	#net.connect("server_disconnected", self, "_server_disconnected")

func connect_to_server():
	print("Connecting to server...")
#	net = NetworkedMultiplayerENet.new()
#	net.create_client(SERVER_IP,PORT)
	net = WebSocketClient.new()
	# Develop locally
	# var url = "ws://127.0.0.1:6969"
	# Connect to server, don't use WSS
	var url = "ws://178.62.117.12:6969"
	# Connect to server, use WSS
	# var url = "wss://178.62.117.12:6969"
	var error = net.connect_to_url(url, PoolStringArray(), true)
	get_tree().set_network_peer(net)

func _process(delta):
	if (net.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || net.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		net.poll()

func disconnect_from_server(): 
	# net.close_connection()
	#net.close()
	net.disconnect_from_host()

func _connection_failed():
	# TODO - this never runs for some reason??
	print("Can't connect to server!")
	get_tree().change_scene("res://UI/Lobby.tscn")
	var lobby = get_node_or_null("/root/Lobby")
	lobby.display_error("Can't connect to server!")

func _connected_to_server():
	print("Successfully connected to server")
	var player_data = Data.player_data
	# temporarily use ids instead of names
	# player_data = { "player_name": str(get_tree().get_network_unique_id()) }
	get_tree().change_scene("res://Environment/World.tscn")
	rpc_id(1, "broadcast_player_list", player_data)

# save it in a global variable so that Enemy could take a name from this list
# to display it above their healthbar
var player_list = [] 
remote func update_player_list(players):
	# When a new player joins, server updates the players variable, and then
	# tells everyone to run this function
	player_list = players
	var HUD = get_node_or_null("/root/World/HUD")
	if HUD: HUD.update_players(player_list)

remote func despawn_enemy(enemy_id):
	# Cant set it on_ready, becasue it disappears when I reload scene
	get_node("/root/World").despawn_enemy(enemy_id)

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state)

remote func receive_world_state(world_state):
	var world = get_node_or_null("/root/World")
	if not world: return
	world.receive_world_state(world_state)

func send_attack(player_state):
	rpc_id(1, "broadcast_attack", player_state)

remote func receive_attack(player_state):
	get_node("/root/World").receive_attack(player_state)




	
