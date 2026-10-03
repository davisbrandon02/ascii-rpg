extends Node

# This class holds all dialogue callbacks.
# Stuff that fires when a dialogue ends

func set_flag(flag_name: String, value: bool):
	if flag_name in Flags:
		Flags.set(flag_name, value)

# Callbacks
