extends Node

var threads = Dictionary()


func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

# Called when the node enters the scene tree for the first time.
func _ready():
	var thread_count = floor(OS.get_processor_count() * 0.8)
	if thread_count < 1:
		thread_count = 1

	for i in range(0,thread_count):
		threads[i] = Thread.new()

func get_thread():
	for key in threads.keys():
		var thread = threads.get(key)
		if not thread.is_active():
			logMessage("giving thread: " + str(key))
			return thread;

	return null;