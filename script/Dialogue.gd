class_name Dialogue
extends Resource

# This class represents a piece of dialogue
# Can have responses, which can lead to new dialogue
@export_multiline() var current_dialogue: Array[String]
@export_multiline() var responses: Array[String]
@export var response_dialogue: Array[Dialogue]
