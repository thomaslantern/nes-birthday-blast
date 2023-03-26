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


itemchoices equ $00 	; variable for item choices; 1=cake, 0=bomb
playerpos equ $01	; variable for player's position
playerbuttons equ $02	; variable for player's buttons
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
expct equ $0E		; variable to count explosion animation



bombcount equ $10	; TODO: may be unnecessary

walkanimation equ $FF	; for walking animation of player

nmihandler:
	pha
	php

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
	; check collisions (floor), player)
	jsr collisions


chkframerate:
	
	; Only move if fallframerate = tickdown
	lda movetimer
	cmp #fallframerate

	bne storenewpos

	jsr moveitems


	; check add new items? (run through all items until maxitems reached)
	; ^^ roll new item if necessary?		

	
storenewpos:
	lda playerpos
	sta $0203 

	lda #$02
	sta $4014


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

	ldx #4
	stx walkanimation

	lda $2002

	
	ldx #$02 	; Set SPR-RAM address to 0
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


bkgd_words:		; "Happy Birthday Tommy!" tiles
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
scoresprites:
	lda scoresprite,x	; Load tiles, x and y attributes
	sta $0224,x
	inx
	cpx #$0C
	bne scoresprites


	; Initialization of game data


	lda #%11111111		; All cakes as options to start
	sta itemchoices

	lda #$5A		; Player position
	sta playerpos 

	lda #3			; Start with 3 lives
	sta playerlives
	
	lda #29
	sta playerscore_lo
	sta playerscore_mid
	sta playerscore_hi

	lda #0
	sta tickup		; number of seconds passed 

	lda #60
	sta tickdown		; frames in a second	

	lda #30
	sta fallframerate	; takes 30 frames to move down	
	
	lda #0
	sta movetimer

	lda #1
	sta maxitems		; only 1 item falling at start

	; First cake
	lda #$30
	sta $0204		; Store starting y-coord
	lda #5			; Tile # for cake
	sta $0205		; Store it as first falling item
	lda #$02
	sta $0206
	lda #$7F
	sta $0207		; Store starting x-coord


	; turn screen on
	lda #%00011110
	sta $2001
	lda #$88
	sta $2000




forever:
	jmp forever


; Walking Animation
animategirl:
	ldx walkanimation
	dex
	cpx #0
	beq movegirl
	rts
movegirl:
	ldx #4
	stx walkanimation
	lda $0201
	cmp #$00
	beq standnow
	jmp walknow
standnow:
	lda #$01
	sta $0201
	rts
walknow:
	lda #$00
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
		jsr animategirl


noadd:
	rts	


tickupdates:
	; check to add tick up (tickdown == 0; reset tickdown)
	; check to add maxitems (tickup == 60; reset tickup)
	; check to inc fallframerate (tickup == 60; reset tickup)
	lda #60
	sta tickdown

	lda tickup
	clc
	adc #1
	sta tickup
	cmp #5		; Has a minute passed?
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
	; Initialize the new item here?
	; for now just initialize it as a cake

	; Take x value, the 1+xth tile is now a cake
	; $0201 + (x*4) to get current tile
	txa
	rol
	rol
	tay
	
	jsr updatetile	
	
checkchoices:
	lda itemchoices
	cmp #%10000000	; Check if already hardest setting
	beq frameupdate
	asl		; Rotate one more cake off list
	sta itemchoices

frameupdate:
	ldx fallframerate
	cpx #5
	beq keepcounting
	
	txa
	sec
	sbc #25
	lda #1
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
	lsr		; now only bottom 3 bits relevant (0-7)
	tax


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

	lda randomnum2
	adc randomnum1
	and #%00111111
	sta temppos
	clc
	adc #$5F

	sta $0203,y		; Store starting x-coord
	rts

collisions:

	; make sure to randomize x position after collision with floor!
	; (but don't ever give starting position for hey gurl)
	
	;0201,0205,0209,020D, etc

	; Check if the tile is active
	ldx #0
collisionloop
	inx
	txa
	asl
	asl
	tay
	lda $0201,y
	
	; Check if cake or bomb/explosion
	; Bomb
	cmp #$02
	beq playercollide

	; Explosion 1
	cmp #$03
	beq playercollide

	; Explosion 2
	cmp #$04
	beq playercollide
	
	; Cake
	cmp #$05
	beq playercollide

	jmp finishedtile

playercollide:
	; Check if it's hitting player

	
	lda $0200,y
	sec
	sbc #$91	; Checking if low enough to collide
	bpl colcheck

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
	
	; subtract 9, will be negative if within 8 pixels
	
	sec
	sbc #9
	bmi connected	; Check whether points or dead lol
	jmp floorcollide
colplayerleft
	; Player is on the left side, which
	; makes subtraction necessarily negative
	
	; add something from it that will make it
	; positive ONLY if it's less than 9:
	clc
	adc #8
	bpl connected	; Dead/Point check lol
	jmp floorcollide
connected:
	lda $0201,y
	cmp #5
	bne boom
cakepoints:
	jsr updatescore	
	jsr updatetile
	jmp finishedtile
boom:
	lda #$50
	sta playerpos
	lda playerlives
	sec
	sbc #1
	jsr loselife
	bpl explodingtime
		


floorcollide:
	; Check if it's hitting floor
	lda $0200,y
	cmp #$98
	bne finishedtile

explodingtime:
	lda $0201,y
	cmp #2		; Bomb check
	bne noexplode
	jsr doexplosion
	jmp finishedtile

noexplode:	
	jsr updatetile
	

finishedtile:
	
	cpx #8
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
	; first tile is player
	; next 7 tiles are potential/actual items
	; loop through them
	; if it's explosion 1, set to explosion 2
	; if it's a bomb or a cake, move it down
	; (assuming we've already checked collision with player/floors

	
	;attrib irrelevant
	;x-coord will never change here
	;only care about tile and y-coord
	
	
	;0204-0207 item 1
	lda $0201,y
	; explosion1 check
	cmp #$03
	bne exp2chk	; If not explosion1, chk if explosion2
	jmp doexplosion	
exp2chk:
	; explosion2 check
	lda $0201,y
	cmp #$04
	bne cakebombchk	; If not explosion2, chk if cake/bomb
doexplosion:

	; Check if tile is bomb (starting new explosion)
	; If it is, load values into expct

	lda $0201,y
	cmp #2
	beq initexp

	; Continuing explosion sequence
	; subtract the relevant bit (there are three in total)
	; if all three are gone, stop being that kind of explosion
	; (if going from exp1 to exp2, go to initexp??? I think so!
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
	lda $0201,y
	clc
	adc #1
	sta $0201,y
	lda #%00000010
	sta $0202,y
	jmp donemoving


cakebombchk:
	; If it's not an explosion
	; it must be a bomb or cake
	; move down if it's on the screen
	; and not busy colliding/killing someone
	
	
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
	lda #03
	sta $022D
	rts
life2:
	lda $0229
	cmp #00
	bne life1
	lda #03
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
	sta playerscore_lo
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
	lda $2002
	lda #$22 				;22e3 where it starts score numbahs
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

