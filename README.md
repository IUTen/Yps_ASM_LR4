<p align="center">
      <img src="https://i.ibb.co/VgqLdNG/lr-logo.png" width="726">
</p>

<p align="center">
   <img alt="Static Badge" src="https://img.shields.io/badge/Asm-FASM-blue?label=Asm&labelColor=%231303fc&color=%23ffffff">
</p>


# Условия задачи

+ Разработать резидентную программу, которая выводит на экран содержимое 256 байт адресного пространства ЦП по 16 байт в одной строке, сегмент и смещение которого передаются через пару регистров на выбор.
Вызвать свой обработчик из другой программы
+ Номер прерывания получить путём сложения номера студента в группе и числа 128(0х80)

# Общая идея решения

Необходимо реализовать обработчик прерывания, при этом для решения задачи по выводу адресного пространства можно использовать LR3, так как это одна и та же задача

# Разъеснение

Пробежимся по коду, попутно разбираясь что, где и как.

## Первая программа

Это программа будет содержать резидентную часть, которая всегда будет находится в памяти компьютера

### Начало программы

В самом начале программы находятся "организационные" команды

```ASM
use16
org 100h

start_:
    jmp init_
```

Первые две строки начальные директивы, а последняя - безусловных переход к следующему блоку кода

<br><br>

### Блок INIT

В этом блоке мы из обычной программы делаем резидентную:

```ASM
init_:
    mov ah, 0x25                ;Функция прерывания 0x21
    mov al, 0x8b                ;Номер вектора прерывания
    mov dx, interruption_       ;Адрес-смещение обработчика прерывания

    int 0x21                    ;Запись параметров прерывания в память

    mov dx, init_               ;Адрес-смещение следующего за резидентной программой
    int 0x27                    ;Прерывание для резидентной программы
```

+ `mov ah, 0x25` - Задаём функцию прерывания *0x21*. То есть указывает, что именно нужно будет сделать
+ `mov al, 0x8b` - Указываем номер прерывания, по которому в последствии можно будет вызвать нашу программу
+ `mov dx, interruption_` - Указываем адрес-смещение. То есть кладём в `DX` метку блока кода, к которому перейдёт программа при вызове прерывания
+ `int 0x21` - Вызов прерывания. В нашем случае запись адреса прерывания в память
+ `mov dx, init_` - Указываем следующий блок кода, после резидентной программы.
+ `int 0x27` - Вызов прерывания. Переводим программу в формат резидентной.

<br><br>

### Блок Interruption

Это блок кода, который начнёт выполняться, когда мы вызовем прерывание, ранее нами записанное в память в блоке `INIT`. Рассмотрим код:

```ASM
interruption_:
    sti                         ;Разрешение маскированных прерываний
    push ax                     ;Сохранение в стек значений регистров
    push bx
    push dx
    push ds

    mov ax, cs                  
    mov ds, ax

    mov es, bx
    mov bx, 0

    mov bx, 0x6e                ;Записываем адрес смещения(из прошлой лабы)
    call main

    pop ds                      ;Возрат значений регистров
    pop dx
    pop bx
    pop ax

    iret
```

+ `sti` - Ключевое слово, разрешающее маскированное прерывание(прерывание нашего типа)
+ `push <Регистр>` - Сохраняем значения регистров в стек, чтобы соблюсти концепцию сохранности данных при выполнении функции
+ `mov ax, cs` <br> `mov ds, ax` - После вызова резидентной программы в cs записались данные, которые нужно положить в ds.
+ `mov bx, 0x6e` - Смещение в памяти из прошлой лабораторной. Необходимо для работы блока `main`
+ `pop <Регистр>` - Возврашаем значения регистров, чтобы соблюсти правила по сохранности данных
+ `iret` - Возврат из резидентной функции

<br><br>

### Блок main

В данном блоке находится сама программа по выводу. Про неё можно почитать в репизитории с [LR3](https://github.com/IUTen/Yps_ASM_LR3)

```ASM
main:
    pusha

    mov cx,16                   ;Пробегаем по строкам
    row_run:
        push cx

        mov cx,16               ;Пробегаем по столбцам
        column_run:
            mov al, byte[es:di] ;записали значение из памяти для вывода
            call print_al
            inc di              ;сделали шаг для номера ячейки в памяти
            call make_space
            loop column_run
        
        call make_endl

        pop cx
        loop row_run

    popa
    ret

;Вывод пробела в консоль
make_space:
    pusha
    mov ah, 0x2
    mov dl, 0x20
    int 21h
    popa
    ret

;Переход на новую строку
make_endl:
    pusha
    mov ah, 0x9
    mov dx, new_line
    int 21h
    popa
    ret

;Печать символа ASCII. В DL должен находиться код символа
print_one:
    pusha
    mov ah, 0x02
    int 21h
    popa
    ret

print_al:
    pusha
    
    mov cx, 1
    push ax                     ;Сохранили значение на будущее

    shr al, 4                   ;Сдвигаем, чтобы осталась первая цифра
    and al, 0xf                 ;Оставляем нужную тетру
    cmp al, 0x9                 ;Проверяем, число или буква
    ja symbol_wrd               ;Если цифра больше 9, это буква
    jmp symbol_figure           ;Если цифра не больше 9, это цифра

    back_get:                   ;Проверяем, делали ли мы второй блок
    cmp cx, 0
    je back_get_2
    sub cx, 1                   ;Учёт выполнения второго блока

    pop ax                      ;Вернули значение на вывод

    and al, 0xf                 ;Оставляем нужную тетру
    cmp al, 0x9                 ;Проверяем, число или буква
    ja symbol_wrd               ;Если цифра больше 9, это буква
    jmp symbol_figure           ;Если цифра не больше 9, это цифра
    back_get_2:

    popa
    ret

symbol_wrd:
    mov dl, al                  ;Запись значения
    add dl, 0x37                ;Смещение по коду ASCII, чтобы получить нужный символ
    call print_one
    jmp back_get
symbol_figure:
    mov dl, al                  ;Запись значения
    add dl, 0x30                ;Cмещение по коду ASCII, чтобы получит нужный символ
    call print_one
    jmp back_get

new_line:
    db 0xD, 0xA, '$'
```

<br><br><br>

## Вторая программа

Эта маленькая программа предназначена для вызова прерывания, которое мы написали в первой программе. Сам код:

```ASM
use16
org 0x100

mov bx, 0x0
mov di, 0x0

int 8bh                 ;Вызов резидентной программы

mov ax, 0               ;Выход из программы
int 16h
int 20h
```

+ `use16 и org 0x100` - Знакомые нам начальные директивы
+ `mov bx,0x0` <br> `mov di, 0x0` - Указываем сегмент и смещение для вывода
+ `int 8bh` - Вызов нашего прерывания из первой программы. ***8bh аналогично записи 0x8b***
+ `mov ax, 0` <br> `int 16h` <br> `int 20h` - Завершение программы

<br><br><br>

# Послесловие

Чтобы всё работало правильно, выполняем следующие действия:

1. `Запускаем первую программу`. После запуска первой программы в память будет записана резидентная программа, которую нужно будет вызвать
2. `Запускаем вторую программу`. Вторая программа предназначена для вызова прерывания. После её запуска будет выполнен код, который мы указали при создании прерывания. В нашем случае это блок `Interruption`(Этот блок может иметь любое название)

<br><br>

В случае, если что-то у вас не работает или вам не понятно, не стесняйтесь открывать `issue`. Обязательно посмотрю и постараюсь помочь.

<p align= "center"> <img src= "https://media.giphy.com/media/3tsV0vUau14uM8LyNh/giphy.gif"> </p>
