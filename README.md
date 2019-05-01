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
 - Threading
    - Do not use clean flag to re-render on chunk.hit
    - Find better way to retry theardpool.get_thread than timer in World.gd
 - Gameplay
    - Add projectiles
    - prevent block placement at occupied position
 - Camera
    - Move camera to 'over the shoulder' when zoomed out, just a translation up and right?
    - Third person camera should move like 'attached to a stick' on the character, camera focus point should not move when pitch changes.
    - Add collision between camera and terrain, change camera location when colliding (low priority)
 - Misc
    - introduce loading / options screen
    - Use different texture for top layer dirt

## Noise distribution 

Distribution of values from `noise.get_noise_3d`, based on `774144` calls:

![Noise distribution](docs/noise_distribution.png)
