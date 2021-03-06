extends Node

var PROD = OS.get_environment("PROD") or Array(OS.get_cmdline_args()).has("-prod")
var server = WebSocketServer.new() # NetworkedMultiplayerENet.new()
const PORT = 6969
const MAX_PLAYERS = 20

func _ready():
	start_server()
	
func start_server():
	if PROD:
		print("Using SSL")
		server.private_key = load("res://HTTPSKeys/privkey.key")
		server.ssl_certificate = load("res://HTTPSKeys/certificate.crt")

	server.listen(PORT, PoolStringArray(), true)

	get_tree().set_network_peer(server)
	print("Server Started")
	# When clients connect/disconnect these signals fire
	server.connect("peer_connected", self, "_peer_connected")
	server.connect("peer_disconnected", self, "_peer_disconnected")

func _process(delta):
	if server.is_listening(): 
		server.poll()

func _peer_connected(player_id):
	print("User " + str(player_id) + " connected")

func _peer_disconnected(player_id):
	print("User " + str(player_id) + " disconnected")
	if player_states.has(player_id):
		player_states.erase(player_id)
		player_list.erase(player_id)
		rpc_id(0, "update_player_list", player_list)

remote func broadcast_player_list(player_data):
	# Once player is _connected_to_server, they'll send me their info(name)
	# so that I can send it to everyone and update their player lists
	var player_id = get_tree().get_rpc_sender_id() 
	player_data["join_order"] = player_list.size()
	player_list[player_id] = player_data
	print("Broadcast player list ", player_list)
	rpc_id(0, "update_player_list", player_list)

# separate variable containing only their names, so that I don't have to
# send player's name along with his state every frame
var player_list = {} 
var player_states = {}
var world_state = {
	"T":0,
	"player_states": {}
}

remote func receive_player_state(player_state):
	var player_id = get_tree().get_rpc_sender_id() 
	# If packets arrived out of order, and the new player_state is older than the old one, we ignore it
	if player_states.has(player_id) and player_state["T"] < player_states[player_id]["T"]: return
	# Create or update player state with the latest one
	player_states[player_id] = player_state


func _on_tick_rate_timeout():
	# Broadcast world state every time the timer times out (every 0.05s. That's 20fps).
	world_state["player_states"] = player_states.duplicate(true) # Deep copy
	# Erase timestamps, helps to make packets as small as possible
	for player_id in world_state["player_states"].keys(): 
		world_state["player_states"][player_id].erase("T")
	world_state["T"] = OS.get_system_time_msecs()
	# Broadcast world states
	rpc_unreliable_id(0, "receive_world_state", world_state)

remote func broadcast_attack(player_state):
	var player_id = get_tree().get_rpc_sender_id() 
	player_state["ID"] = player_id
	rpc_id(0, "receive_attack", player_state)

# CLOCK SYNC
remote func fetch_server_time(initial_client_request_time):
	var player_id = get_tree().get_rpc_sender_id() 
	# Return current server time, and client_time at the moment of the request
	rpc_id(player_id, "return_server_time", OS.get_system_time_msecs(), initial_client_request_time)

remote func determine_latency(client_time):
	# Client runs it every 0.5 seconds to determine latency
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "return_latency", client_time)



