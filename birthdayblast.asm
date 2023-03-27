	; Birthday Blast!
	; © Thomas Wesley Scott, 2023

	; Code starts at $C000.
	; org jump to $BFFO for header info


	org $BFF0
	db "NES",$1a
	db $1
	db $1
	db %00000000
	db %00000000
	db 0
	db 0,0,0,0,0,0,0


itemchoices equ $00 	
playerpos equ $01		
playerbuttons equ $02	
playerlives equ $03
playerscore_hi equ $04
playerscore_mid equ $05
playerscore_lo equ $06
tickdown equ $0F
tickup equ $07
maxitems equ $08
fallframerate equ $09
temppos equ $0A
movetimer equ $0B
randomnum1 equ $0C
randomnum2 equ $0D
walkanimation equ $FF	


A1 equ $00
As1 equ $01
Bb1 equ $01
B1 equ $02

C2 equ $03
Cs2 equ $04
Db2 equ $04
D2 equ $05
Ds2 equ $06
Eb2 equ $06
E2 equ $07
F2 equ $08
Fs2 equ $09
Gb2 equ $09
G2 equ $0A
Gs2 equ $0B
Ab2 equ $0B
A2 equ $0C
As2 equ $0D
Bb2 equ $0D
B2 equ $0E

C3 equ $0F
Cs3 equ $10
Db3 equ $10
D3 equ $11
Ds3 equ $12
Eb3 equ $12
E3 equ $13
F3 equ $14
Fs3 equ $15
Gb3 equ $15
G3 equ $16
Gs3 equ $17
Ab3 equ $17
A3 equ $18
As3 equ $19
Bb3 equ $19
B3 equ $1A

C4 equ $1B
Cs4 equ $1C
Db4 equ $1C
D4 equ $1D
Ds4 equ $1E
Eb4 equ $1E
E4 equ $1F
F4 equ $20
Fs4 equ $21
Gb4 equ $21
G4 equ $22
Gs4 equ $23
Ab4 equ $23
A4 equ $24
As4 equ $25
Bb4 equ $25
B4 equ $26

C5 equ $27
Cs5 equ $28
Db5 equ $28
D5 equ $29
Ds5 equ $2A
Eb5 equ $2A
E5 equ $2B
F5 equ $2C
Fs5 equ $2D
Gb5 equ $2D
G5 equ $2E
Gs5 equ $2F
Ab5 equ $2F
A5 equ $30
As5 equ $31
Bb5 equ $31
B5 equ $32

C6 equ $33
Cs6 equ $34
Db6 equ $34
D6 equ $35
Ds6 equ $36
Eb6 equ $36
E6 equ $37
F6 equ $38
Fs6 equ $39
Gb6 equ $39
G6 equ $3A
Gs6 equ $3B
Ab6 equ $3B
A6 equ $3C
As6 equ $3D
Bb6 equ $3D
B6 equ $3E

C7 equ $3F
Cs7 equ $40
Db7 equ $40
D7 equ $41
Ds7 equ $42
Eb7 equ $42
E7 equ $43
F7 equ $44
Fs7 equ $45
Gb7 equ $45
G7 equ $46
Gs7 equ $47
Ab7 equ $47
A7 equ $48
As7 equ $49
Bb7 equ $49
B7 equ $4A

C8 equ $4B
Cs8 equ $4C
Db8 equ $4C
D8 equ $4D
Ds8 equ $4E
Eb8 equ $4E
E8 equ $4F
F8 equ $50
Fs8 equ $51
Gb8 equ $51
G8 equ $52
Gs8 equ $53
Ab8 equ $53
A8 equ $54
As8 equ $55
Bb8 equ $55
B8 equ $56

C9 equ $57
Cs9 equ $58
Db9 equ $58
D9 equ $59
Ds9 equ $5A
Eb9 equ $5A
E9 equ $5B
F9 equ $5C
Fs9 equ $5D

sqlen equ $7A	; counter for square note duration
ctnt equ $7C  	; current note
ntnum equ $7D	; number of current note


