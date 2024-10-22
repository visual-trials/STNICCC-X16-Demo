  
; FIXME: when x = 255 it goes wrong!

; ================== DRAW POLYGON ==============

; uses variables:
;   vertices
;   nr_of_vertices_bytes:            .byte 0
;   current_vertex_byte_index:       .byte 0
;   vertical_direction:              .byte 0
;   horizontal_direction:            .byte 0
;   min_y:                           .byte 0
;   max_y:                           .byte 0
;   x_address:              .word 0
;   x_increment:            .word 0
;   begin_byte_x:           .word $3040
;   end_byte_x:             .word $3040
;   line_base_address:      .word 0



draw_polygon_fast:


    lda #$FF
    sta min_y

    stz max_y

    lda nr_of_vertices_in_polygon
    asl
    sta nr_of_vertices_bytes
    
    ; We start at vertex index 0
    stz current_vertex_byte_index
    
next_vertex_pair:

.if(do_specific_measuring)
    START_CLOCK
.endif
.if(do_specific_measuring)
    END_CLOCK
    CALC_NR_OF_CYCLES
    SHOW_MEASUREMENT 
    jsr wait_very_long
    stp
.endif

    ; ----- Load x and y of vertex pair -----

    ldy current_vertex_byte_index

    lda vertices,y              ; start x-coordinate
    sta x1
    lda vertices+1,y            ; start y-coordinate
    sta y1
    
    cmp min_y
    bcs :+      ; if y1 < min_y then store it
    sta min_y    
:
    ; TODO: dont store if equal
    cmp max_y
    bcc :+      ; if y1 <= max_y then store it
    sta max_y    
:
    iny
    iny
    sty current_vertex_byte_index
    
    cpy nr_of_vertices_bytes
    bne :+                      ; if we haven't reach the last vertex yet, we do not have to "wrap around"
    ldy #0
:
    lda vertices,y              ; end x-coordinate
    sta x2
    lda vertices+1,y            ; end y-coordinate
    sta y2


    ; ----- Determine start x_address -----
    lda x1
    sta x_address+1
    lda #$80
    sta x_address
    
    ; ----- Determine x_increment and whether we go UP or DOWN -----
    
    ; --- First determine y_diff ---

    ; FIXME: shouldn't we divide by abs(y2-y1) PLUS 1??
    
    LDA y2
    SEC
    SBC y1
    BCC scan_lines_UP           ; if y2 - y1 is positive, then we are going DOWN
                                ; else we are going UP
    JMP scan_lines_DOWN
    
    scan_lines_UP:
    
        ; We go UP

        ; --- y_diff = y1 - y2 (so we negate y2-y1) -> now in A
        EOR #$FF
        INC
        
        ; TODO: for we do nothing when delta-y is 0. Is this really correct? 
        ;       Note that if we take the difference between x2 and x1 and skip the divide we get a wrong begin_x (since vertical_direction is wrong)
        BNE :+
        JMP done_scanning_lines
:

.if(use_new_division_table)
        TAY
.else
        ; Set divide_fast y-part
        
        LSR            ; we divide y by 2 (so we only use the lower 7 bits)
        ORA #$80       ; we set the highest bit to 1 (the first ~128 banks are used by the loaded video data)
        STA RAM_BANK
        
        LDA #0
        ROL            ; we get the lowest bit of y (which was shifted into the carry bit)
        ASL            ; and use it as the highest *used* bit (second lowest bit of the high byte) of the address inside the bank
        CLC
        ADC #$A0        ; we add the byte of the base address ($A000)
        STA bank_address_msb_from_y_lsb
.endif
        
        ; --- Then determine x_diff ---
        
        LDA x2
        SEC
        SBC x1
        BCS :+    ; if x2 - x1 is positive, then we are going RIGHT
                  ; else we are going LEFT

            ; We go LEFT

            ; --- x_diff = x1 - x2 (so we negate x2-x1) -> now in A
            EOR #$FF
            INC
.if(use_new_division_table)
            TAX
            
            LDA division_high_y_part,y
            STA RAM_BANK
            
            LDA division_low_y_part,y
            ORA division_high_x_part,x
            STA division_address+1
            
            LDY division_low_x_part,x
