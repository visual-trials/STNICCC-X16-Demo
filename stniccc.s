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

VERA_DC_HSTART    = $9F29  ; DCSEL=1
VERA_DC_HSTOP     = $9F2A  ; DCSEL=1
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
VRAM_ADDRESS               = $35 ; 36 ; 37
BUFFER_LOAD_ADDRESS        = $38 ; 39

CHUNK_CODE_OFFSET          = $3A
CHUNK_ADDRESS_OFFSET       = $3B

; FIXME: these are TEMPORARY variables and should be REMOVE or REPLACED!
VSYNC_FRAME_COUNTER        = $3C ; 3D
DEFAULT_IRQ_VECTOR         = $3E ; 3F

; Used by the slow polygon filler
FILL_LENGTH_LOW            = $42
FILL_LENGTH_HIGH           = $43
NUMBER_OF_ROWS             = $44

; FIXME: REMOVE THIS!?
NEXT_STEP                  = $45
NR_OF_POLYGONS             = $46
NR_OF_FRAMES               = $47 ; 48
BUFFER_NR                  = $49
SPRITE_X                   = $4A ; 4B
CURRENT_RAM_BANK           = $4C

CURRENT_COLOR_BOTH_NIBBLES = $4D
CURRENT_COLOR_LEFT_NIBBLE =  $4E
CURRENT_COLOR_RIGHT_NIBBLE = $4F

VERTEX_INDEX_IN_POLYGON =    $50
NR_OF_VERTICES_IN_POLYGON =  $51
NR_OF_VERTICES_IN_POLYGON_BYTES = $52
NR_OF_INDEXED_VERTICES_BYTES = $53 ; 54

; Used by polygon filler
MIN_Y =                      $55
MAX_Y =                      $56

CURRENT_VERTEX_INDEX =       $57

X1 =                         $58
Y1 =                         $59
X2 =                         $5A
Y2 =                         $5B

CURRENT_BUFFER =             $60
; FIXME: REMOVE!
BLOCK_NUMBER =               $61      ; 64kB block number

SOURCE_BANK_NUMBER =         $66
TARGET_BANK_NUMBER =         $67

FRAME_ADDRESS =              $68 ; 69

INDEXED_COORDS_ADDRESS =     $70 ; 71
INDEXED_COORDS_ADDRESS_128 = $72 ; 73
CURRENT_POLYGON_ADDRESS =    $74 ; 75
BYTES_SO_FAR =               $76
FRAME_FLAGS =                $77
FRAME_INDEX =                $78
BANK_INDEX_IN_BLOCK =        $79

PALETTE_MASK =               $7A ; 7B
RED =                        $7C



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

CLEAR_256_BYTES_CODE     = $5000   ; takes 00C1 bytes (256 bytes to clear = 64 * stz = 64 * 3 bytes = 192 bytes + 1 byte (rts) = 193 bytes = $C1 bytes)
VERTICES_X               = $50D0   ; 7 bytes (max 7 vertices with an x and y coordinate)
VERTICES_Y               = $50D7   ; 7 bytes (max 7 vertices with an x and y coordinate)

; FIXME: REMOVE/REPLACE!
COPY_BUFFER_TO_RAM_BANK_CODE = $5100   ; takes 64 * 6 + 1 = 385 bytes = $181 bytes

COPY_RAM_BANK_TO_VRAM_CODE   = $5300   ; takes 64 * 6 + 1 = 385 bytes = $181 bytes

; FIXME: these are not FILLED atm!
LEFT_NIBBLE_TO_RIGHT_NIBBLE = $5E00   ; 256 bytes NOTE: this contains very little data, but we have a left nibble (4 highest bits) so we need 256 bytes
LEFT_NIBBLE_TO_BOTH_NIBBLES = $5E01   ;

SCENE_DATA_BUFFER_ADDRESS   = $6000   ; 8*1024 = 8192 (= $2000) bytes

