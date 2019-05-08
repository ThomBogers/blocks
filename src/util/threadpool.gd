extends Node

var threads = Dictionary()

var thread_count = 0
var reserved_thread
func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

# Called when the node enters the scene tree for the first time.
func _ready():
	thread_count = floor(OS.get_processor_count() * 0.8)
	if thread_count < 1:
		thread_count = 1
	else:
		reserved_thread = 0

	for i in range(0,thread_count):
		threads[i] = Thread.new()


func get_thread(high_prio):
	for key in threads.keys():

		if key == reserved_thread && high_prio != true:
			continue

		var thread = threads.get(key)
		if not thread.is_active():
			logMessage("giving thread: " + str(key))
			return thread;

	return null;