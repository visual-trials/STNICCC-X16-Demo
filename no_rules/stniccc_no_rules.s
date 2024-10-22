; == PoC of the STNICCC (without rules) demo  ==

; To build: cl65 -t cx16 -o STNICCC-NO-RULES.PRG stniccc_no_rules.s
; To run: x16emu.exe -prg STNICCC-NO-RULES.PRG -run -ram 2048

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; TODO: The following is *copied* from my x16.s (it should be included instead)

; -- some X16 constants --

VERA_ADDR_LOW     = $9F20
VERA_ADDR_HIGH    = $9F21
VERA_ADDR_BANK    = $9F22
VERA_DATA0        = $9F23
VERA_DATA1        = $9F24
VERA_CTRL         = $9F25

VERA_IEN          = $9F26
VERA_ISR          = $9F27
VERA_IRQLINE_L    = $9F28
VERA_SCANLINE_L   = $9F28

VERA_DC_VIDEO     = $9F29  ; DCSEL=0
VERA_DC_HSCALE    = $9F2A  ; DCSEL=0
VERA_DC_VSCALE    = $9F2B  ; DCSEL=0
VERA_DC_BORDER    = $9F2C  ; DCSEL=0

VERA_DC_VSTART    = $9F2B  ; DCSEL=1
VERA_DC_VSTOP     = $9F2C  ; DCSEL=1

VERA_FX_CTRL      = $9F29  ; DCSEL=2
VERA_FX_TILEBASE  = $9F2A  ; DCSEL=2
VERA_FX_MAPBASE   = $9F2B  ; DCSEL=2

VERA_FX_X_INCR_L  = $9F29  ; DCSEL=3
VERA_FX_X_INCR_H  = $9F2A  ; DCSEL=3
VERA_FX_Y_INCR_L  = $9F2B  ; DCSEL=3
VERA_FX_Y_INCR_H  = $9F2C  ; DCSEL=3

VERA_FX_X_POS_L   = $9F29  ; DCSEL=4
VERA_FX_X_POS_H   = $9F2A  ; DCSEL=4
VERA_FX_Y_POS_L   = $9F2B  ; DCSEL=4
VERA_FX_Y_POS_H   = $9F2C  ; DCSEL=4

VERA_FX_X_POS_S   = $9F29  ; DCSEL=5
VERA_FX_Y_POS_S   = $9F2A  ; DCSEL=5
VERA_FX_POLY_FILL_L = $9F2B  ; DCSEL=5
VERA_FX_POLY_FILL_H = $9F2C  ; DCSEL=5

VERA_FX_CACHE_L   = $9F29  ; DCSEL=6
VERA_FX_ACCUM_RESET = $9F29  ; DCSEL=6
VERA_FX_CACHE_M   = $9F2A  ; DCSEL=6
VERA_FX_ACCUM     = $9F2A  ; DCSEL=6
VERA_FX_CACHE_H   = $9F2B  ; DCSEL=6
VERA_FX_CACHE_U   = $9F2C  ; DCSEL=6

VERA_L0_CONFIG    = $9F2D
VERA_L0_TILEBASE  = $9F2F

; Kernal API functions
SETNAM            = $FFBD  ; set filename
SETLFS            = $FFBA  ; Set LA, FA, and SA
LOAD              = $FFD5  ; Load a file into main memory or VRAM

VERA_PALETTE      = $1FA00
VERA_SPRITES      = $1FC00


; === Zero page addresses ===

; Bank switching
RAM_BANK                  = $00
ROM_BANK                  = $01

; Temp vars
TMP1                      = $02
TMP2                      = $03
TMP3                      = $04
TMP4                      = $05

; For generating code and loading/storing
CODE_ADDRESS              = $2F ; 30
LOAD_ADDRESS              = $31 ; 32
STORE_ADDRESS             = $33 ; 34

; Used by the slow polygon filler
FILL_LENGTH_LOW           = $40
FILL_LENGTH_HIGH          = $41
NUMBER_OF_ROWS            = $42

; FIXME: REMOVE THIS!?
TMP_COLOR                 = $43
TMP_POLYGON_TYPE          = $44

NEXT_STEP                 = $45
NR_OF_POLYGONS            = $46
NR_OF_FRAMES              = $47 ; 48
BUFFER_NR                 = $49
SPRITE_X                  = $4A ; 4B
CURRENT_RAM_BANK          = $4C

VRAM_ADDRESS              = $50 ; 51 ; 52

; FIXME: these are TEMPORARY variables and should be REMOVE or REPLACED!
VSYNC_FRAME_COUNTER       = $53 ; 54
DEFAULT_IRQ_VECTOR        = $55 ; 56


; === RAM addresses ===

IRQ_VECTOR               = $0314

POLYFILL_TBLS_AND_CODE_RAM_ADDRESS = $8400 ; to $9E00
FILL_LINE_START_JUMP     = $9000   ; this is the actual jump table of 256 bytes 

Y_TO_ADDRESS_LOW_0       = $4A00
Y_TO_ADDRESS_HIGH_0      = $4B00
Y_TO_ADDRESS_BANK_0      = $4C00

Y_TO_ADDRESS_LOW_1       = $4D00
Y_TO_ADDRESS_HIGH_1      = $4E00
Y_TO_ADDRESS_BANK_1      = $4F00

CLEAR_256_BYTES_CODE     = $5000   ; takes up to 00F0+rts (256 bytes to clear = 80 * stz = 80 * 3 bytes)

