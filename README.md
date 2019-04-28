# Block game
Attempt a game made with the godot engine. 
It should initially be a minecraft clone, and maybe add cool stuff after?

## Controls:
```
WASD:        Move
MOUSE:       Look around 
E:           Toggle flying
Q/Esc:       Quit the game
LEFT MOUSE:  Remove block
RIGHT MOUSE: Add block
```

## Versions
Screenshots of versions by githash may be found [here](docs/versions.md)

## Todo
 - Moving into wall while jumping causes vertical collision, resetting vertical velocity back to 0
 - Add projectiles
 - Do not use clean flag to re-render on chunk.hit
 - Find better way to retry theardpool.get_thread than timer in World.gd
 - prevent block placement at occupied position 
 - introduce loading / options screen
 - Fix textures for all sides of cubes, and fix direction