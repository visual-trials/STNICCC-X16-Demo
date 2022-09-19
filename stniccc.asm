.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; --- Debug settings ---
do_very_fast_draw     = 0
do_frame_measuring    = 0 ; exclusive!
do_polygon_measuring  = 0 ; exclusive!
do_specific_measuring = 0 ; exclusive!
do_switch_buffer      = 1
use_scanning_lines_table = 1
use_new_scanning_lines_table = 0 ; this overrules use_scanning_lines_table! (but also REQUIRES use_scanning_lines_table!)
use_new_division_table = 1
; FIXME: we disabled audio loading and audio starting right now (see FIXMEs below), so for now keep this at 1
audio_enabled         = 1

; TODO: implement v2 of the new scanning+horizontal draw method!! :):)
;   - one with intro/outro and music (maybe stereo)
;   - one without music (as fast as possible)

; NICE: zoom-out first, then zoom-in (maybe move around (up/down/left/roght as well)
; NICE: use a mathimatical (3 leaf) 'rose' to deploy 'large pixels' in the beginning of the intro
; TODO: add an OUTRO of sorts: credits for music etc, more details about STNICCC, X16 community etc
; NICE: maybe say something like:
;
;     The Commander X16 only has:
;
;        - A simple 8-bit 65C02 (8 MHz)
;        - No DMA
;        - No Blitter
;
;          TIME: 1:39.96
;
;       www.commanderx16.com

; NICE TO HAVE: keep track of the number of v-syncs: show and CLOCK end-time at the end
;       BETTER: use the emulator clock cycle for measuring time, this won't cost performance.


; ---- TODOs afterwards ----

; TODO: hardcode: load_2k_of_new_audio should know how many files there are (and when "last file load" has occured). Also the length of the last file should be hardcoded.

; NICE: we also divide by the diff in abs(y2-y1). But shouldn't we divide by abs(y2-y1) + 1 ?
; NICE: do we do min_y/max_y handling correctly?

; CHECK: somehow the mouse is still active?!? Can we turn this off? (sprite 0 is also used and maybe an interrup?)

; TODO: make it run in the web-emulator (512KB of memory)
;          - We need to load the SCENE files on-the-fly. Probably on-demand and only one (directlty into BANKED RAM)
;          - We need to put the division-tables somewhere inside the 512KB
;          - Have a setting so it still works the way we do now

; ---- After release ----

; - Create a (mini)mod-player :)
; - Create some new demo with 3D effects and nice mod-music :)
; - Create several video's explaining/telling how this was made (and what techniques were used)
; - Create a StarWars scroller (tile-mode, depth by scaling with VERA per line using line-interrupts)


; ------------------ Tables and generated code -------------------


; RAM

; FIXME: this is *VERY* close to the end of code! Dump a memory map to ensure we are not overwriting code!!
nr_of_cycles                        = $1FE0   ; FIXME: placed on a weird place!! 
vertices                            = $1FF0   ; 7 * 2 bytes (max 7 vertices with and x and y coordinate)
audio_file_buffer                   = $2000    ; 2 kb audio ($2000 - $27FF)

clear_400_pixels_4bits              = $2800   ; 3 * 200 bytes + 1 bytes (rts)

left_nibble_to_right_nibble         = $2B00   ; 256 bytes NOTE: this contains very little data, butwe have a left nibble (4 highest bits) so we need 256 bytes
left_nibble_to_both_nibbles         = $2B01   ;

division_low_y_part                 = $2C00    ; 200 bytes
division_high_y_part                = $2D00    ; 200 bytes
division_low_x_part                 = $2E00    ; 256 bytes
division_high_x_part                = $2F00    ; 256 bytes

.if(use_new_scanning_lines_table)
increment_scanning_code             = $3000    ; 12 bytes * 200 = 2400 bytes (9.x * 256) -> uses until $3A00 
decrement_scanning_code             = $3A00    ; 12 bytes * 200 = 2400 bytes (9.x * 256) -> uses until $4400 

jump_to_incrementing_code_LO        = $4400    ; 200 bytes
jump_to_incrementing_code_HI        = $4500    ; 200 bytes
jump_to_decrementing_code_LO        = $4600    ; 200 bytes
jump_to_decrementing_code_HI        = $4700    ; 200 bytes

