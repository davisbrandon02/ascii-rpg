class_name DialogueUI
extends Control

# Singleton pattern for all UIs
static var instance: DialogueUI
func _ready() -> void:
	instance = self

func start_dialogue(dialogue: Dialogue, speaker_name: String = ""):
	# Display speaker name label if there is one and it isn't empty
	
	pass

func display_text():
	# Add the dialogue to the DialogueTextLabel one letter at a time
	# It should autowrap
	# If the player clicks during this, it should auto finish that line.
	# once done with a line, it should wait for the player to click again
	# before going to the next line
	pass
