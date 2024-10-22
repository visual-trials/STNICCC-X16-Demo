
; ======== Init draw screen: 8 bpp =======    
   
init_8bit_draw_screen:

    ; VERA.display.vscale = 0x40; // scale / 2 (320px)
    ; VERA.display.hscale = 0x40; // scale / 2 (240px)
    lda #$40
    sta VERA_dc_vscale
    sta VERA_dc_hscale

    ; VERA.layer0.config = (4 + 3); // enable bitmap mode and color depth = 8bpp on layer 0
    lda #(4+3)
    sta VERA_L0_config

    ; VERA.layer0.tilebase = (0x000 >> 1) | 0; // set new tilebase for layer 0 (0x00000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($000 >> 1)
    sta VERA_L0_tilebase
    
   rts

; ======== Init draw screen: 2 bpp =======    
  
current_tile_index: .word 0  

init_2bit_high_res_draw_screen:

    ; VERA.display.vscale = 0x80; // scale / 1 (640px)
    ; VERA.display.hscale = 0x80; // scale / 1 (480px)
    lda #$80
    sta VERA_dc_vscale
    sta VERA_dc_hscale

    ; VERA.layer0.config = (4 + 1); // enable bitmap mode and color depth = 2bpp on layer 0
;    lda #(4+1)
    ; enable tilemap mode: (64 tiles wide, 32 tiles high) and color depth = 2bpp on layer 0
    lda #%00010001
    sta VERA_L0_config

    ; VERA.layer0.tilebase = (0x000 >> 1) | 1; // set new tilebase for layer 0 (0x00000) and set TileWidth to 640px (=1)
;    lda #(($000 >> 1) | 1)
    ; // set new tilebase for layer 0 (0x00000) and set TileWidth and TileHeight to 16px (=3)
    lda #%00000011
    sta VERA_L0_tilebase

    ; We set the map base to $16000
    lda #>($16000 >> 1)
    sta VERA_L0_mapbase

    ; ---- Creating basic mapbase ----
    
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the new tilebase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    lda #$60
    sta VERA_addr_high
    lda #$00
    sta VERA_addr_low
    
    ldy #0
    
next_tile_row:
    ldx #0
    
next_tile_column:
    lda current_tile_index
    sta VERA_data0
    
    ; NOTE: current_tile_index cannot be higher than 1024
    ; instead we do 40 * 26 = 960 tiles (3 rows at top and bottom are assumed to be empty)
    
    lda current_tile_index+1
    sta VERA_data0
    
    cpy #3   ; TODO: Note sure about this one, but it seems to work
    bcc :+

    cpy #26  ; TODO: Note sure about this one, but it seems to work
    bcs :+

    cpx #40
    bcs :+
    inc current_tile_index
    bne :+
    inc current_tile_index+1
:

    inx
    cpx #64
    bne next_tile_column
    
    iny
    cpy #32
    bne next_tile_row
    
    rts


clear_draw_screen_slow_8bits:

    ; -- First we do the left 256 columns --
    
    ldx #<256 ; first clear 256 byte columns (= 256 pixel columns)
    
next_x_draw_8bits:
    lda #0
    sta VERA_addr_high ; high byte = $00
    dex
    stx VERA_addr_low ; low byte = x

    ; Note that we always have to set the increment after each row, otherwise VERA's incrementer "breaks"  
    lda #%11100000      ; setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 160 (note: 14=320 bytes = 320 pixels)
    sta VERA_addr_bank

    ; Here we really clear the (left part of the) screen

    lda #$00 ; color = 0
; FIXME!
lda #187
    ldy #20 ; we clear 12 lines (8bit = 1wide*12 pixels high) in one go so we do that 20 times (20 * 12 = 240 pixels high)
next_y_draw_8bits:    
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    dey
    bne next_y_draw_8bits
    cpx #0
    bne next_x_draw_8bits

    ; -- Then we do the right 64 columns --
    
    ldx #<64 ; then clear 64 byte columns (= 64 pixel columns)
    
next_x_draw_8bits_2:
    lda #$01
    sta VERA_addr_high ; high byte = $01
    dex
    stx VERA_addr_low ; low byte = x

    ; Note that we always have to set the increment after each row, otherwise VERA's incrementer "breaks"  
    lda #%11100000      ; setting bit 16 of vram address to the highest bit in the tilebase (=0), setting auto-increment value to 160 (note: 14=320 bytes = 320 pixels)
    sta VERA_addr_bank

    ; Here we really clear the (left part of the) screen

    lda #$00 ; color = 0
; FIXME!
lda #187
    ldy #20 ; we clear 12 lines (8bit = 1wide*12 pixels high) in one go so we do that 20 times (20 * 12 = 240 pixels high)
next_y_draw_8bits_2:    
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    dey
    bne next_y_draw_8bits_2
    cpx #0
    bne next_x_draw_8bits_2

    rts    

; ======== Init playback screen =======    
   
init_playback_screen:
    

    ; VERA.display.vscale = 0x40; // scale / 2 (320px)
    ; VERA.display.hscale = 0x40; // scale / 2 (240px)
    lda #$40
    sta VERA_dc_vscale
    sta VERA_dc_hscale
    
    ; VERA.layer0.config = (4 + 2); // enable bitmap mode and color depth = 4bpp on layer 0
    lda #(4+2)
    sta VERA_L0_config
    
    ; VERA.layer0.tilebase = (0x0100 >> 1) | 0; // set new tilebase for layer 0 (0x10000)
    ; TODO: we may want to swap buffers between tilebase $10000 and $00000 (only difference is in bit 16 (using VERA_addr_bank), so you can still set VERA_addr_high and VERA_addr_low as you please)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    lda #($100 >> 1)
    sta VERA_L0_tilebase
    
    ; VERA.layer0.hscroll = 0; // This will clear the pallete offset
    lda #0
    sta VERA_L0_hscroll_h

    ; VERA.control = 0x02; // DSEL=1, ADDRSEL = 0
    lda #2
    sta VERA_ctrl
    
    ; Note: VERA talks in 640*480 pixels, so we should shift 2 bits and double our number, but we are a little lazy here (so we talk in 320*240 and shift one bit less)
    ; Left and right a border of 32 pixels (320 - 64 = 256 pixels wide)
    lda #(32 >> 1)  
    sta VERA_dc_hstart
    lda #((320-32) >> 1)
    sta VERA_dc_hstop
    
    ; Top and bottom a border of 20 pixels (240 - 40 = 200 pixels high)
    lda #(20)
    sta VERA_dc_vsstart
    ; FIXME: there is something weird going on here: we get half a pixel extra to see!!
    ; FIXME: there is something weird going on here: we get half a pixel extra to see!!
    ; FIXME: there is something weird going on here: we get half a pixel extra to see!!
    ; FIXME: for now we remove this half a pixel, which ALSO removed half OUR last pixel!
    lda #(240 - 20 - 1)
    sta VERA_dc_vstop

    ; VERA.control = 0x00; // DSEL=0, ADDRSEL = 0
    lda #0
    sta VERA_ctrl

    ; Set initial buffer to $01
    lda #$01
    sta current_buffer

    rts
    