vram_begin_x_LO                     = $4800    ; 200 bytes -> translates from y to vram_begin_x (LO)
vram_begin_x_HI                     = $4900    ; 200 bytes -> translates from y to vram_begin_x (HI)
vram_end_x_LO                       = $4A00    ; 200 bytes -> translates from y to vram_end_x (LO)
vram_end_x_HI                       = $4B00    ; 200 bytes -> translates from y to vram_end_x (HI)

; VRAM
vram_begin_x                        = $1E000   ; OR $0E000 : 200 bytes (every 2 bytes) -> 400 bytes together
vram_end_x                          = $1E001   ; OR $0E001 : 200 bytes (every 2 bytes) -> 400 bytes together
.endif


.if(do_very_fast_draw)


.else

; TODO: we could also move these to RAM BANK 126 and 127
jump_address_scanning_code_DOWN_LO  = $6700   ; 200 bytes   ; TODO: isn't this table the same as jump_address_scanning_code_UP_LO?
jump_address_scanning_code_DOWN_HI  = $6800   ; 200 bytes
jump_address_scanning_code_UP_LO    = $6900   ; 200 bytes
jump_address_scanning_code_UP_HI    = $6A00   ; 200 bytes

begin_x                             = $8200   ; 200 bytes
begin_x_prev                        = begin_x-1
end_x_prev                          = end_x+1
end_x                               = $8300   ; 200 bytes

y_to_base_line_address_LO           = $8400   ; 200 bytes
y_to_base_line_address_HI           = $8500   ; 200 bytes
y_to_base_line_address_minus_one_HI = $7F00   ; 200 bytes
y_to_base_line_address_minus_one_LO = $8000   ; 200 bytes

jump_address_horizontal_LO_255_is_256       = $8E00   ; 256 bytes 
jump_address_horizontal_HI_255_is_256       = $8F00   ; 256 bytes
jump_address_horizontal_LO                  = $9000   ; 256 bytes 
jump_address_horizontal_HI                  = $9100   ; 256 bytes
draw_up_to_256_pixels_ending_pixel_4bits    = $9200   ; 3 * 128 bytes + 1 byte (rts) + draw-overhead-code
draw_up_to_256_pixels_no_ending_pixel_4bits = $9500   ; 3 * 128 bytes + 1 byte (rts) + draw-overhead-code

.endif

; --------------------------- RAM BANKS -------------------------

INTRO_RAM_BANK    = 240
AUDIO1_RAM_BANK   = 241
AUDIO2_RAM_BANK   = 242

SCANNING_ADC_BANK = 239
SCANNING_SBC_BANK = 238

; ---- RAM BANK 129 to 208 ----
; --> Loaded SCENE data  (80 banks = 80 * 8kb = 640kb)

; ---- RAM BANK 240 ----
intro_audio_volume                  = $A802   ; roughly 1200 bytes (5 * 256) -> so ends around 5D00
intro_palette_file_buffer           = $ACFF   ; 1 byte for nr of palette colors
intro_palette_colors_LO             = $AD00   ; first 128 colors (256 bytes)
intro_palette_colors_HI             = $AE00   ; second 128 colors (256 bytes)
zoom_scroll_x_LO                    = $AF00   ; 256 bytes
zoom_scroll_x_HI                    = $B000   ; 256 bytes
zoom_scroll_y_LO                    = $B100   ; 256 bytes
zoom_scale                          = $B200   ; 256 bytes
y_to_base_line_address_intro_LO     = $B300   ; 240 bytes
y_to_base_line_address_intro_HI     = $B400   ; 240 bytes

; ---- RAM BANK 241 ----
audio_copy_code_1st_kb              = $A000   ; 6 kb of code ($A000 - $B800) -> WARNING: this ends 1 BYTE more than B7FF!!

; ---- RAM BANK 242 ----
audio_copy_code_2nd_kb              = $A000   ; 6 kb of code ($A000 - $B800) -> WARNING: this ends 1 BYTE more than B7FF!!

; ---- RAM BANK 243 and 244 ---- (with the variants that SBC and ADC for both UP and DOWN)
.if(!use_new_scanning_lines_table)
begin_x_scanning_code               = $A000   ; 12 bytes * 200 = 2400 bytes (9.x * 256) -> uses until $AB00 (TODO: less actually)
end_x_scanning_code                 = $AB00   ; 12 bytes * 200 = 2400 bytes (9.x * 256) -> uses until $B600 (TODO: less actually)
.endif