.else
            ASL             ; we need 2 bytes per division result, so we multiply x with 2
            TAY
            
            LDA #0
            ROL                               ; if x > 128, we now get the carry in the lowest bit
            ORA bank_address_msb_from_y_lsb   ; we set the highest used bit (coming from the lowest bit from y) and include the base address ($A000)
            STA division_address+1
.endif
            
.if(use_scanning_lines_table)
            LDA (division_address),y
            STA x_decrement
            INY
            LDA (division_address),y
            STA x_decrement+1
            
            
    .if(use_new_scanning_lines_table)
            lda jump_to_decrementing_code_LO,y
            sta jmp_scanning_code_UP+1
            lda jump_to_decrementing_code_HI,y
            sta jmp_scanning_code_UP+2

            ; NOTE: we set this here, since we know we are going to use SBC-code
            SEC
    .else
            LDY #SCANNING_SBC_BANK          ; We use SCANNING_SBC_BANK for jump_address_scanning_code that use SBC (aka "left")
            STY RAM_BANK

            LDY #$E5          ; SBC Zero page
            STY unpatch_code
    .endif
.else
            LDA (division_address),y
            STA adc_x_decrement_LO_UP+1
            INY
            LDA (division_address),y
            STA adc_x_decrement_HI_UP+1
.endif
            
            bra :++
    :        
            ; We go RIGHT 
            
            ; --- x_diff = x2 - x1 (now in A)
            
.if(use_new_division_table)
            TAX
            
            LDA division_high_y_part,y
            STA RAM_BANK
            
            LDA division_low_y_part,y
            ORA division_high_x_part,x
            STA division_address+1
            
            LDY division_low_x_part,x
.else
            ASL             ; we need 2 bytes per division result, so we multiply x with 2
            TAY
            
            LDA #0
            ROL                               ; if x > 128, we now get the carry in the lowest bit
            ORA bank_address_msb_from_y_lsb   ; we set the highest used bit (coming from the lowest bit from y) and include the base address ($A000)
            STA division_address+1
.endif
            
.if(use_scanning_lines_table)
            ; --- x_decrement = (x2 - x1) / abs(y2 - y1)
            LDA (division_address),y
            STA x_decrement
            INY
            LDA (division_address),y
            STA x_decrement+1
            
    .if(use_new_scanning_lines_table)
            lda jump_to_incrementing_code_LO,y
            sta jmp_scanning_code_UP+1
            lda jump_to_incrementing_code_HI,y
            sta jmp_scanning_code_UP+2

            ; NOTE: we set this here, since we know we are going to use ADC-code
            CLC
    .else
            LDY #SCANNING_ADC_BANK          ; We use SCANNING_ADC_BANK for jump_address_scanning_code that use ADC (aka "right")
            STY RAM_BANK

            LDY #$65          ; ADC Zero page
            STY unpatch_code
    .endif
.else
            ; --- x_decrement = 0 - ( (x1 - x2) / abs(y2 - y1) ) -> So we negate the division result
            SEC
            LDA #0
            SBC (division_address),y
            STA adc_x_decrement_LO_UP+1
            INY
            LDA #0
            SBC (division_address),y
            STA adc_x_decrement_HI_UP+1
.endif

    :


.if(use_new_scanning_lines_table)

        lda #1
        sta VERA_ctrl   ; ADDRSEL=1
        
        LDY y2
        LDA vram_end_x_LO, y
        STA VERA_addr_low
        LDX vram_end_x_HI, y
        STX VERA_addr_high    ; NOTE: this value is stored in vera0 too, so we need to keep the accumilator value
        
buffer_switch_data1_decrement:
        LDY #%00101001  ; setting data1 to: decrement of 2
        STY VERA_addr_bank
    
        STZ VERA_ctrl   ; ADDRSEL=0

        ; LDX vram_end_x_HI, y ; this load was done just before
        STX VERA_addr_high
        ; LDA vram_end_x_LO, y ; this load was done just before
        STA VERA_addr_low
        
