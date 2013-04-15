movi.d r0 3
movi.f r8 1.0f
movi.f r9 1.0f
pushmatrix
vcompmov v0 1 r8
vcompmov v0 2 r9
scale v0
vcompmovi v2 0 255 
vcompmovi v2 1 0 
vcompmovi v2 2 0
setcolor v2
beginprimitive 3
vcompmovi v3 1 -1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 1.0f
vcompmovi v3 2 1.0f
vcompmovi v3 3 0.0f
setvertex v3
vcompmovi v3 1 0.0f
vcompmovi v3 2 -1.0f
vcompmovi v3 3 0.0f
setvertex v3		
endprimitive
popmatrix
draw
addi.f r8 r8 1.0f
addi.f r9 r9 1.0f
addi.d r0 r0 -1
brp -28
