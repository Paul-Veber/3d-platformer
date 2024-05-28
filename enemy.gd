extends CharacterBody3D

@onready var animated_sprite_3d = $AnimatedSprite3D

@export var move_speed = 2.0
@export var attack_range = 2.0

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("player")
var dead = false

const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	
	if dead:
		return

	if player == null:
		return
	
	var dir = player.global_position - global_position
	dir.y = 0.0
	dir = dir.normalized()
	
	velocity = dir * move_speed
	move_and_slide()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

func kill():
	dead = true
	$DeathSound.play()
	animated_sprite_3d.play("death")
	$CollisionShape3D.disabled = true

