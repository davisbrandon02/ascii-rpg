class_name NPC
extends CharacterBody3D

# An NPC is any character that can move around and do stuff that isn't the player
# Some NPCs can have dialogue that can be initiated by walking up and pressing E

# Which face the head mesh uses
@export var face_to_use: Texture

func _ready() -> void:
	pass

# This class is mostly used to get components
func get_component(type):
	if type == DialogueComponent:
		return %DialogueComponent

# The player's raycast hits the NPC body, so forward to the component that handles it
func interact(interactor: Node3D):
	get_component(DialogueComponent).start_dialogue(interactor)

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
