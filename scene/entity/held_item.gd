class_name HeldItem
extends Node3D

# The item the player has in their hand, attached to a hand attach point
var item: Item

func setup(new_item: Item) -> void:
	item = new_item
	if item.held_scene:
		add_child(item.held_scene.instantiate())
