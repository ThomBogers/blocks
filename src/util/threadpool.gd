extends Node

var threads = Dictionary()


func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0,OS.get_processor_count()-1):
		threads[i] = Thread.new()

func get_thread():
	logMessage("got request")

	for key in threads.keys():
		var thread = threads.get(key)
		if not thread.is_active():
			logMessage("giving thread: " + str(key))
			return thread;

	logMessage("no thread available")
	return null;