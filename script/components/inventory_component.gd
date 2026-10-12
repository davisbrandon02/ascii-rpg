class_name InventoryComponent
extends Node

# Holds items in slots
# Slots 0-4 are the hotbar, the rest are the 4x3 inventory grid

signal slots_changed
signal equipped_changed

const HOTBAR_SIZE: int = 5
const GRID_SIZE: int = 12

# Given to the owner when the game starts
@export var starting_items: Array[ItemStack]

# null means the slot is empty
var slots: Array[ItemStack] = []
# Hotbar slot equipped in each hand, -1 means empty
# A BOTH item sets both to the same slot
var right_hand_index: int = -1
var left_hand_index: int = -1

func _ready() -> void:
	slots.resize(HOTBAR_SIZE + GRID_SIZE)
	for stack in starting_items:
		if stack and stack.item:
			add_item(stack.item, stack.count)
	slots_changed.connect(_validate_equipped)

func add_item(item: Item, count: int = 1) -> int:
	# Top up stacks of the same item first, then fill empty slots
	# Returns however many didn't fit
	for stack in slots:
		if count <= 0:
			break
		if stack and stack.item == item and stack.count < item.max_stack:
			var added: int = mini(count, item.max_stack - stack.count)
			stack.count += added
			count -= added

	for i in slots.size():
		if count <= 0:
			break
		if slots[i] == null:
			var added: int = mini(count, item.max_stack)
			slots[i] = _new_stack(item, added)
			count -= added

	slots_changed.emit()
	return count

func take_slot(index: int) -> ItemStack:
	# Remove and return whatever is in the slot
	var stack: ItemStack = slots[index]
	slots[index] = null
	slots_changed.emit()
	return stack

func place_into_slot(index: int, stack: ItemStack) -> ItemStack:
	# Put a stack into a slot
	# Same item merges up to the stack limit, different item swaps
	# Returns whatever is left over (null if nothing)
	var slot_stack: ItemStack = slots[index]
	var leftover: ItemStack = null

	if slot_stack == null:
		slots[index] = stack
	elif slot_stack.item == stack.item:
		var added: int = mini(stack.count, stack.item.max_stack - slot_stack.count)
		slot_stack.count += added
		stack.count -= added
		if stack.count > 0:
			leftover = stack
	else:
		slots[index] = stack
		leftover = slot_stack

	slots_changed.emit()
	return leftover

func toggle_equip(index: int) -> void:
	# Equip the hotbar slot's item in its hand, or unequip it if it's already there
	if is_equipped(index):
		_unequip(index)
		equipped_changed.emit()
		return

	var stack: ItemStack = slots[index]
	if stack == null:
		return

	match stack.item.hand:
		Item.HAND.RIGHT:
			_clear_two_handed()
			right_hand_index = index
		Item.HAND.LEFT:
			_clear_two_handed()
			left_hand_index = index
		Item.HAND.BOTH:
			right_hand_index = index
			left_hand_index = index
	equipped_changed.emit()

func is_equipped(index: int) -> bool:
	return index == right_hand_index or index == left_hand_index

func get_right_hand_item() -> Item:
	return _item_at(right_hand_index)

func get_left_hand_item() -> Item:
	# A two handed item only shows up in the right hand
	if left_hand_index == right_hand_index:
		return null
	return _item_at(left_hand_index)

func _item_at(index: int) -> Item:
	if index < 0 or slots[index] == null:
		return null
	return slots[index].item

func _unequip(index: int) -> void:
	if right_hand_index == index:
		right_hand_index = -1
	if left_hand_index == index:
		left_hand_index = -1

func _clear_two_handed() -> void:
	# Equipping a one handed item takes the place of a two handed one
	if right_hand_index != -1 and right_hand_index == left_hand_index:
		_unequip(right_hand_index)

func _validate_equipped() -> void:
	# Unequip a hand if its slot no longer holds an item for that hand
	# (moved away, or swapped for something else in the inventory)
	var two_handed: bool = right_hand_index != -1 and right_hand_index == left_hand_index
	var right_ok: bool = _slot_fits(right_hand_index, Item.HAND.BOTH if two_handed else Item.HAND.RIGHT)
	var left_ok: bool = _slot_fits(left_hand_index, Item.HAND.BOTH if two_handed else Item.HAND.LEFT)
	if right_ok and left_ok:
		return
	if not right_ok:
		_unequip(right_hand_index)
	if not left_ok:
		_unequip(left_hand_index)
	equipped_changed.emit()

func _slot_fits(index: int, hand: Item.HAND) -> bool:
	if index == -1:
		return true
	return slots[index] != null and slots[index].item.hand == hand

func _new_stack(item: Item, count: int) -> ItemStack:
	var stack := ItemStack.new()
	stack.item = item
	stack.count = count
	return stack
