class_name Dialogue
extends Resource

# This class represents a piece of dialogue
# Can have responses, which can lead to new dialogue
@export_multiline() var current_dialogue: Array[String]
@export_multiline() var responses: Array[String]
@export var response_dialogue: Array[Dialogue]
@export var callback_string:= "" # If it has one, call that when all dialogue finished
@export var reveal_speaker_name:= "" # If it has one, the speaker's name becomes this when this dialogue starts
