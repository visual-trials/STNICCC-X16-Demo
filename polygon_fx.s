

draw_polygon_fx:

    lda #$FF
    sta MIN_Y

    stz MAX_Y

    ; We start at vertex index 0
    stz CURRENT_VERTEX_INDEX
    
next_vertex_pair:


    ; ----- Load x and y of vertex pair -----

    ldy CURRENT_VERTEX_INDEX

    lda VERTICES_X, y            ; start x-coordinate
    sta X1
    lda VERTICES_Y, y            ; start y-coordinate
    sta Y1
    
    cmp MIN_Y
    bcs min_y_updated_1  ; if y1 < min_y then store it
    sta MIN_Y    
min_y_updated_1:

    ; TODO: dont store if equal
    cmp MAX_Y
    bcc max_y_updated_1  ; if y1 <= max_y then store it
    sta MAX_Y    
max_y_updated_1:

    iny
    sty CURRENT_VERTEX_INDEX
    cpy NR_OF_VERTICES_IN_POLYGON
    bne vertex_index_ok                      ; if we havent reach the last vertex yet, we do not have to "wrap around"
    ldy #0
vertex_index_ok:

    lda VERTICES_X, y            ; end x-coordinate
    sta X2
    lda VERTICES_Y, y            ; end y-coordinate
    sta Y2


; FIXME! IMPLEMENT!
; FIXME! IMPLEMENT!
; FIXME! IMPLEMENT!
; FIXME! IMPLEMENT!
    stp
    lda X1
    lda Y1
    lda X2
    lda Y2



done_with_vertex_pair:

    ldy CURRENT_VERTEX_INDEX
    cpy NR_OF_VERTICES_IN_POLYGON
    beq done_with_all_vertex_pairs
    jmp next_vertex_pair                      ; if we havent reach the last vertex yet, we do the next pair
    
done_with_all_vertex_pairs:



    rts