; ---- RAM BANK 245 to 255 ----
; --> Large division table (<128kb)


; --------------------- General settings --------------------

RENDER_WIDTH      = 256
RENDER_HEIGHT     = 200

; ==================== Playback Stream ======================

RAM_BANK =                   $00

ZP_PTR_4 =                   $26     ; Note: we use this, but always make a backup and restore that
ZP_PTR_4_BACKUP:             .addr 0

division_address =           $66 ; word
frame_address =              $68 ; word
indexed_coords_address =     $70 ; word
indexed_coords_address_128 = $72 ; word
current_polygon_address =    $74 ; word
bytes_so_far =               $76 ; byte
frame_flags =                $77 ; byte
frame_index =                $78 ; byte
current_ram_bank =           $79 ; byte


nr_of_vertices_bytes =       $38 ; byte
current_vertex_byte_index =  $39 ; byte
line_base_address_minus_one = $3A ; word
min_y =                      $3C ; byte
max_y =                      $3D ; byte
x_address =                  $3E ; word
x_increment =                $40 ; word ; NOTE: is same as x_decrement!
x_decrement =                $40 ; word ; NOTE: is same as x_increment!
begin_byte_x =               $42 ; word
end_byte_x =                 $44 ; word
line_base_address =          $46 ; word

bytes_difference =           $48 ; word
code_bytes_difference =      $4A ; word 
bytes_skipped =              $4C ; byte

current_color_both_nibbles = $4D ; byte
current_color_left_nibble =  $4E ; byte
current_color_right_nibble = $4F ; byte

x1 =                         $50 ; byte
y1 =                         $51 ; byte
x2 =                         $52 ; byte
y2 =                         $53 ; byte

palette_mask =               $54 ; word
red =                        $56 ; byte
green_and_blue =             $57 ; byte
current_polygon_index =      $58 ; byte
vertex_index_in_polygon =    $59 ; byte
nr_of_vertices_in_polygon =  $5A ; byte
nr_of_vertices_in_polygon_bytes = $5B ; byte
nr_of_indexed_vertices_bytes = $5C ; word

bank_address_msb_from_y_lsb= $5E ; byte ; WARNING: same as unpatch_code
unpatch_code               = $5E ; byte ; WARNING: same as bank_address_msb_from_y_lsb!
current_buffer =             $5F ; byte
x_diff =                     $60 ; byte
y_diff =                     $61 ; byte

jump_address_scanning_code = $60 ; word --> TODO: the same as divisor! Little risky, but should be ok...
patch_address              = $62 ; word --> TODO: the same as dividend! Little risky, but should be ok...

divisor =                    $60 ; word --> FIXME: we still use this (note that we share the memory with x_diff and y_diff)
dividend =                   $62 ; word
remainder =                  $64 ; word ; only used in slow divided (so for building the divide table). 
result = dividend ;save memory by reusing divident to store the result


.include "macro.asm"
.include "intro.asm"
.include "audio.asm"
.include "polygon.asm"
.include "init.asm"
.include "debug.asm"


; --- Start of program ---
start:

    ResetVSyncFrame
    
    ; TODO: we are disabling all interrupts for now (we might want to do something more subtle)
    ; FIXME: we need the aflow interrupt, right? We do a cli then, so this doesn't do much
    sei
    
.if(!(do_polygon_measuring || do_frame_measuring || do_specific_measuring))
    jsr disable_display_layer1
.endif

    jsr init_text_screen
    jsr clear_text_screen
    
    jsr init_8bit_draw_screen
    jsr clear_draw_screen_slow_8bits

    ; FIXME: remove this, just testing if BANK 0 is being used
    ; jsr clear_ram_bank0
    
.if(audio_enabled)

    jsr init_audio_copy_code

    ; Info about PCM audio: https://www.commanderx16.com/forum/index.php?/topic/573-how-to-use-pcm-audio/

    lda #$8F    ; reset, 8 bit, mono + max volume
    ;    lda #$AF    ; reset, 16 bit, mono + max volume
    ;    lda #$BF    ; reset, 16 bit, stereo + max volume
    ; lda #$9F    ; reset, 8 bit, stereo + max volume
    sta VERA_audio_ctrl
    lda #$00    ; zero sample rate 
    sta VERA_audio_rate

    lda #0
    sta audio_file_number
    lda #0
    sta audio_file_number+1
    jsr load_audio_file

    ; Initially we load 4kb of audio (which is the size of the FIFO buffer)
