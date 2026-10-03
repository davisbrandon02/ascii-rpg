class_name DialogueUI
extends Control

@export var characters_per_second: float = 40.0
@export var scroll_wheel_step: float = 40.0

# Template button that gets duplicated for each response
@onready var sample_choice_button: Button = %DialogueResponseVboxContainer.get_node("SampleDialogueChoiceBtn")

var is_open: bool = false
var choosing_response: bool = false
var dialogue_component: DialogueComponent
var dialogue: Dialogue
var line_index: int = 0
var on_finished: Callable
var typing_tween: Tween

# Singleton pattern for all UIs
static var instance: DialogueUI
func _ready() -> void:
	instance = self

func start_dialogue(new_dialogue_component: DialogueComponent, finished_callback: Callable = Callable()):
	dialogue_component = new_dialogue_component
	on_finished = finished_callback
	is_open = true
	visible = true

	_update_speaker_name()
	_start_lines()

func _update_speaker_name():
	# Display speaker name label if there is one and it isn't empty
	var speaker_name: String = dialogue_component.speaker_name
	%SpeakerNameLbl.text = speaker_name
	%SpeakerNameLbl.visible = speaker_name != ""

func _start_lines():
	dialogue = dialogue_component.current_dialogue
	line_index = 0

	# Some dialogue reveals who the speaker is, and it sticks from then on
	if dialogue.reveal_speaker_name != "":
		dialogue_component.set_speaker_name(dialogue.reveal_speaker_name)
		_update_speaker_name()

	# Empty dialogue skips straight to its callback/responses
	if dialogue.current_dialogue.is_empty():
		_end_of_lines()
	else:
		display_text()

func display_text():
	# Add the dialogue to the DialogueTextLabel one letter at a time
	# Autowraps through the RichTextLabel's default autowrap mode
	var line: String = dialogue.current_dialogue[line_index]
	%DialogueTextLabel.text = line
	%DialogueTextLabel.visible_characters = 0

	typing_tween = create_tween()
	typing_tween.tween_property(%DialogueTextLabel, "visible_characters", line.length(), line.length() / characters_per_second)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	# Number keys pick a response
	if choosing_response:
		if event is InputEventKey and event.pressed and not event.echo:
			var response_index: int = event.keycode - KEY_1
			if response_index >= 0 and response_index < 9:
				get_viewport().set_input_as_handled()
				_select_response(response_index)
				return

	# Scroll wheel moves through long lines once they're done typing
	# Mouse is captured, so the label never gets wheel events on its own
	var is_typing: bool = typing_tween and typing_tween.is_running()
	if event is InputEventMouseButton and event.pressed and not choosing_response and not is_typing:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()
			var direction: float = -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			%DialogueTextLabel.get_v_scroll_bar().value += direction * scroll_wheel_step
			return

	if not event.is_action_pressed("advance_dialogue"):
		return

	# Eat the event so the same E press doesn't reach the player and restart the conversation
	get_viewport().set_input_as_handled()

	# Advancing does nothing while picking a response
	if choosing_response:
		return

	# If the player clicks while typing, auto finish that line
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		%DialogueTextLabel.visible_characters = -1
		return

	# Once done with a line, go to the next line on click
	line_index += 1
	if line_index < dialogue.current_dialogue.size():
		display_text()
	else:
		_end_of_lines()

func _end_of_lines():
	# Each dialogue's callback fires when its own lines finish
	if dialogue.callback_string != "" and DialogueCallbacks.has_method(dialogue.callback_string):
		DialogueCallbacks.call(dialogue.callback_string)

	if dialogue.responses.is_empty():
		_finish_dialogue()
	else:
		_show_responses()

func _show_responses():
	choosing_response = true

	# Clear buttons from the last set of responses, keeping the sample as a template
	for child in %DialogueResponseVboxContainer.get_children():
		if child != sample_choice_button:
			child.queue_free()

	for i in dialogue.responses.size():
		var button: Button = sample_choice_button.duplicate()
		button.text = "%d. %s" % [i + 1, dialogue.responses[i]]
		button.visible = true
		button.pressed.connect(_select_response.bind(i))
		%DialogueResponseVboxContainer.add_child(button)

	%DialogueTextLabel.get_parent().visible = false
	%DialogueResponseScrollContainer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _select_response(response_index: int):
	if response_index >= dialogue.responses.size():
		return

	choosing_response = false
	%DialogueResponseScrollContainer.visible = false
	%DialogueTextLabel.get_parent().visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	dialogue_component.select_response(response_index)
	_start_lines()

func _finish_dialogue():
	is_open = false
	visible = false

	if on_finished.is_valid():
		on_finished.call()
