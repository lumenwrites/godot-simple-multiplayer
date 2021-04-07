extends Node2D


export (PackedScene) var bullet
export(AudioStream) var sound

export var fire_rate = 0.12
var can_fire = true

onready var muzzle = $Muzzle
onready var muzzle_flash = $Sprites/MuzzleFlash

func fire():
	if can_fire:
		muzzle_flash.show()
		muzzle_flash.play()
		$AnimationPlayer.play("fire")
		spawn_bullet()
		$AudioStreamPlayer.stream = sound
		# $AudioStreamPlayer.play()

		send_attack()
		
		can_fire = false
		yield(get_tree().create_timer(fire_rate), "timeout") # wait until timer times out
		can_fire = true

func spawn_bullet():
	var instance = bullet.instance()
	var scene_root = get_node("/root/World")
	instance.global_position = $Muzzle.global_position
	instance.parent = get_parent()
	scene_root.add_child(instance)


func send_attack():
	var player_state = {
		"T": OS.get_system_time_msecs(),
		"P": get_parent().get_global_position(),
		"R": get_parent().rotation
	}
	Server.send_attack(player_state)

func _on_MuzzleFlash_animation_finished():
	muzzle_flash.hide()
