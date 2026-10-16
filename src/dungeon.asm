; =====================================================================
;  Generazione dei livelli: griglia 4x3 di celle 16x10, una stanza (o un
;  incrocio di corridoi) per cella, corridoi a L tra celle adiacenti.
; =====================================================================

; azzera 8 pagine a partire da A (hi)
!zone clear8
clear8:
    sta ptr0+1
    lda #0
    sta ptr0
    ldx #8
    ldy #0
-   sta (ptr0),y
    iny
    bne -
    inc ptr0+1
    dex
    bne -
    rts

!zone gen_level
gen_level:
    lda #>MAP
    jsr clear8
    lda #>MONAT
    jsr clear8
    lda #>ITEMAT
    jsr clear8
    ldx #MAXMON-1
    lda #0
-   sta m_flags,x
    dex
    bpl -
    ldx #MAXITEM-1
-   sta i_cls,x
    dex
    bpl -
    ; ---- stanze
    lda #0
    sta gk                  ; indice cella
.cell:
    lda gk
    and #3
    asl
    asl
    asl
    asl
    sta gx                  ; cella x
    lda gk
    lsr
    lsr
    tax
    lda cell_y,x
    sta gy                  ; cella y
    ldx gk
    txa
    beq .room               ; gli angoli sono sempre stanze
    cmp #11
    beq .room
    lda #20
    jsr rnd_n
    cmp #3
    bcs .room
    ; incrocio di corridoi
    lda #1
    sta r_kind,x
    sta r_w,x
    sta r_h,x
    lda #12
    jsr rnd_n
    clc
    adc #2
    adc gx
    sta r_x,x
    lda #6
    jsr rnd_n
    clc
    adc #2
    adc gy
    sta r_y,x
    lda r_y,x
    jsr row_ptrs
    ldy r_x,x
    lda #TR_CORR
    sta (pm),y
    jmp .nextcell
.room:
    lda #0
    sta r_kind,x
    lda #10
    jsr rnd_n
    clc
    adc #5
    sta r_w,x               ; 5..14
    lda #5
    jsr rnd_n
    clc
    adc #4
    sta r_h,x               ; 4..8
    lda #15
    sec
    sbc r_w,x               ; 14-w+1
    jsr rnd_n
    clc
    adc gx
    adc #1
    sta r_x,x
    lda #9
    sec
    sbc r_h,x
    jsr rnd_n
    clc
    adc gy
    adc #1
    sta r_y,x
    jsr draw_room
.nextcell:
    inc gk
    lda gk
    cmp #MAXROOM
    beq +
    jmp .cell
+    ; ---- corridoi orizzontali
    lda #0
    sta gk
-   lda gk
    and #3
    cmp #3
    beq +
    ldx gk
    jsr hconnect
+   inc gk
    lda gk
    cmp #MAXROOM
    bne -
    ; ---- corridoi verticali: una colonna garantita per fila
    lda #0
    sta cnt_a
.vrow:
    lda #4
    jsr rnd_n
    sta cnt_b               ; colonna garantita
    lda #0
    sta gk
-   lda gk
    cmp cnt_b
    beq .doit
    lda #100
    jsr rnd_n
    cmp #35
    bcs .skip
.doit:
    lda cnt_a
    asl
    asl
    ora gk
    tax
    jsr vconnect
.skip:
    inc gk
    lda gk
    cmp #4
    bne -
    inc cnt_a
    lda cnt_a
    cmp #2
    bne .vrow
    ; ---- inizio e scale
    jsr pick_room
    sta start_room
    ; stanza delle scale: la più lontana dall'inizio (in celle)
    lda #0
    sta gi                  ; distanza migliore
    lda #$ff
    sta stair_room
    ldx #0
.far:
    lda r_kind,x
    bne .farn
    cpx start_room
    beq .farn
    jsr cell_dist
    cmp gi
    bcc .farn
    sta gi
    stx stair_room