buffer_switch_data0_decrement:
        ; LDY #%00101001  ; setting data0 to: decrement of 2   ; this load was done just before : 
        STY VERA_addr_bank
        
        LDX x_address
        
        ; TODO: write the first byte! (maybe to data1, so it will be decrement by 2 compared to data0)
        LDA x_address+1
        ; NOTE: this STORE should decrement the address for VERA_data0 by 2 bytes!
        STA VERA_data0
    
        ; TODO: we jump to the scan-code (which has an rts at the end? or does it jump back?) ->
        ; FIXME: should it jump back to *done_scanning_lines*!?
jmp_scanning_code_UP:
        JMP 0                  ; this will be PATCHED beforehand

        ; FIXME: do we have to unset anything?? (or may we assume that everything will be set each vertex pair?)
    
        JMP done_scanning_lines
    
.elseif(use_scanning_lines_table)

        ; NOTE: be careful the CARRY has just been set or unset. Don't touch it!

        ; Determine the ending/jump-back address
        
        LDA y2
; FIXME
;        DEC                 ; We decrement the y2 value we compare to, since we want to loop as long as y >= y2
        TAY                 ; Y = y2-1
        
        ; Get the address for the jump-back command
        
        LDA jump_address_scanning_code_UP_LO, y
        STA patch_address
        LDA jump_address_scanning_code_UP_HI, y
        STA patch_address+1
        
        ; Patch the jump-back command
        
        LDY #0
        LDA #$4C  ; JMP
        STA (patch_address),y
        INY
        LDA #<jmp_back_from_scanning_code_UP
        STA (patch_address),y
        INY
        LDA #>jmp_back_from_scanning_code_UP
        STA (patch_address),y
        
        ; Detrmine starting/jumping address
        
        LDY y1              ; Y = y1

        LDX x_address
        
        LDA x_address+1
        STA end_x,y
        
; FIMXE: we are doing an DEY because the original algo did this. Work out if we can compare differently or we should change our table (to start with 1)
;        DEY
        
        LDA jump_address_scanning_code_UP_LO, y
        STA jmp_scanning_code_UP+1
        LDA jump_address_scanning_code_UP_HI, y
        STA jmp_scanning_code_UP+2

; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
        SEC             ; The carry must be set for the SBC that follows

jmp_scanning_code_UP:
        JMP 0                  ; this will be PATCHED beforehand
jmp_back_from_scanning_code_UP:
        
        ; Unpatch the jump-back command
        
        LDY #0
        LDA #$8A               ; TXA
        STA (patch_address),y
        INY
        LDA unpatch_code       ; ADC/SBC Zero Page
        STA (patch_address),y
        INY
        LDA #x_decrement       ; x_decrement
        STA (patch_address),y

        JMP done_scanning_lines

.else  
        
        LDA y2
        DEC                 ; We decrement the y2 value we compare to, since we want to loop as long as y >= y2
        STA cmp_y2_UP+1
        
        LDY y1
        
        LDX x_address
        
        LDA x_address+1
        STA end_x,y
        
        DEY
        CPY cmp_y2_UP+1      ; TODO: we compare here if we already reached the end, but we use the just decremented value (which is just a little bit slow, maybe?)
        ;BEQ done_scanning_lines
        BNE :+
        JMP done_scanning_lines
:
        
        SEC                  ; The carry must be set for the SBC that follows
        
    next_scan_line_UP:

        TXA
    adc_x_decrement_LO_UP:
        SBC #0
        TAX

        LDA end_x_prev,y
    adc_x_decrement_HI_UP:
        SBC #0
        STA end_x,y

        DEY
    cmp_y2_UP:
        CPY #0
        BNE next_scan_line_UP

        JMP done_scanning_lines
.endif        

    scan_lines_DOWN:

        ; We go DOWN

        ; --- y_diff (now in A) = y2 - y1

        ; TODO: for we do nothing when delta-y is 0. Is this really correct? 
        ;       Note that if we take the difference between x2 and x1 and skip the divide we get a wrong begin_x (since vertical_direction is wrong)
        BNE :+
        JMP done_scanning_lines
:

.if(use_new_division_table)
        TAY
