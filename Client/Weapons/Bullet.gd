extends Area2D

class_name Bullet

export (int) var speed = 800
export (int) var damage = 20
export (float) var lifespan = 0.5
var vel = Vector2()
var parent # player that fired the bullet

func _ready():
	# Fire the bullet where the ship is pointing at
	var direction = parent.global_transform.x
	rotation = direction.angle()
	vel = direction * speed # + parent.vel
	#yield(get_tree().create_timer(lifespan), "timeout")
	#queue_free()


func _physics_process(delta):
	position += vel * delta
	$BulletTrail.scale.x = lerp($BulletTrail.scale.x, 0.7, 0.1)

func _on_Bullet_body_entered(body):
	if body == parent: return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