POLYGON_DATA_RAM_ADDRESS = $A000
POLYGON_DATA_RAM_BANK    = 1      ; polygon data starts at this RAM bank

; === Other constants ===

BACKGROUND_COLOR = 0
BLACK_COLOR = 254     ; this is a non-transparant black color
STARTING_BACKGROUND_COLOR = $16  ; this is the color of the first wall shown

LOAD_FILE = 1
USE_JUMP_TABLE = 1
DEBUG = 0

VSYNC_BIT         = $01

; FIXME: TURN this OFF in PRODUCTION!
DEBUG_SHOW_THREE_FRAMES_MISSES = 1 ; If we exceed 3 frames, we missed a frame (or more) and we mark this (for now) by changing the border color


start:

    sei
    
    ; FIXME: do this a cleaner/nicer way!
    lda VERA_DC_VIDEO
    and #%10001111           ; Disable Layer 0, Layer 1 and sprites
    sta VERA_DC_VIDEO

    jsr copy_palette_from_index_0
    jsr generate_clear_256_bytes_code
    
    ; FIXME: use a fast clear buffers/vram!
    ; jsr clear_vram_slow
    
    ; This clears (almost) the entire VRAM and sets it to the STARTING_BACKGROUND_COLOR
    jsr clear_screen_fast_4_bytes
    
    jsr load_polyfill_tables_and_code_into_fixed_ram
    jsr generate_y_to_address_table_0
    jsr generate_y_to_address_table_1
    
    ; This also fills their buffers two 64-pixel rows of black (non transparant) pixels
    jsr setup_covering_sprites
    
    jsr setup_vera_for_layer0_bitmap_general
    
    
    ; We start with showing buffer 1 while filling buffer 0
    jsr setup_vera_for_layer0_bitmap_buffer_1
    stz BUFFER_NR

    jsr load_polygon_data_into_banked_ram
    
    ; FIXME: this vsync-handling should probably be REPLACED!
    jsr backup_default_irq_handler
    jsr enable_vsync_handler


; FIXME: HACK now looping the entire movie!
;tmp_loop:
    
    lda #POLYGON_DATA_RAM_BANK
    sta CURRENT_RAM_BANK
    
    jsr setup_polygon_filler
    jsr setup_polygon_data_address
    
    jsr draw_all_frames


    jsr unset_polygon_filler
    
; FIXME: HACK now looping the entire move!
;    jmp tmp_loop
    
    
    ; We are not returning to BASIC here...
infinite_loop:
    jmp infinite_loop
    
    rts



draw_all_frames:

; FIXME: HARDCODED!
; FIXME when the 16-bit number goes negative we have detect the end, BUT this means the NR_OF_FRAMES should be initially filled with nr_of_frames-1 !
    lda #<(1801)
    sta NR_OF_FRAMES
    lda #>(1801)
    sta NR_OF_FRAMES+1

; FIXME: replace this with something proper!
    jsr dumb_wait_for_vsync_and_three_frames

draw_next_frame:

    ldy #0
    
    ; -- Nr of polygons in this frame --
    
    lda (LOAD_ADDRESS), y
    cmp #255                  ; if nr of polygon is 255, this means we have to switch to the next RAM bank!
    bne polygon_count_is_ok
    
    inc CURRENT_RAM_BANK
    
    ; We set the new RAM Bank and we set the LOAD_ADDRESS to the start of the new RAM Bank
    jsr setup_polygon_data_address
    
    ; -- Nr of polygons in this frame --
    lda (LOAD_ADDRESS), y
    
polygon_count_is_ok:
    sta NR_OF_POLYGONS

; FIXME: we can probably *avoid* incrementing LOAD_ADDRESS each frame here! (but now we set y to 0 each polygon, so we need to think about a cleaner/better way to implement this)
    clc
    lda LOAD_ADDRESS
    adc #1
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    lda NR_OF_POLYGONS
    beq done_drawing_polygons  ; if nr of polygons is 0, we are done drawing polygons for this frame   
    
draw_next_polygon:
    jsr draw_polygon_fast
    
    clc
    tya                 ; y contained the nr of bytes we read for the previous polygon
    adc LOAD_ADDRESS
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    dec NR_OF_POLYGONS
    bne draw_next_polygon

done_drawing_polygons:
    ; FIXME: replace this with something proper!
    jsr dumb_wait_for_vsync_and_three_frames

    ; Every frame we switch to which buffer we write to and which one we show
    lda #1
    eor BUFFER_NR
    sta BUFFER_NR

    ; If we are going to fill buffer 1 (not 0) then we show buffer 0
    bne show_buffer_0
show_buffer_1:
    jsr setup_vera_for_layer0_bitmap_buffer_1
    bra done_switching_buffer
show_buffer_0:
    jsr setup_vera_for_layer0_bitmap_buffer_0
done_switching_buffer:

    sec
    lda NR_OF_FRAMES
    sbc #1
    sta NR_OF_FRAMES
    lda NR_OF_FRAMES+1
    sbc #0
    sta NR_OF_FRAMES+1
    
    bpl draw_next_frame

    rts
    



setup_polygon_filler:

    lda #%00000101           ; DCSEL=2, ADDRSEL=1
    sta VERA_CTRL
    
    .if(USE_JUMP_TABLE)
        lda #%00110000           ; ADDR1 increment: +4 byte
    .else
        lda #%00010000           ; ADDR1 increment: +1 byte
    .endif
    sta VERA_ADDR_BANK

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
   
    lda #%11100000           ; ADDR0 increment: +320 bytes
    sta VERA_ADDR_BANK

    lda #%00000010           ; Entering *polygon filler mode*
    .if(USE_JUMP_TABLE)
        ora #%01000000           ; cache write enabled = 1
    .endif
    sta VERA_FX_CTRL
    
    rts
    
