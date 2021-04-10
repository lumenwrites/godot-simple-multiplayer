extends KinematicBody2D

class_name Player

onready var HUD = get_node("/root/World/HUD")

var speed = 100
var friction = 0.85
var vel = Vector2()

func _ready():
	Input.set_custom_mouse_cursor(
		load("res://assets/art/icons/crossair_black.png"),
		Input.CURSOR_ARROW, Vector2(16,16)
	)
	
func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("Q"):
		auto_move = !auto_move

var auto_move = false
var dir = Vector2.RIGHT
func _physics_process(delta):
	if auto_move:
		vel += dir*speed
		vel *= friction
		vel = move_and_slide(vel)
		if global_position.x > 350:
			dir = Vector2.LEFT
		if global_position.x < 0:
			dir = Vector2.RIGHT
		return

	move(delta)

	if Input.is_action_pressed("fire"):
		$Weapon.fire()

func move(delta):
	# Walk
	var dir = Vector2()
	dir.x += Input.get_action_strength("right") - Input.get_action_strength("left")
	dir.y += Input.get_action_strength("down") - Input.get_action_strength("up")
	dir = dir.normalized()
	vel += dir*speed
	vel *= friction
	vel = move_and_slide(vel)

	# Aim (has to be after move, otherwise jitter) 
	# [TODO] Lag/jitter still happens anyway somehow??
	look_at(get_global_mouse_position())

func _on_tick_rate_timeout():
	# Send player states every 0.03s, instead of 60 times per second (0.016).
	send_player_state()

func send_player_state():
	var player_state = {
		"T": Server.client_clock, # OS.get_system_time_msecs(),
		"P": get_global_position(),
		"R": rotation,
		"V": vel
	}
	Server.send_player_state(player_state)

var current_health = 100
var dead = false
func take_damage(damage):
	if current_health > 0:
		current_health -= damage
		HUD.get_node("HealthBar").value = current_health
		if current_health <= 0: 
			set_physics_process(false) # make sure I won't try to send_player_state() anymore
			Server.disconnect_from_server() # leave the game
			get_tree().change_scene("res://UI/Lobby.tscn") # kicked out to the lobby
			print("You lost!")