nmihandler:
	pha
	php

	lda playerpos
	sta $0203 

	lda #$02
	sta $4014

	ldx ctnt
	cpx #0
	beq skipnote
	
playnote:
	jsr soundframe

skipnote:


	jsr readcontroller
	
	
	ldx movetimer
	inx
	stx movetimer


	ldx tickdown
	dex
	stx tickdown
	cpx #0
	bne chkcollisions
	
	jsr tickupdates
	

chkcollisions:	
	; Check collisions with either floor or player
	jsr collisions


chkframerate:
	
	; Only move if fallframerate = movetimer
	lda movetimer
	cmp fallframerate
	

	bmi randomizer
	

	lda #0
	sta movetimer
	jsr moveitems

	
randomizer:

	; "Random" number generators	
	lda randomnum1
	clc
	adc playerpos
	clc
	adc itemchoices
	clc
	adc playerlives
	clc
	adc tickdown
	sta randomnum1	
	
	lda randomnum2
	adc playerscore_lo
	clc
	adc playerscore_hi
	clc	
	adc tickdown
	clc
	adc tickup
	clc
	adc fallframerate
	sta randomnum2

	plp
	pla
	rti
	

irqhandler:
	rti

startgame:
	sei		; Disable interrupts
	cld		; Clear decimal mode

	ldx #$ff	
	txs		; Set-up stack
	inx		; x is now 0
	stx $2000	; Disable/reset graphic options 
	stx $2001	; Make sure screen is off
	stx $4015	; Disable sound

	stx $4010	; Disable DMC (sound samples)
	lda #$40
	sta $4017	; Disable sound IRQ
	lda #0	
waitvblank:
	bit $2002	; check PPU Status to see if
	bpl waitvblank	; vblank has occurred.
	lda #0
clearmemory:		; Clear all memory info
	sta $0000,x
	sta $0100,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	lda #$FF
	sta $0200,x	; Load $FF into $0200 to 
	lda #$00	; hide sprites 
	inx		; x goes to 1, 2... 255
	cpx #$00	; loop ends after 256 times,
	bne clearmemory ; clearing all memory


waitvblank2:
	bit $2002	; Check PPU Status one more time
	bpl waitvblank2	; before we start loading in graphics	

	; Load palettes
	lda $2002
	ldx #$3F
	stx $2006
	ldx #$00
	stx $2006
copypalloop:
	lda initial_palette,x
	sta $2007
	inx
	cpx #$20
	bcc copypalloop


	lda $2002

	
	ldx #$02
	stx $4014

	ldx #0
spriteload:
	lda sprites,x	; Load tiles, x and y attributes
	sta $0200,x
	inx
	cpx #$04
	bne spriteload


; Setup background


	ldy #$FF
	lda $2002
	lda #$20
	sta $2006
	sta $09		; zero page - storing high byte here
	lda #$09
	sta $2006
	sta $08		; zero page - storing low byte here

bkgdouter:
	
	ldx #0
bkgd:
	; 14 tiles, place them 20 times

	lda backgrounddata_walls,x
	sta $2007
	inx
	cpx #$0E
	bne bkgd

	lda $2002
	iny
	clc
	lda $08
	adc #32
	sta $08	
	lda $09
	adc #0	; if carry is set, should add to $09
	sta $09	

	sta $2006
	lda $08
	sta $2006

	cpy #$14
	bne bkgdouter

; Load the floor of the house.

	ldx #0
	lda $2002
	lda #$22	; tile address is $2289
	sta $2006
	lda #$89	; low byte of $2289
	sta $2006
bkgd_floor:
	lda #$01	; Tile $01 is a brick
	sta $2007
	inx
	cpx #$0D	; We want 13 bricks total
	bne bkgd_floor


bkgd_words:		; "Happy Birthday!" tiles
	lda #$20
	sta $09
	lda #$2C
	sta $08

	lda $2002
	lda $09
	sta $2006
	lda $08
	sta $2006

	ldx #0
happy:
	
	lda backgrounddata_words,x
	sta $2007
	inx
	cpx #$05
	bne happy

	clc
	lda $08
	adc #32
	sta $08
	lda $2002
	lda $09
	sta $2006
	lda $08
	sta $2006
