extends Node

var USE_SSL = true
var server = WebSocketServer.new() # NetworkedMultiplayerENet.new()
const PORT = 6969
const MAX_PLAYERS = 20

func _ready():
	start_server()
	
func start_server():
	# net.create_server(PORT, MAX_PLAYERS)
	if USE_SSL:
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
	print("Broadcast player list ", player_list)
	# Once player is _connected_to_server, they'll send me their info(name)
	# so that I can send it to everyone and update their player lists
	var player_id = get_tree().get_rpc_sender_id() 
	player_list[player_id] = player_data
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

# physics fps is set to 20 in project settings so that it doesn't update too often
func _physics_process(delta):
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







