	; Basic Controller Program
	; by Thomas Wesley Scott, 2023

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
playerscore_lo equ $04
playerscore_hi equ $05
tickdown equ $06
tickup equ $07
maxitems equ $08
fallframerate equ $09


bombcount equ $10	; TODO: may be unnecessary

walkanimation equ $FF	; for walking animation of player

nmihandler:
	pha
	php

	jsr readcontroller
	
	ldx tickdown
	dex
	stx tickdown
	cpx #0
	
	bne chkcollisions
	
	jsr tickupdates
	

chkcollisions:
		
	; check collisions (floor, player)
	; make sure to randomize x position after collision with floor!
	; (but don't ever give starting position for hey gurl)


chkframerate:
	
	; Only move if fallframerate + tickdown < 60
	lda tickdown
	clc
	adc #fallframerate
	cmp #60
	bpl storenewpos

	jsr moveitems


	; check add new items? (run through all items until maxitems reached)
	; ^^ roll new item if necessary?		

	
storenewpos:
	lda playerpos
	sta $0203 

	lda #$02
	sta $4014

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
	cpx #$4
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


		
	;this clump may be redundant-chk&dlt
	clc
	lda $08
	adc #32
	sta $08
	lda $2002
	lda $09
	sta $2006
	lda $08
	sta $2006



	lda $2002
	lda #$00
	sta $2005
	sta $2005
	

	; Initialization of game data


	lda #%11111111		; All cakes as options to start
	sta itemchoices

	lda #$5A		; Player position
	sta playerpos 

	lda #3			; Start with 3 lives
	sta playerlives
	
	lda #0
	sta playerscore_lo
	sta playerscore_hi
	sta tickup		; number of seconds passed 

	lda #60
	sta tickdown		; frames in a second	

	lda #30
	sta fallframerate	; takes 30 frames to move down	
	
	lda #1
	sta maxitems		; only 1 item falling at start


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
	; check to sub fallframerate (tickup == 60; reset tickup)
	
	lda tickup
	clc
	adc #1
	cmp #60		; Has a minute passed?
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

checkchoices:
	lda itemchoices
	cmp #%10000000	; Check if already hardest setting
	beq frameupdate
	lsr		; Rotate one more cake off list

frameupdate:
	ldx fallframerate
	cpx #5
	beq resetclock
	
	txa
	sec
	sbc #5
	sta fallframrate

keepcounting:
	rts	


; Move items
moveitems:


	ldx #0
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
	
	iny	; skip x-coord
	
	;0204-0203 item 1
	lda $0200,y
	; explosion1 check
	cmp #$03
	bne exp2chk
	lda #$04
	sta $0200,y
	jmp cakebombchk
	
exp2chk:
	; explosion2 check
	jmp donemoving

cakebombchk:
	; If it's not an explosion
	; it must be a bomb or cake
	; move down if it's on the screen
	; and not busy colliding/killing someone
	
	iny	; now checking attrib, don't care, moving on
	iny	; now checking y-attrib

	lda $0200,y
	
	; START FROM HERE
	; Check if on the screen (between what and what???)
	
	; CAN YOU LABEL THE SAME NUMBER TWICE??
	; CAN YOU DO sta $addy,y ???



movedown:

donemoving:	
	cpy maxitems
	bne checkmove


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

