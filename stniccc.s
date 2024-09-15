; == PoC of the STNICCC demo using FX features  ==

; To build: cl65 -t cx16 -o STNICCC.PRG stniccc.s
; To run: x16emu.exe -prg STNICCC.PRG -run -ram 2048

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
RAM_BANK                   = $00
ROM_BANK                   = $01

; Temp vars
TMP1                       = $02
TMP2                       = $03
TMP3                       = $04
TMP4                       = $05

; For generating code and loading/storing
CODE_ADDRESS               = $2F ; 30
LOAD_ADDRESS               = $31 ; 32
STORE_ADDRESS              = $33 ; 34

; Used by the slow polygon filler
FILL_LENGTH_LOW            = $40
FILL_LENGTH_HIGH           = $41
NUMBER_OF_ROWS             = $42

; FIXME: REMOVE THIS!?
NEXT_STEP                  = $45
NR_OF_POLYGONS             = $46
NR_OF_FRAMES               = $47 ; 48
BUFFER_NR                  = $49
SPRITE_X                   = $4A ; 4B
CURRENT_RAM_BANK           = $4C

VRAM_ADDRESS               = $50 ; 51 ; 52

; FIXME: these are TEMPORARY variables and should be REMOVE or REPLACED!
VSYNC_FRAME_COUNTER        = $53 ; 54
DEFAULT_IRQ_VECTOR         = $55 ; 56


SCENE_FILE_NUMBER =          $65

FRAME_ADDRESS =              $68 ; 69

INDEXED_COORDS_ADDRESS =     $70 ; 71
INDEXED_COORDS_ADDRESS_128 = $72 ; 73
CURRENT_POLYGON_ADDRESS =    $74 ; 75
BYTES_SO_FAR =               $76
FRAME_FLAGS =                $77
FRAME_INDEX =                $78
; FIXME: remove? CURRENT_RAM_BANK =           $79


CURRENT_COLOR_BOTH_NIBBLES = $4D
CURRENT_COLOR_LEFT_NIBBLE =  $4E
CURRENT_COLOR_RIGHT_NIBBLE = $4F

PALETTE_MASK =               $54 ; 55
RED =                        $56

VERTEX_INDEX_IN_POLYGON =    $59
NR_OF_VERTICES_IN_POLYGON =  $5A
NR_OF_VERTICES_IN_POLYGON_BYTES = $5B
NR_OF_INDEXED_VERTICES_BYTES = $5C ; 5D

CURRENT_BUFFER =             $5F


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

; FIXME!
; FIXME!
; FIXME!
CLEAR_256_BYTES_CODE     = $5000   ; takes up to 00F0+rts (256 bytes to clear = 80 * stz = 80 * 3 bytes)
; FIXME!
; FIXME!
; FIXME!
VERTICES                 = $50F0   ; 7 * 2 bytes (max 7 vertices with and x and y coordinate)

LEFT_NIBBLE_TO_RIGHT_NIBBLE = $5100   ; 256 bytes NOTE: this contains very little data, butwe have a left nibble (4 highest bits) so we need 256 bytes
LEFT_NIBBLE_TO_BOTH_NIBBLES = $5101   ;


; === Other constants ===

BACKGROUND_COLOR = 0
BLACK_COLOR = 254     ; this is a non-transparant black color
STARTING_BACKGROUND_COLOR = $16  ; this is the color of the first wall shown

LOAD_FILE = 1
USE_JUMP_TABLE = 1
DEBUG = 0

VSYNC_BIT         = $01

; FIXME: TURN this OFF in PRODUCTION!
;DEBUG_SHOW_THREE_FRAMES_MISSES = 1 ; If we exceed 3 frames, we missed a frame (or more) and we mark this (for now) by changing the border color

; --- Start of program ---
start:

    sei
    
    ; ---- load scene files ----
    
    lda #1
    sta SCENE_FILE_NUMBER
load_next_scene_file:
    jsr load_scene_file
    inc SCENE_FILE_NUMBER
    lda SCENE_FILE_NUMBER
    cmp #$51
    bne load_next_scene_file
    
;    jsr init_playback_screen

    ; Clear buffer $00
    ; Clear buffer $01
    
    ; Setting the border color to black
;    lda #0
;    sta VERA_DC_BORDER

    ; Start stream playback
    jsr playback_stream