.farn:
    inx
    cpx #MAXROOM
    bne .far
    lda stair_room
    bpl +
    lda start_room
    sta stair_room
+   ; giocatore
    lda start_room
    jsr room_point
    lda gx
    sta p_x
    lda gy
    sta p_y
    ; scale o amuleto
    lda stair_room
    jsr room_point_free
    lda p_depth
    cmp #MAXDEPTH
    beq .amulet
    lda gy
    jsr row_ptrs
    ldy gx
    lda #TR_STAIRS
    sta (pm),y
    jmp .items
.amulet:
    lda #IC_AMULET
    sta gi
    lda #0
    sta gj
    sta gk
    jsr place_item
    ; drago accanto all'amuleto
    lda gx
    sta tmpw
    lda gy
    sta tmpw+1
    lda #9
    jsr spawn_near
.items:
    ; ---- oggetti
    lda #4
    jsr rnd_n
    clc
    adc #5
    sta cnt_a
-   jsr pick_room
    jsr room_point_free
    jsr random_item
    jsr place_item
    dec cnt_a
    bne -
    ; ---- mostri
    lda p_depth
    lsr
    clc
    adc #3
    sta cnt_a
    lda #3
    jsr rnd_n
    clc
    adc cnt_a
    sta cnt_a
-   jsr pick_room
    cmp start_room
    beq -
    jsr room_point_free
    jsr random_montype
    jsr spawn_monster
    dec cnt_a
    bne -
    lda #0
    sta spawn_ctr
    jmp fov_update

cell_y: !byte 1, 11, 21

; A = indice di una stanza vera a caso
!zone pick_room
pick_room:
-   lda #MAXROOM
    jsr rnd_n
    tax
    lda r_kind,x
    bne -
    txa
    rts

; X = stanza -> A = distanza in celle da start_room
!zone cell_dist
cell_dist:
    txa
    and #3
    sta tmp0
    lda start_room
    and #3
    sec
    sbc tmp0
    jsr abs
    sta tmp1
    txa
    lsr
    lsr
    sta tmp0
    lda start_room
    lsr
    lsr
    sec
    sbc tmp0
    jsr abs
    clc
    adc tmp1
    rts

; A = stanza -> gx, gy punto interno a caso
!zone room_point
room_point:
    tax
    lda r_w,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_x,x
    adc #1
    sta gx
    lda r_h,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_y,x
    adc #1
    sta gy
    rts

; come room_point ma libero (pavimento, niente mostri/oggetti/giocatore)
!zone room_point_free
room_point_free:
    sta tmp3
    lda #40
    sta tmp4
-   lda tmp3
    jsr room_point
    jsr cell_free
    bcs +
    dec tmp4
    bne -
+   rts

; gx,gy liberi? C=1 sì
!zone cell_free
cell_free:
    lda gy
    jsr row_ptrs
    ldy gx
    lda (pm),y
    and #$0f
    cmp #TR_FLOOR
    bne .no
    lda (pmo),y
    bne .no
    lda (pit),y
    bne .no
    lda gx
    cmp p_x
    bne .yes
    lda gy
    cmp p_y
    beq .no
.yes:
    sec
    rts
.no:
    clc
    rts

; stanza X: muri e pavimento
!zone draw_room
draw_room:
    lda r_y,x
    sta tmp0                ; y
    lda r_h,x
    sta tmp1                ; righe rimaste
.row:
    lda tmp0
    jsr row_ptrs
    ldy r_x,x
    lda r_w,x
    sta tmp2
    ; muro se prima/ultima riga
    lda tmp0
    cmp r_y,x
    beq .wallrow
    lda tmp1
    cmp #1
    beq .wallrow
    lda #TR_WALL
    sta (pm),y
    iny
    dec tmp2
-   lda tmp2
    cmp #1
    beq +
    lda #TR_FLOOR
    sta (pm),y
    iny
    dec tmp2
    jmp -
