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
 - Change kubelet shape to d20 die (icosahedron)
 - Add textures to kubelets (Add color item to quad, and set color in shader?)
 - Add multipe chunk functionality
 - Improve world generation algorithm: https://thebookofshaders.com/13/
 - Store chunk data more efficiently than just an array
 - Remove duplicate vertices when adding verticals/overlapping horizontals
 - Move mesh generation to native code