clear_playback_screen_fast_4bits:

    ldx #128 ; clear 128 byte columns (= 256 pixel columns)
    
next_x_fast:
    lda #0
    sta VERA_addr_high ; high byte = $00
    dex
    stx VERA_addr_low ; low byte = x
    
buffer_switch_clear_screen_fast_4bit:
    lda #%11010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 160 (note: 13=160 bytes = 320     
    sta VERA_addr_bank

    lda #$00 ; color = 0 (for both 4bits and 8bits pixels)

    jsr clear_400_pixels_4bits
    
    cpx #0
    bne next_x_fast
    
    rts

clear_playback_screen_slow_8bits:

    ldx #<256 ; clear 256 byte columns (= 256 pixel columns)
    
next_x_8bits:
    lda #0
    sta VERA_addr_high ; high byte = $00
    dex
    stx VERA_addr_low ; low byte = x

    ; TODO: note that we always have to set the increment after each row, otherwise VERA's incrementer "breaks"  
    lda #%11100001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 160 (note: 14=320 bytes = 320 pixels)
    sta VERA_addr_bank

    ; Here we really clear the screen

    lda #$00 ; color = 0

    ldy #20 ; we clear 10 lines (8bit = 1wide*10 pixels high) in one go so we do that 20 times (20 * 10 = 200 pixels high)
next_y_8bits:    
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    
    dey
    bne next_y_8bits

    cpx #0
    bne next_x_8bits

    rts    


; FIXME: remove this!    
tmp_vert_color: .byte 0

clear_playback_screen_slow_4bits:

    ldx #128 ; clear 128 byte columns (= 256 pixel columns)
next_x:
    lda #0
    sta VERA_addr_high ; high byte = $00
    dex
    stx VERA_addr_low ; low byte = x

    ; TODO: note that we always have to set the increment after each row, otherwise VERA's incrementer "breaks"  
buffer_switch_clear_screen:
    lda #%11010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 160 (note: 13=160 bytes = 320 pixels)
    sta VERA_addr_bank

; bra raster

    ; Here we really clear the screen

    lda #$00 ; color = 0 (for both 4bits and 8bits pixels)

    ldy #20 ; we clear 10 lines (4bits = 2wide*10 pixels high, 8bit = 1wide*10 pixels high) in one go so we do that 20 times (20 * 10 = 200 pixels high)
next_y:    
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    
    dey
    bne next_y

    cpx #0
    bne next_x

    rts    
    
; FIXME: the code below wont work for 8 bits pixels!!!
raster:
    ; Here we create a raster on the screen
    
    lda #$55 ; color = 5 (2x)
    sta tmp_vert_color

    txa
    and #$0F
    cmp #$00
    beq start_color
    cmp #$0F
    beq end_color
    bra start_draw

start_color:
    lda #$15
    sta tmp_vert_color
    bra start_draw
   
end_color: 
    lda #$54
    sta tmp_vert_color
    bra start_draw
 
start_draw:

    ldy #20 ; we clear 20 pixels (10 bytes) in one go (2 wide x 10 pixels high, so we do that 20 times (20 * 10 = 200 pixels)
next_y_raster:    
lda #$22
    sta VERA_data0
lda tmp_vert_color
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
    sta VERA_data0
lda #$77
    sta VERA_data0

    dey
    bne next_y_raster

    cpx #0
    bne next_x_jmp

    rts
    
next_x_jmp:
    jmp next_x


; ============== Init color table ===============    
    
init_color_table:

    lda #$00
    sta current_color_left_nibble
    
:    
    tax   ; left nibble in x
    
    lsr
    lsr
    lsr
    lsr
    sta left_nibble_to_right_nibble, x
    ora current_color_left_nibble
    sta left_nibble_to_both_nibbles, x

    lda current_color_left_nibble
    clc
    adc #$10   ; we add 1 to the left nibble
    sta current_color_left_nibble
    bne :-

    rts
    
    
.if(use_new_division_table)

; ================ Init (Large) Division table (new) ====================

divide_x:    .byte 0
divide_y:    .byte 0
divide_y_high: .byte 0
divide_y_low: .byte 0
divide_x_high: .byte 0
divide_x_low: .byte 0

init_division_y_helper_table:

    ldy #0
:
    sty divide_y_high
    stz divide_y_low
    
    lsr divide_y_high
    rol divide_y_low
    lsr divide_y_high
    rol divide_y_low
    lsr divide_y_high
    rol divide_y_low
    lsr divide_y_high
    rol divide_y_low
    
    asl divide_y_low   ; we now have 4 low bits. But the lowest bit should be from x. So we shift one more time.
    
    lda divide_y_high
    eor #$FF       ; We put this high up in BANK RAM (last 16 banks)
    sta division_high_y_part,y

    lda divide_y_low
    clc
    adc #$A0        ; we add the base address ($A000)
    sta division_low_y_part,y

    iny
    cpy #200+1  ; FIXME: do we need y == 200?
    bne :-
    
    rts


init_division_x_helper_table:

    ldx #0
:
    stx divide_x_low
    stz divide_x_high
    
    asl divide_x_low    ; 7 bits of x in the low byte (we need 2 bytes per result)
    rol divide_x_high   ; 1 bit of x in the high byte
    
    lda divide_x_high
    sta division_high_x_part,x

    lda divide_x_low
    sta division_low_x_part,x

    inx
    bne :-
    
    rts


init_large_division_table:

    stz divide_x   ; FIXME: should we really start with 0?
    stz divide_y   ; FIXME: should we really start with 0?
    
next_divide_y:
    stz divide_x
    
    ldy divide_y
    lda division_high_y_part,y
    sta RAM_BANK
    
next_divide_x: 

    lda divide_x
    sta dividend+1
    stz dividend
    
    stz divisor+1
    lda divide_y
    sta divisor
    
    jsr divide

    ; Set the division_address (to store the division result)
    ldy divide_y
    ldx divide_x
    
    lda division_low_y_part,y
    ora division_high_x_part,x
    sta division_address+1
    ldy division_low_x_part,x

    ; Store the division result in the division_address + y
    lda dividend
    sta (division_address),y
    lda dividend+1
    iny
    sta (division_address),y
    
    inc divide_x
    beq :+    ; if x reaches 0 (again) we have done all 256 x-es
    jmp next_divide_x