tmp_loop:
    jmp tmp_loop
    
    rts
    
    

playback_stream:

    ; --- init addresses ---

    lda #0
    sta FRAME_INDEX
    
    lda #$81               ; We start at scene file 01, which corresponds to RAM BANK $81
    sta CURRENT_RAM_BANK
    sta RAM_BANK
    
    lda #$00
    sta FRAME_ADDRESS
    lda #$A0
    sta FRAME_ADDRESS+1

    
next_frame:

    lda CURRENT_RAM_BANK
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it
    
    ldy #0
    lda (FRAME_ADDRESS), y    ; frame flags
    sta FRAME_FLAGS
    iny
    and #$01  ; clear screen
    beq screen_cleared_or_ready
    
; FIXME: use phy/ply instead!
    tya
    pha
; FIXME!
;    jsr clear_playback_screen_fast_4bits
    pla
    tay
    
screen_cleared_or_ready:

    lda FRAME_FLAGS
    and #$02  ; frame contains palette
    beq palette_loaded
    
    jsr load_palette  ; NOTE: this increases y

palette_loaded:

    lda FRAME_FLAGS
    and #$04  ; frame contains indexed vertices
    beq non_indexed_frame

indexed_frame:
    jsr prepare_indexed_draw
    jsr draw_indexed_frame
    bra done_drawing_frame
    
non_indexed_frame:

    jsr prepare_non_indexed_draw    
    jsr draw_non_indexed_frame
    
done_drawing_frame:

    cpx #$FD
    beq end_of_video
    
    cpx #$FE    ; block/ram bank marker
    bne increment_frame_address

    ; We go to the next ram bank and we set the frame address to $A000
    inc CURRENT_RAM_BANK
    
    lda #$00
    sta FRAME_ADDRESS
    lda #$A0
    sta FRAME_ADDRESS+1
    bra frame_address_set

increment_frame_address:

    ; We set the next frame address to the last current polygon address (of the latest frame)
    lda CURRENT_POLYGON_ADDRESS
    sta FRAME_ADDRESS
    lda CURRENT_POLYGON_ADDRESS+1
    sta FRAME_ADDRESS+1

frame_address_set:

    inc FRAME_INDEX
    lda FRAME_INDEX

    ; Show the buffer we just wrote to
    lda CURRENT_BUFFER
    bne set_buffer_1_address
    
set_buffer_0_address:
    lda #($000 >> 1)
    sta VERA_L0_TILEBASE
    bra buffer_address_set
    
set_buffer_1_address:
    lda #($100 >> 1)
    sta VERA_L0_TILEBASE
    
buffer_address_set:

    jmp next_frame

end_of_video:

    rts


; ===================== Load Palette =================================    

load_palette:

    lda VERA_ADDR_BANK
    pha

    ; Preparing VERA to store palette colors
    ldx #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    stx VERA_ADDR_BANK

    lda #$FA
    sta VERA_ADDR_HIGH
    lda #0
    sta VERA_ADDR_LOW

    lda (FRAME_ADDRESS),y
    sta PALETTE_MASK
    iny
    lda (FRAME_ADDRESS),y
    sta PALETTE_MASK+1
    iny
    
    ldx #$FF           ; color-index (we start at 255)
next_color_LO:
    inx
    cpx #8
    beq end_colors_LO  ; when we reach color #8 we have to stop with this mask-byte
    
    rol PALETTE_MASK  ; check left-most bit
    bcc palette_color_not_changed_LO ; if carry is not set, we do not load a next color (no color info in palette for that color). We (effectively) store random colors instead
    
    ; -- we have to construct the color

    lda (FRAME_ADDRESS),y
    iny
    
    and #07    ; get the red bits
    asl        ; shift one bit to the left (3-bit color to 4-bit color)
    sta RED
    
    lda (FRAME_ADDRESS),y
    iny
    
    asl        ; shift one bit to the left (3-bit color to 4-bit color)

    sta VERA_DATA0
    lda RED
    sta VERA_DATA0
    
    jmp next_color_LO
    
palette_color_not_changed_LO:

    ; We should NOT store into unchanged palette entries! So we LOAD from DATA0 now!
    lda VERA_DATA0
    lda VERA_DATA0
    jmp next_color_LO

end_colors_LO:
    dex         ; TODO: we decrement x first to get it to #7 again (since its incremented immediatly)