.else
        ; Set divide_fast y-part
        LSR            ; we divide y by 2 (so we only use the lower 7 bits)
        ORA #$80       ; we set the highest bit to 1 (the first ~128 banks are used by the loaded video data)
        STA RAM_BANK
        
        LDA #0
        ROL            ; we get the lowest bit of y (which was shifted into the carry bit)
        ASL            ; and use it as the highest *used* bit (second lowest bit of the high byte) of the address inside the bank
        CLC
        ADC #$A0        ; we add the byte of the base address ($A000)
        STA bank_address_msb_from_y_lsb
.endif
        

        ; --- Then determine x_diff ---
        
        LDA x2
        SEC
        SBC x1
        BCS :+    ; if x2 - x1 is positive, then we are going RIGHT
                  ; else we are going LEFT

            ; We go LEFT

            ; --- x_diff = x1 - x2 (so we negate x2-x1) -> now in A
            EOR #$FF
            INC
            
.if(use_new_division_table)
            TAX
            
            LDA division_high_y_part,y
            STA RAM_BANK
            
            LDA division_low_y_part,y
            ORA division_high_x_part,x
            STA division_address+1
            
            LDY division_low_x_part,x
.else
            ASL             ; we need 2 bytes per division result, so we multiply x with 2
            TAY
            
            LDA #0
            ROL                               ; if x > 128, we now get the carry in the lowest bit
            ORA bank_address_msb_from_y_lsb   ; we set the highest used bit (coming from the lowest bit from y) and include the base address ($A000)
            STA division_address+1
.endif
            
            
.if(use_scanning_lines_table)
            ; --- x_decrement = (x2 - x1) / abs(y2 - y1)
            LDA (division_address),y
            STA x_decrement
            INY
            LDA (division_address),y
            STA x_decrement+1

    .if(use_new_scanning_lines_table)
            lda jump_to_decrementing_code_LO,y
            sta jmp_scanning_code_DOWN+1
            lda jump_to_decrementing_code_HI,y
            sta jmp_scanning_code_DOWN+2

            ; NOTE: we set this here, since we know we are going to use SBC-code
            SEC
    .else
            LDY #SCANNING_SBC_BANK          ; We use SCANNING_SBC_BANK for jump_address_scanning_code that use SBC (aka "left")
            STY RAM_BANK

            LDY #$E5          ; SBC Zero page
            STY unpatch_code
    .endif
.else
            ; --- x_increment = 0 - ( (x1 - x2) / abs(y2 - y1) ) -> So we negate the division result
            SEC
            LDA #0
            SBC (division_address),y
            STA adc_x_increment_LO_DOWN+1
            INY
            LDA #0
            SBC (division_address),y
            STA adc_x_increment_HI_DOWN+1
.endif

            
            bra :++
    :        
            ; We go RIGHT
            
            ; --- x_diff = x2 - x1 -> now in A
            
.if(use_new_division_table)
            TAX
            
            LDA division_high_y_part,y
            STA RAM_BANK
            
            LDA division_low_y_part,y
            ORA division_high_x_part,x
            STA division_address+1
            
            LDY division_low_x_part,x
.else
            ASL             ; we need 2 bytes per division result, so we multiply x with 2
            TAY
            
            LDA #0
            ROL                               ; if x > 128, we now get the carry in the lowest bit
            ORA bank_address_msb_from_y_lsb   ; we set the highest used bit (coming from the lowest bit from y) and include the base address ($A000)
            STA division_address+1
.endif
            
.if(use_scanning_lines_table)
            LDA (division_address),y
            STA x_increment
            INY
            LDA (division_address),y
            STA x_increment+1
            
    .if(use_new_scanning_lines_table)
            lda jump_to_incrementing_code_LO,y
            sta jmp_scanning_code_DOWN+1
            lda jump_to_incrementing_code_HI,y
            sta jmp_scanning_code_DOWN+2

            ; NOTE: we set this here, since we know we are going to use ADC-code
            CLC
    .else
            LDY #SCANNING_ADC_BANK          ; We use SCANNING_ADC_BANK for jump_address_scanning_code that use ADC (aka "right")
            STY RAM_BANK
            
            LDY #$65          ; ADC Zero page
            STY unpatch_code
    .endif
