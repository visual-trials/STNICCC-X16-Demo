
; ======= DRAW INTRO TEXT ======

intro_offset_x: .byte 8
intro_offset_y: .byte 10

intro_text:   .byte "thisis*not*anataridemo",0
intro_text_x: .byte 1,3,5,7, 11,13    ; this is
              .byte   3,5,7,9,11      ;  *not*
              .byte 0,2, 6,8,10,12,14 ; an atari
              .byte    4,6,8,10       ;   demo
intro_text_y: .byte 0,0,0,0, 0,0
              .byte   1,1,1,1,1
              .byte 2,2,  2,2,2,2,2
              .byte    3,3,3,3
              
character_pixel_x:         .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
character_pixel_y:         .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
nr_of_pixels_in_character: .byte 0

intro_pixel_frame_counter:     .word 0
current_intro_character_index: .byte 0
current_intro_character_pixel: .byte 0

current_intro_character: .byte 0

pixel_x: .word 0
pixel_y: .byte 0

; ============= Draw a single character-pixel as a small sqaure on the screen ===============

draw_intro_text_pixel:

    ; Get the x,y for the current pixel

    ; ---------- pixel_x -----------

    ; First the pixel_x inside the character (*1)
    ldx current_intro_character_pixel
    lda character_pixel_x,x
    clc
    adc intro_offset_x
    sta pixel_x
    
    ; Then the pixel_x from the character position (*4)
    ldx current_intro_character_index
    lda intro_text_x,x
    asl ; * 2
    asl ; * 4
    clc
    adc pixel_x
    sta pixel_x

    ; Now placing it on the screen (*4)
    
    asl ; * 2
    asl ; * 4
    sta pixel_x  ; effectively * 6

    ; Store the carry in pixel_x+1
    lda #0
    adc #0
    sta pixel_x+1

    ; ---------- pixel_y -----------
    ; First the pixel_y inside the character (*1)
    ldx current_intro_character_pixel
    lda character_pixel_y,x
    clc
    adc intro_offset_y
    sta pixel_y
    
    ; Then the pixel_y from the character position (*9)
    ldx current_intro_character_index
    lda intro_text_y,x
    asl ; * 2
    asl ; * 4
    asl ; * 8
    adc intro_text_y,x
    adc intro_text_y,x
    adc pixel_y
    sta pixel_y
    
    ; Now placing it on the screen (*4)
    
    asl ; * 2
    asl ; * 4
    sta pixel_y

    ; Draw the pixel at x,y (offset by the character x,y)
    
    ; color background: 187
    ; color text: 183

    lda pixel_y
    tay
    clc
    adc #3   ; draw 3 pixels in height
    sta pixel_until_y+1

draw_next_small_line:

    lda y_to_base_line_address_intro_LO,y
    clc
    adc pixel_x
    sta VERA_addr_low

    lda y_to_base_line_address_intro_HI,y
    
    adc pixel_x+1   ; we add the HI byte to the base tile address
    sta VERA_addr_high
    
    lda #%00010000      ; setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 1
    sta VERA_addr_bank
    
    lda #183  ; TODO: hardcoded color 
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0  ; draw 3 pixels in width

    iny
pixel_until_y:    
    cpy #8
    bne draw_next_small_line

    ; We have just drawn a pixel of a character, so we increment
    inc current_intro_character_pixel

    rts


; ============= Get pixels data from a character ===============

tilebase_characters =   $1E000 ; this is the default tilebase for layer 1
current_y_in_char: .byte 0

retrieve_pixels_from_current_character:

    lda #0
    sta nr_of_pixels_in_character

    ; Info about X16/VERA PETSCII characters: https://cx16.dk/veratext/verachars/

    ; Load and store character specific data
    ldx current_intro_character_index
    lda intro_text,x
    cmp #0
    beq done_retrieving_pixels_from_character  ; When we encounter a $00-character we stop retrieving pixels
    cmp #64   ; HACK: if character is larger than 64 we simply subtract 64 
    bcc :+
    sec
    sbc #64
:

    sta current_intro_character
    
    lda #1
    sta VERA_ctrl   ; ADDRSEL=1

    ; VERA.address = 0x1E800 + character * 8 + pixel_y; 
    lda current_intro_character
    asl
    asl
    asl  ; * 8
    ; adc #<tilebase_characters  ; this is 00! -> and we want to preserve the carry, so we don't do this
    sta VERA_addr_low
    
    lda #>tilebase_characters
    adc #0   ; in case the value didn't fit in the low byte alone
    sta VERA_addr_high
    
    lda VERA_addr_low
    adc current_y_in_char   ; y-line of character
    sta VERA_addr_low

    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    

    ldy #0