COPY_VRAM_TO_RAM_BANK_CODE  = $8000   ; 8 * 256 bytes (actually only $C1 needed per chunk) = $800 bytes

; Original scene data
ORIG_SCENE_DATA_RAM_ADDRESS = $A000
ORIG_SCENE_DATA_RAM_BANK    = $80    ; Note: we are currently loading the raw scene data into the 1MB point of Banked RAM

; Scene data in 7kB chunks (overlapping 1kB for each RAM bank)
; FIXME! REMOVE!
; FIXME! REMOVE!
; FIXME! REMOVE!
SCENE_DATA_RAM_ADDRESS      = $A000
SCENE_DATA_RAM_BANK         = $1 

SCENE_DATA_VRAM_ADDRESS     = $10000


; === Other constants ===

BACKGROUND_COLOR = 0
BLACK_COLOR = 16     ; this is a non-transparant black color

LOAD_FILE = 1
USE_JUMP_TABLE = 1
DEBUG = 0

VSYNC_BIT         = $01


.include "polygon_fx.s"


; --- Start of program ---
start:

    sei
    
    ; FIXME: do this a cleaner/nicer way!
    lda VERA_DC_VIDEO
    and #%10001111           ; Disable Layer 0, Layer 1 and sprites
    sta VERA_DC_VIDEO

    jsr generate_clear_256_bytes_code
    
    jsr generate_copy_ram_bank_to_vram_code
    
    ; Generating code for copying 1kB to each specific chunk of the target RAM bank
    stz CHUNK_CODE_OFFSET
    stz CHUNK_ADDRESS_OFFSET
generate_next_copy_vram_to_ram_bank_code_chunk:
    jsr generate_copy_vram_to_ram_bank_code
    
    clc
    lda CHUNK_CODE_OFFSET
    adc #$01
    sta CHUNK_CODE_OFFSET
    
    clc
    lda CHUNK_ADDRESS_OFFSET
    adc #$04
    sta CHUNK_ADDRESS_OFFSET
    
    cmp #$20   ; We go from $A000 to $C000 (= $2000 address offset)
    bne generate_next_copy_vram_to_ram_bank_code_chunk
    
    
    ; This clears (almost) the entire VRAM and sets it to the BACKGROUND_COLOR
    jsr clear_vram_fast_4_bytes
    
    jsr generate_y_to_address_table_0
    jsr generate_y_to_address_table_1
    
    ; This also fills their buffers two 64-pixel rows of black (non transparant) pixels
    jsr setup_covering_sprites
    
    jsr setup_vera_for_layer0_bitmap_general
    
    
    jsr load_scene_data_into_banked_ram
    jsr copy_scene_data_into_7kb_chunks
    
    ; Setting the border color
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    lda #0
    sta VERA_DC_BORDER

    ; We start with showing buffer 1 while filling buffer 0
    jsr setup_vera_for_layer0_bitmap_buffer_1
    stz BUFFER_NR

    
;    jsr init_playback_screen

    ; Clear buffer $00
    ; Clear buffer $01
    

    ; FIXME: this vsync-handling should probably be REPLACED!
;    jsr backup_default_irq_handler
;    jsr enable_vsync_handler
    

    ; Start stream playback
    jsr playback_stream


tmp_loop:
    jmp tmp_loop
    
    rts
    
    
    ; Since we convert 8kB chunks into 7kB chunks, every 64kB block border is now offset
    ; Note that a 64kB takes 9 ram banks + 1024 bytes (9 * 7kB + 1kB = 64 kB)
    

playback_stream:

    ; --- init addresses ---

    stz FRAME_INDEX
    
    lda #1
    sta CURRENT_RAM_BANK
    sta RAM_BANK
    stz BANK_INDEX_IN_BLOCK
    
    lda #$00
    sta FRAME_ADDRESS
    lda #$A0
    sta FRAME_ADDRESS+1
    
next_frame:

; FIXME! do not ALWAYS clear the buffer! THIS SHOULD BE CONDITIONALLY!
; FIXME! do not ALWAYS clear the buffer! THIS SHOULD BE CONDITIONALLY!
; FIXME! do not ALWAYS clear the buffer! THIS SHOULD BE CONDITIONALLY!

    lda BUFFER_NR
    bne do_clear_1
    jsr clear_buffer_0_fast
    bra done_clearing_buffer
do_clear_1:
    jsr clear_buffer_1_fast
done_clearing_buffer:


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
    
    cpx #$FE    ; block marker
    bne increment_frame_address

    ; We go to the next 64kB blockram bank + address
    
    inc CURRENT_RAM_BANK
    stz BANK_INDEX_IN_BLOCK  ; We are at the beginning of a 64 kB block, so our index is 0

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
    
    ; We check if we are passed the 7kB barrier, if so we switch to the next bank and move the frame address back 7kB
    cmp #$BC
    bcc frame_address_set
    
    ; We check if we are at the last of 9 RAM banks, if so, we do *not* move to the next RAM bank yet (we are expecting a block marker soon)
    
    lda BANK_INDEX_IN_BLOCK
    cmp #8
    beq frame_address_set
    
    inc CURRENT_RAM_BANK
    inc BANK_INDEX_IN_BLOCK
    
    sec
    lda FRAME_ADDRESS+1
    sbc #>(7*1024)
    sta FRAME_ADDRESS+1
    

frame_address_set:

    ; FIXME: replace this with something proper!
    jsr dumb_wait_for_vsync


    inc FRAME_INDEX
    lda FRAME_INDEX

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

    
; FIXME!
; FIXME!
; FIXME!
;    lda FRAME_INDEX
;    cmp #13+1
;    bne no_tmp_loop2
;tmp_loop2:
;    bra tmp_loop2
;no_tmp_loop2:
    



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
    sta VERTICES_X, x
    iny
    lda (INDEXED_COORDS_ADDRESS),y
    sta VERTICES_Y, x
    bra vertex_coords_loaded

indexed_coords_address_HI:
    tay  ; put the vertex-index * 2 in y
    lda (INDEXED_COORDS_ADDRESS_128),y
    sta VERTICES_X, x
    iny
    lda (INDEXED_COORDS_ADDRESS_128),y
    sta VERTICES_Y, x

vertex_coords_loaded:
 
    inc VERTEX_INDEX_IN_POLYGON
    ldy VERTEX_INDEX_IN_POLYGON
    inx
    
    cpy NR_OF_VERTICES_IN_POLYGON
    bcc load_next_vertex_indexed
    beq load_next_vertex_indexed

    jsr draw_polygon_fx


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
    sta VERTICES_X, x
    
    lda (CURRENT_POLYGON_ADDRESS), y   ; loads the y-coord
    iny
    sta VERTICES_Y, x ; TODO: we dont have to do +1 here, we can simply increase x
    inx
    
    cpy NR_OF_VERTICES_IN_POLYGON_BYTES
    bcc load_next_vertex_non_indexed
    beq load_next_vertex_non_indexed
 
    jsr draw_polygon_fx
    
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
  

scene_data_filename:      .byte    "scene1.bin" 
end_scene_data_filename:

load_scene_data_into_banked_ram:

    lda #(end_scene_data_filename-scene_data_filename) ; Length of filename
    ldx #<scene_data_filename      ; Low byte of Fname address
    ldy #>scene_data_filename      ; High byte of Fname address
    jsr SETNAM
 
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #2            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
                      ; 2=?use address in bin file? (and dont add first 2 bytes?)
    
    jsr SETLFS
    
    lda #ORIG_SCENE_DATA_RAM_BANK
    sta RAM_BANK
    
    lda #0            ; load into Fixed RAM (current RAM Bank) (see https://github.com/X16Community/x16-docs/blob/master/X16%20Reference%20-%2004%20-%20KERNAL.md#function-name-load )
    ldx #<ORIG_SCENE_DATA_RAM_ADDRESS
    ldy #>ORIG_SCENE_DATA_RAM_ADDRESS
    jsr LOAD
    bcc scene_data_loaded
    ; FIXME: do proper error handling!
    stp