unset_polygon_filler:

    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL
   
    lda #%00010000           ; ADDR0 increment: +1 bytes
    sta VERA_ADDR_BANK

    lda #%00000000           ; Exiting *polygon filler mode*
    sta VERA_FX_CTRL

    rts



setup_polygon_data_address:

    .if(LOAD_FILE)
        lda #<POLYGON_DATA_RAM_ADDRESS
    .else
        lda #<polygon_data
    .endif
    sta LOAD_ADDRESS
    .if(LOAD_FILE)
        lda #>POLYGON_DATA_RAM_ADDRESS
    .else
        lda #>polygon_data
    .endif
    sta LOAD_ADDRESS+1
    
    .if(LOAD_FILE)
        lda CURRENT_RAM_BANK
        sta RAM_BANK
    .endif
    
    rts
    
    

    
    
draw_polygon_fast:

    ldy #0
    
    ; -- Polygon type --
    lda (LOAD_ADDRESS), y
    sta TMP_POLYGON_TYPE
   
    ; FIXME: its better to use a FRAME-END code!

; FIXME: technically this name is INCORRECT, since we are MIXING single and double top draws!
single_top_free_form:
; FIXME: this iny should be moved up when we have an actual jump table!
    iny
    
    ; -- Polygon color --
    
    .if(USE_JUMP_TABLE)
        ; We first need to fill the 32-bit cache with 4 times our color
        
        lda #%00001100           ; DCSEL=6, ADDRSEL=0
        sta VERA_CTRL

        lda (LOAD_ADDRESS), y
        iny
        ; FIXME: we can SPEED this up  if we use the alternative cache incrementer! (only 2 bytes need to be set then)
        sta VERA_FX_CACHE_L      ; cache32[7:0]
        sta VERA_FX_CACHE_M      ; cache32[15:8]
        sta VERA_FX_CACHE_H      ; cache32[23:16]
        sta VERA_FX_CACHE_U      ; cache32[31:24]
    .else
        lda (LOAD_ADDRESS), y
        iny
        ; We put it into a ZP when drawing slowly
        sta TMP_COLOR
    .endif
    
    ; -- Y-start --
    
    ; FIXME: we can do this more efficiently!
    lda BUFFER_NR
    bne do_y_to_address_1
    
do_y_to_address_0:
    lda (LOAD_ADDRESS), y
    iny
    
    tax
    lda Y_TO_ADDRESS_LOW_0, x
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH_0, x
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK_0, x
    sta VERA_ADDR_BANK
    
    bra y_to_address_done

do_y_to_address_1:
    lda (LOAD_ADDRESS), y
    iny
    
    tax
    lda Y_TO_ADDRESS_LOW_1, x
    sta VERA_ADDR_LOW
    lda Y_TO_ADDRESS_HIGH_1, x
    sta VERA_ADDR_HIGH
    lda Y_TO_ADDRESS_BANK_1, x
    sta VERA_ADDR_BANK

y_to_address_done:


    lda #%00001000           ; DCSEL=4, ADDRSEL=0
    sta VERA_CTRL
    
    ; FIXME: we are MIXING single and double top drawing, so we use TMP_POLYGON_TYPE here for now!
    lda TMP_POLYGON_TYPE
    bmi set_double_x_positions
    
set_single_x_positions:
    ; -- X-position LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_POS_L
    sta VERA_FX_Y_POS_L
    
    ; -- X-position HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_POS_H
    sta VERA_FX_Y_POS_H
    
    bra done_with_x_positions
    
set_double_x_positions:
    ; -- X1-position LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_POS_L
    
    ; -- X1-position HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_POS_H

    ; -- X2-position LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_POS_L
    
    ; -- X2-position HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_POS_H
    
done_with_x_positions:

    lda #%00000110           ; DCSEL=3, ADDRSEL=0
    sta VERA_CTRL

    ; -- X1 incr LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_INCR_L

    ; -- X1 incr HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_INCR_H
    
    ; -- X2 incr LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_INCR_L

    ; -- X2 incr HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_INCR_H
    
    .if(USE_JUMP_TABLE)
        ; -- nr of lines --
        lda (LOAD_ADDRESS), y
        iny
        
        phy   ; backup y (byte offset into data)
        
        tay   ; put nr-of-lines into y register
        
        lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1

        lda #%00001010           ; DCSEL=5, ADDRSEL=0
        sta VERA_CTRL
        ldx VERA_FX_POLY_FILL_L  ; This contains: FILL_LENGTH >= 16, X1[1:0], FILL_LENGTH[3:0], 0
    
        jsr draw_polygon_part_using_polygon_filler_and_jump_tables

        ply   ; restore y (byte offset into data)
    .else
        ; -- nr of lines --
        lda (LOAD_ADDRESS), y
        iny
        sta NUMBER_OF_ROWS

        phy
    ; FIXME: temp solution for color!
        ldy TMP_COLOR
        jsr draw_polygon_part_using_polygon_filler_slow
        ply
    .endif
    
    
