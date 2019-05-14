extends Node

const savePath = 'res://user/'
const savePost = '.sav'


func logMessage(message: String):
	var name = self.get_script().get_path().get_file().replace('.gd', '')
	print( name, ": ", message)

func _ready():
    pass

func _saveToFile(location, data):
    var file = File.new()
    if file.open(location, File.WRITE) != 0:
        logMessage("Error opening file")
        return

    file.store_line(to_json(data))
    file.close()

func _loadFromFile(location):
    var data = Dictionary()
    var file = File.new()
    if file.open(location, File.READ) != 0:
        # logMessage("Error opening file")
        return

    while not file.eof_reached():
        var line = file.get_line()
        logMessage("chunk line: " + line)
        var json = parse_json(line)
        logMessage("chunk json: " + (str(json)) + ' type: ' + str(typeof(json)))
        if not json:
            continue

        for json_key in json.keys():
            logMessage('chunk key: ' + json_key)
            var json_value = json.get(json_key)
            if not json:
                return
            data[json_key] = json_value

    return data

func savePlayerState(position, rotation, pitch, yaw):
    logMessage("saving player state, pos: " + str(position) + " rot: " + str(rotation) + " pch: " + str(pitch) + " yaw: " + str (yaw))
    var data = {
        position = var2str(position),
        rotation = var2str(rotation),
        pitch = var2str(pitch),
        yaw = var2str(yaw)
    }
    var playerStateLocation = savePath + 'saved_player' + savePost
    _saveToFile(playerStateLocation, data)
    logMessage('saved player state')


func saveChunkState(id, diff):
    var chunkLocation = savePath + "chunk_" + id + savePost
    logMessage("saving chunk state: " + chunkLocation + ' diff: ' + str(diff))
    # var data = var2str(diff)
    _saveToFile(chunkLocation, diff)
    logMessage('saved chunk state')


func loadPlayerState():
    logMessage("Loading player state")
    var data = {
        position = null,
        rotation = null,
        pitch = null,
        yaw = null
    }
    var playerStateLocation = savePath + 'saved_player' + savePost

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

func loadChunkState(id):
    var chunkLocation = savePath + "chunk_" + id + savePost
    # logMessage("loading chunk state: " + chunkLocation)
    var data = _loadFromFile(chunkLocation)

    if data:
        logMessage('loaded chunk state')

    return data