:
    inc divide_y
    lda divide_y
    cmp #200+1  ; FIXME: do we need y == 200?
    beq :+
    jmp next_divide_y
:
    rts


.else

; ================ Init (Large) Division table (old) ====================

divide_x:    .byte 0
divide_y:    .byte 0

init_large_division_table:

    stz divide_x   ; FIXME: should we really start with 0?
    stz divide_y   ; FIXME: should we really start with 0?

next_divide_y:
    stz divide_x
    
    lda divide_y
    lsr            ; we divide y by 2 (so the highest bit is free to use)
    ora #$80       ; we set the highest bit (the first ~128 banks are used by the loaded video data)
    sta RAM_BANK
    
    lda #0
    rol            ; we get the lowest bit of y (which was shifted into the carry bit)
    asl            ; and use it as the highest *used* bit (second lowest bit of the high byte) of the address inside the bank
    clc
    adc #$A0        ; we add the byte of the base address ($A000)
    sta bank_address_msb_from_y_lsb
    
next_divide_x: 

    lda divide_x
    sta dividend+1
    stz dividend
    
    stz divisor+1
    lda divide_y
    sta divisor
    
    jsr divide

    lda divide_x
    asl             ; we need 2 bytes per division result, so we multiply x with 2
    tay
    
    lda #0
    rol                               ; if x > 128, we now get the carry in the lowest bit
    ora bank_address_msb_from_y_lsb   ; we set the highest used bit (coming from the lowest bit from y) and include the base address ($A000)
    sta division_address+1
    
    lda dividend
    sta (division_address),y
    lda dividend+1
    iny
    sta (division_address),y
    
    inc divide_x
    beq :+    ; if x reaches 0 (again) we have done all 256 x-es
    jmp next_divide_x
:
    inc divide_y
    lda divide_y
    cmp #200+1  ; FIXME: do we need y == 200?
    beq :+
    jmp next_divide_y
:
    rts


.endif
    
    

divide:
    lda #0            ;preset remainder to 0
    sta remainder
    sta remainder+1
    ldx #16            ;repeat for each bit: ...
divloop:
    asl dividend    ;dividend lb & hb*2, msb -> Carry
    rol dividend+1    
    rol remainder    ;remainder lb & hb * 2 + msb from carry
    rol remainder+1
    lda remainder
    sec
    sbc divisor    ;substract divisor to see if it fits in
    tay            ;lb result -> Y, for we may need it later
    lda remainder+1
    sbc divisor+1
    bcc skip    ;if carry=0 then divisor didn't fit in yet

    sta remainder+1    ;else save substraction result as new remainder,
    sty remainder    
    inc result    ;and INCrement result cause divisor fit in 1 times

skip:
    dex
    bne divloop    
    
    rts
    

    
    
    
; ================ Init Base Line Addresses =====================

init_base_line_addresses:

    lda #0
    sta line_base_address
    sta line_base_address+1

    lda #$FF
    sta line_base_address_minus_one
    sta line_base_address_minus_one+1

    ldx #0
next_base_line_address:
    lda line_base_address+1
    sta y_to_base_line_address_HI,x
    lda line_base_address
    sta y_to_base_line_address_LO,x
    
    lda line_base_address_minus_one+1
    sta y_to_base_line_address_minus_one_HI,x
    lda line_base_address_minus_one
    sta y_to_base_line_address_minus_one_LO,x
    
    clc
    lda line_base_address
    adc #<160
    sta line_base_address
    lda line_base_address+1
    adc #>160     ; TODO: this is always 0!
    sta line_base_address+1
    
    clc
    lda line_base_address_minus_one
    adc #<160
    sta line_base_address_minus_one
    lda line_base_address_minus_one+1
    adc #>160     ; TODO: this is always 0!
    sta line_base_address_minus_one+1
    
    inx
    cpx #200
    bne next_base_line_address

    rts
    
; ============= BASE LINE ADDRESS USED BY INTRO ===========

init_base_line_addresses_intro:

    lda #0
    sta line_base_address
    sta line_base_address+1

    ldx #0
next_base_line_address_intro:
    lda line_base_address+1
    sta y_to_base_line_address_intro_HI,x
    lda line_base_address
    sta y_to_base_line_address_intro_LO,x
    
    clc
    lda line_base_address
    adc #<320
    sta line_base_address
    lda line_base_address+1
    adc #>320
    sta line_base_address+1
    
    inx
    cpx #240
    bne next_base_line_address_intro

    rts


; ================================================================================================
; =================================== INIT AUDIO COPY CODE =======================================
; ================================================================================================

; FIXME: put this in Zero page memory!
current_audio_buffer_HI: .byte 0

init_audio_copy_code:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1


    ; --- Filling audio copy code 1st kb --- 

    ; Desired output:

    ; LDA $2000
    ; STA VERA_audio_data
    ; LDA $2001
    ; STA VERA_audio_data
    ; ...
    ; LDA $23FF
    ; STA VERA_audio_data

    lda #AUDIO1_RAM_BANK
    sta RAM_BANK
    
    lda #<audio_copy_code_1st_kb
    sta ZP_PTR_4
    lda #>audio_copy_code_1st_kb
    sta ZP_PTR_4+1
    
    lda #>audio_file_buffer 
    sta current_audio_buffer_HI
    
    ldy #0                 ; generated code byte counter
    
next_audio_block_copy_1st:
    ldx #<audio_file_buffer ; is zero 

next_audio_copy_1st:

    ; -- LDA audio_file_buffer + byte-index
    lda #$AD               ; LDA ....
    jsr addCodeByte
    txa                    ; low byte
    jsr addCodeByte
    lda current_audio_buffer_HI   ; high byte
    jsr addCodeByte
    
    ; -- STA VERA_audio_data
    lda #$8D               ; STA ....
    jsr addCodeByte
    lda #<VERA_audio_data
    jsr addCodeByte
    lda #>VERA_audio_data
    jsr addCodeByte

    inx
    cpx #0
    bne next_audio_copy_1st
    
    inc current_audio_buffer_HI
    lda current_audio_buffer_HI
    cmp #$24   ; go from 2000 - 23FF (so stop at 24)
    bne next_audio_block_copy_1st
    
    ; -- rts --
    lda #$60
    jsr addCodeByte
    

    ; --- Filling audio copy code 2nd kb --- 

    ; Desired output:

    ; LDA $2400
    ; STA VERA_audio_data
    ; LDA $2401
    ; STA VERA_audio_data
    ; ...
    ; LDA $27FF
    ; STA VERA_audio_data

    lda #AUDIO2_RAM_BANK
    sta RAM_BANK
    
    lda #<audio_copy_code_2nd_kb
    sta ZP_PTR_4
    lda #>audio_copy_code_2nd_kb
    sta ZP_PTR_4+1
    
    lda #>(audio_file_buffer+$400)  ; $2000 + 400 = $2400
    sta current_audio_buffer_HI
    
    ldy #0                 ; generated code byte counter
    