; FIXME
;    jsr load_2k_of_new_audio
;    jsr load_2k_of_new_audio
    
    jsr backup_default_irq_handler
    jsr enable_vsync_and_aflow_handler
    
.endif

    ; ============== INTRO ======================
    
    jsr enable_display_layer0
    
    ; ======== Start Audio =====
    
.if(audio_enabled)
    ; Start audio playback
    lda #64    ; 64 = 24414 Hz sample rate 
; FIXME
;    sta VERA_audio_rate
.endif

    ; ======== Setup for drawing intro text SLOWLY =====

    lda #INTRO_RAM_BANK
    sta RAM_BANK
    
    jsr init_base_line_addresses_intro
    stz intro_pixel_frame_counter  
    stz intro_pixel_frame_counter+1
    stz current_intro_character_index
    stz current_intro_character_pixel
    jsr retrieve_pixels_from_current_character
    
    ; ======== Draw Intro Text SLOWLY =====
draw_intro_text_px:
    lda nr_of_pixels_in_character
    beq done_drawing_intro_text    ; if the nr_of_pixels_in_character == 0 we are done drawing pixels

    jsr draw_intro_text_pixel
    
    ; We just drew a pixel check if we are done drawing all pixels of the current character
    lda current_intro_character_pixel
    cmp nr_of_pixels_in_character
    bcc increment_pixel_frame_counter
    
    ; We drew the last pixel of a character, so we have to retrieve the pixels from the next character
    inc current_intro_character_index
    jsr retrieve_pixels_from_current_character
    lda #0
    sta current_intro_character_pixel
    
increment_pixel_frame_counter:
    ; Increment pixel frame counter
    inc intro_pixel_frame_counter
    bne :+
    inc intro_pixel_frame_counter+1
:
    WaitUntilVSyncFrame intro_pixel_frame_counter
    
    jmp draw_intro_text_px
    
done_drawing_intro_text:
 
 
    ; ======== Show HiRes Intro text =====
 
    WaitUntilVSyncFrameImmediate 675    ; after drawing the first into page and the first *BANG* in the music (mono 24Khz, 2KB files, only VSYNC)

    jsr disable_display_layer0
    jsr init_2bit_high_res_draw_screen
    jsr load_intro_files    
    jsr enable_display_layer0
    jsr enable_sprites
    
; FIXME    
;lda #0
;sta VERA_dc_border


;lda #150
;sta VERA_dc_vscale
;sta VERA_dc_hscale

;lda #100
;sta VERA_L0_hscroll_l
;lda #100
;sta VERA_L0_hscroll_h

;:
;jmp :-
    
    lda #1
    sta move_sprites_based_on_music_volume
    
    ; ---- In the mean time we prepare for the playback of the steam ----
        jsr init_clearing_code_4bits
        jsr init_draw_code_4bits_no_ending_pixel
        jsr init_draw_code_4bits_ending_pixel
        jsr init_line_scanning_code

        jsr init_color_table
        jsr init_base_line_addresses
        
        .if(use_new_division_table)
            jsr init_division_y_helper_table
            jsr init_division_x_helper_table
        .endif
        jsr init_large_division_table   ; this takes quite long...

        ; ---- load scene files ----
        lda #1
        sta scene_file_number
    :
        jsr load_scene_file
        inc scene_file_number
        lda scene_file_number
        cmp #$51
        bne :-
    ; ---- We have prepared (enough) for the playback ----
    
    ; ---- Next phase in the intro ----
    
    lda #INTRO_RAM_BANK
    sta RAM_BANK
    
; FIXME: returned back to old way of only zooming in!
    WaitUntilVSyncFrameImmediate 1675
;    WaitUntilVSyncFrameImmediate (1675-128)
       
    CopyWord vsync_frame_counter, intro_zoom_frame_counter

zoom_in_slowly:
;    dec intro_scale_screen

    ; Scale change (vertical and horizontal)
    