scene_data_loaded:

    rts


; This uses 8kB of VRAM as a buffer (to copy to and from)
copy_scene_data_into_7kb_chunks:

    lda #ORIG_SCENE_DATA_RAM_BANK
    sta SOURCE_BANK_NUMBER
    
    lda #<ORIG_SCENE_DATA_RAM_ADDRESS
    sta LOAD_ADDRESS
    lda #>ORIG_SCENE_DATA_RAM_ADDRESS
    sta LOAD_ADDRESS+1
    
    lda #SCENE_DATA_RAM_BANK
    sta TARGET_BANK_NUMBER
 
    stz CHUNK_CODE_OFFSET
    
copy_next_scene_bank:

    lda #%10000001      ; setting bit 16 of vram address to 1, setting auto-increment value to 128 (= 1000b)
    sta VERA_ADDR_BANK
    
    jsr copy_8kb_to_vram_buffer
    
    ; We copy 9 chunks of 1kB size into the appropiate RAM banks

    lda #%01100001      ; setting bit 16 of vram address to 1, setting auto-increment value to 32 (= 0110b)
    sta VERA_ADDR_BANK
    
    ; The VRAM address (which will be determined by CHUNK_ADDRESS_OFFSET) is set to 0 when we start a new ram bank
    stz CHUNK_ADDRESS_OFFSET
    
    ldy #0
copy_next_1kb_chunk:

    jsr copy_1kb_from_vram_to_ram_bank
    
    clc
    lda CHUNK_CODE_OFFSET
    adc #$01
    sta CHUNK_CODE_OFFSET
    
    cmp #8
    bne chunk_code_offset_is_ok
    
    ; We are at the end of the RAM bank, so we reset the CHUNK_CODE_OFFSET and increment the RAM bank
    ; Note that CHUNK_CODE_OFFSET (implicitly) represents the target address in the RAM Bank
    stz CHUNK_CODE_OFFSET
    inc TARGET_BANK_NUMBER
    
    ; Note: Effectively we put 64 kB in 9 RAM banks. The FIRST bank has 8 kB! The other eight have 7kB. 
    ; Total: 8kB + 8*7kB = 64kB. So one original 64 kB block FITS perfectly!

    ; We need to NOT increment the CHUNK_ADDRESS_OFFSET when we just incremented the RAM bank, since we want this 1kB to be used AGAIN
    bra chunk_address_offset_is_ok
    
chunk_code_offset_is_ok:
    
    clc
    lda CHUNK_ADDRESS_OFFSET
    adc #$04
    sta CHUNK_ADDRESS_OFFSET
       
chunk_address_offset_is_ok:
    iny
    cpy #9
    bne copy_next_1kb_chunk

    inc SOURCE_BANK_NUMBER
    lda SOURCE_BANK_NUMBER
   
; FIXME: WHAT DO WE COUNT? TARGET OR SOURCE?
; FIXME: which amount? +1?
    cmp #$51+$80
    bne copy_next_scene_bank
    

    rts
    
    
    
copy_8kb_to_vram_buffer:

    lda SOURCE_BANK_NUMBER
    sta RAM_BANK
    
    ldx #0
copy_ram_bank_to_vram_next_64:
    stx VERA_ADDR_LOW               ; Note: we are ignoring the lower part/byte of SCENE_DATA_VRAM_ADDRESS
    lda #>SCENE_DATA_VRAM_ADDRESS
    sta VERA_ADDR_HIGH

    jsr COPY_RAM_BANK_TO_VRAM_CODE   ; copies 64 bytes
    inx
    cpx #128       ; we copy 64 * 128 bytes = 8kB
    bne copy_ram_bank_to_vram_next_64

    rts
    
    
    
