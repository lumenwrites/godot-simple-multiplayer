extends Node

var client

# Enable dev mode by launching the game with -dev flag or "DEV=true" env variable.
var DEV = OS.get_environment("DEV") or Array(OS.get_cmdline_args()).has("-dev") or true
# save it in a global variable so that Enemy could take a name from this list
# to display it above their healthbar
var player_list = [] 

func _ready():
	# Start the game automatically, without going through the lobby
	if DEV: connect_to_server()


func connect_to_server():
	client = WebSocketClient.new()
	
	# Connect to server, use WSS
	var url = "wss://godotlab.io:6969"
	# Develop locally
	if DEV: url = "ws://127.0.0.1:6969"
	# Connect without WSS
	# url = "ws://178.62.117.12:6969"

	print("Connecting to server: ", url)
	var error = client.connect_to_url(url, PoolStringArray(), true)

	# Connect signals
	client.connect("connection_failed", self, "_connection_failed")
	client.connect("connection_succeeded", self, "_connection_succeeded")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	#net.connect("network_peer_connected", self, "_network_peer_connected")
	#net.connect("network_peer_disconnected", self, "_network_peer_disconnected")
	#net.connect("server_disconnected", self, "_server_disconnected")

	get_tree().set_network_peer(client)

func _process(delta):
	if not client: return
	if (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		client.poll()

func disconnect_from_server(): 
	# client.close_connection()
	client.disconnect_from_host()
	get_tree().set_network_peer(null)
	# Disconnet signals
	client.disconnect("connection_failed", self, "_connection_failed")
	get_tree().disconnect("connected_to_server", self, "_connected_to_server")

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


remote func update_player_list(players):
	# When a new player joins, server updates the players variable, and then
	# tells everyone to run this function
	player_list = players
	get_node("/root/World").receive_player_info(player_list)

remote func despawn_enemy(enemy_id):
	# Cant set it on_ready, becasue it disappears when I reload scene
	get_node("/root/World").despawn_enemy(enemy_id)

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state)

remote func receive_world_state(world_state):
	var world = get_node_or_null("/root/World")
	if not world: return
	world.receive_world_state(world_state)
	# print("Server Time: ", print_time(world_state["T"]), "\tClient Time: ", print_time(client_clock))
	print("Difference: ", world_state["T"] - client_clock)

func send_attack(player_state):
	rpc_id(1, "broadcast_attack", player_state)

remote func receive_attack(player_state):
	get_node("/root/World").receive_attack(player_state)


# CLOCK SYNC
var latency = 0
var client_clock = 0
var decimal_collector : float = 0
var latency_array = []
var delta_latency = 0

func _connection_succeeded():
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	# latency adjustment required to calculate delta_latency
	# check latency every 0.5 seconds, so it's not happening every frame
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "determine_latency")
	add_child(timer)

remote func return_server_time(server_time, initial_client_request_time):
	# Estimate latency, half the time of the roundtrip to server and back
	latency = (OS.get_system_time_msecs() - initial_client_request_time) / 2
	# Server clock has been ticking since it replied with server time
	# So we need to add the latency to get it more accurately
	# This will set the initial client clock, that will be incremented in _physics_process
	client_clock = server_time + latency

func _physics_process(delta):
	# Make the client clock tick to make sure it stays synchronised
	# client_clock is an integer, in milliseconds. Must be integer because it's too big for a float to remain precise
# The latency is constantly shifting. It changes every ms, but you can't check for it every ms, it'd take too much bandwidth and effort	
	# we have caculated average change in latency in return_latency, and now we're taking it into account here
	client_clock += int(delta*1000) + delta_latency
	delta_latency = 0 # reset delta latency once we've taken it into account
	# Collect the remaining decimals that are left after we've turned the float into an integer
	# Turn it from seconds into milliseconds, subtract the ms's we've already added to the client_clock above
	# Once it's higher than 1 - increment the client_clock by 1ms.
	decimal_collector += (delta*1000) - int(delta*1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00

	
func determine_latency():
	# Runs every 0.5 seconds, checks the current latency
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())

remote func return_latency(client_time):
	# Estimate latency, 
	latency_array.append((OS.get_system_time_msecs() - client_time)/2)
	# Calculate average latency over the past 4.5 seconds, and set latency to that average value
	if latency_array.size() == 9:
		var total_latency = 0
		# Packets can get lost, which will lead to extreme latency values
		# sorting and finding the mid value will help us ignore extreme values
		latency_array.sort()
		var mid_point = latency_array[4]
		# iterate back through the loop (??)
		for i in range(latency_array.size()-1,-1,-1):
			# If value is twice the size of mid point, we remove it, ignore it
			# delete it only if > 20ms, otherwise in very fast connections it can get twice the midpoint too easily
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
				print("remove")
				latency_array.remove(i) # remove the extreme value
			else:
				total_latency += latency_array[i]
		# Difference from previous latency to current one
		delta_latency = (total_latency / latency_array.size()) - latency
		# Update the latency we're using with the average latency
		latency = total_latency / latency_array.size()
		print("New Latency ", latency)
		# Start again
		latency_array.clear()
	
func print_time(t):
	t = str(t)
	var a = []
	for c in t:
		a.append(c)
	if a.size() < 4: return
	var time_string = a[-4]+a[-3]+":"+a[-2]+a[-1]
	return time_string
