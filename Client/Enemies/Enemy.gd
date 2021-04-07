extends KinematicBody2D

onready var world = get_node("/root/World")
const INTERPOLATION_OFFSET = 100

func _ready():
	$HealthBarPosition.set_as_toplevel(true)
	$HealthBarPosition/PlayerName.text = Server.player_list[int(name)]["player_name"]

func _physics_process(delta):
	$HealthBarPosition.global_position = global_position

	move()

func move():
	# We render the world 100ms in the past
	var render_time = OS.get_system_time_msecs() - INTERPOLATION_OFFSET
	if world.states.size() < 2: return # if there's not enough states

	# If the enemy isn't in the previous world state - they've just joined, 
	# we have nothing to interoplate with, so we wait for them to send enough states
	if not world.states[0]["player_states"].has(int(name)): return

	# Take the time of the updates from the world state
	var prev_time = world.states[0]["T"]
	var next_time = world.states[1]["T"]
	# Take information about player's position/rotation from player states
	var prev_state = world.states[0]["player_states"][int(name)]
	var next_state = world.states[1]["player_states"][int(name)]
	
	var progress = float(render_time - prev_time) / float(next_time - prev_time)
	progress = clamp(progress, 0, 1)

	var curr_pos = lerp(prev_state["P"], next_state["P"], progress)
	var curr_rot = lerp_angle(prev_state["R"], next_state["R"], progress)
	global_position = curr_pos
	rotation = curr_rot

var current_health = 100
func take_damage(damage):
	if current_health > 0:
		current_health -= damage
		$HealthBarPosition/HealthBar.value = current_health
		if current_health <= 0: 
			queue_free()
