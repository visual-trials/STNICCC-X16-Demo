

wait_hi: .byte 0
wait_lo: .byte 0

wait_very_long:
    php
    pha

    lda #$7F
    sta wait_hi
:
    lda #$FF
    sta wait_lo
:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
    dec wait_lo
    bne :-
    
    dec wait_hi
    bne :--
    
    pla 
    plp
    
    rts

.if(0)
; FIXME: just testing!
clear_ram_bank0:

    ; Set to ram bank 0
    stz RAM_BANK

    lda #$00
    sta ZP_PTR_4
    lda #$A0
    sta ZP_PTR_4+1
    ldy #0                 ; generated code byte counter
    ldx #0                 ; counts nr of blocks-of-instructions

next_clear_bank0:

    lda #$DB               ; STP
    
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    jsr addCodeByte
    
    inx
    bne next_clear_bank0

    rts
.endif