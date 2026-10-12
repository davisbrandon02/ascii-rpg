class_name Item
extends Resource

enum HAND {
	RIGHT,
	LEFT,
	BOTH, # Takes up both hands, model goes in the right hand
}

# Data for anything that can go in an inventory
@export var display_name: String
@export_multiline() var description: String
@export var max_stack: int = 1 # How many fit in one slot
@export var icon: Texture2D # Not shown yet, slots use text for now
@export var hand: HAND = HAND.RIGHT
@export var held_scene: PackedScene # Model shown in the player's hand, can be empty
@export var hold_animation: String # Plays while equipped
@export var use_animation: String # Plays when used, then goes back to hold_animation
@export var ammo: Item # What this item fires, if anything (bow/crossbow -> arrows)
