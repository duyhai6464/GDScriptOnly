class_name QueueNode
var data
var next
var prev

func _init(new_data) -> void:
	data = new_data
	next = null
	prev = null
