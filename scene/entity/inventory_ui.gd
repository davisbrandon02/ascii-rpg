class_name InventoryUI
extends Control

@export var equipped_slot_color: Color = Color(1.0, 0.85, 0.4)
@export var cursor_offset: Vector2 = Vector2(12, 12)

# Template button that gets duplicated for each slot
@onready var sample_slot_button: Button = %InventoryGrid.get_node("SampleSlotBtn")

var is_open: bool = false
var inventory: InventoryComponent
var slot_buttons: Array[Button] = []
# Stack picked up with the mouse, waiting to be placed
var cursor_stack: ItemStack

# Singleton pattern for all UIs
static var instance: InventoryUI
func _ready() -> void:
	instance = self
	sample_slot_button.visible = false
	%InventoryPanel.visible = false
	%CursorLbl.visible = false

func setup(new_inventory: InventoryComponent) -> void:
	inventory = new_inventory
	var slot_count: int = InventoryComponent.HOTBAR_SIZE + InventoryComponent.GRID_SIZE
	for i in slot_count:
		var button: Button = sample_slot_button.duplicate()
		button.visible = true
		button.pressed.connect(_on_slot_pressed.bind(i))
		# First slots go on the hotbar, the rest in the grid
		if i < InventoryComponent.HOTBAR_SIZE:
			%HotbarContainer.add_child(button)
		else:
			%InventoryGrid.add_child(button)
		slot_buttons.append(button)

	inventory.slots_changed.connect(_refresh)
	inventory.equipped_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	if cursor_stack:
		%CursorLbl.position = get_local_mouse_position() + cursor_offset

func open() -> void:
	is_open = true
	%InventoryPanel.visible = true

func close() -> void:
	# Put back anything still held on the cursor
	if cursor_stack:
		inventory.add_item(cursor_stack.item, cursor_stack.count)
		cursor_stack = null
	is_open = false
	%InventoryPanel.visible = false
	_refresh()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _on_slot_pressed(index: int) -> void:
	if not is_open:
		return
	if cursor_stack:
		cursor_stack = inventory.place_into_slot(index, cursor_stack)
	else:
		cursor_stack = inventory.take_slot(index)
	_refresh()

func _refresh() -> void:
	for i in slot_buttons.size():
		slot_buttons[i].text = _stack_text(inventory.slots[i])
		var equipped: bool = inventory.is_equipped(i)
		slot_buttons[i].modulate = equipped_slot_color if equipped else Color.WHITE

	%CursorLbl.visible = cursor_stack != null
	%CursorLbl.text = _stack_text(cursor_stack)

func _stack_text(stack: ItemStack) -> String:
	if stack == null:
		return ""
	if stack.count > 1:
		return "%s\nx%d" % [stack.item.display_name, stack.count]
	return stack.item.display_name
