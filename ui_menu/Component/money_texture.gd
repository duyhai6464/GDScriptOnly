extends HBoxContainer

@export var icon: Texture2D
@export var value: int:
	set(v):
		if v != value:
			money_label.from = value
			money_label.to = v
			money_label.play()
			value = v

@onready var money_icon: TextureRect = %MoneyIcon
@onready var money_label:= %MoneyLabel

signal count_finished

func _ready() -> void:
	if icon != null:
		money_icon.texture = icon
	money_label.text = str(value)

func _on_money_label_play_finished() -> void:
	count_finished.emit()
