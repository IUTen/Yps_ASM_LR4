use16
org 0x100

mov bx, 0x0
mov di, 0x0

int 8bh                 ;Вызов резидентной программы

mov ax, 0               ;Выход из программы
int 16h
int 20h