birthday:
	; do not reset x, keep going
	
	lda backgrounddata_words,x
	sta $2007
	inx
	cpx #$0E
	bne birthday

	lda $2002
	lda #$22
	sta $2006
	lda #$C3
	sta $2006
	ldx #0
livesandscore:
	lda scorelivetiles,x
	sta $2007
	inx
	cpx #5
	bne livesandscore

	lda $2002
	lda #$22
	sta $2006
	lda #$E3
	sta $2006
	
score:
	lda scorelivetiles,x
	sta $2007
	inx
	cpx #$F
	bne score

	; Reset scroll values
	lda $2002
	lda #$00
	sta $2005
	sta $2005
	

	ldx #0


; We are using sprites to show the number of lives
; because the tile used is the same as the player

scoresprites:
	lda scoresprite,x	; Load tiles, x and y attributes
	sta $0224,x
	inx
	cpx #$0C
	bne scoresprites


	; Initialization of game data


	lda #%11111111		; All cakes as options to start (0 is bomb)
	sta itemchoices

	lda #$5A		; Player position
	sta playerpos 

	lda #3			; Start with 3 lives
	sta playerlives
	
	lda #29			; 29th tile is zero tile
	sta playerscore_lo
	sta playerscore_mid
	sta playerscore_hi

	lda #0
	sta tickup		; Number of seconds passed 

	lda #60
	sta tickdown		; Frames in a second	

	lda #15			; Number of frames before
	sta fallframerate	; items move down
	
	lda #0			; Used to determine when
	sta movetimer		; items should move down

	lda #1
	sta maxitems		; Only 1 item falling at start

	lda #4
	sta walkanimation

	; First cake
	lda #$30
	sta $0204		; Store starting y-coord
	lda #5			; Tile # for cake
	sta $0205		; Store it as first falling item
	lda #$02
	sta $0206
	lda #$7F
	sta $0207		; Store starting x-coord


musicsetup:
	; Initialization
	lda #$01
	sta $4015	; Turn on instruments
	lda #%11111111
	sta $4000	; Configure square 1
	lda #$00
	sta $4001	; Turn off sweeping on square 1

	
	; Load initial values
	; Then turn the screen on so music can play
	lda birthday_notes
	sta ctnt
	asl		; Double it since we're dealing with words	
	tax		; Put the value in x-register

	lda notes,x 	; Lower half of note
	sta $4002
	lda notes+1,x 	; Higher half of note
	sta $4003

	; Length of first note
	lda birthday_length	
	sta sqlen
	
	lda #0
	sta ntnum	; Number of note starts at zero
	

	; turn screen on
	lda #%00011110
	sta $2001
	lda #$88
	sta $2000


forever:
	jmp forever


soundframe:

	; This subroutine is only loaded via vblank
	; and only if there are still notes to play

	; Check first if a new note is needed
	; If not, we simply decrease counter
	; and move on

	lda sqlen
	bne decreasecount
	
	; sqlen is zero, so we
	; need a new note
	; Increase note counter
	ldx ntnum	
	inx
	stx ntnum
	

	lda birthday_notes,x
	sta ctnt
	
	; Make sure newest note is a note
	cmp #0
	bne newnote
	
silence:

	; Note is "zero", so stop music
	lda #0
	sta $4015
	rts

newnote:
	

	; Load up a new note		
	ldx ntnum
	lda birthday_length,x
	sta sqlen	; Length of new note

	ldx ctnt

	txa
	asl		; Double value since using words
	tax		; Put back in x-register

	lda notes,x
	sta $4002
	lda notes+1,x
	sta $4003

decreasecount:
	ldx sqlen
	dex
	stx sqlen

	rts 		; exit subroutine


