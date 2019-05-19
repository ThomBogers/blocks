extends Control

onready var player = get_node("..")

func _ready():
	set_process_input(true)


func _input(event):
	if event.is_action_pressed("escape"):
		if player.inControlModeMenu():
			player.setControlModePlay();
		elif player.inControlModePlay():
			player.setControlModeMenu();