;    ldx intro_scale_screen
    ldx intro_zoom_index
    lda zoom_scale,x
    sta VERA_dc_vscale
    sta VERA_dc_hscale

    ; Horizontal scroll repositioning
    
    lda zoom_scroll_x_LO,x
    sta VERA_L0_hscroll_l
    lda zoom_scroll_x_HI,x
    sta VERA_L0_hscroll_h

    ; Vertical scroll repositioning
    
    lda zoom_scroll_y_LO,x
    sta VERA_L0_vscroll_l
    
    ; Left sprite repositioning

    lda #<left_sprite_x_orig
    sec
    sbc zoom_scroll_x_LO,x
    sta left_sprite_x
    lda #>left_sprite_x_orig
    sbc zoom_scroll_x_HI,x
    sta left_sprite_x+1

    lda #<left_sprite_y_orig
    sec
    sbc zoom_scroll_y_LO,x
    sta left_sprite_y

    ; Right sprite repositioning
    
    lda #<right_sprite_x_orig
    sec
    sbc zoom_scroll_x_LO,x
    sta right_sprite_x
    lda #>right_sprite_x_orig
    sbc zoom_scroll_x_HI,x
    sta right_sprite_x+1

    lda #<right_sprite_y_orig
    sec
    sbc zoom_scroll_y_LO,x
    sta right_sprite_y

    jsr setup_intro_sprites

;    ldx intro_scale_screen
;    cpx #3
    inc intro_zoom_index
    ldx intro_zoom_index
; FIXME: returned back to old way of only zooming in!
    cpx #126
;    cpx #254
    beq stop_zooming
    
    ; Increment zoom frame counter
    inc intro_zoom_frame_counter
    bne :+
    inc intro_zoom_frame_counter+1
:
    WaitUntilVSyncFrame intro_zoom_frame_counter
    
    jmp zoom_in_slowly
stop_zooming:

    WaitUntilVSyncFrameImmediate 1795  ; right at the beginning (mono 24Khz, 2KB files)

.if(audio_enabled)
    ; ----- This turns off vsync irqs and any intro logic -----
    jsr enable_aflow_handler_only
.endif

    ; We disable layer0 for a moment , because we switch to a different mode
    jsr disable_display_layer0
    ; We disable all sprites, since we don't need them anymore
    jsr disable_sprites
    
    ; Note: initial buffer is $01
    jsr init_playback_screen

    ; Clear buffer $00
    jsr switch_buffer
    jsr clear_playback_screen_fast_4bits
    ; Clear buffer $01
    jsr switch_buffer
    jsr clear_playback_screen_fast_4bits
    jsr enable_display_layer0
    
    ; Setting the border color to black
    lda #0
    sta VERA_dc_border

    ; Start stream playback
    jsr playback_stream


    ; Show time (FIXME: hardcoded for now)
    jsr enable_display_layer1
    jsr draw_text_at_xy
    
    
loop:
    nop
    jmp loop
    
    rts
    
    

playback_stream:

    ; --- init addresses ---

    lda #0
    sta frame_index
    
    lda #$81               ; We start at scene file 01, which corresponds to RAM BANK $81
    sta current_ram_bank
    sta RAM_BANK
    
    lda #$00
    sta frame_address
    lda #$A0
    sta frame_address+1

    
next_frame:

.if(do_switch_buffer)
    jsr switch_buffer
.endif
    
.if(do_frame_measuring)
    START_CLOCK
.endif
    
    lda current_ram_bank
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it
    
    ldy #0
    lda (frame_address), y    ; frame flags
    sta frame_flags
    iny
    and #$01  ; clear screen
    beq :+
    tya
    pha
    jsr clear_playback_screen_fast_4bits
    pla
    tay
:
    lda frame_flags
    and #$02  ; frame contains palette
    beq :+
    jsr load_palette  ; NOTE: this increases y

:
    lda frame_flags
    and #$04  ; frame contains indexed vertices
    beq :+

    jsr prepare_indexed_draw
    jsr draw_indexed_frame
    bra :++
:

    jsr prepare_non_indexed_draw    
    jsr draw_non_indexed_frame
:
    cpx #$FD
    beq end_of_video
    
    cpx #$FE    ; block/ram bank marker
    bne :+

    ; We go to the next ram bank and we set the frame address to $A000
    inc current_ram_bank
    
    lda #$00
    sta frame_address
    lda #$A0
    sta frame_address+1
    bra :++
:
    ; We set the next frame address to the last current polygon address (of the latest frame)
    lda current_polygon_address
    sta frame_address
    lda current_polygon_address+1
    sta frame_address+1
