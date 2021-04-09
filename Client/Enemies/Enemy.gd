extends KinematicBody2D

onready var world = get_node("/root/World")
onready var INTERPOLATION_OFFSET = world.INTERPOLATION_OFFSET
var is_extrapolating = false
var is_rubberbanding = false
var rubberband_state_time = 0
var rubberband_arrival_time = 0
var rubberband_start_position = Vector2()
var rubberband_start_rotation = 0
var progress

func _ready():
	$HealthBarPosition.set_as_toplevel(true)
	$VisualizerRed.set_as_toplevel(true)
	if Server.player_list.has(int(name)): # sometimes it crashes here, not sure why
		$HealthBarPosition/PlayerName.text = Server.player_list[int(name)]["player_name"]

func _physics_process(delta):
	$HealthBarPosition.global_position = global_position
	# move_simple(delta)
	move()
	
	# Visualize the most recent known position, without offset delay
	if not world.states[-1]["player_states"].has(int(name)): return
	$VisualizerRed.global_position = world.states[-1]["player_states"][int(name)]["P"]

func move_simple(delta):
	if not world.states[-1]["player_states"].has(int(name)): return
	# most recent known state
	var state = world.states[-1]["player_states"][int(name)]
	print(delta)
	global_position = lerp(global_position, state["P"], 0.1)
	rotation = lerp_angle(rotation, state["R"], 0.1)

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

	if next_time >= render_time and is_extrapolating:
		print("Was extrapolating, new state just arrived, start rubberbanding to it")
		is_extrapolating = false
		# Remember rubberbanding time. I will lerp to it until it slides into the past
		rubberband_state_time = next_time
		# Remember my position/rotation and time at the moment a rubberbanding state arrives
		rubberband_arrival_time = OS.get_system_time_msecs() - INTERPOLATION_OFFSET
		rubberband_start_position = global_position
		rubberband_start_rotation = rotation

	is_rubberbanding = rubberband_state_time >= render_time
	if is_rubberbanding:
		# time_since_rubberband_state_has_arrived / rubberband_duration
		var rubberband_progress = float(render_time - rubberband_arrival_time) / float(rubberband_state_time - rubberband_arrival_time)
		global_position = lerp(rubberband_start_position, next_state["P"], rubberband_progress)
		rotation = lerp_angle(rubberband_start_rotation, next_state["R"], rubberband_progress)
		# print("Rubberbanding ", rubberband_progress)
		return
	
	var progress = float(render_time - prev_time) / float(next_time - prev_time)
	if progress > 1: 
		print("Most recent known state slid into the past, before render time")
		progress = 1
		is_extrapolating = true

	global_position = lerp(prev_state["P"], next_state["P"], progress)
	rotation = lerp_angle(prev_state["R"], next_state["R"], progress)



func print_time(t):
	t = str(t)
	var a = []
	for c in t:
		a.append(c)
	var time_string = a[8]+a[9]+":"+a[10]+a[11]
	return time_string
	# print(time_string)
	# for c in a.slice(-4,-1): time_string += c


var current_health = 100
func take_damage(damage):
	if current_health > 0:
		current_health -= damage
		$HealthBarPosition/HealthBar.value = current_health
		if current_health <= 0: 
			queue_free()
