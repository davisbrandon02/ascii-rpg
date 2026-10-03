extends Node

# This class holds all dialogue callbacks.
# Stuff that fires when a dialogue ends

func set_flag(flag_name: String, value: bool):
	if Flags.has(flag_name):
		Flags.flag_name = value

# Callbacks
