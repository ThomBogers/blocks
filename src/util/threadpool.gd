extends Node

var CONSTANTS = load("res://src/util/constants.gd")

var threads = Dictionary()

var thread_count = 0

var thread_key = 0

var reserved_thread
func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

# Called when the node enters the scene tree for the first time.
func _ready():
	thread_count = floor(OS.get_processor_count() * CONSTANTS.THREADPER)
	if thread_count < 1:
		thread_count = 1
	else:
		reserved_thread = 0

	for i in range(0,thread_count):
		threads[i] = Thread.new()


func get_thread(high_prio):

	for i in threads.keys():
		var key = get_next_thread_key(thread_key, high_prio)
		var thread = threads.get(key)
		if not thread.is_active():
			thread_key = key
			logMessage("giving thread: " + str(key))
			return thread;

	return null;

func get_next_thread_key(base, high_prio):
	var next_thread = base + 1
	if next_thread >= threads.size():
		next_thread = 0

	if next_thread == reserved_thread && high_prio != true:
		next_thread = get_next_thread_key(next_thread, high_prio)

	return next_thread
