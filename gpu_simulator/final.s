movi.d r0 60
movi.f r8 0.0f
loadidentity
pushmatrix
vcompmovi v1 1 -1.5f
vcompmovi v1 2 -1.0f
translate v1
pushmatrix
vcompmov v0 0 r8
vcompmovi v0 1 0.0f
vcompmovi v0 2 0.0f
vcompmovi v0 3 1.0f
rotate v0
beginprimitive 4
vcompmovi v2 0 255
vcompmovi v2 1 0
vcompmovi v2 2 0
setcolor v2
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v2 0 0
vcompmovi v2 1 255
vcompmovi v2 2 0
setcolor v2
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v2 0 0
vcompmovi v2 1 0
vcompmovi v2 2 255
setcolor v2
vcompmovi v3 1 0.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 0.0f
setvertex v3		
endprimitive
popmatrix
vcompmovi v1 1 0.0f
vcompmovi v1 2 2.0f
translate v1
vcompmov v0 0 r8
vcompmovi v0 1 0.0f
vcompmovi v0 2 0.0f
vcompmovi v0 3 1.0f
rotate v0
addi.f r8 r8 3.0f	
popmatrix
loadidentity
pushmatrix
vcompmovi v1 1 1.5f
vcompmovi v1 2 0.0f
translate v1
pushmatrix
vcompmovi v5 1 1.2f
vcompmovi v5 2 1.2f
scale v5
pushmatrix
vcompmovi v5 1 1.2f
vcompmovi v5 2 1.2f
scale v5
beginprimitive 4
vcompmovi v2 0 255
vcompmovi v2 1 0
vcompmovi v2 2 0
setcolor v2
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 2.0f
setvertex v3
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 2.0f
setvertex v3
vcompmovi v3 1 -1.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 2.0f
setvertex v3		
endprimitive
popmatrix
beginprimitive 4
vcompmovi v2 0 0
vcompmovi v2 1 255
vcompmovi v2 2 0
setcolor v2
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 1.0f
setvertex v3
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 1.0f
setvertex v3
vcompmovi v3 1 -1.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 1.0f
setvertex v3		
endprimitive
popmatrix
beginprimitive 4
vcompmovi v2 0 0
vcompmovi v2 1 0
vcompmovi v2 2 255
setcolor v2
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 -1.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 0.0f
setvertex v3		
endprimitive
popmatrix
draw
addi.d r0 r0 -1
brzp -121 
