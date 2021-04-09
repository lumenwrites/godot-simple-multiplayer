extends Node2D

var PLAYER = preload("res://Player/Player.tscn")
var ENEMY = preload("res://Enemies/Enemy.tscn")
onready var enemies = $Enemies
onready var HUD = $HUD

const INTERPOLATION_OFFSET = 200
var last_world_state_t = 0
var states = []

var number_of_packets = 0

func receive_player_info(player_list):
	HUD.update_players(player_list)
	var my_id = get_tree().get_network_unique_id()
	if not player_list.has(my_id): return # haven't broadcasted my info yet
	if has_node("Player"): return # already spawned myself before
	# Spawn Myself
	var player_info = player_list[my_id]
	var instance = PLAYER.instance()
	# Set my color
	instance.get_node("Body").modulate = player_info["color"]
	# Choose a spawn based on joining order
	var spawn_number = player_info["join_order"] % 4
	var spawn = $SpawnPositions.get_children()[spawn_number]
	instance.global_position = spawn.global_position
	add_child(instance, true)
	print("Spawn myself ", spawn_number)

func receive_world_state(world_state):
	# lose 70% of packets
	# if rand_range(0,1) < 0.7: return 
	# lose 4 out of 5 packets
	#number_of_packets += 1
	#if number_of_packets %5 != 0: return
	# Ignore old out of order packets
	if world_state["T"] < last_world_state_t: return
	last_world_state_t = world_state["T"]
	# Remove myself from the world state
	var my_id = get_tree().get_network_unique_id()
	world_state["player_states"].erase(my_id)
	# Add to the state buffer
	states.append(world_state)
	
	# Spawn enemy if he doesn't already exist.
	for enemy_id in world_state["player_states"].keys():
		if not enemies.has_node(str(enemy_id)):
			# Spawn Enemy
			var instance = ENEMY.instance()
			instance.position = world_state["player_states"][enemy_id]["P"]
			instance.name = str(enemy_id)
			enemies.add_child(instance, true)
	# If enemy no longer exists in the world state - despawn it
	for enemy in enemies.get_children():
		if not world_state["player_states"].has(int(enemy.name)):
			enemy.queue_free()

func _physics_process(delta):
	# We render the world 100ms in the past
	var render_time = OS.get_system_time_msecs() - INTERPOLATION_OFFSET
	if states.size() < 2: return # if there's not enough states
	# Once a state slides past the render time, it becomes the prev_state (state[0])
	# And the next upcoming state becomes next_state (state[1])
	while states.size() > 2 and render_time > states[1]["T"]: 
		states.remove(0)
	# print(states.size())

func receive_attack(player_state):
	var my_id = get_tree().get_network_unique_id()
	if player_state["ID"] == my_id: return # if I'm the attacker - ignore

	var attacker = get_node_or_null("/root/World/Enemies/" + str(player_state["ID"]))
	if attacker: # check it exists, just in case someone attacks and disconnects?
		# Update the position/rotation of the attacker
		yield(get_tree().create_timer(float(INTERPOLATION_OFFSET)/1000), "timeout")
		attacker.global_position = player_state["P"]
		attacker.rotation = player_state["R"]
		attacker.get_node("EnemyWeapon").fire()
	else:
		print("Attacker not found.")


