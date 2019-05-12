extends Node

const playerStateLocation = 'res://user/saved_player.sav'

func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _ready():
    pass

func savePlayerState(position, rotation, pitch, yaw):
    logMessage("saving player state, pos: " + str(position) + " rot: " + str(rotation) + " pch: " + str(pitch) + " yaw: " + str (yaw))
    var data = {
        position = var2str(position),
        rotation = var2str(rotation),
        pitch = var2str(pitch),
        yaw = var2str(yaw)
    }

    var file = File.new()
    if file.open(playerStateLocation, File.WRITE) != 0:
        logMessage("Error opening file")
        return

    # Save the dictionary as JSON (or whatever you want, JSON is convenient here because it's built-in)
    file.store_line(to_json(data))
    file.close()
    logMessage('saved player state')

func loadPlayerState():
    logMessage("Loading player state")
    var data = {
        position = null,
        rotation = null,
        pitch = null,
        yaw = null
    }

    var file = File.new()
    if file.open(playerStateLocation, File.READ) != 0:
        logMessage("Error opening file")
        return

    while not file.eof_reached():
        var json = parse_json(file.get_line())
        if not json:
            continue

        for key in json.keys():
            if data.has(key):
                var json_value = json.get(key)
                if not json:
                    return
                var value = str2var(json_value)
                data[key] = value

    logMessage('loaded player state: ' + str(data))

    file.close()
    return data