draw_next_part:
    
    ; -- next step code --
    lda (LOAD_ADDRESS), y
    sta NEXT_STEP
    beq done_drawing_polygon
    iny
    
    ; We know we have to either change the left or right increment (or both) so we need to set the appropiate DCSEL
    ldx #%00000110           ; DCSEL=3, ADDRSEL=0
    stx VERA_CTRL
    
    and #$01   ; bit 0 determines if we have to change the left increment
    beq left_increment_is_ok
    
    ; we (at least) have to change the left increment
    
    ; -- X1 incr LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_INCR_L

    ; -- X1 incr HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_X_INCR_H
    
left_increment_is_ok:
    
    lda NEXT_STEP
    and #$02   ; bit 1 determines if we have to change the right increment
    beq right_increment_is_ok
    
    ; we have to change the right increment

    ; -- X2 incr LOW --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_INCR_L

    ; -- X2 incr HIGH --
    lda (LOAD_ADDRESS), y
    iny
    sta VERA_FX_Y_INCR_H

right_increment_is_ok:
    
    .if(USE_JUMP_TABLE)
        ; -- nr of lines --
        lda (LOAD_ADDRESS), y
        iny
        
        phy   ; backup y (byte offset into data)
        
        tay   ; put nr-of-lines into y register
        
        lda VERA_DATA1   ; this will increment x1 and x2 and the fill_length value will be calculated (= x2 - x1). Also: ADDR1 will be updated with ADDR0 + x1

        lda #%00001010           ; DCSEL=5, ADDRSEL=0
        sta VERA_CTRL
        ldx VERA_FX_POLY_FILL_L  ; This contains: FILL_LENGTH >= 16, X1[1:0], FILL_LENGTH[3:0], 0
    
        jsr draw_polygon_part_using_polygon_filler_and_jump_tables

        ply   ; restore y (byte offset into data)
    .else
        ; -- nr of lines --
        lda (LOAD_ADDRESS), y
        iny
        sta NUMBER_OF_ROWS

        phy
    ; FIXME: temp solution for color!
        ldy TMP_COLOR
        jsr draw_polygon_part_using_polygon_filler_slow
        ply
    .endif
    
    bra draw_next_part
    
    

done_drawing_polygon:
    iny   ; We can only get here from one place, and there we still hadnt incremented y yet
    
    rts
    

    .if(USE_JUMP_TABLE)
    
draw_polygon_part_using_polygon_filler_and_jump_tables:
    jmp (FILL_LINE_START_JUMP,x)
    
    .else
    
; Routine to draw a triangle part
draw_polygon_part_using_polygon_filler_slow:

    lda #%00001010        ; DCSEL=5, ADDRSEL=0
    sta VERA_CTRL

polygon_fill_triangle_row_next:

    lda VERA_DATA1   ; This will do three things (inside of VERA): 
                     ;   1) Increment the X1 and X2 positions. 
                     ;   2) Calculate the fill_length value (= x2 - x1)
                     ;   3) Set ADDR1 to ADDR0 + X1

    ; What we do below is SLOW: we are not using all the information 
    ; we get here and are *only* reconstructing the 10-bit value.
    
    lda VERA_FX_POLY_FILL_L ; This contains: FILL_LENGTH >= 16, X1[1:0],
                          ;                FILL_LENGTH[3:0], 0
    lsr
    and #%00000111        ; We keep the 3 lower bits (note that bit 3 is ALSO in the HIGH byte, so we discard it)
                          
    sta FILL_LENGTH_LOW   ; We now have 3 bits in FILL_LENGTH_LOW

    stz FILL_LENGTH_HIGH
    lda VERA_FX_POLY_FILL_H ; This contains: FILL_LENGTH[9:3], 0
    asl
    rol FILL_LENGTH_HIGH
    asl
    rol FILL_LENGTH_HIGH  ; FILL_LENGTH_HIGH now contains the two highest bits: 8 and 9
                            
    ora FILL_LENGTH_LOW
    sta FILL_LENGTH_LOW   ; FILL_LENGTH_LOW now contains all lower 8 bits
                           

    tax
    beq done_fill_triangle_pixel  ; If x = 0, we dont have to draw any pixels
                                   
polygon_fill_triangle_pixel_next:
    sty VERA_DATA1        ; This draws a single pixel
    dex
    bne polygon_fill_triangle_pixel_next
    
done_fill_triangle_pixel:

    ; We draw an additional FILL_LENGTH_HIGH * 256 pixels on this row
    lda FILL_LENGTH_HIGH
    beq polygon_fill_triangle_row_done

polygon_fill_triangle_pixel_next_256:
    ldx #0
polygon_fill_triangle_pixel_next_256_0:
    sty VERA_DATA1
    dex
    bne polygon_fill_triangle_pixel_next_256_0
    dec FILL_LENGTH_HIGH
    bne polygon_fill_triangle_pixel_next_256
    
polygon_fill_triangle_row_done:

    ; We always increment ADDR0
    lda VERA_DATA0   ; this will increment ADDR0 with 320 bytes
                     ; So +1 vertically
    
    ; We check if we have reached the end, and if so we stop
    dec NUMBER_OF_ROWS
    bne polygon_fill_triangle_row_next
    
    rts

    .endif
    
    
generate_y_to_address_table_0:

    ; Buffer 0 starts at $00000
    stz VRAM_ADDRESS
    stz VRAM_ADDRESS+1
    stz VRAM_ADDRESS+2

    ; First entry
    ldy #0
    lda VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW_0, y
    lda VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH_0, y
    lda VRAM_ADDRESS+2
    ora #%11100000           ; +320 byte increment (=%1110)
    sta Y_TO_ADDRESS_BANK_0, y

    ; Entries 1-255
    ldy #1