.else
            LDA (division_address),y
            STA adc_x_increment_LO_DOWN+1
            INY
            LDA (division_address),y
            STA adc_x_increment_HI_DOWN+1
.endif
            
    :

        
.if(use_new_scanning_lines_table)

        lda #1
        sta VERA_ctrl   ; ADDRSEL=1
        
        LDY y2
        LDA vram_end_x_LO, y
        STA VERA_addr_low
        LDX vram_end_x_HI, y
        STX VERA_addr_high    ; NOTE: this value is stored in vera0 too, so we need to keep the accumilator value
        
buffer_switch_data1_increment:
        LDY #%00100001  ; setting data1 to: increment of 2
        STY VERA_addr_bank
    
        STZ VERA_ctrl   ; ADDRSEL=0

        ; LDX vram_end_x_HI, y ; this load was done just before
        STX VERA_addr_high
        ; LDA vram_end_x_LO, y ; this load was done just before
        STA VERA_addr_low
        
buffer_switch_data0_increment:
        ; LDY #%00100001  ; setting data0 to: increment of 2   ; this load was done just before : 
        STY VERA_addr_bank
        
        LDX x_address
        
        LDA x_address+1
        ; NOTE: this STORE should increment the address for VERA_data0 by 2 bytes!
        STA VERA_data0
    
        ; TODO: we jump to the scan-code (which has an rts at the end? or does it jump back?) ->
        ; FIXME: should it jump back to *done_scanning_lines*!?
jmp_scanning_code_DOWN:
        JMP 0                  ; this will be PATCHED beforehand

        ; FIXME: do we have to unset anything?? (or may we assume that everything will be set each vertex pair?)
    
        ; FIXME: no need to do this (we are already there): JMP done_scanning_lines
    
    
.elseif(use_scanning_lines_table)

        ; Determine the ending/jump-back address
        
        LDA y2
; FIXME
;        INC                 ; We increment the y2 value we compare to, since we want to loop as long as y <= y2
        TAY                 ; Y = y2+1
        
        ; Get the address for the jump-back command
        
        LDA jump_address_scanning_code_DOWN_LO, y
        STA patch_address
        LDA jump_address_scanning_code_DOWN_HI, y
        STA patch_address+1
        
        ; Patch the jump-back command
        
        LDY #0
        LDA #$4C  ; JMP
        STA (patch_address),y
        INY
        LDA #<jmp_back_from_scanning_code_DOWN
        STA (patch_address),y
        INY
        LDA #>jmp_back_from_scanning_code_DOWN
        STA (patch_address),y
        
        ; Detrmine starting/jumping address
        
        LDY y1              ; Y = y1
        
        LDX x_address
        
        LDA x_address+1
        STA begin_x,y
        
; FIMXE: we are doing an INY because the original algo did this. Work out if we can compare differently or we should change our table (to start with 1)
;        INY
        
        LDA jump_address_scanning_code_DOWN_LO, y
        STA jmp_scanning_code_DOWN+1
        LDA jump_address_scanning_code_DOWN_HI, y
        STA jmp_scanning_code_DOWN+2

; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
; FIXME: shouldnt this be set when we determine LEFT or RIGHT?
        CLC

jmp_scanning_code_DOWN:
        JMP 0                  ; this will be PATCHED beforehand
jmp_back_from_scanning_code_DOWN:
        
        ; Unpatch the jump-back command
        
        LDY #0
        LDA #$8A               ; TXA
        STA (patch_address),y
        INY
        LDA unpatch_code       ; ADC/SBC Zero Page
        STA (patch_address),y
        INY
        LDA #x_increment       ; x_increment
        STA (patch_address),y

