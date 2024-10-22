; --- Macros ---

cycle_start:    .dword 0
cycle_end:      .dword 0
CLOCK_CYCLE     = $9FB8

.macro START_CLOCK
    lda CLOCK_CYCLE
    sta cycle_start
    lda CLOCK_CYCLE+1
    sta cycle_start+1
    lda CLOCK_CYCLE+2
    sta cycle_start+2
    lda CLOCK_CYCLE+3
    sta cycle_start+4
.endmacro
.macro END_CLOCK
    lda CLOCK_CYCLE
    sta cycle_end
    lda CLOCK_CYCLE+1
    sta cycle_end+1
    lda CLOCK_CYCLE+2
    sta cycle_end+2
    lda CLOCK_CYCLE+3
    sta cycle_end+3
.endmacro
.macro CALC_NR_OF_CYCLES
    sec
    lda cycle_end
    sbc cycle_start
    sta nr_of_cycles
    lda cycle_end+1
    sbc cycle_start+1
    sta nr_of_cycles+1
    lda cycle_end+2
    sbc cycle_start+2
    sta nr_of_cycles+2
    lda cycle_end+3
    sbc cycle_start+3
    sta nr_of_cycles+3
.endmacro

.macro SHOW_MEASUREMENT
    lda nr_of_cycles
    sta number_to_draw
    lda nr_of_cycles+1
    sta number_to_draw+1
    jsr draw_number_as_text_at_xy
.endmacro

.macro SHOW_MEASUREMENT_TIMES_256
    lda nr_of_cycles+1
    sta number_to_draw
    lda nr_of_cycles+2
    sta number_to_draw+1
    jsr draw_number_as_text_at_xy
.endmacro

.macro CopyWord from_word, to_word
    lda from_word
    sta to_word
    lda from_word+1
    sta to_word+1
.endmacro

.macro NegateWord word_to_negate, negated_word
    sec                     ; set carry for borrow purpose
    lda #0
    sbc word_to_negate   ; perform subtraction on the LSBs
    sta negated_word
    lda #0
    sbc word_to_negate+1 ; do the same for the MSBs, with carry set according to the previous result
    sta negated_word+1
.endmacro

.macro WaitUntilVSyncFrame frame_to_wait_for
.if(audio_enabled)
:
    lda vsync_frame_counter+1
    cmp frame_to_wait_for+1
    bcc :-
    lda vsync_frame_counter
    cmp frame_to_wait_for
    bcc :-
.endif
.endmacro

.macro WaitUntilVSyncFrameImmediate frame_to_wait_for_value
.if(audio_enabled)
:
    lda vsync_frame_counter+1
    cmp #>frame_to_wait_for_value
    bcc :-
    lda vsync_frame_counter
    cmp #<frame_to_wait_for_value
    bcc :-
.endif
.endmacro

.macro ResetVSyncFrame
    stz vsync_frame_counter
    stz vsync_frame_counter+1
.endmacro
