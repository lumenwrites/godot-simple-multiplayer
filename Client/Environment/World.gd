extends Node2D

var ENEMY = preload("res://Enemies/Enemy.tscn")
onready var enemies = $Enemies

const INTERPOLATION_OFFSET = 100
var last_world_state_t = 0
var states = []

func receive_world_state(world_state):
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
			spawn_enemy(enemy_id, world_state["player_states"][enemy_id]["P"])
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

func receive_attack(player_state):
	var my_id = get_tree().get_network_unique_id()
	if player_state["ID"] == my_id: return # if I'm the attacker - ignore

	var attacker = get_node_or_null("/root/World/Enemies/" + str(player_state["ID"]))
	if attacker: # check it exists, just in case someone attacks and disconnects?
		# Update the position/rotation of the attacker
		attacker.global_position = player_state["P"]
		attacker.rotation = player_state["R"]
		attacker.get_node("EnemyWeapon").fire()
	else:
		print("Attacker not found.")

# Whenever a new player connects to server, this function is called on all the peers
func spawn_enemy(enemy_id, spawn_position):
	var instance = ENEMY.instance()
	instance.position = spawn_position
	instance.name = str(enemy_id)
	enemies.add_child(instance, true)