; Table of different notes and their values
notes:	
	dw $07F1, $0780, $0713 				; A1 to B1 ($00-$02)
	dw $06AD, $064D, $05F3, $059D, $054D, $0500	; C2 to F2 ($03-$08)
	dw $04B8, $0475, $0435, $03F8, $03BF, $0389 	; F#2 to B2 ($09-$0E)
	dw $0356, $0326, $02F9, $02CE, $02A6, $027F	; C3 to F3 ($0F-$15)
	dw $025C, $023A, $021A, $01FB, $01DF, $01C4 	; F#3 to B3 ($16-$1A)
	dw $01AB, $0193, $017C, $0167, $0151, $013F	; C4 to F4 ($1B-$20)
	dw $012D, $011C, $010C, $00FD, $00EF, $00E2	; F#4 to B4 ($20-$26)
	dw $00D2, $00C9, $00BD, $00B3, $00A9, $009F	; C5 to F5 ($27-$2C)
	dw $0096, $008E, $0086, $007E, $0077, $0070 	; F#5 to B5 ($2D-$32)
	dw $006A, $0064, $005E, $0059, $0054, $004F	; C6 to F6 ($33-$38)
	dw $004B, $0046, $0042, $003F, $003B, $0038 	; F#6 to B6 ($39-$3E)
	dw $0034, $0031, $002F, $002C, $0029, $0027	; C7 to F7 ($3F-$45)
	dw $0025, $0023, $0021, $001F, $001D, $001B 	; F#7 to B7 ($46-$4A)
	dw $001A, $0018, $0017, $0015, $0014, $0013	; C8 to F8 ($4B-$50)
	dw $0012, $0011, $0010, $000F, $000E, $000D 	; F#8 to B8 ($51-$56)
	dw $000C, $000C, $000B, $000A, $000A, $0009, $0008 ; C9 to F#9 ($57-$5D)

; Notes to the song ("Happy Birthday")
birthday_notes:
	db G3, G3, A3, G3, C4, B3
	db G3, G3, A3, G3, D4, C4
	db G3, G3, G4, E4, C4, B3, A3
	db F4, F4, E4, C4, D4, C4
	db 0 ; Zero indicates song is over

birthday_length:
	
	; 240 BPM -> 4 times a second -> 15 counts per quarter note
	db 30, 15, 45, 45, 45, 90
	db 30, 15, 45, 45, 45, 90
	db 30, 15, 45, 45, 45, 45, 90
	db 30, 15, 45, 45, 45, 105


; Walking Animation
animategirl:
	lda walkanimation
	sec
	sbc #16		; Animation updates for every
	bmi movegirl	; 16 frames of walking (approx.)
	rts
movegirl:
	lda $0201
	beq walknow
standnow:
	lda #$00	; Standing tile
	sta $0201
	rts
walknow:
	lda #$01	; Walking tile
	sta $0201
	rts

; Controller Input Reading
readcontroller:
	lda #1		; Begin logging controller input
	sta $4016	; Controller 1
	lda #0		; Finish logging
	sta $4016	; Controller 1

	ldx #8
readctrlloop:
	pha		; Put accumulator on stack
	lda $4016	; Read next bit from controller

	and #%00000011	; If button is active on 1st controller,
	cmp #%00000001	; this will set the carry
	pla		; Retrieve current button list from stack

	ror		; Rotate carry onto bit 7, push other
			; bits one to the right

	dex		
	bne readctrlloop
	
	sta playerbuttons	

checkright:
	lda playerbuttons	; Load buttons
	and #%10000000		; Bit 7 is "right"
	beq checkleft		; Skip move if zero/not pressed
	moveright:
		clc
		lda playerpos	; Load current position
		cmp #$A9	; Make sure it's not $A9
		beq noadd	; If it is, don't move!
		adc #1		; If it's not, add 1 to x-position
		sta playerpos	; Store in playerpos
		lda #%00000010
		sta $0202
		jsr animategirl
checkleft:
	lda playerbuttons
	and #%01000000		; Bit 6 is "left"
	beq noadd		; Skip move if zero/not pressed
	moveleft:		; (Sim. to code above but for moving left)
		clc
		lda #$4F	; Don't move left past $4F (wall)
		cmp playerpos
		beq noadd
		lda playerpos	; Ok to move
		adc #255	; Add 255 (= -1) to position
		sta playerpos	; Store in playerpos
		lda #%01000010
		sta $0202
		jsr animategirl
