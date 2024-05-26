extends CharacterBody3D

@onready var animated_sprite_2d = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var ray_cast_3d = $RayCast3D
@onready var shoot_sound = $CanvasLayer/shoutSound
@onready var dash_sound = $dashSound
@onready var Camera: Camera3D = $Camera3D

const JUMP_VELOCITY = 7.0

var CameraRotation = Vector2(0.0,0.0)
var MouseSensitivity = 0.002

var Speed = 10.0
var Run_bonus = 10

@export_category("Movement Parameters")
@export var Jump_Peak_Time: float = .5
@export var Jump_Fall_Time: float = .5
@export var Jump_Height: float = 2.0
@export var Jump_Distance: float = 4.0
@export var Jump_Run_Distance = 8.0
var Jump_Velocity: float = 5.0

@export_category("dash")
@export var default_dash_duration = 0.5
@export var dash_speed = 30
@export var dash_max = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var Jump_Gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var Fall_Gravity: float = -5.0


var can_shoot = true
var dead = false
var running = false

var dashing = false
var dash_duration = 0
var dash_number = 0

var jump_count = 0
var jump_max = 3

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(shoot_anim_done)
	$CanvasLayer/DeathScreen/Panel/restart.button_up.connect(restart)
	Establish_Speed()

func Establish_Speed()->void:
	Jump_Gravity = (2*Jump_Height)/ pow(Jump_Peak_Time,2)
	Fall_Gravity = (2*Jump_Height)/ pow(Jump_Fall_Time,2)
	Jump_Velocity = ((Jump_Gravity)*(Jump_Peak_Time))
	Speed = Jump_Distance/(Jump_Peak_Time+Jump_Fall_Time)
	Run_bonus = Jump_Run_Distance/(Jump_Peak_Time+Jump_Fall_Time) - Speed
	
	print("Fall Gravity: ", Fall_Gravity)
	print("Jump Gravity: ", Jump_Gravity)
	print("Jump Velocity: ", Jump_Velocity)
	print("Speed: ", Speed)

func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * MouseSensitivity
		CameraLook(MouseEvent)

func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	if dead:
		return
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if dashing and !dash_sound.playing:
		dash_sound.play()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	if dead:
		return
	# Add the gravity.
	if not is_on_floor() and !dashing:
		if velocity.y>0:
			velocity.y -= Jump_Gravity * delta
		else:
			velocity.y -= Fall_Gravity * delta
	
	if Input.is_action_just_pressed("run") and is_on_floor():
		running = true
		Speed += Run_bonus
	
	if is_on_floor() and !Input.is_action_pressed("run") and running:
		running = false
		Speed -= Run_bonus
		
	
	if is_on_floor():
		jump_count = 0
		dash_number = 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count < jump_max and !dashing :
		velocity.y = Jump_Velocity
		jump_count += 1
		print(jump_count)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * Speed
		velocity.z = direction.z * Speed
	else:
		velocity.x = move_toward(velocity.x, 0, Speed)
		velocity.z = move_toward(velocity.z, 0, Speed)
	
	if dash_duration > 0:
		dash_duration -= delta
	
	if dashing and dash_duration <= 0:
		print('stop dash')
		dashing = false
		Speed -= dash_speed
		dash_sound.stop()
	
	if Input.is_action_just_pressed("dash"):
		if !dashing and dash_number < dash_max :
			print('dash')
			velocity.y = 0
			dashing = true
			Speed += dash_speed
			dash_duration = default_dash_duration
			print(dash_duration)
			dash_number += 1
		elif dashing:
			dashing = false
			Speed -= dash_speed
			dash_sound.stop()

	move_and_slide()

func restart():
	get_tree().reload_current_scene()

func shoot()->void:
	if !can_shoot:
		return
	can_shoot = false
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("kill"):
		ray_cast_3d.get_collider().kill()

func shoot_anim_done()->void:
	can_shoot = true

func kill()->void:
	dead = true
	$CanvasLayer/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	
	transform.basis = Basis()
	Camera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0),-CameraRotation.x) # first rotate in Y
	Camera.rotate_object_local(Vector3(1,0,0), -CameraRotation.y) # then rotate in X
	CameraRotation.y = clamp(CameraRotation.y,-1.5,1.2)