next_y_in_character:
    lda VERA_data1
    
    ldx #0
next_x_in_character_line:

    asl
    bcc :+
    
    ; We found a bit set to 1 in the character pixels. So we add a pixel entry

    pha
    txa
    pha
    
    ldx nr_of_pixels_in_character
    sta character_pixel_x,x
    
    tya
    sta character_pixel_y,x
    
    inc nr_of_pixels_in_character

    pla
    tax
    pla
:   
    inx
    cpx #8
    bne next_x_in_character_line
    
    iny
    cpy #8
    bne next_y_in_character
    
    
    lda #0
    sta VERA_ctrl   ; ADDRSEL=0

done_retrieving_pixels_from_character:
    rts
    

; ====================== LOAD INTRO FILES ==============================


load_intro_files:
    
    jsr load_intro_text_file
    jsr load_intro_logo_file
    jsr load_intro_volume_file
    jsr load_intro_zoom_file
    jsr load_intro_palette_file
    jsr set_intro_palette_colors
    jsr setup_intro_sprites
    
    rts



;  -------- Load intro text file ----------
    
intro_text_filename:      .byte    "intro/text.bin"
end_intro_text_filename:
intro_text_file_vram_buffer = $00000
intro_zoom_frame_counter:  .word 0
; intro_scale_screen:  .byte $80
intro_zoom_index: .byte 0


load_intro_text_file:

    
    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_intro_text_filename-intro_text_filename) ; Length of filename
    ldx #<intro_text_filename      ; Low byte of Fname address
    ldy #>intro_text_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>intro_text_file_vram_buffer   ; VRAM HIGH address
    ldx #<intro_text_file_vram_buffer   ; VRAM LOW address
    
    lda #$02            ; VERA BANK + 2 (so: bank 0)
    jsr LOAD            ; Load binary file into VRAM, ignoring 2 first bytes
    
    rts
    
;  -------- Load intro logo file ----------

intro_logo_filename:      .byte    "intro/logoleft.bin"
end_intro_logo_filename:
intro_logo_file_vram_buffer = $18000

load_intro_logo_file:

    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_intro_logo_filename-intro_logo_filename) ; Length of filename
    ldx #<intro_logo_filename      ; Low byte of Fname address
    ldy #>intro_logo_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>intro_logo_file_vram_buffer   ; VRAM HIGH address
    ldx #<intro_logo_file_vram_buffer   ; VRAM LOW address
    
    lda #$03            ; VERA BANK + 2 (so: bank 1)
    jsr LOAD            ; Load binary file into VRAM, ignoring 2 first bytes
    
    rts
    
    
;  -------- Load intro volume file ----------

intro_volume_filename:      .byte    "intro/volume.bin"
end_intro_volume_filename:

load_intro_volume_file:

    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_intro_volume_filename-intro_volume_filename) ; Length of filename
    ldx #<intro_volume_filename      ; Low byte of Fname address
    ldy #>intro_volume_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>intro_audio_volume   ; HIGH address
    ldx #<intro_audio_volume   ; LOW address
    
    lda #$00            ; to load into RAM
    jsr LOAD            ; Load binary file into RAM, ignoring 2 first bytes
    
    rts

;  -------- Load intro zoom file ----------

intro_zoom_filename:      .byte    "intro/zoom.bin"
end_intro_zoom_filename:

load_intro_zoom_file:

    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_intro_zoom_filename-intro_zoom_filename) ; Length of filename
    ldx #<intro_zoom_filename      ; Low byte of Fname address
    ldy #>intro_zoom_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>zoom_scroll_x_LO   ; HIGH address
    ldx #<zoom_scroll_x_LO   ; LOW address
    
    lda #$00            ; to load into RAM
    jsr LOAD            ; Load binary file into RAM, ignoring 2 first bytes

    rts

;  -------- Load intro palette file ----------

intro_palette_filename:      .byte    "intro/palette.bin"
end_intro_palette_filename:

load_intro_palette_file:

    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_intro_palette_filename-intro_palette_filename) ; Length of filename
    ldx #<intro_palette_filename      ; Low byte of Fname address
    ldy #>intro_palette_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>intro_palette_file_buffer   ; HIGH address
    ldx #<intro_palette_file_buffer   ; LOW address
    
    lda #$00            ; to load into RAM
    jsr LOAD            ; Load binary file into RAM, ignoring 2 first bytes
    
    rts
    
