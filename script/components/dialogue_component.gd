class_name DialogueComponent
extends Node

# What shows on the dialogue UI
@export var speaker_name: String

# This is the class that holds important dialogue for characters
@export var current_dialogue: Dialogue
@export var turns_toward_player_to_speak: bool = true

func set_dialogue(dialogue: Dialogue, turn_toward_player: bool = true):
	current_dialogue = dialogue
	turns_toward_player_to_speak = turn_toward_player

func select_response(response_index: int):
	if current_dialogue.response_dialogue.has(response_index):
		current_dialogue = current_dialogue.response_dialogue[response_index]
	# Set new dialogue based on response index if appropriate.
	# If there isn't one, don't do anything

func set_speaker_name(name: String):
	# Set the name of the speaker
	# Can be used to reveal names through dialogue, events, etc
	speaker_name = name