noadd:
	rts	


tickupdates:
	; check to add tick up (tickdown == 0; reset tickdown)
	; check to add maxitems (tickup == 5; reset tickup)
	; check to decrease fallframerate (tickup == 5; reset tickup)
	lda #60
	sta tickdown


	lda tickup
	clc
	adc #1
	sta tickup
	cmp #5		; Check to add new item drop
	bne keepcounting


	; Reset tickup, update maxitems, fallframerate
	; and add one more bomb to item choices

	lda #0
	sta tickup	; New minute begins

	ldx maxitems
	cpx #7		; Check if 7 items already falling
	beq checkchoices

	inx
	stx maxitems	; One more item can fall now
	

	; Initialize the xth item
	; $0201 + (x*4) to get current tile
	txa
	rol
	rol
	tay
	jsr updatetile	
	
checkchoices:
	lda itemchoices
	cmp #%11100000	; Check if already hardest setting
	beq frameupdate
	asl		; Rotate one more cake off list
	sta itemchoices

frameupdate:
	lda fallframerate
	cmp #0
	beq keepcounting
	
	sec
	sbc #1		; One less frame before items move
	sta fallframerate

keepcounting:
	rts	


updatetile:	
	ldx randomnum2	; 1 of 8 choices for bomb/cake
	txa
	clc
	lsr
	clc
	lsr
	clc
	lsr
	clc
	lsr
	clc
	lsr		; Now only bottom 3 bits relevant (0-7)
	tax		; Transfer "random" number (0 to 7) to x


	lda itemchoices	
	sta temppos
cakeorbomb:
	lda temppos
	lsr
	sta temppos
	dex
	cpx #0
	bne cakeorbomb
	
	lda temppos
	and #%00000001	; Keep only bottom bit
	cmp #1
	bne itsabomb

itsacake:
	lda #5
	jmp makenewitem
itsabomb:
	lda #2
makenewitem:	
	
	sta $0201,y
	lda #$30
	sta $0200,y		; Store starting y-coord
	
	lda #$02
	sta $0202,y

	lda randomnum2		; Setup for "random" x-coord
	adc randomnum1
	and #%00111111
	sta temppos
	clc
	adc #$5F		; Offset by at least $5F on screen

	sta $0203,y		; Store starting x-coord
	rts


collisions:

	
	; Check if the tile is active
	ldx #0
collisionloop
	inx
	txa
	asl
	asl
	tay

	lda $0201,y
	bpl playercollide	; All active tiles have value < 127 (positive)
	
	jmp finishedtile

playercollide:
	; Check if it's hitting player

	lda $0200,y
	sec
	sbc #$91	; Checking if y-coord is low enough
	bpl colcheck	; Positive means it's at least that low


	jmp floorcollide
colcheck:

	lda $0203,y
	sta temppos	; Store item x-position

	lda $0203	; Player x-position
	sec
	sbc temppos	
	bmi colplayerleft


colplayerright:
	; Player is on the right side, which
	; makes subtraction necessarily positive		
	
	; subtract 6, will be negative if within 5 pixels
	
	sec
	sbc #6
	bmi connected		; Collision!
	jmp floorcollide

colplayerleft
	; Player is on the left side, which
	; makes subtraction necessarily negative
	
	; add something from it that will make it
	; positive ONLY if it's less than 6:
	clc
	adc #5
	bpl connected		; Collision!
	jmp floorcollide

connected:
	lda $0201,y
	cmp #5
	bne boom		; Go boom if not a cake
cakepoints:
	jsr updatescore		; Points for cake!
	jsr updatetile
	jmp finishedtile
boom:
	lda #$50		; Player re-start
	sta playerpos
	lda playerlives		; Lose a life!
	sec
	sbc #1
	jsr loselife
	bpl explodingtime