next_audio_block_copy_2nd:
    ldx #<(audio_file_buffer+$400) ; is zero 

next_audio_copy_2nd:

    ; -- LDA audio_file_buffer+$400 + byte-index
    lda #$AD               ; LDA ....
    jsr addCodeByte
    txa                    ; low byte
    jsr addCodeByte
    lda current_audio_buffer_HI   ; high byte
    jsr addCodeByte
    
    ; -- STA VERA_audio_data
    lda #$8D               ; STA ....
    jsr addCodeByte
    lda #<VERA_audio_data
    jsr addCodeByte
    lda #>VERA_audio_data
    jsr addCodeByte

    inx
    cpx #0
    bne next_audio_copy_2nd
    
    inc current_audio_buffer_HI
    lda current_audio_buffer_HI
    cmp #$28   ; go from 2400 - 27FF (so stop at 28)
    bne next_audio_block_copy_2nd
    
    ; -- rts --
    lda #$60
    jsr addCodeByte


    lda ZP_PTR_4_BACKUP
    sta ZP_PTR_4
    lda ZP_PTR_4_BACKUP+1
    sta ZP_PTR_4+1
    
    rts



; ================================================================================================
; ================================ INIT LINE SCANNING CODE =======================================
; ================================================================================================

.if(use_new_scanning_lines_table)

init_line_scanning_code:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1


    ; --- Filling increment_scanning_code: ADC (aka "right") --- 

    ; Desired output:

    ; TXA
    ; ADC x_increment
    ; TAX
    ; LDA VERA_data1
    ; ADC x_increment+1
    ; STA VERA_data0

    lda #<increment_scanning_code
    sta ZP_PTR_4
    lda #>increment_scanning_code
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ; NOTE: we start at 1, since the _prev must start at 0
    ldx #1                 ; counts nr of blocks-of-instructions

next_line_increment_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- ADC x_increment
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment       ; x_increment
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA VERA_data0
    lda #$AD               ; LDA ....
    jsr addCodeByte
    lda #<VERA_data1       ; high byte of VERA_data1 (e.g. #$24)
    jsr addCodeByte
    lda #>VERA_data1       ; high byte of VERA_data1 (e.g. #$9F)
    jsr addCodeByte
    
    ; -- ADC x_increment+1
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment+1     ; x_increment+1
    jsr addCodeByte
    
    ; -- STA VERA_data1
    lda #$8D               ; STA ....
    jsr addCodeByte
    lda #<VERA_data0       ; high byte of VERA_data0 (e.g. #$23)
    jsr addCodeByte
    lda #>VERA_data0       ; high byte of VERA_data0 (e.g. #$9F)
    jsr addCodeByte

    inx
    cpx #200
    bne next_line_increment_scanning_itertion
    
next_line_decrement_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- SBC x_decrement
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement       ; x_decrement
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA VERA_data0
    lda #$AD               ; LDA ....
    jsr addCodeByte
    lda #<VERA_data1       ; high byte of VERA_data1 (e.g. #$24)
    jsr addCodeByte
    lda #>VERA_data1       ; high byte of VERA_data1 (e.g. #$9F)
    jsr addCodeByte
    
    ; -- SBC x_decrement+1
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement+1     ; x_decrement+1
    jsr addCodeByte
    
    ; -- STA VERA_data1
    lda #$8D               ; STA ....
    jsr addCodeByte
    lda #<VERA_data0       ; high byte of VERA_data0 (e.g. #$23)
    jsr addCodeByte
    lda #>VERA_data0       ; high byte of VERA_data0 (e.g. #$9F)
    jsr addCodeByte

    inx
    cpx #200
    bne next_line_decrement_scanning_itertion
    


    ; TODO: fill these tables:
    
    ; jump_to_incrementing_code_LO
    ; jump_to_incrementing_code_HI
    ; jump_to_decrementing_code_LO
    ; jump_to_decrementing_code_HI
    
    
    ; TODO: fill these tables:
    
    ; vram_begin_x_LO
    ; vram_begin_x_HI
    ; vram_end_x_LO
    ; vram_end_x_HI





    lda ZP_PTR_4_BACKUP
    sta ZP_PTR_4
    lda ZP_PTR_4_BACKUP+1
    sta ZP_PTR_4+1
    
    rts


.else
init_line_scanning_code:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1


    ; --- Filling begin_x_scanning_code: ADC (aka "right") --- 

    ; Desired output:

    ; TXA
    ; ADC x_increment
    ; TAX
    ; LDA begin_x+index-1
    ; ADC x_increment+1
    ; STA begin_x+index

    lda #SCANNING_ADC_BANK           ; We use SCANNING_ADC_BANK for jump_address_scanning_code that use ADC (aka "right")
    sta RAM_BANK
    
    lda #<begin_x_scanning_code
    sta ZP_PTR_4
    lda #>begin_x_scanning_code
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ; NOTE: we start at 1, since the _prev must start at 0
    ldx #1                 ; counts nr of blocks-of-instructions

