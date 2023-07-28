class_name DevInfoTag
extends Control
## UI Element for displaying entity info

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var state_label: Label = $VBoxContainer/StateLabel
@onready var info_label: Label = $VBoxContainer/InfoLabel

func set_name_label(name_string: String):
	name_label.text = name_string

func set_state_label(state_string: String):
	state_label.text = state_string

func set_info_label(info_string: String):
	info_label.text = info_string
