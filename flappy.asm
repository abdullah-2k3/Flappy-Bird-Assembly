org 0x0100
	jmp main
	
oldisr: dd 0
	
clrscr:
	push es 
	push ax 
	push di 
	mov ax, 0xb800
	mov es, ax 
	mov di, 0 

	mov ax, 0x3320
	mov cx, 2000
	cld
	rep stosw

	pop di 
	pop ax 
	pop es 
	
	ret
	
	
	
draw_pillar:	
	push bp
	mov bp, sp
	pusha


	mov ax, 0xb800
	mov es, ax
	
	
	mov di, [bp+6]
	
	mov ah, 0x11
	mov al, '*'
	
	mov bx, [bp+4]
.l:	
	mov cx, 8
.l1:	
	mov [es:di], ax
	add di, 2
	loop .l1
	add di, 144
	sub bx, 1
	cmp bx, 0
	jg .l
	
	add di, 1440
	
.L:	
	mov cx, 8
.L1:	
	mov [es:di], ax
	add di, 2
	loop .L1
	add di, 144
	cmp di, 4000
	jl .L
	

	popa
	pop bp
	ret 4
	
	
erase_pillar:	
	push bp
	mov bp, sp
	pusha

	mov ax, 0xb800
	mov es, ax
	
	mov di, [bp+6]
	
	mov ah, 0x33
	mov al, '.'
	
	mov bx, [bp+4]
.l:	
	mov cx, 8
.l1:	
	mov [es:di], ax
	add di, 2
	loop .l1
	add di, 144
	sub bx, 1
	cmp di, 4000
	jl .l
	
	
	

	popa
	pop bp
	ret 4

printstr:
	push bp
	mov bp, sp
	pusha
	
	push ds
	pop es
	mov di,[bp+4]
	mov cx, 0xffff
	xor al,al
	repne scasb
	mov ax, 0xffff
	sub ax, cx
	dec ax
	jz d
	
	mov cx, ax
	mov ax, 0xb800
	mov es, ax
	mov di, [bp+6]
	mov si, [bp+4]
	mov ah, 0x30
	cld
	nextchar:
		lodsb
		stosw
		loop nextchar
d:
		popa
		pop bp
		ret 4


printnum: push bp 
	 mov bp, sp 
	 push es 
	 push ax 
	 push bx 
	 push cx 
	 push dx 
	 push di 
	 push si
	 mov si, 0
	 mov ax, 0xb800 
	 mov es, ax ; point es to video base 
	 mov ax, [bp+4] ; load number in ax 
	 cmp ax, 0
	 je _pexit
	 
	 mov cx, 0 ; initialize count of digits 
nextdigit:
	 mov bx, 10
	 mov dx, 0 ; zero upper half of dividend 
	 div bx ; divide by 10 
	 add dl, 0x30 ; convert digit into ascii value 
	 push dx ; save ascii value on stack 
	 inc cx ; increment count of values 
	 cmp ax, 0 ; is the quotient zero 
	 jnz nextdigit ; if no divide it again 
	 mov di,  [bp+6]; 
nextpos:
	 pop dx ; remove a digit from the stack 
	 mov dh, 0x34 ; use normal attribute 
	 mov [es:di], dx ; print char on screen 
	 add di, 2 ; move to next screen location 
	 ;inc si
	 loop nextpos ; repeat for all digits on stack
_pexit:
	 pop si
	 pop di 
	 pop dx 
	 pop cx 
	 pop bx 
	 pop ax 
	 pop es 
	 pop bp 
	 ret 4

	
GenRandNum:
	push bp
	mov bp,sp;
	push cx
	push ax
	push dx;

	MOV AH, 00h ; interrupts to get system time
	INT 1AH ; CX:DX now hold number of clock ticks since midnight
	mov ax, dx
	xor dx, dx
	mov cx, 14;
	div cx ; here dx contains the remainder of the division - from 0 to 9
	inc dx
	mov word [randNum],dx;

	pop dx;
	pop ax;
	pop cx;
	pop bp;
	ret
	
delay:
	push cx
	mov cx, 0xffff
