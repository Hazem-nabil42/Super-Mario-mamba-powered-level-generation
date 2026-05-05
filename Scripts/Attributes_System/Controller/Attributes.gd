class_name Attributes
extends Node

var attributes : Array[Node]

func _ready() -> void:
	attributes = get_children()

func _get(property):
	for attribute in (attributes):
		if attribute.get(property):
			return attribute[property]

func _set(property, _value):
	for attribute in (attributes):
		return attribute[property]