.else  
        LDA y2
        INC                 ; We increment the y2 value we compare to, since we want to loop as long as y <= y2
        STA cmp_y2_DOWN+1
        
        LDY y1
        
        LDX x_address
        
        LDA x_address+1
        STA begin_x,y
        
        INY
        CPY cmp_y2_DOWN+1      ; TODO: we compare here if we already reached the end, but we use the just incremented value (which is just a little bit slow, maybe?)
        BEQ done_scanning_lines
        
        CLC                  ; The carry must be cleared for the ADC that follows
        
        
    next_scan_line_DOWN:

        TXA
    adc_x_increment_LO_DOWN:
        ADC #0
        TAX

        LDA begin_x_prev,y
    adc_x_increment_HI_DOWN:
        ADC #0
        STA begin_x,y

        INY
    cmp_y2_DOWN:
        CPY #0
        BNE next_scan_line_DOWN
.endif

done_scanning_lines:

    ldy current_vertex_byte_index
    cpy nr_of_vertices_bytes
    beq :+
    jmp next_vertex_pair                      ; if we haven't reach the last vertex yet, we do the next pair
:


    ; ============== Do the DRAWING =================


; FIXME: set *data1*** decrement/increment correctly! And set its address correctly!

.if(use_new_scanning_lines_table)
    lda #1
    sta VERA_ctrl   ; ADDRSEL=1

; FIXME: is this correct??
    LDY min_y
    LDA vram_end_x_LO, y
    STA VERA_addr_low
    LDX vram_end_x_HI, y
    STX VERA_addr_high    ; NOTE: this value is stored in vera0 too, so we need to keep the accumilator value

buffer_switch_data0_and_data1_to_increment_by_1:
    LDY #%00010001  ; setting data1 to: increment of 1
    STY VERA_addr_bank
    
    STZ VERA_ctrl   ; ADDRSEL=0
    
;buffer_switch_data0_increment1:
    ;LDY #%00010001  ; setting data0 to: increment of 1
    STY VERA_addr_bank
    
.endif


; FIXME: set *data0* decrement/increment correctly! And set its address correctly!
; NOTE: this is ONLY needed when doing the REALLY fast draw!!


    lda min_y
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+(cmp_min_y_ending_pixel-draw_with_ending_pixel)+1
    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(cmp_min_y_no_ending_pixel-draw_with_no_ending_pixel)+1
    ldy max_y
    iny                ; y is incremented because it is decremented immediatly in the loop
    
buffer_switch_start_drawing:
    ldx #$11            ; turn on increment of 1
    stx VERA_increment
    
    ; Patching colors (immediate loads) inside the inner loop

    lda current_color_left_nibble
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+(left_nibble_ending_pixel-draw_with_ending_pixel)+1

    lda current_color_both_nibbles
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+(color_both_nibbles_ending_and_no_starting_pixel-draw_with_ending_pixel)+1
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+(color_both_nibbles_ending_and_starting_pixel-draw_with_ending_pixel)+1

    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(color_both_nibbles_no_ending_and_no_starting_pixel-draw_with_no_ending_pixel)+1
    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(color_both_nibbles_no_ending_and_starting_pixel-draw_with_no_ending_pixel)+1

    lda current_color_right_nibble
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+(right_nibble_ending_pixel-draw_with_ending_pixel)+1
    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(right_nibble_no_ending_pixel-draw_with_no_ending_pixel)+1

    ; since we just increment of 1, we act as if we just drew no ending pixel (which also results in an increment of 1)
    jmp draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(draw_next_line_no_ending_pixel-draw_with_no_ending_pixel) 
    
done_drawing_lines:
    ; We have draw the lines from min_y to max_y

;lda frame_index
;cmp #65
;bne do_not_stop
;jsr wait_very_long
;stp    
;do_not_stop:    
   
    rts


; ========== Draw horizonal line FAST: draw ENDING pixel ==========

draw_with_ending_pixel:
buffer_switch_ending_pixel:
    LDX #$01
    STX VERA_increment
    LDA #$0F
    AND VERA_data0
left_nibble_ending_pixel:
    ORA #$20            ; This will be patched beforehand
    STA VERA_data0 

cmp_min_y_ending_pixel:
    CPY #0              ; this is patched beforehand
    BEQ jmp_done_drawing_lines_ending_pixel   ; The carry is always set after this CPY and BEQ
