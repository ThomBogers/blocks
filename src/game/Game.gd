extends Spatial


func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _on_goToMain_pressed():
	logMessage("goto main menu")
	var _root = get_tree().root

	var _menu_resource = load("res://scenes/Menu.tscn")
	var _menu = _menu_resource.instance()
	_root.add_child(_menu)

	_root.remove_child(self)
	self.call_deferred("free")

func _on_quit_pressed():
	get_tree().quit()
