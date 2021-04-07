extends Node2D


export (PackedScene) var bullet
export(AudioStream) var sound

onready var muzzle = $Muzzle
onready var muzzle_flash = $Sprites/MuzzleFlash

func fire():
	muzzle_flash.show()
	muzzle_flash.play()
	$AnimationPlayer.play("fire")
	spawn_bullet()
	$AudioStreamPlayer2D.stream = sound
	$AudioStreamPlayer2D.play()


func spawn_bullet():
	var instance = bullet.instance()
	var scene_root = get_node("/root/World")
	instance.global_position = $Muzzle.global_position
	instance.parent = get_parent()
	scene_root.add_child(instance)


func _on_MuzzleFlash_animation_finished():
	muzzle_flash.hide()
