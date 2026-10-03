class_name DialogueComponent
extends Node

# This is the class that holds important dialogue for characters
@export var current_dialogue: Dialogue
@export var turns_toward_player_to_speak: bool = true

func set_dialogue(dialogue: Dialogue, turn_toward_player: bool = true):
	current_dialogue = dialogue
	turns_toward_player_to_speak = turn_toward_player

func select_response(response_index: int):
	pass
	# Set new dialogue based on response index if appropriate.
	# If there isn't one, don't do anything
