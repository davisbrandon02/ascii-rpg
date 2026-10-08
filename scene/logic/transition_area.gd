class_name TransitionArea
extends Area3D

# An area3d that, when crossed by the player's InteractRaycast,
# allows the player to travel to a new map.
# Ex: doors into buildings, connnections between exterior maps, etc

@export var scene_to_load: PackedScene

# If left at Vector3.ZERO, leave player node at default player pos for that map
@export var position_in_loaded_scene: Vector3 = Vector3.ZERO