next_line_begin_x_adc_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- ADC x_increment
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment       ; x_increment
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA begin_x+index-1
    lda #$AD               ; LDA ....
    jsr addCodeByte
    dex                    ; we want the current index (x) MINUS ONE!
    txa                    ; read index-1 from the begin_x table (e.g. #37)
    inx
    jsr addCodeByte
    lda #>begin_x          ; high byte of begin_x (e.g. #$82)
    jsr addCodeByte
    
    ; -- ADC x_increment+1
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment+1     ; x_increment+1
    jsr addCodeByte
    
    ; -- STA begin_x+index
    lda #$8D               ; STA ....
    jsr addCodeByte
    txa                    ; read index from the begin_x table (e.g. #38)
    jsr addCodeByte
    lda #>begin_x          ; high byte of begin_x (e.g. #$82)
    jsr addCodeByte

    inx
    cpx #200
    bne next_line_begin_x_adc_scanning_itertion
    
    
    ; --- Filling begin_x_scanning_code: SBC (aka "left") --- 

    ; Desired output:

    ; TXA
    ; SBC x_decrement
    ; TAX
    ; LDA begin_x+index-1
    ; SBC x_decrement+1
    ; STA begin_x+index

    lda #SCANNING_SBC_BANK           ; We use SCANNING_SBC_BANK for jump_address_scanning_code that use SBC (aka "left")
    sta RAM_BANK
    
    lda #<begin_x_scanning_code
    sta ZP_PTR_4
    lda #>begin_x_scanning_code
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ; NOTE: we start at 1, since the _prev must start at 0
    ldx #1                 ; counts nr of blocks-of-instructions

next_line_begin_x_sbc_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- SBC x_decrement
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement       ; x_decrement
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA begin_x+index-1
    lda #$AD               ; LDA ....
    jsr addCodeByte
    dex                    ; we want the current index (x) MINUS ONE!
    txa                    ; read index-1 from the begin_x table (e.g. #37)
    inx
    jsr addCodeByte
    lda #>begin_x          ; high byte of begin_x (e.g. #$82)
    jsr addCodeByte
    
    ; -- SBC x_decrement+1
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement+1     ; x_decrement+1
    jsr addCodeByte
    
    ; -- STA begin_x+index
    lda #$8D               ; STA ....
    jsr addCodeByte
    txa                    ; read index from the begin_x table (e.g. #38)
    jsr addCodeByte
    lda #>begin_x          ; high byte of begin_x (e.g. #$82)
    jsr addCodeByte

    inx
    cpx #200
    bne next_line_begin_x_sbc_scanning_itertion               
    


    ; --- Filling end_x_scanning_code: ADC (aka "right")  --- 
    
    ; Desired output:

    ; TXA
    ; ADC x_increment
    ; TAX
    ; LDA end_x+index+1
    ; ADC x_increment+1
    ; STA end_x+index

    lda #SCANNING_ADC_BANK           ; We use SCANNING_ADC_BANK for jump_address_scanning_code that use ADC (aka "right")
    sta RAM_BANK
    
    lda #<end_x_scanning_code
    sta ZP_PTR_4
    lda #>end_x_scanning_code
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ; NOTE: we start at 199, since the _prev must start at 200
    ldx #199               ; counts nr of blocks-of-instructions

next_line_end_x_adc_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- ADC x_increment
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment       ; x_increment
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA end_x+index+1
    lda #$AD               ; LDA ....
    jsr addCodeByte
    inx                    ; we want the current index (x) PLUS ONE!
    txa                    ; read index+1 from the end_x table (e.g. #37)
    dex
    jsr addCodeByte
    lda #>end_x            ; high byte of end_x (e.g. #$83)
    jsr addCodeByte
    
    ; -- ADC x_increment+1
    lda #$65               ; ADC Zero Page
    jsr addCodeByte
    lda #x_increment+1     ; x_increment+1
    jsr addCodeByte
    
    ; -- STA end_x+index
    lda #$8D               ; STA ....
    jsr addCodeByte
    txa                    ; read index from the end_x table (e.g. #38)
    jsr addCodeByte
    lda #>end_x            ; high byte of end_x (e.g. #$83)
    jsr addCodeByte

    dex
    cpx #255
    bne next_line_end_x_adc_scanning_itertion       

    
    ; --- Filling end_x_scanning_code: SBC (aka "left")  --- 
    
    ; Desired output:

    ; TXA
    ; SBC x_decrement
    ; TAX
    ; LDA end_x+index+1
    ; SBC x_decrement+1
    ; STA end_x+index

    lda #SCANNING_SBC_BANK           ; We use SCANNING_SBC_BANK for jump_address_scanning_code that use SBC (aka "left")
    sta RAM_BANK
    
    lda #<end_x_scanning_code
    sta ZP_PTR_4
    lda #>end_x_scanning_code
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ; NOTE: we start at 199, since the _prev must start at 200
    ldx #199               ; counts nr of blocks-of-instructions

next_line_end_x_sbc_scanning_itertion:

    ; -- TXA
    lda #$8A               ; TXA
    jsr addCodeByte

    ; -- SBC x_decrement
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement       ; x_decrement
    jsr addCodeByte
    
    ; -- TAX
    lda #$AA               ; TAX
    jsr addCodeByte

    ; -- LDA end_x+index+1
    lda #$AD               ; LDA ....
    jsr addCodeByte
    inx                    ; we want the current index (x) PLUS ONE!
    txa                    ; read index+1 from the end_x table (e.g. #37)
    dex
    jsr addCodeByte
    lda #>end_x            ; high byte of end_x (e.g. #$83)
    jsr addCodeByte
    
    ; -- SBC x_decrement+1
    lda #$E5               ; SBC Zero Page
    jsr addCodeByte
    lda #x_decrement+1     ; x_decrement+1
    jsr addCodeByte
    
    ; -- STA end_x+index
    lda #$8D               ; STA ....
    jsr addCodeByte
    txa                    ; read index from the end_x table (e.g. #38)
    jsr addCodeByte
    lda #>end_x            ; high byte of end_x (e.g. #$83)
    jsr addCodeByte

    dex
    cpx #255
    bne next_line_end_x_sbc_scanning_itertion       
    
    
    
    
    ; ============= Generate accompaning jump address tables ===========
    
    ; --- jump_address_scanning_code_DOWN_LO ---
    
    lda #<begin_x_scanning_code
    sta jump_address_scanning_code
    lda #>begin_x_scanning_code
    sta jump_address_scanning_code+1
    
    ldx #0

next_scanning_code_DOWN:        

    lda jump_address_scanning_code
    sta jump_address_scanning_code_DOWN_LO,x
    lda jump_address_scanning_code+1
    sta jump_address_scanning_code_DOWN_HI,x
    
    clc
    lda jump_address_scanning_code
    adc #12                             ; 12 bytes of code
    sta jump_address_scanning_code
    lda jump_address_scanning_code+1
    adc #0
    sta jump_address_scanning_code+1
    
    inx
    cpx #201
    bne next_scanning_code_DOWN
    
    ; --- jump_address_scanning_code_DOWN_LO ---

    lda #<end_x_scanning_code
    sta jump_address_scanning_code
    lda #>end_x_scanning_code
    sta jump_address_scanning_code+1
    
    ldx #200

next_scanning_code_UP:

    lda jump_address_scanning_code
    sta jump_address_scanning_code_UP_LO,x
    lda jump_address_scanning_code+1
    sta jump_address_scanning_code_UP_HI,x
    
    clc
    lda jump_address_scanning_code
    adc #12                             ; 12 bytes of code
    sta jump_address_scanning_code
    lda jump_address_scanning_code+1
    adc #0
    sta jump_address_scanning_code+1
    
    dex
    cpx #255
    bne next_scanning_code_UP
    

    lda ZP_PTR_4_BACKUP
    sta ZP_PTR_4
    lda ZP_PTR_4_BACKUP+1
    sta ZP_PTR_4+1
    
    rts
    
.endif

; ================================================================================================
; ==================================== INIT DRAW CODE ============================================
; ================================================================================================

; TODO: Helper variables
nr_of_pixels_to_draw: .byte 0
;nr_of_full_pixels_to_draw: .byte 0
;nr_of_pixels_to_draw_halved: .byte 0
nr_of_code_bytes_skipped: .word 0


; This is used for clearing the screen

init_clearing_code_4bits:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1

    lda #<clear_400_pixels_4bits
    sta ZP_PTR_4
    lda #>clear_400_pixels_4bits
    sta ZP_PTR_4+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of "sta $9F23" instructions

next_clearing_instruction_4bits:

    ; -- sta VERA_data0 ($9F23)
    lda #$8D               ; sta ....
    jsr addCodeByte

    lda #$23               ; $23
    jsr addCodeByte
    
    lda #$9F               ; $9F
    jsr addCodeByte

    inx
    cpx #200
    bne next_clearing_instruction_4bits
    
    ; -- rts --
    lda #$60
    jsr addCodeByte

    lda ZP_PTR_4_BACKUP
    sta ZP_PTR_4
    lda ZP_PTR_4_BACKUP+1
    sta ZP_PTR_4+1
    
    rts


; ---- Create drawing cide (+copy overhead code) for non-ending pixel ----

end_of_draw_up_to_256_pixels_no_ending_pixel_4bits = draw_up_to_256_pixels_no_ending_pixel_4bits+3*128

init_draw_code_4bits_no_ending_pixel:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1

    lda #<draw_up_to_256_pixels_no_ending_pixel_4bits
    sta ZP_PTR_4
    lda #>draw_up_to_256_pixels_no_ending_pixel_4bits
    sta ZP_PTR_4+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of "sta $9F23" instructions

next_instruction_4bits_no_ending_pixel:

    ; -- sta VERA_data0 ($9F23)
    lda #$8D               ; sta ....
    jsr addCodeByte

    lda #$23               ; $23
    jsr addCodeByte
    
    lda #$9F               ; $9F
    jsr addCodeByte

    inx
    cpx #128
    bne next_instruction_4bits_no_ending_pixel

    ; Copying the no_ending_pixel draw-overhead-code at the end of the just generated code

    ldx #0
copy_draw_overhead_code_no_ending_pixel:
    lda draw_with_no_ending_pixel,x
    sta end_of_draw_up_to_256_pixels_no_ending_pixel_4bits,x
    
    inx
    
    cpx #(1+end_of_drawing_with_no_ending_pixel-draw_with_no_ending_pixel)
    bne copy_draw_overhead_code_no_ending_pixel


; ---- Create drawing code (+copy overhead code) for ending pixel ----

end_of_draw_up_to_256_pixels_ending_pixel_4bits = draw_up_to_256_pixels_ending_pixel_4bits+3*128

init_draw_code_4bits_ending_pixel:

    lda ZP_PTR_4
    sta ZP_PTR_4_BACKUP
    lda ZP_PTR_4+1
    sta ZP_PTR_4_BACKUP+1

    lda #<draw_up_to_256_pixels_ending_pixel_4bits
    sta ZP_PTR_4
    lda #>draw_up_to_256_pixels_ending_pixel_4bits
    sta ZP_PTR_4+1
    
    ldy #0                 ; generated code byte counter
    
    ldx #0                 ; counts nr of "sta $9F23" instructions

next_instruction_4bits_ending_pixel:

    ; -- sta VERA_data0 ($9F23)
    lda #$8D               ; sta ....
    jsr addCodeByte

    lda #$23               ; $23
    jsr addCodeByte
    
    lda #$9F               ; $9F
    jsr addCodeByte

    inx
    cpx #128
    bne next_instruction_4bits_ending_pixel

    ; Copying the ending_pixel draw-overhead-code at the end of the just generated code
    
    ldx #0
copy_draw_overhead_code_ending_pixel:
    lda draw_with_ending_pixel,x
    sta end_of_draw_up_to_256_pixels_ending_pixel_4bits,x
    
    inx
    
    cpx #(1+end_of_drawing_with_ending_pixel-draw_with_ending_pixel) ; TODO: do we really need the +1?
    bne copy_draw_overhead_code_ending_pixel



    ; Create horizontal jump tables 
    
    ; NOTE: x == 0 (y == 255) sometimes means we have to draw 256 pixels!!
    ;       this means we need two tables: one going from 0 to 255 pixels drawn (indexed by x), the other from 1 to 256 pixels drawn (indexed by y)

    ldx #0     ; nr of pixels to draw
    
    lda #<(128*3)
    sta nr_of_code_bytes_skipped
    lda #>(128*3)
    sta nr_of_code_bytes_skipped+1

    ; First we do 0 pixels (only stored in jump_address_horizontal_LO/HI)
    clc
    lda #<draw_up_to_256_pixels_no_ending_pixel_4bits
    adc nr_of_code_bytes_skipped
    sta jump_address_horizontal_LO,x
    lda #>draw_up_to_256_pixels_no_ending_pixel_4bits
    adc nr_of_code_bytes_skipped+1
    sta jump_address_horizontal_HI,x

    inx      ; nr of pixels to draw     = 1
    ldy #0   ; nr of pixels to draw - 1 = 0

next_nr_of_pixels:
    txa

    lsr 
    bcc generate_jmp_without_ending_pixel
    
generate_jmp_with_ending_pixel:

    clc
    lda #<draw_up_to_256_pixels_ending_pixel_4bits
    adc nr_of_code_bytes_skipped
    sta jump_address_horizontal_LO,x
    sta jump_address_horizontal_LO_255_is_256,y
    lda #>draw_up_to_256_pixels_ending_pixel_4bits
    adc nr_of_code_bytes_skipped+1
    sta jump_address_horizontal_HI,x
    sta jump_address_horizontal_HI_255_is_256,y
    
    ; decrement nr_of_code_bytes_skipped by 3
    sec
    lda nr_of_code_bytes_skipped
    sbc #3
    sta nr_of_code_bytes_skipped
    lda nr_of_code_bytes_skipped+1
    sbc #0
    sta nr_of_code_bytes_skipped+1
    
    bra :+

generate_jmp_without_ending_pixel:
    clc
    lda #<draw_up_to_256_pixels_no_ending_pixel_4bits
    adc nr_of_code_bytes_skipped
    sta jump_address_horizontal_LO,x
    sta jump_address_horizontal_LO_255_is_256,y
    lda #>draw_up_to_256_pixels_no_ending_pixel_4bits
    adc nr_of_code_bytes_skipped+1
    sta jump_address_horizontal_HI,x
    sta jump_address_horizontal_HI_255_is_256,y
    
:
    inx
    iny
    cpx #0
    bne next_nr_of_pixels

    ; x is now 0, y is 255

    ; Lastly we do 256 pixels (only stored in jump_address_horizontal_LO_255_is_256/LO_255_is_256)
    clc
    lda #<draw_up_to_256_pixels_no_ending_pixel_4bits
    sta jump_address_horizontal_LO_255_is_256,y
    lda #>draw_up_to_256_pixels_no_ending_pixel_4bits
    sta jump_address_horizontal_HI_255_is_256,y
    
    lda ZP_PTR_4_BACKUP
    sta ZP_PTR_4
    lda ZP_PTR_4_BACKUP+1
    sta ZP_PTR_4+1
    
    rts



addCodeByte:
    sta (ZP_PTR_4),y       ; store code byte at address (located at ZP_PTR_4) + y
    iny                    ; increase y
    cpy #0                 ; if y == 0
    bne :+
    inc ZP_PTR_4+1         ; increment high-byte of ZP_PTR_4
:   rts




    
; --- X16 constants ---    
    
SETLFS			= $FFBA
SETNAM			= $FFBD
LOAD			= $FFD5

IRQVec            = $0314

; --- VERA constants ---    

VSYNC_BIT         = $01
AFLOW_BIT         = $08

VERA_addr_low     = $9F20
VERA_addr_high    = $9F21
VERA_addr_bank    = $9F22
VERA_increment    = $9F22 ; same as VERA_addr_bank
VERA_data0        = $9F23
VERA_data1        = $9F24
VERA_ctrl         = $9F25
VERA_ien          = $9F26
VERA_isr          = $9F27
VERA_irqline_l    = $9F28
VERA_dc_video     = $9F29
VERA_dc_hscale    = $9F2A
VERA_dc_vscale    = $9F2B
VERA_dc_border    = $9F2C
VERA_dc_hstart    = $9F29
VERA_dc_hstop     = $9F2A
VERA_dc_vsstart   = $9F2B
VERA_dc_vstop     = $9F2C
VERA_L0_config    = $9F2D
VERA_L0_mapbase   = $9F2E
VERA_L0_tilebase  = $9F2F
VERA_L0_hscroll_l = $9F30
VERA_L0_hscroll_h = $9F31
VERA_L0_vscroll_l = $9F32
VERA_L0_vscroll_h = $9F33
VERA_L1_config    = $9F34
VERA_L1_mapbase   = $9F35
VERA_L1_tilebase  = $9F36
VERA_L1_hscroll_l = $9F37
VERA_L1_hscroll_h = $9F38
VERA_L1_vscroll_l = $9F39
VERA_L1_vscroll_h = $9F3A
VERA_audio_ctrl   = $9F3B
VERA_audio_rate   = $9F3C
VERA_audio_data   = $9F3D


enable_display_layer0:
    ; VERA.display.video = VERA.display.video | 16; // enable layer 0
    lda VERA_dc_video
    ora #%00010000
    sta VERA_dc_video
    rts
    
enable_display_layer1:
    ; VERA.display.video = VERA.display.video | 32; // enable layer 1  (the default for x16)
    lda VERA_dc_video
    ora #%00100000
    sta VERA_dc_video
    rts

enable_sprites:
    ; VERA.display.video = VERA.display.video | 64; // enable sprites
    lda VERA_dc_video
    ora #%01000000
    sta VERA_dc_video
    rts
    
disable_display_layer0:
    ; VERA.display.video = VERA.display.video & ~16; // disable layer 0
    lda VERA_dc_video
    and #%11101111
    sta VERA_dc_video
    rts
    
disable_display_layer1:
    ; VERA.display.video = VERA.display.video & ~32; // disable layer 1
    lda VERA_dc_video
    and #%11011111
    sta VERA_dc_video
    rts
    
disable_sprites:
    ; VERA.display.video = VERA.display.video & ~64; // disable sprites
    lda VERA_dc_video
    and #%10111111
    sta VERA_dc_video
    rts


; ======== Init text screen =======

init_text_screen:

    ; By default layer 1 has a mapbase at $00000 and a tilebase at $1F000, 
    ; we now set the mapbase to $1E800 and move the tilebase to $1E000
    ;
    lda #($1E8>>1)
    sta VERA_L1_mapbase

    lda #%00010000 ; 32 tiles high, 64 tiles wide, color depth = 0 (1 bpp)
    sta VERA_L1_config
    
    ; Copy tilebase from $1F000 to $1E000 ($800 bytes)

    ; ADDRSEL = 1
    lda #1
    sta VERA_ctrl
    
    ; Old = $1F000
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the old tilebase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    lda #$F0
    sta VERA_addr_high
    lda #$00
    sta VERA_addr_low
    
    ; ADDRSEL = 0
    lda #0
    sta VERA_ctrl
    
    ; New = $1E000
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the new tilebase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    lda #$E0
    sta VERA_addr_high
    lda #$00
    sta VERA_addr_low
    
    ; We need to copy $800 bytes (so we do: 8 times 256 ($100) bytes)
   ldx #0

copy_8_bytes:
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
    lda VERA_data1
    sta VERA_data0
   
    inx
    bne copy_8_bytes
    
    ; Set new tilebase for layer 1
    
    lda VERA_L1_tilebase
    and #$03   ; keep the two lower bits
    ; VERA.layer1.tilebase = (0x1E8 >> 1) | XX; // set new tilebase for layer 0 (0x1E000)
    ; NOTE: this also sets the TILE WIDTH to 320 px!!
    ora #($1E0 >> 1)
    sta VERA_L1_tilebase
    
    rts
    
clear_text_screen:

    ; The above settings (in init_text_screen) results in an actual 40 x 25 character screen (for a 256x200 pixel visible screen) that is VISIBLE
    ; BUT we have 64 characters in a row
    ; We clear all (visible) characters here
    
    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the mapbase (=1), setting auto-increment value to 1
    sta VERA_addr_bank
    
    lda #$E8
    sta VERA_addr_high
    
    lda #$00
    sta VERA_addr_low
    
    ; We also want to show the text screen when we are at a resolution of 320x240, so we extend the amount of characters we clear here to 64x32
    ldy #32
next_charachter_row:
    ldx #64
next_charachter_column:

    lda #32  ; character
    sta VERA_data0

    lda #$01  ; background color = 0 | foreground color = 1
    sta VERA_data0

    dex
    bne next_charachter_column

    dey
    bne next_charachter_row

    rts


copy_string_to_text_to_draw:




    rts

text_to_draw: .byte "time: 1:39.96"
text_length: .byte 13
text_x:  .byte 9
text_y:  .byte 12
text_bytes_address: .word 0

draw_text_at_xy:

    lda VERA_addr_bank
    pha
    
    ; FIXME: we may want a different color, so we will need to increment by 1 instead
    
    lda #%00100001      ; setting bit 16 of vram address to the highest bit in the mapbase (=1), setting auto-increment value to 2
    sta VERA_addr_bank
    
    ; add x*2 and y*128 to the map base
    
    ; multiply text_y with 128
    lda text_y
    asl
    asl
    asl
    asl ; * 16
    sta text_bytes_address
    rol text_bytes_address+1
    
    asl text_bytes_address ; * 32
    rol text_bytes_address+1
    
    asl text_bytes_address ; * 64
    rol text_bytes_address+1
    
    asl text_bytes_address ; * 128
    rol text_bytes_address+1
    
    ; add text_x
    lda text_bytes_address
    clc
    adc text_x
    adc text_x  ; We need to multiply by 2, since each x costs 2 bytes
    sta text_bytes_address
    lda text_bytes_address+1
    adc #$E8   ; FIXME: get the base map address out of a constant/variable
    sta text_bytes_address+1
    
    lda text_bytes_address+1
    sta VERA_addr_high

    lda text_bytes_address
    sta VERA_addr_low
    
    ldx #0
load_from_text_to_draw:
    lda text_to_draw,x
    
    ; We are *sort-of* converting ASCII to PETSCII here!
    cmp #64
    bcc :+
    sec
    sbc #64
:
    
    sta VERA_data0
    inx
    cpx text_length
    bne load_from_text_to_draw

; TODO: set auto-increment back to 1?
;    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the mapbase (=1), setting auto-increment value to 1
;    sta VERA_addr_bank

    pla
    sta VERA_addr_bank

    rts

number_to_draw: .word 1234

draw_number_as_text_at_xy:

    lda number_to_draw
    sta integer_to_convert
    lda number_to_draw+1
    sta integer_to_convert+1

    jsr int2str
    
    lda VERA_addr_bank
    pha
    
    lda #%00100001      ; setting bit 16 of vram address to the highest bit in the mapbase (=1), setting auto-increment value to 2
    sta VERA_addr_bank
    
    ; FIXME: get the base map address out of a constant/variable
    ; FIXME: add x and y*32 to the map base
    lda #$E8
    sta VERA_addr_high
    
    lda #$00
    sta VERA_addr_low
    
    ldx #0
:    
    lda output_string,x
    sta VERA_data0
    inx
    cpx #5
    bne :-

; TODO: set auto-increment back to 1?
;    lda #%00010001      ; setting bit 16 of vram address to the highest bit in the mapbase (=1), setting auto-increment value to 1
;    sta VERA_addr_bank

    pla
    sta VERA_addr_bank
    
    rts
    
; http://beebwiki.mdfs.net/Number_output_in_6502_machine_code
; https://unfinishedbitness.info/2014/09/26/6502-string-to-integer-and-reverse/

integer_to_convert:  .word 0
output_string:       .asciiz "000000"
digit_count:         .byte 0

int2str:
    ldy #0
    sty digit_count
int2str_next:
    ldx #0
int2str_subtract_loop:
    ; substract 10000, 1000, 100, 10 or 1 from the integer_to_convert
    lda integer_to_convert
    sec
    sbc int2str_table,y
    sta integer_to_convert
    lda integer_to_convert+1
    iny 
    sbc int2str_table,y
    bcc int2str_add           ; if we went below 0, we have to add back one time (only LSB)
    sta integer_to_convert+1
    inx                       ; 
    dey 
    bra int2str_subtract_loop
int2str_add:
    dey 
    lda integer_to_convert
    adc int2str_table,y
    sta integer_to_convert
    txa 
    ora #$30   ; '0'
    ldx digit_count
    sta output_string,x
    inc digit_count
    iny 
    iny 
    cpy #8
    bcc int2str_next
    
    lda integer_to_convert
    ora #$30   ; '0'
    ldx digit_count
    sta output_string,x
    inx 
    lda #$FF ; #EOL ; FIXME: what to do here?
    sta output_string,x
    rts 
    
int2str_table:
     .word 10000
     .word 1000
     .word 100
     .word 10


.if(0)
; Print 24-bit decimal number
; num=number to print
; pad=0 or pad character (eg '0' or ' ')
; On entry at PrDec24Lp1,
;           Y=(number of digits)*3-3, eg 21 for 8 digits
; On exit,  A,X,Y,num,pad corrupted
; Size      98 bytes

; FIXME: this should be set before calling!
pad: .byte '0'
num: .byte 0,0,0 ; (24 bit number)

PrDec24:
   LDY #21                                  ; Offset to powers of ten
PrDec24Lp1:
   LDX #$FF                                 ; Start with digit=-1
   SEC                             
PrDec24Lp2:
   
   ; Subtract current tens
   LDA num+0
   SBC PrDec24Tens+0,Y
   STA num+0  
   
   LDA num+1
   SBC PrDec24Tens+1,Y
   STA num+1
   
   LDA num+2
   SBC PrDec24Tens+2,Y
   STA num+2
   
   INX
   BCS PrDec24Lp2                           ; Loop until <0
   
   LDA num+0
   ADC PrDec24Tens+0,Y
   STA num+0                                ; Add current tens back in
   
   LDA num+1
   ADC PrDec24Tens+1,Y
   STA num+1
   
   LDA num+2
   ADC PrDec24Tens+2,Y
   STA num+2
   
   TXA
   BNE PrDec24Digit                         ; Not zero, print it
   LDA pad
   BNE PrDec24Print
   BEQ PrDec24Next                          ; pad<>0, use it
PrDec24Digit:
   LDX #'0'
   STX pad                                  ; No more zero padding
   ORA #'0'                                 ; Print this digit
PrDec24Print:
   ; FIXME JSR OSWRCH
PrDec24Next:
   DEY
   DEY
   DEY
   BPL PrDec24Lp1                           ; Loop for next digit
   RTS
   
PrDec24Tens:
   .word 1          ; 1 %   65536
   .byte 0          ; 1 DIV 65536
   .word 10         ; 10 %   65536
   .byte 0          ; 10 DIV 65536
   .word 100        ; 100 %   65536
   .byte 0          ; 100 DIV 65536
   .word 1000       ; 1000 %   65536
   .byte 0          ; 1000 DIV 65536
   .word 10000      ; 10000 %   65536
   .byte 0          ; 10000 DIV 65536
   .word 34464      ; 100000 %   65536
   .byte 1          ; 100000 DIV 65536
   .word 16960      ; 1000000 %   65536
   .byte 15         ; 1000000 DIV 65536
   .word 38528      ; 10000000 %   65536
   .byte 152        ; 10000000 DIV 65536
.endif