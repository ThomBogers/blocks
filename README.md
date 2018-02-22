# Block game
Attempt a game made with the godot engine. 
It should initially be a minecraft clone, and maybe add cool stuff after?

## Versions
### dc0a51451bb734620bf8648742c002acd7487879
![version dc0a51451bb734620bf8648742c002acd7487879](docs/dc0a51451bb734620bf8648742c002acd7487879.png)
### 3aa6a67edb5d9ec3932759044aaac8a8f46307d4
![version 3aa6a67edb5d9ec3932759044aaac8a8f46307d4](docs/3aa6a67edb5d9ec3932759044aaac8a8f46307d4.png)
### 44d742f5ff472aaab26d5e42b406963afafd1467
![version 44d742f5ff472aaab26d5e42b406963afafd1467](docs/44d742f5ff472aaab26d5e42b406963afafd1467.png)
### ffb87836b53babee7f96a18df1757a66d39090cc
![version ffb87836b53babee7f96a18df1757a66d39090cc](docs/ffb87836b53babee7f96a18df1757a66d39090cc.png)
### 8159427ae8ebdf4a5c8d04844a67258f39826bbd
![version 8159427ae8ebdf4a5c8d04844a67258f39826bbd](docs/8159427ae8ebdf4a5c8d04844a67258f39826bbd.png)

## Todo
 - Moving into wall while jumping causes vertical collision, resetting vertical velocity back to 0
 - Change kubelet shape to d20 die (icosahedron)
 - Add textures to kubelets (Add color item to quad, and set color in shader?)
 - Add multipe chunk functionality
 - Improve world generation algorithm: https://thebookofshaders.com/13/
 - Implement block destruction for new mesh world (chunk mesh regeneration)
 - Add tunneling possibility
 - Store chunk data more efficiently than just an array
 - Remove duplicate vertices when adding verticals/overlapping horizontals
 - Move mesh generation to native code