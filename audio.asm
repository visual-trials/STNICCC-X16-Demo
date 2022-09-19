
; ===================================== Audio Flow Handler ============================================

default_irq_vector:  .addr 0
vsync_frame_counter: .word 0
move_sprites_based_on_music_volume: .byte 0


backup_default_irq_handler:

    ; backup default RAM IRQ vector
    lda IRQVec
    sta default_irq_vector
    lda IRQVec+1
    sta default_irq_vector+1

    rts

enable_vsync_and_aflow_handler:

    ; overwrite RAM IRQ vector with custom handler address
    sei ; disable IRQ while vector is changing
    lda #<vsync_and_aflow_irq_handler
    sta IRQVec
    lda #>vsync_and_aflow_irq_handler
    sta IRQVec+1

    lda #VSYNC_BIT ; make VERA generate VSYNC IRQs
;   ora #AFLOW_BIT ; make VERA *also* generate AFLOW IRQs
    sta VERA_ien
    cli ; enable IRQ now that vector is properly set

    rts
   
enable_aflow_handler_only:

   ; overwrite RAM IRQ vector with custom handler address
   sei ; disable IRQ while vector is changing
   lda #<aflow_irq_handler
   sta IRQVec
   lda #>aflow_irq_handler
   sta IRQVec+1

   lda #AFLOW_BIT ; make VERA generate AFLOW IRQs
   sta VERA_ien
   cli ; enable IRQ now that vector is properly set

   rts

vsync_and_aflow_irq_handler:

    PHA                     ; save accumulator
    TXA
    PHA                     ; save X-register
    TYA
    PHA                     ; save Y-register
    
    lda VERA_isr
    and #VSYNC_BIT
    beq check_aflow ; non-VSYNC IRQ, skip incrementing the vsync-frame-counter
    stz VERA_isr
    
    ; Increment vsync frame counter
    inc vsync_frame_counter
    bne :+
    inc vsync_frame_counter+1
:
    
check_aflow:
    lda VERA_isr
    and #AFLOW_BIT
    beq skip_loading_audio_file  ; AFLOW has not occured, skip loading audio data, 
   
    jsr load_2k_of_new_audio
skip_loading_audio_file:

    lda move_sprites_based_on_music_volume
    beq :+
    
    ldy RAM_BANK ; backup RAM_BANK
    lda #INTRO_RAM_BANK
    sta RAM_BANK
    clc
    lda vsync_frame_counter
    adc #<(intro_audio_volume-676)  ; index = frame - 676
    sta load_audio_volume+1
    lda vsync_frame_counter+1
    adc #>(intro_audio_volume-676)
    sta load_audio_volume+2
    
load_audio_volume:
    lda intro_audio_volume
    sta sprite_delta
    jsr move_sprites_to_delta_position ; NOTE: should *NOT* use register y!
    sty RAM_BANK ; restore RAM_BANK
:

continue_to_default_irq_hanndler:

    PLA
    TAY                     ; restore Y-register
    PLA
    TAX                     ; restore X-register
    PLA                     ; restore accumulator
    
    jmp (default_irq_vector) ; continue to default IRQ handler

    
aflow_irq_handler:

    PHA                     ; save accumulator
    TXA
    PHA                     ; save X-register
    TYA
    PHA                     ; save Y-register
    
    jsr load_2k_of_new_audio

    PLA
    TAY                     ; restore Y-register
    PLA
    TAX                     ; restore X-register
    PLA                     ; restore accumulator
    
; FIXME: measure how much time is spend in the default IRQ handler!
    jmp (default_irq_vector) ; continue to default IRQ handler


; ============== LOAD AUDIO into VERA FIFO buffer ============    
    
load_2k_of_new_audio:

    ; FIXME: check if we are at the end of the audio files?!
        ; TODO: Maybe disable the IRQ?
        ; TODO: Stop the sound playback
        
    ; FIXME: the last file has less bytes!!
    ; FIXME: the last file has less bytes!!
    ; FIXME: the last file has less bytes!!
        
    jsr load_audio_file

    ldx RAM_BANK ; backup RAM_BANK
    
    lda #AUDIO1_RAM_BANK
    sta RAM_BANK
    jsr audio_copy_code_1st_kb
    
    lda #AUDIO2_RAM_BANK
    sta RAM_BANK
    jsr audio_copy_code_2nd_kb
    
    stx RAM_BANK ; restore RAM_BANK
    
    lda audio_file_number
    clc
    adc #1
    sta audio_file_number
    bcc :+
    inc audio_file_number+1
:
    
    rts    



; ====================== LOAD AUDIO FILE ==============================

audio_file_number:   .word 0
; FIXME: we need 3 digits!
audio_filename:      .byte    "audio/000.bin"
end_audio_filename:

; https://gist.github.com/JimmyDansbo/f955378ee4f1087c2c286fcd6956e223
; https://www.commanderx16.com/forum/index.php?/topic/80-loading-a-file-into-vram-assembly/
; https://www.commanderx16.com/forum/index.php?/topic/795-cc65-cbm_k_load-into-banked-ram/
load_audio_file:
    jsr set_audio_filename
    
    ; TODO; what should the logical file number be?
    lda #1            ; Logical file number
    ldx #8            ; Device 8 = sd card
    ldy #0            ; 0=ignore address in bin file (2 first bytes)
                      ; 1=use address in bin file
    jsr SETLFS

    lda #(end_audio_filename-audio_filename) ; Length of scene filename
    ldx #<audio_filename      ; Low byte of Fname address
    ldy #>audio_filename      ; High byte of Fname address
    jsr SETNAM

    ldy #>audio_file_buffer   ; HIGH address
    ldx #<audio_file_buffer   ; LOW address
    lda #$00            ; to load into RAM
    jsr LOAD            ; Load binary file into VRAM, ignoring 2 first bytes

    rts
    

set_audio_filename:

    lda audio_file_number
    and #$0F
    
    cmp #$0A
    bcs :+
    clc
    adc #48-0  ; = '0'
    sta audio_filename+8
    bra :++
:
    clc
    adc #65-10  ; = 'a'
    sta audio_filename+8
:

    lda audio_file_number
    lsr
    lsr
    lsr
    lsr
    and #$0F
    
    cmp #$0A
    bcs :+
    
    clc
    adc #48-0  ; = '0'
    sta audio_filename+7
    bra :++
:
    clc
    adc #65-10  ; = 'a'
    sta audio_filename+7
:

    ; The highest byte is never bigger than 2, so no need to check if its A to F
    lda audio_file_number+1
    clc
    adc #48-0  ; = '0'
    sta audio_filename+6

    rts