+   lda #TR_WALL
    sta (pm),y
    jmp .nrow
.wallrow:
    lda #TR_WALL
-   sta (pm),y
    iny
    dec tmp2
    bne -
.nrow:
    inc tmp0
    dec tmp1
    bne .row
    rts

; porta in gx,gy (chiusa 1 volta su 4)
!zone set_door
set_door:
    lda gy
    jsr row_ptrs
    ldy gx
    lda #4
    jsr rnd_n
    beq +
    lda #TR_DOORO
    sta (pm),y
    rts
+   lda #TR_DOORC
    sta (pm),y
    rts

; scava corridoio su roccia in gx,gy
!zone carve
carve:
    lda gy
    jsr row_ptrs
    ldy gx
    lda (pm),y
    bne +
    lda #TR_CORR
    sta (pm),y
+   rts

; orizzontale da tmp0 a tmp1 sulla riga gy
!zone carve_h
carve_h:
    lda tmp0
    cmp tmp1
    bcc +
    ldx tmp1
    sta tmp1
    stx tmp0
+   lda tmp0
    sta gx
-   jsr carve
    lda gx
    cmp tmp1
    beq +
    inc gx
    jmp -
+   rts

; verticale da tmp0 a tmp1 sulla colonna gx
!zone carve_v
carve_v:
    lda tmp0
    cmp tmp1
    bcc +
    ldx tmp1
    sta tmp1
    stx tmp0
+   lda tmp0
    sta gy
-   jsr carve
    lda gy
    cmp tmp1
    beq +
    inc gy
    jmp -
+   rts

; collega la cella X con quella a destra (X+1)
; usa: ya=tmp4 xs=tmp5 yb=tmp6 xe=tmp7
!zone hconnect
hconnect:
    stx gi
    lda r_kind,x
    bne .aj
    lda r_h,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_y,x
    adc #1
    sta tmp4
    lda r_x,x
    clc
    adc r_w,x
    sec
    sbc #1
    sta gx
    lda tmp4
    sta gy
    jsr set_door
    ldx gi
    lda gx
    clc
    adc #1
    sta tmp5
    jmp .b
.aj:
    lda r_y,x
    sta tmp4
    lda r_x,x
    sta tmp5
.b:
    inx
    lda r_kind,x
    bne .bj
    lda r_h,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_y,x
    adc #1
    sta tmp6
    lda r_x,x
    sta gx
    lda tmp6
    sta gy
    jsr set_door
    lda gx
    sec
    sbc #1
    sta tmp7
    jmp .carve
.bj:
    lda r_y,x
    sta tmp6
    lda r_x,x
    sta tmp7
.carve:
    ; xm = xs + rnd(xe-xs+1)
    lda tmp7
    sec
    sbc tmp5
    clc
    adc #1
    jsr rnd_n
    clc
    adc tmp5
    sta gj                  ; xm
    lda tmp4
    sta gy
    lda tmp5
    sta tmp0
    lda gj
    sta tmp1
    lda tmp6                ; salva yb (carve_h usa tmp0/tmp1)
    pha
    lda tmp7
    pha
    lda tmp4
    pha
    jsr carve_h
    pla
    sta tmp0                ; ya
    pla
    sta tmp7
    pla
    sta tmp6
    sta tmp1                ; yb
    lda gj
    sta gx
    lda tmp6
    pha
    lda tmp7
    pha
    jsr carve_v
    pla
    sta tmp1                ; xe
    pla
    sta gy                  ; yb
    lda gj
    sta tmp0
    jsr carve_h
    ldx gi
    rts

; collega la cella X con quella sotto (X+4)
!zone vconnect
vconnect:
    stx gi
    lda r_kind,x
    bne .aj
    lda r_w,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_x,x
    adc #1
    sta tmp4                ; xa
    lda r_y,x
    clc
    adc r_h,x
    sec
    sbc #1
    sta gy
    lda tmp4
    sta gx
    jsr set_door
    ldx gi
    lda gy
    clc
    adc #1
    sta tmp5                ; ys
    jmp .b
