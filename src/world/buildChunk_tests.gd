func _get_random_y(x,z):
	randomize()
	var prev

	if x == 0 and z == 0:
		return randi()%4
	elif x == 0:
		prev = chunk[0][z-1]
	elif z == 0:
		prev = chunk[x-1][z]
	else:
		prev = (chunk[x][z-1] + chunk[x-1][z] + chunk[x-1][z-1]) / 3


	var up   = randi()%4

	if x+z%128 == 0:
		up   = randi()%10

	var down = randi()%4
	if x+z%256 == 0:
		down   = randi()%10

	var res = prev + up - down

	return res

func _build_chunk():
	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])
			var y_top = randi()%5
			for y in range(chunksize):
				if y <= y_top:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)

func _build_chunk_test0():
	chunksize = 10

	for x in range(chunksize):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])
			var h = x*z

			for y in range(chunksize*2):
				var current
				if y <= h:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)

	var y = 2
	for x in range(chunksize):
		for z in range(4,8):
			chunk[x][z][y] = BLOCK_TYPE.AIR
			chunk[x][z][y+1] = BLOCK_TYPE.AIR
	for z in range(chunksize):
		for x in range(4,8):
			chunk[x][z][y] = BLOCK_TYPE.AIR
			chunk[x][z][y+1] = BLOCK_TYPE.AIR

func _build_chunk_test1():
	chunksize = 3

	for x in range(chunksize*3):
		chunk.append([])
		for z in range(chunksize):
			chunk[x].append([])

			var h = 0
			if z == 1 and x%3 == 1:
				h = 2

			for y in range(chunksize):

				var current
				if y <= h:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)

func _build_chunk_test2():

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			for y in range(chunksize.y):

				var current
				if y == 0:
					current = BLOCK_TYPE.DIRT
				else:
					current = BLOCK_TYPE.AIR

				chunk[x][z].append(current)


func _build_test_chunk():

	for x in range(chunksize.x):
		chunk.append([])
		for z in range(chunksize.z):
			chunk[x].append([])

			for y in range(chunksize.y):
				if x == 10:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				elif z == 10:
					chunk[x][z].append(BLOCK_TYPE.DIRT)
				# elif z == 10:
				# 	chunk[x][z].append(BLOCK_TYPE.DIRT)
				else:
					chunk[x][z].append(BLOCK_TYPE.AIR)
