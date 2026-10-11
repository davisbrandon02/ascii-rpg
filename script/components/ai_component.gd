class_name AIComponent
extends Node

# Handles decisions for the AI

# If player enters detection radius, they will enter attack mode
@export var hostile: bool = false
@export var detection_range: float = 10.0

enum AI_STATE {
	# sit in place
	IDLE,
	# stand for a while, pick a new spot, walk there, wait, repeat
	WANDER,
	# Move toward player and attack them when in range
	ATTACK,
}
@export var state: AI_STATE

const AI_STATE_DEBUG_LABELS = {
	AI_STATE.IDLE: "...",
	AI_STATE.WANDER: "->",
	AI_STATE.ATTACK: "!",
}

@export var wander_wait_time:= 10 # seconds to wait before picking new spot
@export var wander_radius:= 10

func _process(delta: float) -> void:
	pass