generate_next_y_to_address_entry_0:
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW_0, y

    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH_0, y

    lda VRAM_ADDRESS+2
    adc #0
    sta VRAM_ADDRESS+2
    ora #%11100000           ; +320 byte increment (=%1110)
    sta Y_TO_ADDRESS_BANK_0, y

    iny
    bne generate_next_y_to_address_entry_0

    rts
    
    
generate_y_to_address_table_1:

    ; Buffer 1 starts at 31*2048 + 640 = 64128 = $0FA80
    
    lda #$80
    sta VRAM_ADDRESS
    lda #$FA
    sta VRAM_ADDRESS+1
    stz VRAM_ADDRESS+2

    ; First entry
    ldy #0
    lda VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW_1, y
    lda VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH_1, y
    lda VRAM_ADDRESS+2
    ora #%11100000           ; +320 byte increment (=%1110)
    sta Y_TO_ADDRESS_BANK_1, y

    ; Entries 1-255
    ldy #1
generate_next_y_to_address_entry_1:
    clc
    lda VRAM_ADDRESS
    adc #<320
    sta VRAM_ADDRESS
    sta Y_TO_ADDRESS_LOW_1, y

    lda VRAM_ADDRESS+1
    adc #>320
    sta VRAM_ADDRESS+1
    sta Y_TO_ADDRESS_HIGH_1, y

    lda VRAM_ADDRESS+2
    adc #0
    sta VRAM_ADDRESS+2
    ora #%11100000           ; +320 byte increment (=%1110)
    sta Y_TO_ADDRESS_BANK_1, y

    iny
    bne generate_next_y_to_address_entry_1

    rts



setup_covering_sprites:
    ; We setup 5 covering 64x64 sprites that contain 2 rows of black pixels at the bottom (actually we flip the sprite vertically, so its at the top of their buffer)
    ; We can use the 128 bytes available between the two bitmap buffer for these black pixels. Note: these pixels cannot be 0, since that would make them transparant!

    ; We first fill these 128 with a non-transparant black color
    ; The buffer of these sprites is at 320*200 (right after the end of the first buffer) = 64000 = $0FA00
    
    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK
    lda #<($FA00)
    sta VERA_ADDR_LOW
    lda #>($FA00)
    sta VERA_ADDR_HIGH

    lda #BLACK_COLOR
    ldx #128
next_black_pixel:
    sta VERA_DATA0
    dex
    bne next_black_pixel
    
    ; We then setup the actual 5 sprites

    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #<(VERA_SPRITES)
    sta VERA_ADDR_LOW
    lda #>(VERA_SPRITES)
    sta VERA_ADDR_HIGH

    ldx #0
    
    stz SPRITE_X
    stz SPRITE_X+1

setup_next_sprite:

    ; The buffer of these sprites is at 320*200 (right after the end of the first buffer) = 64000 = $0FA00

    ; Address (12:5)
    lda #<($FA00>>5)
    sta VERA_DATA0

    ; Mode,	-	, Address (16:13)
    lda #<($FA00>>13)
    ora #%10000000 ; 8bpp
    sta VERA_DATA0
    
    ; X (7:0)
    lda SPRITE_X
    sta VERA_DATA0
    
    ; X (9:8)
    lda SPRITE_X+1
    sta VERA_DATA0

    ; Y (7:0)
    lda #<(-62)
    sta VERA_DATA0

    ; Y (9:8)
    lda #>(-64)
    sta VERA_DATA0
    
    ; Collision mask	Z-depth	V-flip	H-flip
    lda #%00001110   ; Z-depth = in front of all layers, v-flip = 1
    sta VERA_DATA0

    ; Sprite height,	Sprite width,	Palette offset
    lda #%11110000 ; 64x64, 0 palette offset
    sta VERA_DATA0

    clc
    lda SPRITE_X
    adc #64
    sta SPRITE_X
    lda SPRITE_X+1
    adc #0
    sta SPRITE_X+1
    
    inx
    
    cpx #5
    bne setup_next_sprite



    rts

setup_vera_for_layer0_bitmap_general:

    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    ; Enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_CONFIG

    rts
    
    
; FIXME: this can be done more efficiently!    
setup_vera_for_layer0_bitmap_buffer_0:

    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda VERA_DC_VIDEO
    ora #%00010000           ; Enable Layer 0
    and #%10011111           ; Disable Layer 1 and sprites
    sta VERA_DC_VIDEO

    ; Set layer0 tilebase to 0x00000 and tile width to 320 px
    lda #0
    sta VERA_L0_TILEBASE

    ; Setting VSTART/VSTOP so that we have 200 rows on screen (320x200 pixels on screen)

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #20
    sta VERA_DC_VSTART
    lda #400/2+20-1
    sta VERA_DC_VSTOP
    
    rts
    
; FIXME: this can be done more efficiently!    
setup_vera_for_layer0_bitmap_buffer_1:

    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda VERA_DC_VIDEO
    ora #%01010000           ; Enable Layer 0 and sprites
    and #%11011111           ; Disable Layer 1
    sta VERA_DC_VIDEO

    ; Buffer 1 starts at: (320*200-512) = 31*2048
    
    ; Set layer0 tilebase to 0x0F800 and tile width to 320 px
    lda #(31<<2)
    sta VERA_L0_TILEBASE

    ; Setting VSTART/VSTOP so that we have 202 rows on screen (320x200 pixels on screen)

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #20-2  ; we show 2 lines of 'garbage' so the *actual* bitmap starts at 31*2048 + 640  (128 bytes after the *first* buffer ends)
    ; Note: we cover these 2 garbage-lines with five 64x64 black sprites (of which only the two last lines are actually black and have their sprite data pointed to the 128 bytes mentioned above)
    sta VERA_DC_VSTART
    lda #400/2+20-1
    sta VERA_DC_VSTOP
    
    rts

    