nr_of_intro_color_bytes: .byte 0  ; TODO: note that we only store the lower byte of the nr of bytes needed to load from memory for all the palette colors!
set_intro_palette_colors:

    ; Preparing VERA to store palette colors
    ldx #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    stx VERA_addr_bank

    lda #$FA
    sta VERA_addr_high
    lda #0
    sta VERA_addr_low
    
    lda intro_palette_file_buffer ; the first byte contains the nr of colors in the palette
    asl  ; * 2 (note that we ignore the carry, we assume more than 128 bytes!)
    sta nr_of_intro_color_bytes
    
    ldx #0
next_intro_palette_color_LO:
    
    lda intro_palette_colors_LO,x
    sta VERA_data0
    inx
    bne next_intro_palette_color_LO
    
    ldx #0
next_intro_palette_color_HI:
    
    lda intro_palette_colors_HI,x
    sta VERA_data0
    inx
    cpx nr_of_intro_color_bytes
    bne next_intro_palette_color_HI
    
    rts
    
left_sprite_x_orig  = 410
left_sprite_x:  .word 410
left_sprite_y_orig  = 202
left_sprite_y:  .word 202

right_sprite_x_orig = 474
right_sprite_x: .word 474
right_sprite_y_orig = 202
right_sprite_y: .word 202

sprite_delta: .byte 0
    
move_sprites_to_delta_position:

    ; Preparing VERA to store sprite attributes
    
    ldx #%00000001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 0
    stx VERA_addr_bank

    lda #$FC
    sta VERA_addr_high
    lda #10               ; X-coord (low) of sprite 1
    sta VERA_addr_low
    
    lda left_sprite_x
    sec
    sbc sprite_delta
    sta VERA_data0

    lda #18               ; X-coord (low) of sprite 2
    sta VERA_addr_low

    lda right_sprite_x
    clc
    adc sprite_delta
    sta VERA_data0

    rts

setup_intro_sprites:

    ; Preparing VERA to store sprite attributes
    
    ldx #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    stx VERA_addr_bank

    lda #$FC
    sta VERA_addr_high
    lda #8               ; We skip sprite 0 (since its used for the mouse)
    sta VERA_addr_low

    ; ----------- Left sprite -----------
    
    ; --- Data address (12:5) ---
    lda #$00
    sta VERA_data0
    
    ; --- Data Address (16:13) ---
    lda #$8C                 ; Mode	+ Data Address (16:13) -> mode = 8bpp, data address = $18000 ($C000 when shifted 1 bit to the right)
    sta VERA_data0

    ; --- X-coordinate (7:0)
    lda left_sprite_x
    sta VERA_data0    ; x-coord (low)
    
    ; --- X-coordinate (9:8)
    lda left_sprite_x+1
    sta VERA_data0    ; x-coord (high)

    ; --- Y-coordinate (7:0)
    lda left_sprite_y
    sta VERA_data0    ; y-coord (low)
    
    ; --- Y-coordinate (9:8)
    lda left_sprite_y+1
    sta VERA_data0    ; y-coord (high)

    ; --- Collision mask, flip, z-depth ---
    lda #%00001100    
    sta VERA_data0    ; Sprite in front of Layer 1 (no collosion mask, no flipping)
    
    ; --- Sprite height/width, pallette offset ---
    
    lda #%11110000
    sta VERA_data0    ; Sprite height = 64px	Sprite width = 64px	 Palette offset = 0


    ; ----------- Right sprite -----------

    ; --- Data address (12:5) ---
    lda #$00
    sta VERA_data0
    
    ; --- Data Address (16:13) ---
    lda #$8C                 ; Mode	+ Data Address (16:13) -> mode = 8bpp, data address = $18000 ($C000 when shifted 1 bit to the right)
    sta VERA_data0

    ; --- X-coordinate (7:0)
    lda right_sprite_x
    sta VERA_data0    ; x-coord (low)
    
    ; --- X-coordinate (9:8)
    lda right_sprite_x+1
    sta VERA_data0    ; x-coord (high)

    ; --- Y-coordinate (7:0)
    lda right_sprite_y
    sta VERA_data0    ; y-coord (low)
    
    ; --- Y-coordinate (9:8)
    lda right_sprite_y+1
    sta VERA_data0    ; y-coord (high)

    ; --- Collision mask, flip, z-depth ---
    lda #%00001101    
    sta VERA_data0    ; Sprite in front of Layer 1 (no collosion mask, h-flip)
    
    ; --- Sprite height/width, pallette offset ---
    
    lda #%11110000
    sta VERA_data0    ; Sprite height = 64px	Sprite width = 64px	 Palette offset = 0

    rts