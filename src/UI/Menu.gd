extends Control

var _timer = null
var _game = null
var _root = null

var timestep = 1.0
var loadtime = 0.0

onready var loader = get_node("./Loader")
onready var progressBar = get_node("./Loader/ProgressBar")
onready var estimatedTime = get_node("./Loader/EstimatedTime")

func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _ready():

	_timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(timestep)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()

func _on_StartButton_pressed():
	logMessage("StartButton pressed")
	_root = get_tree().root

	loader.visible = true

	var _game_resource = load("res://scenes/Game.tscn")
	_game = _game_resource.instance()

	_root.add_child(_game)

func _on_Timer_timeout():

	if _game != null:

		var _world = _game.get_node("./World")
		if _world != null:
			
			loadtime += timestep
			var load_progress = _world._get_chunks_initialized()
			
			
			if load_progress[0] != 0:
				var percentage = int(float(load_progress[0])/load_progress[1]*100)
				
				var seconds_per_percent = (percentage / loadtime)
				var estimated_loadtime = (100 - percentage) / seconds_per_percent

				estimatedTime.set_text("Loadtime: " + str(ceil(estimated_loadtime)) + 's')
				progressBar.value = percentage

			if _world.world_ready:
				logMessage("Entering game")
				_root.remove_child(self)
				self.call_deferred("free")
