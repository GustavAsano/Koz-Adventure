extends Resource
class_name ItemSlots

const MAX_STACK_SIZE = 99
@export_range(1, MAX_STACK_SIZE) var qnt:int = 1
@export var baseItem: ItemData

