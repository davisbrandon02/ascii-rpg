class_name DialogueComponent
extends Node

# What shows on the dialogue UI
@export var speaker_name: String

# This is the class that holds important dialogue for characters
@export var current_dialogue: Dialogue
@export var turns_toward_player_to_speak: bool = true
@export var turn_duration: float = 0.4

# The NPC that owns this component
@onready var npc: NPC = owner

# Facing before a conversation, so we can turn back when it's over
var original_rotation_y: float
var turn_tween: Tween

func start_dialogue(interactor: Node3D):
	if not current_dialogue:
		return

	original_rotation_y = npc.rotation.y
	if turns_toward_player_to_speak:
		# Turn toward the player on the Y axis only, then start talking
		var to_interactor: Vector3 = interactor.global_position - npc.global_position
		var target_y: float = atan2(-to_interactor.x, -to_interactor.z)
		_turn_to(target_y)
		turn_tween.tween_callback(npc.set_state.bind(NPC.STATE.TALKING))
	else:
		npc.set_state(NPC.STATE.TALKING)

	DialogueUI.instance.start_dialogue(self, _on_dialogue_finished)

func _on_dialogue_finished():
	npc.set_state(NPC.STATE.IDLE)
	_turn_to(original_rotation_y)

func _turn_to(target_y: float):
	# Stop any turn already in progress, then take the shortest way around
	if turn_tween:
		turn_tween.kill()
	var end_y: float = npc.rotation.y + wrapf(target_y - npc.rotation.y, -PI, PI)
	turn_tween = create_tween()
	turn_tween.tween_property(npc, "rotation:y", end_y, turn_duration)

func set_dialogue(dialogue: Dialogue, turn_toward_player: bool = true):
	current_dialogue = dialogue
	turns_toward_player_to_speak = turn_toward_player

func select_response(response_index: int):
	if response_index < current_dialogue.response_dialogue.size():
		current_dialogue = current_dialogue.response_dialogue[response_index]
	# Set new dialogue based on response index if appropriate.
	# If there isn't one, don't do anything

func set_speaker_name(name: String):
	# Set the name of the speaker
	# Can be used to reveal names through dialogue, events, etc
	speaker_name = name