clear_vram_slow:

    lda #%00010000      ; setting bit 16 of vram address to 0, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    lda #0
    sta VERA_ADDR_LOW
    lda #0
    sta VERA_ADDR_HIGH

    ; FIXME: PERFORMANCE we can do this MUCH faster using CACHE writes and UNROLLING!
    
    ; We need 320*400 + 128 = 128128 bytes to be cleared
    ; This means we need 501*256 bytes to be cleared (501 = 256+245)

    lda #BACKGROUND_COLOR
    
    ; First 256*256 bytes
    ldy #0
clear_bitmap_next_256:
    ldx #0
clear_bitmap_next_1:
    sta VERA_DATA0
    inx
    bne clear_bitmap_next_1
    dey
    bne clear_bitmap_next_256

    ldy #245
clear_bitmap_next_256a:
    ldx #0
clear_bitmap_next_1a:
    sta VERA_DATA0
    inx
    bne clear_bitmap_next_1a
    dey
    bne clear_bitmap_next_256a
    
    rts

    
    
    
polyfill_tables_and_code_filename:      .byte    "polyfill-8bit-tbls-and-code.dat" 
end_polyfill_tables_and_code_filename:

load_polyfill_tables_and_code_into_fixed_ram:

    lda #(end_polyfill_tables_and_code_filename-polyfill_tables_and_code_filename) ; Length of filename
    ldx #<polyfill_tables_and_code_filename      ; Low byte of Fname address
    ldy #>polyfill_tables_and_code_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    
    jsr SETLFS
    
    lda #0            ; load into Fixed RAM (see https://github.com/X16Community/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-load )
    ldx #<POLYFILL_TBLS_AND_CODE_RAM_ADDRESS
    ldy #>POLYFILL_TBLS_AND_CODE_RAM_ADDRESS
    jsr LOAD
    bcc tables_and_code_loaded
    ; FIXME: do proper error handling!
    stp
tables_and_code_loaded:

    rts

    
    
polygon_data_filename:      .byte    "stniccc-polygons.dat" 
end_polygon_data_filename:

load_polygon_data_into_banked_ram:

    lda #(end_polygon_data_filename-polygon_data_filename) ; Length of filename
    ldx #<polygon_data_filename      ; Low byte of Fname address
    ldy #>polygon_data_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    
    jsr SETLFS
    
    lda #POLYGON_DATA_RAM_BANK
    sta RAM_BANK
    
    lda #0            ; load into Fixed RAM (current RAM Bank) (see https://github.com/X16Community/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-load )
    ldx #<POLYGON_DATA_RAM_ADDRESS
    ldy #>POLYGON_DATA_RAM_ADDRESS
    jsr LOAD
    bcc polygon_data_loaded
    ; FIXME: do proper error handling!
    stp
polygon_data_loaded:

    rts

    

copy_palette_from_index_0:

    ; Starting at palette VRAM address
    
    lda #%00010001      ; setting bit 16 of vram address to 1, setting auto-increment value to 1
    sta VERA_ADDR_BANK

    ; We start at color index 0 of the palette (we preserve the first 16 default VERA colors)
    lda #<(VERA_PALETTE)
    sta VERA_ADDR_LOW
    lda #>(VERA_PALETTE)
    sta VERA_ADDR_HIGH

    ; HACK: we know we have more than 128 colors to copy (meaning: > 256 bytes), so we are just going to copy 128 colors first
    
    ldy #0
next_packed_color_256:
    lda palette_data, y
    sta VERA_DATA0
    iny
    bne next_packed_color_256

    ldy #0
next_packed_color_1:
    lda palette_data+256, y
    sta VERA_DATA0
    iny
    ; TODO: remove this? we are now assuming all 256 colors need to be copied!
    ;    cpy #<(end_of_palette_data-palette_data)
    bne next_packed_color_1
    
    rts
    
    
    
    
clear_screen_fast_4_bytes:

    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #STARTING_BACKGROUND_COLOR
    sta VERA_FX_CACHE_L      ; cache32[7:0]
    sta VERA_FX_CACHE_M      ; cache32[15:8]
    sta VERA_FX_CACHE_H      ; cache32[23:16]
    sta VERA_FX_CACHE_U      ; cache32[31:24]

    ; We setup blit writes
    
    lda #%00000100           ; DCSEL=2, ADDRSEL=0
    sta VERA_CTRL

    lda #%01000000           ; transparent writes = 0, blit write = 1, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL

    ; -- Set the starting VRAM address --
    lda #%00110000           ; Setting bit 16 of vram address to the highest bit (=0), setting auto-increment value to 4 bytes
    sta VERA_ADDR_BANK
    
    ; We start at the very beginning of VRAM
    lda #0
    sta VERA_ADDR_HIGH
    lda #0
    sta VERA_ADDR_LOW
    
    ; Two full frame buffers + 2 extra 320-rows + two 64-rows for the covering sprites (not precise, but good enough)
    ; 128768 * 1 byte / 256 = 503 iterations = 256 + 247 iterations
    ldx #0