.aj:
    lda r_x,x
    sta tmp4
    lda r_y,x
    sta tmp5
.b:
    txa
    clc
    adc #4
    tax
    lda r_kind,x
    bne .bj
    lda r_w,x
    sec
    sbc #2
    jsr rnd_n
    clc
    adc r_x,x
    adc #1
    sta tmp6                ; xb
    lda r_y,x
    sta gy
    lda tmp6
    sta gx
    jsr set_door
    lda gy
    sec
    sbc #1
    sta tmp7                ; ye
    jmp .carve
.bj:
    lda r_x,x
    sta tmp6
    lda r_y,x
    sta tmp7
.carve:
    lda tmp7
    sec
    sbc tmp5
    clc
    adc #1
    jsr rnd_n
    clc
    adc tmp5
    sta gj                  ; ym
    ; verticale xa: ys -> ym
    lda tmp4
    sta gx
    lda tmp5
    sta tmp0
    lda gj
    sta tmp1
    lda tmp6
    pha
    lda tmp7
    pha
    lda tmp4
    pha
    jsr carve_v
    ; orizzontale ym: xa -> xb
    pla
    sta tmp0                ; xa
    pla
    sta tmp7
    pla
    sta tmp6
    sta tmp1                ; xb
    lda gj
    sta gy
    lda tmp6
    pha
    lda tmp7
    pha
    jsr carve_h
    ; verticale xb: ym -> ye
    pla
    sta tmp1                ; ye
    pla
    sta gx                  ; xb
    lda gj
    sta tmp0
    jsr carve_v
    ldx gi
    rts

; ---------------------------------------------------------------- FOV
; stanza del giocatore + area 3x3 diventano esplorate
!zone fov_update
fov_update:
    jsr find_room
    sta p_room
    tax
    bmi .nb
    lda r_y,x
    sta tmp0
    lda r_h,x
    sta tmp1
-   lda tmp0
    jsr row_ptrs
    ldy r_x,x
    lda r_w,x
    sta tmp2
--  lda (pm),y
    ora #EXPLORED
    sta (pm),y
    iny
    dec tmp2
    bne --
    inc tmp0
    dec tmp1
    bne -
.nb:
    lda p_y
    sec
    sbc #1
    sta tmp0
    lda #3
    sta tmp1
-   lda tmp0
    jsr row_ptrs
    ldy p_x
    dey
    ldx #3
--  lda (pm),y
    ora #EXPLORED
    sta (pm),y
    iny
    dex
    bne --
    inc tmp0
    dec tmp1
    bne -
    lda #1
    sta dirty
    rts

; A = stanza (vera) che contiene il giocatore, $FF se nessuna
!zone find_room
find_room:
    ldx #0
-   lda r_kind,x
    bne .n
    lda p_x
    cmp r_x,x
    bcc .n
    lda r_x,x
    clc
    adc r_w,x
    sta tmp0
    lda p_x
    cmp tmp0
    bcs .n
    lda p_y
    cmp r_y,x
    bcc .n
    lda r_y,x
    clc
    adc r_h,x
    sta tmp0
    lda p_y
    cmp tmp0
    bcs .n
    txa
    rts
.n: inx
    cpx #MAXROOM
    bne -
    lda #$ff
    rts

; rivela tutta la mappa (pergamena)
!zone reveal_map
reveal_map:
    lda #0
    sta tmp0
-   lda tmp0
    jsr row_ptrs
    ldy #MAPW-1
--  lda (pm),y
    and #$0f
    beq +
    lda (pm),y
    ora #EXPLORED
    sta (pm),y
+   dey
    bpl --
    inc tmp0
    lda tmp0
    cmp #MAPH
    bne -
    lda #1
    sta dirty
    rts