draw_next_line_ending_pixel:
    DEY
    LDA end_x, y
    SBC begin_x, y
    BCC cmp_min_y_ending_pixel  ; If end_x < begin_x, then skip line and try next y
    TAX                 ; x = nr of pixels
    
    LDA begin_x, y
    LSR                 ; divide by 2
    BCS do_first_pixel_ending_pixel
    
        ADC y_to_base_line_address_LO,y
        STA VERA_addr_low
        LDA y_to_base_line_address_HI,y
        ADC #0              ; The carry is always unset after this ADC
        STA VERA_addr_high    
        
        LDA jump_address_horizontal_LO_255_is_256,x
        STA draw_up_to_256_pixels_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_ending_and_no_starting_pixel-draw_with_ending_pixel)+1
        LDA jump_address_horizontal_HI_255_is_256,x
        STA draw_up_to_256_pixels_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_ending_and_no_starting_pixel-draw_with_ending_pixel)+2
    
    buffer_switch_no_first_pixel_ending_pixel:
        LDX #$11
        STX VERA_increment  ; Since we started with a ENDING pixel, VERA_increment is still $01, so we change it to $11 (since we won't draw a STARTING pixel)
        
    color_both_nibbles_ending_and_no_starting_pixel:
        LDA #$22            ; This will be patched beforehand
    jmp_to_draw_full_pixels_ending_and_no_starting_pixel:
        JMP draw_up_to_256_pixels_ending_pixel_4bits   ; draw_full_pixels, this will be PATCHED beforehand

    
do_first_pixel_ending_pixel:
    
        ; The carry is set (by the LSR), so it will be added to the ADC, so we need to use the minus_one table

        ADC y_to_base_line_address_minus_one_LO,y
        STA VERA_addr_low
        LDA y_to_base_line_address_minus_one_HI,y
        ADC #0              ; The carry is always unset after this ADC
        STA VERA_addr_high    

        LDA jump_address_horizontal_LO,x
        STA draw_up_to_256_pixels_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_ending_and_starting_pixel-draw_with_ending_pixel)+1
        LDA jump_address_horizontal_HI,x
        STA draw_up_to_256_pixels_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_ending_and_starting_pixel-draw_with_ending_pixel)+2
        
        LDA #$F0
        AND VERA_data0
    right_nibble_ending_pixel:
        ORA #$02            ; This will be patched beforehand
    buffer_switch_first_pixel_ending_pixel:
        LDX #$11
        STX VERA_increment
        STA VERA_data0     

    color_both_nibbles_ending_and_starting_pixel:
        LDA #$22            ; This will be patched beforehand
    jmp_to_draw_full_pixels_ending_and_starting_pixel:
        JMP draw_up_to_256_pixels_ending_pixel_4bits  ; draw_full_pixels, this will be PATCHED beforehand

jmp_done_drawing_lines_ending_pixel:
    JMP done_drawing_lines
end_of_drawing_with_ending_pixel:
    


; ========== Draw horizonal line FAST: draw no ENDING pixel ==========

draw_with_no_ending_pixel:
cmp_min_y_no_ending_pixel:
    CPY #0              ; this is patched beforehand
    BEQ jmp_done_drawing_lines_no_ending_pixel   ; The carry is always set after this CPY and BEQ
draw_next_line_no_ending_pixel:
    DEY
    LDA end_x, y
    SBC begin_x, y
    BCC cmp_min_y_no_ending_pixel  ; If end_x < begin_x, then skip line and try next y
    TAX                 ; x = nr of pixels
    
    LDA begin_x, y
    LSR                 ; divide by 2
    BCS do_first_pixel_no_ending_pixel
    
        ADC y_to_base_line_address_LO,y
        STA VERA_addr_low
        LDA y_to_base_line_address_HI,y
        ADC #0              ; The carry is always unset after this ADC
        STA VERA_addr_high    
        
        LDA jump_address_horizontal_LO_255_is_256,x
        STA draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_no_ending_and_no_starting_pixel-draw_with_no_ending_pixel)+1
        LDA jump_address_horizontal_HI_255_is_256,x
        STA draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_no_ending_and_no_starting_pixel-draw_with_no_ending_pixel)+2
        
    color_both_nibbles_no_ending_and_no_starting_pixel:
        LDA #$22            ; This will be patched beforehand
    jmp_to_draw_full_pixels_no_ending_and_no_starting_pixel:
        JMP draw_up_to_256_pixels_no_ending_pixel_4bits  ; draw_full_pixels, this will be PATCHED beforehand
        
    do_first_pixel_no_ending_pixel:
        
        ; The carry is set (by the LSR), so it will be added to the ADC, so we need to use the minus_one table

        ADC y_to_base_line_address_minus_one_LO,y
        STA VERA_addr_low
        LDA y_to_base_line_address_minus_one_HI,y
        ADC #0              ; The carry is always unset after this ADC
        STA VERA_addr_high    

        LDA jump_address_horizontal_LO,x
        STA draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_no_ending_and_starting_pixel-draw_with_no_ending_pixel)+1
        LDA jump_address_horizontal_HI,x
        STA draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+(jmp_to_draw_full_pixels_no_ending_and_starting_pixel-draw_with_no_ending_pixel)+2

