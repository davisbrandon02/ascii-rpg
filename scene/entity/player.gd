class_name Player
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var pitch_limit_deg: float = 89.0

@export var standing_camera_height: float = .8
@export var crouching_camera_height: float = 0.5

@onready var camera: Camera3D = $Camera3D
@onready var footstep_sound: AudioStreamPlayer3D = %FootstepSoundEffect
@onready var interaction_raycast: RayCast3D = $InteractionRaycast

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching: bool = false

# Singleton so that its position can always be found easily by AI
static var instance: Player
func _ready() -> void:
	instance = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))

	if event.is_action_pressed("pause_menu"):
		_toggle_mouse_capture()

	if event.is_action_pressed("interact") and not DialogueUI.instance.is_open:
		interact()

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Freeze movement while talking, but still allow looking around
	var in_dialogue: bool = DialogueUI.instance.is_open

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not in_dialogue:
		velocity.y = jump_velocity

	if Input.is_action_just_pressed("crouch") and not in_dialogue:
		_set_crouching(not is_crouching)

	var input_dir: Vector2 = Vector2.ZERO
	if not in_dialogue:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed: float = crouch_speed if is_crouching else walk_speed

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	_update_footsteps()
	%InteractLbl.visible = get_interactible() != null and not in_dialogue

func _update_footsteps() -> void:
	var is_walking: bool = is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.1
	if is_walking and not footstep_sound.playing:
		footstep_sound.play()
	elif not is_walking and footstep_sound.playing:
		footstep_sound.stop()

func _set_crouching(crouching: bool) -> void:
	is_crouching = crouching
	camera.position.y = crouching_camera_height if crouching else standing_camera_height

func get_interactible():
	# Get whatever interactible is colliding with raycast
	# Anything with an interact() method counts
	var collider: Object = interaction_raycast.get_collider()
	if collider and collider.has_method("interact"):
		return collider
	return null

func interact():
	# Activate whatever the interactible is
	var interactible = get_interactible()
	if interactible:
		interactible.interact(self)