floorcollide:
	; Check if it's hitting floor
	lda $0200,y
	cmp #$98
	bmi finishedtile	; Negative means it's above this spot


	; Check to see if already exploding
	; Skip to next tile if so
	lda $0201,y
	cmp #3			
	beq finishedtile
	cmp #4
	beq finishedtile

explodingtime:
	
	lda $0201,y
	cmp #2		; Verify it's a bomb

	bne noexplode
	jsr doexplosion
	jmp finishedtile

noexplode:	
	jsr updatetile
	

finishedtile:
	
	cpx #8		; 8 possible falling tiles
	bne collisionloop

	rts


; Move items
moveitems:

	ldx #0
	stx movetimer	; Reset movetimer
checkmove:
	lda $2002
	inx
	txa
	
	; Multiply by four because
	; there are 4 attribs per tile
	asl
	asl	
	tay

	;0200-0203 y-coord, tile#, attrib, x-coord
	; First tile is player
	; Next 7 tiles are potential/actual items
	; Loop through them, if it's explosion 1,
	; set to explosion 2. If it's a bomb or a cake, 
	; move it down.

	
	lda $0201,y
	
	; Explosion tile 1 check
	cmp #$03
	bne exp2chk	; If not explosion tile 1, chk tile 2
	jmp doexplosion	
exp2chk:
	; explosion2 check
	lda $0201,y
	cmp #$04
	bne cakebombchk	; If not explosion, check if cake/bomb


doexplosion:

	; Check if tile is bomb (starting new explosion)
	lda $0201,y
	cmp #2
	beq initexp


	; Continuing explosion sequence
	; Subtract the relevant bit (there are three in total).
	; If all three are gone, stop being that kind of explosion
	; (if going from exp1 to exp2, go to initexp)
	lda $0202,y
	cmp #%00000010
	beq bombanim1
	cmp #%00000011
	beq bombanim2
	cmp #%00100011
	beq bombanim3
	cmp #%01100011
	beq bombanim4
	
	lda $0201,y
	cmp #3
	beq initexp
	jsr updatetile
	jmp donemoving

	;Bomb animation data
bombanim4:
	lda #%11100011
	sta $0202,y		
	jmp donemoving
bombanim3:
	lda #%01100011
	sta $0202,y		
	jmp donemoving
bombanim2:
	lda #%00100011
	sta $0202,y		
	jmp donemoving
bombanim1:
	lda #%00000011
	sta $0202,y
	jmp donemoving


	
initexp:
	; Turn from bomb to explosion1,
	; or explosion1 to explosion2
	lda $0201,y
	clc
	adc #1
	sta $0201,y
	lda #%00000010
	sta $0202,y
	jmp donemoving


cakebombchk:
	; If it's not an explosion,
	; it must be a bomb or cake,
	; so move it down
	
		
	lda $0200,y
	clc
	adc #1
	sta $0200,y
		

donemoving:	
	cpx maxitems
	bne checkmove

	rts


loselife:
life3:
	lda $022D
	cmp #00
	bne life2
	lda #06
	sta $022D
	rts
life2:
	lda $0229
	cmp #00
	bne life1
	lda #06
	sta $0229
	rts

life1:
	jmp startgame


updatescore:
	
	lda playerscore_lo
	clc
	adc #1
	sta playerscore_lo
	cmp #39
	bne noaddcarry
	lda #29
	sta playerscore_lo	; Reset to 0 (added 1 to 9)
	lda playerscore_mid
	clc
	adc #1
	sta playerscore_mid
	cmp #39
	bne noaddcarry
addcarry:
	lda #29
	sta playerscore_mid
	lda playerscore_hi
	clc
	adc #1
	sta playerscore_hi

noaddcarry:
	; Go to namespace address for score tiles
	; and update them

	lda $2002
	lda #$22 		
	sta $2006
	lda #$E9 		
	sta $2006
updating:
	lda playerscore_hi
	sta $2007
	lda playerscore_mid
	sta $2007
	lda playerscore_lo
	sta $2007
	lda #0
	sta $2005
	sta $2005
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Music and graphics data ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;


