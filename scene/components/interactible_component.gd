class_name InteractibleComponent
extends Node

# Handles whenever a node is interacted with.
# Mostly just delegates to other components.

@export var collider: CollisionShape3D

enum TYPE {
	DIALOGUE,
	LOOT, # open inventory transfer window (not in yet)
	TRAVEL, 
}
