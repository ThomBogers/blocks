extends Control

func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _ready():
	_timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(1.0)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var _timer = null
var _game = null
var _root = null

func _on_StartButton_pressed():
	logMessage("StartButton pressed")
	_root = get_tree().root

	var _game_resource = load("res://scenes/Game.tscn")
	_game = _game_resource.instance()
	_root.add_child(_game)

func _on_Timer_timeout():

	if _game != null:
		if _game.get_node("./World").world_ready:
			logMessage("Entering game")
			_root.remove_child(self)
			self.call_deferred("free")