.d:  nop
	loop .d
	pop cx
	ret
	
	
draw_bird:
	push bp
	mov bp, sp
	pusha 
	
	mov ax, 0xb800
	mov es, ax
	
	mov ah, 0x34
	mov al, '^'
	
	mov di, [bp+4]
	push di 
	call check_collision
	mov cx, 3
.l:
	mov [es:di], ax
	add di, 2
	loop .l
	
	add di, 156
	push di
	call check_collision
	mov cx, 2
.l1:
	mov [es:di], ax
	add di, 2
	loop .l1	
	
	popa
	pop bp
	ret 2
	
erase_bird:
	push bp
	mov bp, sp
	pusha 
	
	mov ax, 0xb800
	mov es, ax
	
	mov ah, 0x33
	mov al, ' '
	
	mov di, [bp+4]
	push di 
	call check_collision
	mov cx, 3
.l:
	mov [es:di], ax
	add di, 2
	loop .l
	
	add di, 156
	push di
	call check_collision
	mov cx, 2
.l1:
	mov [es:di], ax
	add di, 2
	loop .l1	
	
	popa
	pop bp
	ret 2

	
check_collision:
	push bp
	mov bp, sp
	pusha
	
	mov di, [bp+4]
	add di, 2
	mov ax, [es:di]
	cmp ah, 0x11
	jne .done
	mov word [crash], 1
	
.done
	
	popa
	pop bp
	ret 2


kbisr:
	push ax
	push di
		
	in al, 0x60
	cmp ah, ' '
	jne .ignore
	mov word [jump], 1
	jmp .exit

.ignore:
	mov word [jump], 1
	pop di
	pop ax
	jmp far [cs:oldisr]
	
.exit:
	mov al, 0x20
	out 0x20, al
	pop di
	pop ax
	iret
	
	

make_jump:
	push bp
	mov bp, sp
	pusha
	
	mov ax, [bp+4]
	push ax
	call erase_bird
	
	sub ax, 480
	push ax
	call draw_bird
	
	mov [bird_loc], ax
	
	popa
	pop bp
	ret 2

	
	
main:

	xor ax, ax
	mov es, ax
	mov ax, [es:9*4]
	mov [oldisr], ax
	mov ax, [es:9*4+2]
	mov [oldisr+2], ax
	
	cli
	mov word [es:9*4], kbisr
	mov word [es:9*4+2], cs
	sti
	
	
	call clrscr
	
	mov ax, welcome
	push word 1658
	push ax
	call printstr
	
	mov ax, continue
	push word 2296
	push ax
	call printstr
	
	
	
	mov ah, 0
	int 0x16
	
	call clrscr
	mov ax, score
	push word 0
	push ax
	call printstr

.GameLoop:
	call GenRandNum
	
	mov di, 140	
	mov dx, 2000
	mov cx, 30
.l1:
	call delay
	call delay
	push di
	push word [randNum]
	call erase_pillar
	
	push dx
	call erase_bird
	add dx, 160
	
	sub di, 4
	push di
	push word [randNum]
	call draw_pillar
	
	cmp di, 80
	jg .here
	push 12
	push word [score_val]
	call printnum
.here:	
	push dx
	call draw_bird
	cmp word [jump], 1
	jne .con
	push dx
	call make_jump
	mov dx, [bird_loc]
	cmp dx, 3900
	jl .con
	mov word [crash], 1
	
.con		
	mov word [jump], 0
	cmp word [crash], 1
	je .quit
	loop .l1
	
	push di
	push word [randNum]
	call erase_pillar
	
	push dx
	call erase_bird
	
	add word [score_val], 1
	cmp word [crash], 1
	jne .GameLoop
	
	
.quit:

mov ax, game_over
push word 1994
push ax
call printstr

mov ax, 0x4c00
int 0x21


bird_loc: dw 0
jump: dw 0

crash: dw 0

randNum: dw 0

score_val: dw 1
score: db "Score: ", 0
welcome: db "Welcome To Flappy Bird!", 0
continue: db "Press any key to Contiune", 0
game_over: db "Game Over", 0
