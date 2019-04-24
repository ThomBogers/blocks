extends Node

var threads = Dictionary()

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0,OS.get_processor_count()-1):
		threads[i] = Thread.new()

func get_thread():
	print("thread request")

	for key in threads.keys():
		var thread = threads.get(key)
		if not thread.is_active():
			print("Giving thread: " + str(key))
			return thread;

	print("No thread available")
	return null;



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