next_color_HI:
    inx
    cpx #16
    beq end_colors_HI  ; when we reach color #16 we have to stop with this (last) mask-byte
    
    rol PALETTE_MASK+1  ; check left-most bit
    bcc palette_color_not_changed_HI ; if carry is not set, we do not load a next color (no color info in palette for that color). We (effectively) store random colors instead
    
    ; -- we have to construct the color

    lda (FRAME_ADDRESS),y
    iny
    
    and #07    ; get the red bits
    asl        ; shift one bit to the left (3-bit color to 4-bit color)
    sta RED
    
    lda (FRAME_ADDRESS),y
    iny
    
    asl        ; shift one bit to the left (3-bit color to 4-bit color)

    sta VERA_DATA0
    lda RED
    sta VERA_DATA0
    jmp next_color_HI
    
palette_color_not_changed_HI:
    ; We should NOT store into unchanged palette entries! So we LOAD from DATA0 now!
    lda VERA_DATA0
    lda VERA_DATA0
    jmp next_color_HI
    
end_colors_HI:

    pla
    sta VERA_ADDR_BANK

    rts


prepare_indexed_draw:

    lda (FRAME_ADDRESS),y   ; number of (indexed) vertices
    iny
    asl
    sta NR_OF_INDEXED_VERTICES_BYTES
    lda #0
    rol       ; if there was a carry we put it in a
    sta NR_OF_INDEXED_VERTICES_BYTES+1
    
    ; --- create INDEXED_COORDS_ADDRESS by adding FRAME_ADDRESS + y bytes
    sty BYTES_SO_FAR
    clc
    lda FRAME_ADDRESS
    adc BYTES_SO_FAR
    sta INDEXED_COORDS_ADDRESS
    lda FRAME_ADDRESS+1
    adc #0
    sta INDEXED_COORDS_ADDRESS+1

    ; FIXME: this is a bit of an ugly solution, but it works (probably better than copying and splitting into two (X and Y) tables
    ; FIXME: we only need this address if we have more than 128 indexed vertices
    ; INDEXED_COORDS_ADDRESS_128 is 256 bytes further than INDEXED_COORDS_ADDRESS
    lda INDEXED_COORDS_ADDRESS
    sta INDEXED_COORDS_ADDRESS_128
    clc
    lda INDEXED_COORDS_ADDRESS+1
    adc #1 ; +256
    sta INDEXED_COORDS_ADDRESS_128+1

    clc
    lda INDEXED_COORDS_ADDRESS
    adc NR_OF_INDEXED_VERTICES_BYTES
    sta CURRENT_POLYGON_ADDRESS
    lda INDEXED_COORDS_ADDRESS+1
    adc NR_OF_INDEXED_VERTICES_BYTES+1
    sta CURRENT_POLYGON_ADDRESS+1

    rts
    
prepare_non_indexed_draw:

    ; --- create INDEXED_COORDS_ADDRESS by adding FRAME_ADDRESS + y bytes
    sty BYTES_SO_FAR
    clc
    lda FRAME_ADDRESS
    adc BYTES_SO_FAR
    sta CURRENT_POLYGON_ADDRESS
    lda FRAME_ADDRESS+1
    adc #0
    sta CURRENT_POLYGON_ADDRESS+1
    
    rts
    
    
; ===================== Draw Indexed Frame =======================

draw_indexed_frame:

; FIXME: remove?
;    lda #0
;    sta CURRENT_POLYGON_INDEX
    
next_polygon_in_indexed_frame:

    ldy #0
    lda (CURRENT_POLYGON_ADDRESS),y  ; two nibbles: color + NR_OF_VERTICES_IN_POLYGON
   
    cmp #$FD
    bcc continue_indexed_frame
    jmp end_of_indexed_frame
    
continue_indexed_frame:
    
    tax       ; keep the orignal (combined) value
    and #$0F  ; only leaving the NR_OF_VERTICES_IN_POLYGON
    sta NR_OF_VERTICES_IN_POLYGON
    
    txa       ; original
    and #$F0  ; only leaving the color (left nibble)
    sta CURRENT_COLOR_LEFT_NIBBLE
    tax

    lda LEFT_NIBBLE_TO_RIGHT_NIBBLE, x
    sta CURRENT_COLOR_RIGHT_NIBBLE
    lda LEFT_NIBBLE_TO_BOTH_NIBBLES, x
    sta CURRENT_COLOR_BOTH_NIBBLES
    
; FIXME: maybe based on NR_OF_VERTICES_IN_POLYGON jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
; FIXME: maybe based on NR_OF_VERTICES_IN_POLYGON jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
; FIXME: maybe based on NR_OF_VERTICES_IN_POLYGON jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
    
    ; NOTE: we start with 1, since the first byte is the color+NR_OF_VERTICES_IN_POLYGON
    ldy #1
    sty VERTEX_INDEX_IN_POLYGON
    ldx #0

    ; FIXME: we probably want to copy the polygon data to a fixed place so we can access it using x as index (now we can only use y)
    ;        OR we change the "lda (CURRENT_POLYGON_ADDRESS), y" into "lda CURRENT_POLYGON_ADDRESS, x" and patch the address
load_next_vertex_indexed:
    
; FIXME: use this: load_from_current_polygon_address:
    lda (CURRENT_POLYGON_ADDRESS), y   ; loads the index of the vertex
    
    asl  ; do vertex-index * 2
    bcs indexed_coords_address_HI  ; if we overflow (carry set) then we must look 128 positions further in the indexed table
    
indexed_coords_address_LO:
    tay  ; put the vertex-index * 2 in y
    lda (INDEXED_COORDS_ADDRESS),y
    sta VERTICES, x
    iny
    lda (INDEXED_COORDS_ADDRESS),y
    sta VERTICES+1, x
    bra vertex_coords_loaded

indexed_coords_address_HI:
    tay  ; put the vertex-index * 2 in y
    lda (INDEXED_COORDS_ADDRESS_128),y
    sta VERTICES, x
    iny
    lda (INDEXED_COORDS_ADDRESS_128),y
    sta VERTICES+1, x

vertex_coords_loaded:
 
    inc VERTEX_INDEX_IN_POLYGON
    ldy VERTEX_INDEX_IN_POLYGON
    inx
    inx
    
    cpy NR_OF_VERTICES_IN_POLYGON
    bcc load_next_vertex_indexed
    beq load_next_vertex_indexed

; FIXME!    jsr draw_polygon_fast


    lda CURRENT_RAM_BANK
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it

; FIXME: maybe we could only let x increase, and just before it reaches 255 we increment CURRENT_POLYGON_ADDRESS?
;        the problem is that the storing in the vertices table(s) will be wrong, so those have to be patched (negating the advantage)
    clc
    lda CURRENT_POLYGON_ADDRESS
    inc NR_OF_VERTICES_IN_POLYGON ; we add one byte: "the byte with color + nr of vertices in polygon"
    adc NR_OF_VERTICES_IN_POLYGON ; one byte for each vertex-index in the polygon
    sta CURRENT_POLYGON_ADDRESS
    lda CURRENT_POLYGON_ADDRESS+1
    adc #0
    sta CURRENT_POLYGON_ADDRESS+1
    
    jmp next_polygon_in_indexed_frame
    
end_of_indexed_frame:    

    tax                           ; we put the MARK-byte in x
    clc
    lda CURRENT_POLYGON_ADDRESS
    adc #1   ; the MARKING byte 
    sta CURRENT_POLYGON_ADDRESS
    lda CURRENT_POLYGON_ADDRESS+1
    adc #0
    sta CURRENT_POLYGON_ADDRESS+1

    rts
    


; ===================== Draw Non-Indexed Frame =======================

draw_non_indexed_frame:

; FIXME: remove?
;    lda #0
;    sta CURRENT_POLYGON_INDEX
    
next_polygon_in_non_indexed_frame:

    ldy #0
    lda (CURRENT_POLYGON_ADDRESS),y  ; two nibbles: color + NR_OF_VERTICES_IN_POLYGON
    
    cmp #$FD
    bcs end_of_non_indexed_frame
    
    tax       ; keep the orignal (combined) value
    and #$0F  ; only leaving the NR_OF_VERTICES_IN_POLYGON
    sta NR_OF_VERTICES_IN_POLYGON
    asl       ; we have to do NR_OF_VERTICES_IN_POLYGON * 2 bytes
    sta NR_OF_VERTICES_IN_POLYGON_BYTES
    
    txa       ; original
    and #$F0  ; only leaving the color (left nibble)
    sta CURRENT_COLOR_LEFT_NIBBLE
    tax

    lda LEFT_NIBBLE_TO_RIGHT_NIBBLE, x
    sta CURRENT_COLOR_RIGHT_NIBBLE
    lda LEFT_NIBBLE_TO_BOTH_NIBBLES, x
    sta CURRENT_COLOR_BOTH_NIBBLES
    
    ; FIXME: use only y here, dont use x
    
    ; NOTE: we start with 1, since the first byte is the color+NR_OF_VERTICES_IN_POLYGON
    ldy #1
    
    ldx #0 ; We start with 0 for the verices array
    
    ; FIXME: we probably want to copy the polygon data to a fixed place so we can access it using x as index (now we can only use y)
    ;        OR we change the "lda (CURRENT_POLYGON_ADDRESS), y" into "lda CURRENT_POLYGON_ADDRESS, x" and patch the address
load_next_vertex_non_indexed:
    
    lda (CURRENT_POLYGON_ADDRESS), y   ; loads the x-coord
    iny
    sta VERTICES, x
    
    lda (CURRENT_POLYGON_ADDRESS), y   ; loads the y-coord
    iny
    sta VERTICES+1, x ; TODO: we dont have to do +1 here, we can simply increase x
    inx
    inx
    
    cpy NR_OF_VERTICES_IN_POLYGON_BYTES
    bcc load_next_vertex_non_indexed
    beq load_next_vertex_non_indexed
 
; FIXME! 
;    jsr draw_polygon_fast
    
    lda CURRENT_RAM_BANK
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it
    
    clc
    lda CURRENT_POLYGON_ADDRESS
    inc NR_OF_VERTICES_IN_POLYGON_BYTES ; we add one byte: "the byte with color + nr of vertices in polygon"
    adc NR_OF_VERTICES_IN_POLYGON_BYTES ; one byte for each vertex-index in the polygon
    sta CURRENT_POLYGON_ADDRESS
    lda CURRENT_POLYGON_ADDRESS+1
    adc #0
    sta CURRENT_POLYGON_ADDRESS+1
    
    jmp next_polygon_in_non_indexed_frame
    
end_of_non_indexed_frame:    

    tax                           ; we put the MARK-byte in x
    clc
    lda CURRENT_POLYGON_ADDRESS
    adc #1   ; the MARKING byte 
    sta CURRENT_POLYGON_ADDRESS
    lda CURRENT_POLYGON_ADDRESS+1
    adc #0
    sta CURRENT_POLYGON_ADDRESS+1

    rts
  

; ====================== LOAD SCENE FILE ==============================


scene_filename:      .byte    "scene/00.bin"
end_scene_filename:

; https://gist.github.com/JimmyDansbo/f955378ee4f1087c2c286fcd6956e223
; https://www.commanderx16.com/forum/index.php?/topic/80-loading-a-file-into-vram-assembly/
load_scene_file:

    lda SCENE_FILE_NUMBER
    ora #$80               ; We put the SCENE data into RAM BANKs 128 and higher
    sta RAM_BANK
    
    jsr set_scene_filename
    
    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_scene_filename-scene_filename) ; Length of scene filename
    ldx #<scene_filename      ; Low byte of Fname address
    ldy #>scene_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #$A0            ; VERA HIGH address
    ldx #$00            ; VERA LOW address

    lda #$00            ; RAM?
    jsr LOAD            ; Load binary file into VRAM, ignoring 2 first bytes
    
    rts
    

set_scene_filename:

    lda SCENE_FILE_NUMBER
    and #$0F
    
    cmp #$0A
    bcs low_nibble_a
    
low_nibble_0:
    clc
    adc #48-0  ; = '0'
    sta scene_filename+7
    bra low_nibble_done
    
low_nibble_a:
    clc
    adc #65-10  ; = 'a'
    sta scene_filename+7
    
low_nibble_done:

    lda SCENE_FILE_NUMBER
    lsr
    lsr
    lsr
    lsr
    and #$0F
    
    cmp #$0A
    bcs high_nibble_a
    
high_nibble_0:
    clc
    adc #48-0  ; = '0'
    sta scene_filename+6
    bra high_nibble_done
    
high_nibble_a:
    clc
    adc #65-10  ; = 'a'
    sta scene_filename+6
    
high_nibble_done:

    rts