initial_palette:
	db $2A,$27,$0F,$1A  ; Background palettes
	db $2A,$23,$33,$1A
	db $2A,$22,$33,$1A
	db $2A,$27,$31,$1A
	db $0F,$0F,$27,$16  ; bomb palette
	db $0F,$27,$16,$11  ; cake palette
	db $0F,$07,$27,$25  ; girl palette
	db $0F,$2d,$16,$2d  ; extra palette


sprites:

	db $98, $00, $02, $78 ; Girl #1

; Background data
	
backgrounddata_walls:
	
	db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01

backgrounddata_words:
	db $09,$02,$11,$11,$1A			; HAPPY
	db $03,$0A,$13,$15,$09,$05,$02,$1A, $1C	; BIRTHDAY

scorelivetiles:
	db $0D, $0A, $17, $06, $14	; LIVES
	db $14, $04, $10, $13, $06, $2C, $1D, $1D, $1D, $1D ; SCORE 0000

scoresprite:

	db $AE, $00, $02, $45 ; Girl #1
	db $AE, $00, $02, $4D ; Girl #1
	db $AE, $00, $02, $55 ; Girl #1



	org $FFFA
	dw nmihandler
	dw startgame
	dw irqhandler

chr_rom_start:

background_tile_start:

	db %00000000	; "Blank" tile
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF	; bitplane 2

	db %11101110	; Brick tile
	db %11101110
	db %10111011
	db %10111011
	db %11101110
	db %11101110
	db %10111011
	db %10111011

	db %00010001	; bitplane 2
	db %00010001
	db %01000100
	db %01000100
	db %00010001
	db %00010001
	db %01000100
	db %01000100

	db %00000000	
	db %00011000	; "A"
	db %00100100
	db %01000010
	db %01000010
	db %01111110
	db %01000010
	db %01000010
	db $00, $00, $00, $00, $00, $00, $00, $00	; bitplane 2

	db %00000000
	db %11111000	; "B"
	db %10000100
	db %10000100
	db %11111000
	db %10001000
	db %10000100
	db %11111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00111100	; "C"
	db %01000010
	db %10000000
	db %10000000
	db %10000000
	db %10000010
	db %01111100

	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11100000	; "D"
	db %10010000
	db %10001100
	db %10000110
	db %10000110
	db %10011000
	db %11100000

	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "E"
	db %11111110
	db %10000000
	db %10000000
	db %11111100
	db %10000000
	db %10000000
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "F"
	db %11111110
	db %10000000
	db %10000000
	db %11111100
	db %10000000
	db %10000000
	db %10000000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00111000	; "G"
	db %01000100
	db %10000000
	db %10000000
	db %10011100
	db %10000110
	db %01111100

	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "H"
	db %10000010
	db %10000010
	db %10000010
	db %11111110
	db %10000010
	db %10000010
	db %10000010
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11111110	; "I"
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00


	db %00000000
	db %11111110	; "J"
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %10010000
	db %01110000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "K"
	db %10000100
	db %10011000
	db %11100000
	db %10100000
	db %10011000
	db %10000100

	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "L"
	db %10000000
	db %10000000
	db %10000000
	db %10000000
	db %10000000
	db %10000000
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "M"
	db %11000110
	db %10101010
	db %10010010
	db %10000010
	db %10000010
	db %10000010
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "N"
	db %11000010
	db %10100010
	db %10010010
	db %10001010
	db %10000110
	db %10000010

	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "O"
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %01111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "P"
	db %10000010
	db %10000010
	db %11111100
	db %10000000
	db %10000000
	db %10000000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111000	; "Q"
	db %10000100
	db %10000010
	db %10000010
	db %10001010
	db %10000100
	db %01111010
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00111000	; "R"
	db %11000100
	db %10000100
	db %11111100
	db %10001000
	db %10000100
	db %10000110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "S"
	db %11000010
	db %10000000
	db %01110000
	db %00001100
	db %10000110
	db %11111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11111110	; "T"
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "U"
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "V"
	db %10000010
	db %10000010
	db %10000010
	db %01000100
	db %00101000
	db %00010000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %10000010	; "W"
	db %10000010
	db %10000010
	db %10000010
	db %10010010
	db %10101010
	db %01000100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "X"
	db %10000010	
	db %01000100
	db %00101000
	db %00010000
	db %00101000
	db %01000100
	db %10000010
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000	; "Y"
	db %10000010	
	db %01000100
	db %00101000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11111110	; "Z"
	db %00001100	
	db %00011000
	db %00110000
	db %01100000
	db %11000000
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00010000	; "!"
	db %00010000
	db %00010000
	db %00010000
	db %00000000
	db %00010000
	db %00010000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "0"
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %10000010
	db %01111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00010000	; "1"
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db %00010000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "2"
	db %10000010
	db %00000100
	db %00001000
	db %00110000
	db %01000000
	db %11111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %01111100	; "3"
	db %10000010
	db %00000100
	db %00011000
	db %00000100
	db %10000010
	db %01111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00001110	; "4"
	db %00010010
	db %00100010
	db %01111110
	db %00000010
	db %00000010
	db %00000010
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11111110	; "5"
	db %10000000
	db %10000000
	db %11111000
	db %00000100
	db %10000010
	db %01111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00010000	; "6"
	db %00100000
	db %01000000
	db %01111000
	db %10000100
	db %10000100
	db %01111100
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %11111110	; "7"
	db %00000100
	db %00001000
	db %00010000
	db %00100000
	db %01000000
	db %10000000
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00011000	; "8"
	db %00100100
	db %01000010
	db %00111000
	db %01000100
	db %10000010
	db %01111110
	db $00, $00, $00, $00, $00, $00, $00, $00

	db %00000000
	db %00011000	; "9"
	db %00100100
	db %01000010
	db %00111110
	db %00000010
	db %00000010
	db %00000010
	db $00, $00, $00, $00, $00, $00, $00, $00