:

    inc frame_index
    lda frame_index
;    cmp #200+1
;    beq :+
.if(do_frame_measuring)
    END_CLOCK
    CALC_NR_OF_CYCLES
    SHOW_MEASUREMENT_TIMES_256
; FIXME    
; FIXME    
; FIXME    
;    jsr wait_very_long
    stp
.endif

    ; Show the buffer we just wrote to
    lda current_buffer
    bne :+
; FIXME
;    beq :+
    lda #($000 >> 1)
    sta VERA_L0_tilebase
    bra :++
:
    lda #($100 >> 1)
    sta VERA_L0_tilebase
:

;jsr wait_very_long
;stp
;lda frame_index


    jmp next_frame

end_of_video:

    rts


; ===================== Load Palette =================================    

; uses variables:     
;   palette_mask:                .word 0
;   red:                         .byte 0
;   green_and_blue:              .byte 0
;   current_polygon_index:       .byte 0
;   vertex_index_in_polygon:     .byte 0
;   current_color_both_nibbles:  .byte 0
;   current_color_left_nibble:   .byte 0
;   current_color_right_nibble:  .byte 0
;   nr_of_vertices_in_polygon:   .byte 0
;   nr_of_vertices_in_polygon_bytes:   .byte 0

load_palette:

    lda VERA_addr_bank
    pha

    ; Preparing VERA to store palette colors
    ldx #%00010001      ; setting bit 16 of vram address to the highest bit in the tilebase (=1), setting auto-increment value to 1
    stx VERA_addr_bank

    lda #$FA
    sta VERA_addr_high
    lda #0
    sta VERA_addr_low

    lda (frame_address),y
    sta palette_mask
    iny
    lda (frame_address),y
    sta palette_mask+1
    iny
    
    ldx #$FF           ; color-index (we start at 255)
next_color_LO:
    inx
    cpx #8
    beq end_colors_LO  ; when we reach color #8 we have to stop with this mask-byte
    
    rol palette_mask  ; check left-most bit
    bcc :+            ; if carry is not set, we do not load a next color (no color info in palette for that color). We (effectively) store random colors instead
    
    ; -- we have to construct the color

    lda (frame_address),y
    iny
    
    and #07    ; get the red bits
    asl        ; shift one bit to the left (3-bit color to 4-bit color)
    sta red
    
    lda (frame_address),y
    iny
    
    asl        ; shift one bit to the left (3-bit color to 4-bit color)

    sta VERA_data0
    lda red
    sta VERA_data0
    jmp next_color_LO
:
    lda #0
    ; Fixed: we should NOT store into unchanged palette entries! So we LOAD from DATA0 now!
    lda VERA_data0
    lda VERA_data0
    ;sta VERA_data0
    ;sta VERA_data0
    jmp next_color_LO

end_colors_LO:
    dex         ; TODO: we decrement x first to get it to #7 again (since its incremented immediatly)

next_color_HI:
    inx
    cpx #16
    beq end_colors_HI  ; when we reach color #16 we have to stop with this (last) mask-byte
    
    rol palette_mask+1  ; check left-most bit
    bcc :+            ; if carry is not set, we do not load a next color (no color info in palette for that color). We (effectively) store random colors instead
    
    ; -- we have to construct the color

    lda (frame_address),y
    iny
    
    and #07    ; get the red bits
    asl        ; shift one bit to the left (3-bit color to 4-bit color)
    sta red
    
    lda (frame_address),y
    iny
    
    asl        ; shift one bit to the left (3-bit color to 4-bit color)

    sta VERA_data0
    lda red
    sta VERA_data0
    jmp next_color_HI
:
    lda #0
    ; Fixed: we should NOT store into unchanged palette entries! So we LOAD from DATA0 now!
    lda VERA_data0
    lda VERA_data0
    ;sta VERA_data0
    ;sta VERA_data0
    jmp next_color_HI
    
end_colors_HI:

    pla
    sta VERA_addr_bank

    rts


