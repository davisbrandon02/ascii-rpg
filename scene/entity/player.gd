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
@onready var inventory: InventoryComponent = $InventoryComponent
@onready var right_hand: Node3D = %RightHandAttachPoint
@onready var left_hand: Node3D = %LeftHandAttachPoint

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching: bool = false
var right_held_item: HeldItem
var left_held_item: HeldItem

# Singleton so that its position can always be found easily by AI
static var instance: Player
func _ready() -> void:
	instance = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	InventoryUI.instance.setup(inventory)
	inventory.equipped_changed.connect(_update_held_items)
	_update_held_items()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))

	if event.is_action_pressed("pause_menu"):
		_toggle_mouse_capture()

	if event.is_action_pressed("interact") and not DialogueUI.instance.is_open:
		interact()

	if event.is_action_pressed("inventory") and not DialogueUI.instance.is_open:
		_toggle_inventory()

	for i in InventoryComponent.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			inventory.toggle_equip(i)

	# Use whatever is in each hand (two handed items use the right)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not DialogueUI.instance.is_open:
		if event.is_action_pressed("use_right"):
			_use_item(right_held_item, %RightArmAnimationPlayer)
		if event.is_action_pressed("use_left"):
			_use_item(left_held_item, %LeftArmAnimationPlayer)

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_inventory() -> void:
	InventoryUI.instance.toggle()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if InventoryUI.instance.is_open else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Freeze movement while talking, but still allow looking around
	var in_dialogue: bool = DialogueUI.instance.is_open
	# Same for the inventory
	var in_menu: bool = in_dialogue or InventoryUI.instance.is_open

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not in_menu:
		velocity.y = jump_velocity

	if Input.is_action_just_pressed("crouch") and not in_menu:
		_set_crouching(not is_crouching)

	var input_dir: Vector2 = Vector2.ZERO
	if not in_menu:
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
	%InteractLbl.visible = get_interactible() != null and not in_menu

func _update_footsteps() -> void:
	var is_walking: bool = is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.1
	if is_walking and not footstep_sound.playing:
		footstep_sound.play()
	elif not is_walking and footstep_sound.playing:
		footstep_sound.stop()

func _set_crouching(crouching: bool) -> void:
	is_crouching = crouching
	camera.position.y = crouching_camera_height if crouching else standing_camera_height

func _update_held_items() -> void:
	right_held_item = _update_hand(right_held_item, inventory.get_right_hand_item(), right_hand, %RightArmMesh, %RightArmAnimationPlayer)
	left_held_item = _update_hand(left_held_item, inventory.get_left_hand_item(), left_hand, %LeftArmMesh, %LeftArmAnimationPlayer)
	# Two handed items need both arms
	var right_item: Item = inventory.get_right_hand_item()
	if right_item and right_item.hand == Item.HAND.BOTH:
		%LeftArmMesh.visible = true

func _update_hand(held_item: HeldItem, item: Item, attach_point: Node3D, arm_mesh: MeshInstance3D, anim_player: AnimationPlayer) -> HeldItem:
	# Swap out the held item in one hand, returns the new one
	# Arm is hidden when the hand is empty
	arm_mesh.visible = item != null
	if held_item and held_item.item == item:
		return held_item
	if held_item:
		held_item.queue_free()
		held_item = null

	if item:
		held_item = HeldItem.new()
		held_item.setup(item)
		attach_point.add_child(held_item)
		if item.hold_animation:
			anim_player.play(item.hold_animation)
		else:
			anim_player.stop()
	else:
		anim_player.stop()
	return held_item

func _use_item(held_item: HeldItem, anim_player: AnimationPlayer) -> void:
	# Just the animation for now, goes back to holding when it's done
	if held_item == null or not held_item.item.use_animation:
		return
	anim_player.play(held_item.item.use_animation)
	if held_item.item.hold_animation:
		anim_player.queue(held_item.item.hold_animation)

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