background_tile_end:
	ds 4096-(background_tile_end-background_tile_start)


sprite_tile_start:


	db %00000000	; "Person walk" (0)
	db %00011100
	db %00010000
	db %00010000
	db %00011100
	db %00001100
	db %00001100
	db %00010010

	db %00000000	; "Person walk bp2" 
	db %00000000
	db %00001100
	db %00001100
	db %00001100
	db %00001100
	db %00001100
	db %00000000

	db %00000000	; "Person standing" (1)
	db %00011100
	db %00010000
	db %00010000
	db %00011100
	db %00001100
	db %00001100
	db %00001100

	db %00000000	; "Person standing bp2"
	db %00000000
	db %00001100
	db %00001100
	db %00001100
	db %00001100
	db %00001100
	db %00000000

	db %00000000	; "bomb" (2)
	db %00001000
	db %00111100
	db %01111110	
	db %01111110	
	db %01111110	
	db %00111100	
	db %00000000


	db %00001000	; "bomb bp2"
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000
	db %00000000	


	db %00000000	; "bomb explosion!" (3)
	db %00000000
	db %00000000
	db %00000000	
	db %00000000	
	db %00000000	
	db %00000000	
	db %00000000


	db %00000100	; "explosion bp2"
	db %01101010
	db %10111101
	db %01111111
	db %11111110
	db %10111111
	db %01111100
	db %00100110	

	db %00000100	; "bomb explosion! 2 (4)"
	db %01101010
	db %10111101
	db %01111111
	db %11111110
	db %10111111
	db %01111100
	db %00100110


	db %00000100	; "explosion bp2"
	db %01101010
	db %10111101
	db %01111111
	db %11111110
	db %10111111
	db %01111100
	db %00100110	


	db %00000000	; "Cake" (5)
	db %00000000
	db %00000000
	db %00111100	
	db %00111100	
	db %00111100	
	db %00111100	
	db %01111110


	db %00000000	; "Cake bp2"
	db %00000000
	db %00000000
	db %00000000
	db %00111100
	db %00000000
	db %00111100
	db %00000000	


sprite_tile_end

	
chr_rom_end:

; Pad chr-rom to 8k(to make valid file)
	ds 8192-(chr_rom_end-chr_rom_start)