copy_1kb_from_vram_to_ram_bank:

    lda TARGET_BANK_NUMBER
    sta RAM_BANK

    clc
    lda #>COPY_VRAM_TO_RAM_BANK_CODE
    adc CHUNK_CODE_OFFSET
    sta patch_copy_vram_to_ram_bank_jmp+2  

    ldx #0
copy_vram_to_ram_bank_32:
    stx VERA_ADDR_LOW               ; Note: we are ignoring the lower part/byte of SCENE_DATA_VRAM_ADDRESS
    
    clc
    lda #>SCENE_DATA_VRAM_ADDRESS
    adc CHUNK_ADDRESS_OFFSET
    sta VERA_ADDR_HIGH
       
patch_copy_vram_to_ram_bank_jmp:
    jsr COPY_VRAM_TO_RAM_BANK_CODE   ; copies 32 bytes
    inx
    cpx #32       ; we copy 32 * 32 bytes = 1kB
    bne copy_vram_to_ram_bank_32

    rts

    
    
; This is just a dumb verison of a proper vsync-wait
dumb_wait_for_vsync:

    ; We wait until SCANLINE == $1FF (indicating the beam is off screen, lines 512-524)
wait_for_scanline_bit8:
    lda VERA_IEN
    and #%01000000
    beq wait_for_scanline_bit8
    
wait_for_scanline_low:
    lda VERA_SCANLINE_L
    cmp #$FF
    bne wait_for_scanline_low

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

    lda #%00000010  ; DCSEL=1
    sta VERA_CTRL
   
    lda #32*2/4
    sta VERA_DC_HSTART
    lda #(256+32)*2/4
    sta VERA_DC_HSTOP
    
    ; -- Setup Layer 0 --
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL
    
    lda #$40                 ; 2:1 scale (320 x 240 pixels on screen)
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
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


clear_buffer_0_fast:
    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #BACKGROUND_COLOR
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
    
    ; We start at the beginning of the PIXELS of buffer 0 (=the very beginning of VRAM)
    lda #0
    sta VERA_ADDR_HIGH
    lda #0
    sta VERA_ADDR_LOW
    
    ; One buffer of 320x200 pixels
    ; 64000 * 1 byte / 256 = 250 iterations

    ldx #250
clear_buffer_0_next_256_bytes:
    jsr CLEAR_256_BYTES_CODE
    dex
    bne clear_buffer_0_next_256_bytes
     
; FIXME: we should NOT do this right?
; FIXME: we should NOT do this right?
; FIXME: we should NOT do this right?
    lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL

    rts



clear_buffer_1_fast:
    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #BACKGROUND_COLOR
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
    
    ; We start at the beginning of the PIXELS of buffer 1
    ; Note Buffer 1 PIXELS starts at: (320*200-512+320*2) = $0FA80
    
    lda #$FA
    sta VERA_ADDR_HIGH
    lda #$80
    sta VERA_ADDR_LOW
    
    ; One buffer of 320x200 pixels
    ; 64000 * 1 byte / 256 = 250 iterations

    ldx #250
clear_buffer_1_next_256_bytes:
    jsr CLEAR_256_BYTES_CODE
    dex
    bne clear_buffer_1_next_256_bytes 
     
; FIXME: we should NOT do this right?
; FIXME: we should NOT do this right?
; FIXME: we should NOT do this right?
    lda #%00000000           ; transparent writes = 0, blit write = 0, cache fill enabled = 0, one byte cache cycling = 0, 16bit hop = 0, 4bit mode = 0, normal addr1 mode 
    sta VERA_FX_CTRL
    
    lda #%00000000           ; DCSEL=0, ADDRSEL=0
    sta VERA_CTRL

    rts

    
