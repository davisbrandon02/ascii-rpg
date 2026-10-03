class_name NPC
extends CharacterBody3D

# An NPC is any character that can move around and do stuff that isn't the player
# Some NPCs can have dialogue that can be initiated by walking up and pressing E


@export var turn_duration: float = 0.4

# Facing before a conversation, so we can turn back when it's over
var original_rotation_y: float
var turn_tween: Tween

# This class is mostly used to get components
func get_component(type):
	if type == DialogueComponent:
		return %DialogueComponent

func interact(interactor: Node3D):
	var dialogue_component: DialogueComponent = get_component(DialogueComponent)
	if not dialogue_component.current_dialogue:
		return

	original_rotation_y = rotation.y
	if dialogue_component.turns_toward_player_to_speak:
		# Turn toward the player on the Y axis only, then start talking
		var to_interactor: Vector3 = interactor.global_position - global_position
		var target_y: float = atan2(-to_interactor.x, -to_interactor.z)
		_turn_to(target_y)
		turn_tween.tween_callback(set_state.bind(STATE.TALKING))
	else:
		set_state(STATE.TALKING)

	DialogueUI.instance.start_dialogue(dialogue_component, _on_dialogue_finished)

func _on_dialogue_finished():
	set_state(STATE.IDLE)
	_turn_to(original_rotation_y)

func _turn_to(target_y: float):
	# Stop any turn already in progress, then take the shortest way around
	if turn_tween:
		turn_tween.kill()
	var end_y: float = rotation.y + wrapf(target_y - rotation.y, -PI, PI)
	turn_tween = create_tween()
	turn_tween.tween_property(self, "rotation:y", end_y, turn_duration)

enum STATE {
	IDLE,
	TALKING,
	WALKING,
	RUNNING,
	FALLING,
	MELEE_ATTACKING,
	RANGED_TARGETTING,
}
var state: STATE = STATE.IDLE
func set_state(s: STATE):
	state = s
	
	# Set animation based on state
	match state:
		STATE.IDLE:
			%AnimationPlayer.play("IdleStanding", -1, 1.0)
		STATE.WALKING:
			%AnimationPlayer.play("Walk", -1, 1.0)
		STATE.RUNNING:
			%AnimationPlayer.play("Walk", -1, 2.0)  # Don't have a run yet
		STATE.TALKING:
			%AnimationPlayer.play("talking", -1, 1.0)
		STATE.FALLING:
			%AnimationPlayer.play("Walk", -1, 1.0) # Don't have a fall yet
		STATE.MELEE_ATTACKING:
			pass
			# This will be based on type of weapon equipped
			# Swords will use swing, spears will use stab, etc
		STATE.RANGED_TARGETTING:
			pass
			# Same as melee attacking
			# Bows will use draw, crossbows will use shoulder aim