clear_next_256_bytes_256:
    jsr CLEAR_256_BYTES_CODE
    dex
    bne clear_next_256_bytes_256

    ldx #247
clear_next_256_bytes:
    jsr CLEAR_256_BYTES_CODE
    dex
    bne clear_next_256_bytes 
     
    lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    rts
    
    
generate_clear_256_bytes_code:

    lda #<CLEAR_256_BYTES_CODE
    sta CODE_ADDRESS
    lda #>CLEAR_256_BYTES_CODE
    sta CODE_ADDRESS+1
    
    ldy #0                 ; generated code byte counter

    ; -- We generate 64 clear (stz) instructions --
    
    ldx #64                ; counts nr of clear instructions
next_clear_instruction:

    ; -- stz VERA_DATA0 ($9F23)
    lda #$9C               ; stz ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    dex
    bne next_clear_instruction

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts

    
add_code_byte:
    sta (CODE_ADDRESS),y   ; store code byte at address (located at CODE_ADDRESS) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne done_adding_code_byte
    inc CODE_ADDRESS+1     ; increment high-byte of CODE_ADDRESS
done_adding_code_byte:
    rts

    

palette_data:
  .byte $00, $00
  .byte $33, $04
  .byte $33, $04
  .byte $33, $04
  .byte $33, $04
  .byte $44, $05
  .byte $44, $05
  .byte $55, $06
  .byte $55, $06
  .byte $55, $06
  .byte $66, $07
  .byte $66, $07
  .byte $77, $08
  .byte $77, $08
  .byte $88, $09
  .byte $88, $09
  .byte $99, $09
  .byte $99, $09
  .byte $aa, $0a
  .byte $aa, $0a
  .byte $aa, $0a
  .byte $bb, $0b
  .byte $bb, $0b
  .byte $cc, $0c
  .byte $cc, $0c
  .byte $dd, $0d
  .byte $dd, $0d
  .byte $dd, $0d
  .byte $ee, $0e
  .byte $ee, $0e
  .byte $ff, $0f
  .byte $ff, $0f
  .byte $32, $02
  .byte $32, $02
  .byte $42, $02
  .byte $43, $03
  .byte $43, $03
  .byte $53, $03
  .byte $53, $03
  .byte $53, $03
  .byte $64, $03
  .byte $64, $04
  .byte $64, $04
  .byte $74, $04
  .byte $74, $04
  .byte $74, $04
  .byte $85, $04
  .byte $85, $04
  .byte $85, $04
  .byte $95, $05
  .byte $95, $05
  .byte $95, $05
  .byte $a5, $05
  .byte $a5, $05
  .byte $a5, $05
  .byte $b6, $05
  .byte $b6, $05
  .byte $b6, $05
  .byte $c6, $05
  .byte $c6, $05
  .byte $c6, $05
  .byte $d6, $05
  .byte $d6, $05
  .byte $d7, $05
  .byte $33, $02
  .byte $33, $02
  .byte $43, $03
  .byte $44, $03
  .byte $44, $03
  .byte $55, $04
  .byte $55, $04
  .byte $55, $04
  .byte $66, $04
  .byte $66, $05
  .byte $67, $05
  .byte $67, $05
  .byte $77, $05
  .byte $78, $06
  .byte $78, $06
  .byte $79, $06
  .byte $79, $06
  .byte $79, $07
  .byte $7a, $07
  .byte $8a, $07
  .byte $8a, $08
  .byte $8b, $08
  .byte $8b, $08
  .byte $9c, $09
  .byte $9c, $09
  .byte $9d, $0a
  .byte $ad, $0a
  .byte $ad, $0a
  .byte $ae, $0b
  .byte $ae, $0b
  .byte $bf, $0c
  .byte $bf, $0c
  .byte $46, $03
  .byte $56, $03
  .byte $56, $03
  .byte $57, $03
  .byte $57, $04
  .byte $57, $04
  .byte $67, $04
  .byte $68, $04
  .byte $68, $05
  .byte $68, $05
  .byte $78, $05
  .byte $79, $05
  .byte $79, $06
  .byte $89, $06
  .byte $89, $06
  .byte $8a, $07
  .byte $8a, $07
  .byte $9a, $07
  .byte $9a, $08
  .byte $9a, $08
  .byte $ab, $09
  .byte $ab, $09
  .byte $ab, $09
  .byte $ab, $0a
  .byte $bc, $0a
  .byte $bc, $0a
  .byte $bc, $0b
  .byte $cc, $0b
  .byte $cd, $0c
  .byte $dd, $0c
  .byte $dd, $0d
  .byte $de, $0d
  .byte $34, $03
  .byte $34, $03
  .byte $44, $04
  .byte $45, $04
  .byte $45, $05
  .byte $55, $05
  .byte $56, $05
  .byte $56, $06
  .byte $56, $06
  .byte $67, $06
  .byte $67, $07
  .byte $67, $07
  .byte $78, $08
  .byte $78, $08
  .byte $78, $08
  .byte $89, $09
  .byte $89, $09
  .byte $99, $0a
  .byte $9a, $0a
  .byte $9a, $0a
  .byte $aa, $0a
  .byte $aa, $0b
  .byte $aa, $0b
  .byte $ab, $0c
  .byte $bb, $0c
  .byte $bb, $0c
  .byte $bb, $0d
  .byte $cc, $0d
  .byte $cc, $0d
  .byte $dd, $0e
  .byte $dd, $0e
  .byte $ed, $0f
  .byte $40, $0a
  .byte $40, $0a
  .byte $50, $0a
  .byte $50, $0a
  .byte $50, $0a
  .byte $60, $0b
  .byte $60, $0b
  .byte $60, $0b
  .byte $70, $0b
  .byte $70, $0c
  .byte $80, $0c
  .byte $80, $0c
  .byte $90, $0c
  .byte $90, $0c
  .byte $90, $0d
  .byte $a0, $0d
  .byte $a0, $0d
  .byte $b0, $0d
  .byte $b0, $0d
  .byte $c0, $0e
  .byte $c0, $0e
  .byte $d0, $0e
  .byte $d0, $0e
  .byte $e0, $0f
  .byte $e0, $0f
  .byte $f0, $0f
  .byte $f2, $0f
  .byte $f5, $0f
  .byte $f7, $0f
  .byte $fa, $0f
  .byte $fc, $0f
  .byte $ff, $0f
  .byte $34, $03
  .byte $44, $04
  .byte $44, $04
  .byte $45, $04
  .byte $55, $05
  .byte $56, $05
  .byte $56, $05
  .byte $67, $06
  .byte $67, $06
  .byte $77, $06
  .byte $78, $07
  .byte $78, $07
  .byte $89, $07
  .byte $89, $08
  .byte $8a, $08
  .byte $9a, $08
  .byte $9a, $09
  .byte $ab, $09
  .byte $ab, $09
  .byte $ac, $0a
  .byte $ac, $0a
  .byte $bd, $0a
  .byte $bd, $0a
  .byte $be, $0b
  .byte $ce, $0b
  .byte $cf, $0b
  .byte $df, $0b
  .byte $df, $0c
  .byte $ef, $0d
  .byte $ef, $0d
  .byte $ef, $0e
  .byte $ff, $0f
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $b5, $0e
  .byte $00, $00
  .byte $b5, $0e