clear_vram_fast_4_bytes:

    ; We first need to fill the 32-bit cache with 4 times our background color

    lda #%00001100           ; DCSEL=6, ADDRSEL=0
    sta VERA_CTRL

    ; TODO: we *could* use 'one byte cache cycling' so we have to set only *one* byte of the cache here
    lda #BACKGROUND_COLOR
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
    
    
generate_copy_ram_bank_to_vram_code:

    ; We generate 64 times a byte-copy like this (with x ranging from 0->127):
    ;     lda $A000, x
    ;     sta DATA0
    ;     lda $A080, x
    ;     sta DATA0
    ;     lda $A100, x
    ;     sta DATA0
    ;       ...
    ;     lda $BF80, x
    ;     sta DATA0
    ;     rts

    lda #<COPY_RAM_BANK_TO_VRAM_CODE
    sta CODE_ADDRESS
    lda #>COPY_RAM_BANK_TO_VRAM_CODE
    sta CODE_ADDRESS+1
    
    lda #<ORIG_SCENE_DATA_RAM_ADDRESS
    sta LOAD_ADDRESS
    lda #>ORIG_SCENE_DATA_RAM_ADDRESS
    sta LOAD_ADDRESS+1
    

    ldy #0                 ; generated code byte counter

    ; -- We generate 64 copy (lda/sta) instructions --
    
    ldx #64                ; counts nr of copy instructions

next_copy_to_vram_instruction:

    ; -- lda $A000, x 
    lda #$BD               ; lda ...., x
    jsr add_code_byte

    lda LOAD_ADDRESS
    jsr add_code_byte
    
    lda LOAD_ADDRESS+1
    jsr add_code_byte
    
    ; -- sta VERA_DATA0 ($9F23)
    lda #$8D               ; sta ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    
    clc
    lda LOAD_ADDRESS
    adc #$80
    sta LOAD_ADDRESS
    lda LOAD_ADDRESS+1
    adc #0
    sta LOAD_ADDRESS+1
    
    dex
    bne next_copy_to_vram_instruction

    ; -- rts --
    lda #$60
    jsr add_code_byte

    rts
    
    
    
generate_copy_vram_to_ram_bank_code:

    ; We generate 32 times a byte-copy like this (with x ranging from 0->31):
    ;     lda DATA0
    ;     sta $A000, x
    ;     lda DATA0
    ;     sta $A020, x
    ;     lda DATA0
    ;     sta $A040, x
    ;     ...
    ;     lda DATA0
    ;     sta $A3E0, x
    ;     rts

    lda #<COPY_VRAM_TO_RAM_BANK_CODE
    sta CODE_ADDRESS
    clc
    lda #>COPY_VRAM_TO_RAM_BANK_CODE
    adc CHUNK_CODE_OFFSET
    sta CODE_ADDRESS+1
    
    lda #<SCENE_DATA_RAM_ADDRESS
    sta STORE_ADDRESS
    clc
    lda #>SCENE_DATA_RAM_ADDRESS
    adc CHUNK_ADDRESS_OFFSET
    sta STORE_ADDRESS+1
    

    ldy #0                 ; generated code byte counter

    ; -- We generate 32 copy (lda/sta) instructions --
    
    ldx #32                ; counts nr of copy instructions

next_copy_from_vram_instruction:

    ; -- lda VERA_DATA0 ($9F23)
    lda #$AD               ; lda ....
    jsr add_code_byte

    lda #$23               ; $23
    jsr add_code_byte
    
    lda #$9F               ; $9F
    jsr add_code_byte
    

    ; -- sta $A000, x 
    lda #$9D               ; sta ...., x
    jsr add_code_byte

    lda STORE_ADDRESS
    jsr add_code_byte
    
    lda STORE_ADDRESS+1
    jsr add_code_byte


    clc
    lda STORE_ADDRESS
    adc #$20            ; we add 32 each time
    sta STORE_ADDRESS
    lda STORE_ADDRESS+1
    adc #0
    sta STORE_ADDRESS+1
    
    dex
    bne next_copy_from_vram_instruction

    ; -- rts --
    lda #$60
    jsr add_code_byte

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


