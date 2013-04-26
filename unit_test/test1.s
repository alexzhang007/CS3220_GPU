movi.f r9 5.0f
movi.f r10 1.5f
addi.f r10 r10 5.0f
add.f r11 r9 r10
vmovi v1 10.5f
vmovi v2 2.5f
vadd v3 v1 v2
vcompmovi v1 0 1.5f
vcompmovi v1 2 3.0f
vcompmov v1 1 r9