end_of_palette_data:




; This is just a dumb verison of a proper vsync-wait
dumb_wait_for_vsync_and_three_frames:

    ; We wait until SCANLINE == $1FF (indicating the beam is off screen, lines 512-524)
wait_for_scanline_bit8:
    lda VERA_IEN
    and #%01000000
    beq wait_for_scanline_bit8
    
wait_for_scanline_low:
    lda VERA_SCANLINE_L
    cmp #$FF
    bne wait_for_scanline_low
       
; FIXME!
; FIXME!
; FIXME!
    bra reset_frame_counter
       
       
wait_until_three_frames_have_passed:
    ; We should be (just) past the VSYNC-IRQ now, so the vsync counter is not going to increment any time soon. We read it and wait until its 3. When it is we reset it and move on.
    
    lda VSYNC_FRAME_COUNTER
    cmp #3
    bcc wait_until_three_frames_have_passed
    
    .if(DEBUG_SHOW_THREE_FRAMES_MISSES)
        beq reset_frame_counter
        
        ; FIXME: The counter exceeded 3 frames so we missed a frame (or more) we mark this (for now) by changing the border color!
        
        lda #%00000000           ; DCSEL=0, ADDRSEL=0
        sta VERA_CTRL

        ; FIXME: quick and dirty way of showing that we missed a frame
        lda VERA_DC_BORDER
        eor #40
        sta VERA_DC_BORDER
    .endif

reset_frame_counter:
    stz VSYNC_FRAME_COUNTER
done_waiting:
    
    rts



; FIXME: REPLACE/REMOVE THIS!
; FIXME: REPLACE/REMOVE THIS!
; FIXME: REPLACE/REMOVE THIS!
backup_default_irq_handler:

    ; backup default RAM IRQ vector
    lda IRQ_VECTOR
    sta DEFAULT_IRQ_VECTOR
    lda IRQ_VECTOR+1
    sta DEFAULT_IRQ_VECTOR+1

    rts

; FIXME: REPLACE/REMOVE THIS!
; FIXME: REPLACE/REMOVE THIS!
; FIXME: REPLACE/REMOVE THIS!
enable_vsync_handler:

    ; overwrite RAM IRQ vector with custom handler address
    sei ; disable IRQ while vector is changing
    lda #<vsync_irq_handler
    sta IRQ_VECTOR
    lda #>vsync_irq_handler
    sta IRQ_VECTOR+1

    lda #VSYNC_BIT ; make VERA generate VSYNC IRQs
    sta VERA_IEN
    
    stz VSYNC_FRAME_COUNTER
    stz VSYNC_FRAME_COUNTER+1
    
    cli ; enable IRQ now that vector is properly set

    rts
    
    
vsync_irq_handler:

    pha                     ; save accumulator
    txa
    pha                     ; save X-register
    tya
    pha                     ; save Y-register
    
    lda VERA_ISR
    and #VSYNC_BIT
    beq continue_to_default_irq_hanndler  ; non-VSYNC IRQ, skip incrementing the vsync-frame-counter
    stz VERA_ISR
    
    ; Increment vsync frame counter
    inc VSYNC_FRAME_COUNTER
    bne vsync_counter_is_incremented
    inc VSYNC_FRAME_COUNTER+1
vsync_counter_is_incremented:
    
continue_to_default_irq_hanndler:

    pla
    tay                     ; restore Y-register
    pla
    tax                     ; restore X-register
    pla                     ; restore accumulator
    
    jmp (DEFAULT_IRQ_VECTOR) ; continue to default IRQ handler