prepare_indexed_draw:

    lda (frame_address),y   ; number of (indexed) vertices
    iny
    asl
    sta nr_of_indexed_vertices_bytes
    lda #0
    rol       ; if there was a carry we put it in a
    sta nr_of_indexed_vertices_bytes+1
    
    ; --- create indexed_coords_address by adding frame_address + y bytes
    sty bytes_so_far
    clc
    lda frame_address
    adc bytes_so_far
    sta indexed_coords_address
    lda frame_address+1
    adc #0
    sta indexed_coords_address+1

    ; FIXME: this is a bit of an ugly solution, but it works (probably better than copying and splitting into two (X and Y) tables
    ; FIXME: we only need this address if we have more than 128 indexed vertices
    ; indexed_coords_address_128 is 256 bytes further than indexed_coords_address
    lda indexed_coords_address
    sta indexed_coords_address_128
    clc
    lda indexed_coords_address+1
    adc #1 ; +256
    sta indexed_coords_address_128+1

    clc
    lda indexed_coords_address
    adc nr_of_indexed_vertices_bytes
    sta current_polygon_address
    lda indexed_coords_address+1
    adc nr_of_indexed_vertices_bytes+1
    sta current_polygon_address+1

    rts
    
prepare_non_indexed_draw:

    ; --- create indexed_coords_address by adding frame_address + y bytes
    sty bytes_so_far
    clc
    lda frame_address
    adc bytes_so_far
    sta current_polygon_address
    lda frame_address+1
    adc #0
    sta current_polygon_address+1
    
    rts
    
    
; ===================== Draw Indexed Frame =======================

draw_indexed_frame:

    lda #0
    sta current_polygon_index
    
next_polygon_in_indexed_frame:

.if(do_polygon_measuring)
    START_CLOCK
.endif

    ldy #0
    lda (current_polygon_address),y  ; two nibbles: color + nr_of_vertices_in_polygon
   
    cmp #$FD
    bcc :+
    jmp end_of_indexed_frame
:
    
    tax       ; keep the orignal (combined) value
    and #$0F  ; only leaving the nr_of_vertices_in_polygon
    sta nr_of_vertices_in_polygon
    
    txa       ; original
    and #$F0  ; only leaving the color (left nibble)
    sta current_color_left_nibble
    tax

    lda left_nibble_to_right_nibble, x
    sta current_color_right_nibble
    lda left_nibble_to_both_nibbles, x
    sta current_color_both_nibbles
    
; FIXME: maybe based on nr_of_vertices_in_polygon jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
; FIXME: maybe based on nr_of_vertices_in_polygon jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
; FIXME: maybe based on nr_of_vertices_in_polygon jump to code (with jump table if needed) that does 3-7 vertices!! (we can hardcode quite a bit)
    
    ; NOTE: we start with 1, since the first byte is the color+nr_of_vertices_in_polygon
    ldy #1
    sty vertex_index_in_polygon
    ldx #0

    ; FIXME: we probably want to copy the polygon data to a fixed place so we can access it using x as index (now we can only use y)
    ;        OR we change the "lda (current_polygon_address), y" into "lda current_polygon_address, x" and patch the address
load_next_vertex_indexed:
    
; FIXME: use this: load_from_current_polygon_address:
    lda (current_polygon_address), y   ; loads the index of the vertex
    
    asl  ; do vertex-index * 2
    bcs :+                          ; if we overflow (carry set) then we must look 128 positions further in the indexed table
    
    tay  ; put the vertex-index * 2 in y
    lda (indexed_coords_address),y
    sta vertices, x
    iny
    lda (indexed_coords_address),y
    sta vertices+1, x
    bra :++
:
    tay  ; put the vertex-index * 2 in y
    lda (indexed_coords_address_128),y
    sta vertices, x
    iny
    lda (indexed_coords_address_128),y
    sta vertices+1, x
: 
    inc vertex_index_in_polygon
    ldy vertex_index_in_polygon
    inx
    inx
    
    cpy nr_of_vertices_in_polygon
    bcc load_next_vertex_indexed
    beq load_next_vertex_indexed

    jsr draw_polygon_fast


    lda current_ram_bank
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it

; FIXME: maybe we could only let x increase, and just before it reaches 255 we increment current_polygon_address?
;        the problem is that the storing in the vertices table(s) will be wrong, so those have to be patched (negating the advantage)
    clc
    lda current_polygon_address
    inc nr_of_vertices_in_polygon ; we add one byte: "the byte with color + nr of vertices in polygon"
    adc nr_of_vertices_in_polygon ; one byte for each vertex-index in the polygon
    sta current_polygon_address
    lda current_polygon_address+1
    adc #0
    sta current_polygon_address+1
    
.if(do_polygon_measuring)
    END_CLOCK
    CALC_NR_OF_CYCLES
    SHOW_MEASUREMENT 
    jsr wait_very_long
    stp
.endif

    jmp next_polygon_in_indexed_frame
    
end_of_indexed_frame:    

    tax                           ; we put the MARK-byte in x
    clc
    lda current_polygon_address
    adc #1   ; the MARKING byte 
    sta current_polygon_address
    lda current_polygon_address+1
    adc #0
    sta current_polygon_address+1

    rts
    


; ===================== Draw Non-Indexed Frame =======================

draw_non_indexed_frame:

    lda #0
    sta current_polygon_index
    
next_polygon_in_non_indexed_frame:

    ldy #0
    lda (current_polygon_address),y  ; two nibbles: color + nr_of_vertices_in_polygon
    
    cmp #$FD
    bcs end_of_non_indexed_frame
    
    tax       ; keep the orignal (combined) value
    and #$0F  ; only leaving the nr_of_vertices_in_polygon
    sta nr_of_vertices_in_polygon
    asl       ; we have to do nr_of_vertices_in_polygon * 2 bytes
    sta nr_of_vertices_in_polygon_bytes
    
    txa       ; original
    and #$F0  ; only leaving the color (left nibble)
    sta current_color_left_nibble
    tax

    lda left_nibble_to_right_nibble, x
    sta current_color_right_nibble
    lda left_nibble_to_both_nibbles, x
    sta current_color_both_nibbles
    
    ; FIXME: use only y here, don't use x
    
    ; NOTE: we start with 1, since the first byte is the color+nr_of_vertices_in_polygon
    ldy #1
    
    ldx #0 ; We start with 0 for the verices array
    
    ; FIXME: we probably want to copy the polygon data to a fixed place so we can access it using x as index (now we can only use y)
    ;        OR we change the "lda (current_polygon_address), y" into "lda current_polygon_address, x" and patch the address
load_next_vertex_non_indexed:
    
    lda (current_polygon_address), y   ; loads the x-coord
    iny
    sta vertices, x
    
    lda (current_polygon_address), y   ; loads the y-coord
    iny
    sta vertices+1, x ; TODO: we dont have to do +1 here, we can simply increase x
    inx
    inx
    
    cpy nr_of_vertices_in_polygon_bytes
    bcc load_next_vertex_non_indexed
    beq load_next_vertex_non_indexed
    
    jsr draw_polygon_fast
    
    lda current_ram_bank
    sta RAM_BANK  ; We reload the ram bank because the divide_fast (inside draw_polygon) changes it
    
    clc
    lda current_polygon_address
    inc nr_of_vertices_in_polygon_bytes ; we add one byte: "the byte with color + nr of vertices in polygon"
    adc nr_of_vertices_in_polygon_bytes ; one byte for each vertex-index in the polygon
    sta current_polygon_address
    lda current_polygon_address+1
    adc #0
    sta current_polygon_address+1
    
    jmp next_polygon_in_non_indexed_frame
    
end_of_non_indexed_frame:    

    tax                           ; we put the MARK-byte in x
    clc
    lda current_polygon_address
    adc #1   ; the MARKING byte 
    sta current_polygon_address
    lda current_polygon_address+1
    adc #0
    sta current_polygon_address+1

    rts
  

; ====================== LOAD SCENE FILE ==============================


scene_file_number:   .byte 0
scene_filename:      .byte    "scene/00.bin"
end_scene_filename:

; https://gist.github.com/JimmyDansbo/f955378ee4f1087c2c286fcd6956e223
; https://www.commanderx16.com/forum/index.php?/topic/80-loading-a-file-into-vram-assembly/
load_scene_file:


    lda scene_file_number
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

    lda scene_file_number
    and #$0F
    
    cmp #$0A
    bcs :+
    
    clc
    adc #48-0  ; = '0'
    sta scene_filename+7
    bra :++
:
    clc
    adc #65-10  ; = 'a'
    sta scene_filename+7
:

    lda scene_file_number
    lsr
    lsr
    lsr
    lsr
    and #$0F
    
    cmp #$0A
    bcs :+
    
    clc
    adc #48-0  ; = '0'
    sta scene_filename+6
    bra :++
:
    clc
    adc #65-10  ; = 'a'
    sta scene_filename+6
:

    rts