buffer_switch_first_pixel_no_ending_pixel:        
        LDX #$01
        STX VERA_increment  ; Since we DIDN'T start with an ending pixel, VERA_increment is still $11, so we change it to $01 (since we WILL draw a STARTING pixel)
        
        LDA #$F0
        AND VERA_data0
    right_nibble_no_ending_pixel:
        ORA #$02            ; This will be patched beforehand
buffer_switch_first_pixel_no_ending_pixel2:
        LDX #$11
        STX VERA_increment
        STA VERA_data0     
        
    color_both_nibbles_no_ending_and_starting_pixel:
        LDA #$22            ; This will be patched beforehand
    jmp_to_draw_full_pixels_no_ending_and_starting_pixel:
        JMP draw_up_to_256_pixels_no_ending_pixel_4bits     ; draw_full_pixels, this will be PATCHED beforehand

jmp_done_drawing_lines_no_ending_pixel:
    JMP done_drawing_lines
end_of_drawing_with_no_ending_pixel:



switch_buffer:

    lda current_buffer
    eor #$01
    sta current_buffer

    lda buffer_switch_clear_screen+1
    eor #$01
    sta buffer_switch_clear_screen+1

    lda buffer_switch_clear_screen_fast_4bit+1
    eor #$01
    sta buffer_switch_clear_screen_fast_4bit+1
    
    lda buffer_switch_start_drawing+1
    eor #$01
    sta buffer_switch_start_drawing+1

.if(use_new_scanning_lines_table)
    lda buffer_switch_data0_increment+1
    eor #$01
    sta buffer_switch_data0_increment+1
    sta buffer_switch_data1_increment+1

    lda buffer_switch_data0_decrement+1
    eor #$01
    sta buffer_switch_data0_decrement+1
    sta buffer_switch_data1_decrement+1
    
    lda buffer_switch_data0_and_data1_to_increment_by_1+1
    eor #$01
    sta buffer_switch_data0_and_data1_to_increment_by_1+1
.endif

    lda draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_ending_pixel-draw_with_ending_pixel+1
    eor #$01
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_ending_pixel-draw_with_ending_pixel+1
    
    lda draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_no_first_pixel_ending_pixel-draw_with_ending_pixel+1
    eor #$01
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_no_first_pixel_ending_pixel-draw_with_ending_pixel+1
    
    lda draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_first_pixel_ending_pixel-draw_with_ending_pixel+1
    eor #$01
    sta draw_up_to_256_pixels_ending_pixel_4bits+3*128+buffer_switch_first_pixel_ending_pixel-draw_with_ending_pixel+1

    lda draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+buffer_switch_first_pixel_no_ending_pixel-draw_with_no_ending_pixel+1
    eor #$01
    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+buffer_switch_first_pixel_no_ending_pixel-draw_with_no_ending_pixel+1
    
    lda draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+buffer_switch_first_pixel_no_ending_pixel2-draw_with_no_ending_pixel+1
    eor #$01
    sta draw_up_to_256_pixels_no_ending_pixel_4bits+3*128+buffer_switch_first_pixel_no_ending_pixel2-draw_with_no_ending_pixel+1
    
    rts

