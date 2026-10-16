; =====================================================================
;  Video lato programma: disegno del back buffer, sincronizzazione con
;  lo scroll, pagine di testo, riga di stato e messaggi, effetti sprite
; =====================================================================

!zone wait_frame
wait_frame:
    lda frame
-   cmp frame
    beq -
    rts

!zone wait_back_free
wait_back_free:
-   lda back_ready
    bne -
    rts

; A = byte alto del back buffer
!zone get_back_hi
get_back_hi:
    lda front_sel
    beq +
    lda #>SCR_A
    rts
+   lda #>SCR_B
    rts

; ---------------------------------------------------------------- render
; disegna la vista con origine a caratteri (rv_cx, rv_cy) nel back buffer
!zone render_view
render_view:
    lda rv_cx
    and #1
    sta rv_sub
    lda rv_cx
    clc
    adc #32
    lsr
    sec
    sbc #32
    sta rv_tx0
    lda rv_cy
    clc
    adc #32
    lsr
    sec
    sbc #32
    sta rv_ty
    jsr get_back_hi
    sta rv_scr+1
    lda #120
    sta rv_scr
    lda #<COLBUF
    sta rv_col
    lda #>COLBUF
    sta rv_col+1
    lda #0
    sta rv_row
    lda rv_cy
    and #1
    beq .loop
    jsr render_tilerow
    lda #1
    jsr copy_half
    inc rv_ty
.loop:
    lda rv_row
    cmp #22
    bcs .done
    jsr render_tilerow
    lda #0
    jsr copy_half
    lda rv_row
    cmp #22
    bcs .done
    lda #1
    jsr copy_half
    inc rv_ty
    jmp .loop
.done:
    lda rv_cx
    sta back_cx
    lda rv_cy
    sta back_cy
    rts

; A = 0 metà alta, 1 metà bassa -> riga rv_row
!zone copy_half
copy_half:
    ldx rv_sub
    ldy #0
    cmp #0
    bne .h1
.h0:
    lda LC0,x
    sta (rv_scr),y
    lda LCOL,x
    sta (rv_col),y
    inx
    iny
    cpy #40
    bne .h0
    beq .adv
.h1:
    lda LC1,x
    sta (rv_scr),y
    lda LCOL,x
    sta (rv_col),y
    inx
    iny
    cpy #40
    bne .h1
.adv:
    clc
    lda rv_scr
    adc #40
    sta rv_scr
    bcc +
    inc rv_scr+1
+   clc
    lda rv_col
    adc #40
    sta rv_col
    bcc +
    inc rv_col+1
+   inc rv_row
    rts

; A = riga tile -> pm, pmo, pit
!zone row_ptrs
row_ptrs:
    pha
    asl
    asl
    asl
    asl
    asl
    asl
    sta pm
    sta pmo
    sta pit
    pla
    lsr
    lsr
    clc
    adc #>MAP
    sta pm+1
    adc #8
    sta pmo+1
    adc #8
    sta pit+1
    rts

; riempie LC0/LC1/LCOL per la riga di tile rv_ty
!zone render_tilerow
render_tilerow:
    lda rv_ty
    cmp #MAPH
    bcc .valid
    ldx #41
    lda #0
-   sta LC0,x
    sta LC1,x
    sta LCOL,x
    dex
    bpl -
    rts
.valid:
    jsr vis_interval
    lda rv_ty
    jsr row_ptrs
    lda rv_tx0
    sta rv_tx
    ldx #0
.tile:
    ldy rv_tx
    cpy #MAPW
    bcs .blank0
    lda (pm),y
    bmi +
.blank0:
    jmp .blank
+
    cpy rv_vlo
    bcc .remem
    cpy rv_vhi
    beq .vis
    bcs .remem
.vis:
    lda (pmo),y
    beq .vitem
    tay
    lda m_type-1,y
    tay
    lda mt_tile,y
    sta tmp1
    tay
    lda tile_color,y
    sta tmp2
    jmp .emit
.vitem:
    lda (pit),y
    beq .vterr
    tay
    lda i_tile-1,y
    sta tmp1
    lda i_col-1,y
    sta tmp2
    jmp .emit
.vterr:
    jsr terrain_tile
    bcs .blank
    sta tmp1
    tay
    lda tile_color,y
    sta tmp2
    jmp .emit
.remem:
    lda (pit),y
    beq .rterr
    tay
    lda i_tile-1,y
    sta tmp1
    lda #6
    sta tmp2
    jmp .emit
.rterr:
    jsr terrain_tile
    bcs .blank
    sta tmp1
    lda #6
    sta tmp2
.emit:
    ldy tmp1
    lda tile_char,y
    sta LC0,x
    clc
    adc #1
    sta LC0+1,x
    adc #1
    sta LC1,x
    adc #1
    sta LC1+1,x
    lda tmp2
    sta LCOL,x
    sta LCOL+1,x
.next:
    inx
    inx
    inc rv_tx
    cpx #42
    beq +
    jmp .tile
+    rts
.blank:
    lda #0
    sta LC0,x
    sta LC0+1,x
    sta LC1,x
    sta LC1+1,x
    sta LCOL,x
    sta LCOL+1,x
    jmp .next

; Y = tx, rv_ty = ty, (pm) riga -> A = tile, C=1 se vuoto (roccia)
!zone terrain_tile
terrain_tile:
    lda (pm),y
    and #$0f
    beq .rock
    cmp #TR_WALL
    bne +
    tya
    eor rv_ty
    and #3
    bne .w1
    lda #T_WALL2
    clc
    rts
.w1:
    lda #T_WALL1
    clc
    rts
+   cmp #TR_FLOOR
    bne +
    tya
    adc rv_ty               ; C=1 qui (cmp uguale): non importa
    and #7
    bne .f1
    lda #T_FLOOR2
    clc
    rts
.f1:
    lda #T_FLOOR
    clc
    rts
+   tay
    lda terr_tile,y
    ldy rv_tx
    clc
    rts
.rock:
    sec
    rts
!zone terr_tile
terr_tile:
    !byte 0, T_WALL1, T_FLOOR, T_CORR, T_DOORC, T_DOORO, T_STAIRS

; intervallo di tile visibili (rv_vlo..rv_vhi) sulla riga rv_ty
!zone vis_interval
vis_interval:
    lda #$ff
    sta rv_vlo
    lda #0
    sta rv_vhi
    ldx p_room
    bmi .nb
    lda rv_ty
    cmp r_y,x
    bcc .nb
    lda r_y,x
    clc
    adc r_h,x
    sta tmp0
    lda rv_ty
    cmp tmp0
    bcs .nb
    lda r_x,x
    sta rv_vlo
    clc
    adc r_w,x
    sec
    sbc #1
    sta rv_vhi
.nb:
    lda rv_ty
    sec
    sbc p_y
    clc
    adc #1
    cmp #3
    bcs .done
    lda p_x
    sec
    sbc #1
    cmp rv_vlo
    bcs +
    sta rv_vlo
+   lda p_x
    clc
    adc #1
    cmp rv_vhi
    bcc .done
    sta rv_vhi
.done:
    rts

; gx, gy visibili dal giocatore? C=1 sì
!zone tile_visible
tile_visible:
    lda gy
    sta rv_ty
    jsr vis_interval
    lda gx
    cmp rv_vlo
    bcc .no
    lda rv_vhi
    cmp gx
    bcc .no
    sec
    rts
.no:
    clc
    rts

; ---------------------------------------------------------------- camera
!zone set_cam_target
set_cam_target:
    ; tgtx = 16*p_x + 116 ; tgty = 16*p_y + 180
    lda #0
    sta tmpw+1
    lda p_x
    asl
    rol tmpw+1
    asl
    rol tmpw+1
    asl
    rol tmpw+1
    asl
    rol tmpw+1
    clc
    adc #116
    sta tmpw
    bcc +
    inc tmpw+1
+   lda #0
    sta tmp1
    lda p_y
    asl
    rol tmp1
    asl
    rol tmp1
    asl
    rol tmp1
    asl
    rol tmp1
    clc
    adc #180
    sta tmp0
    bcc +
    inc tmp1
+   sei
    lda tmpw
    sta tgtx
    lda tmpw+1
    sta tgtx+1
    lda tmp0
    sta tgty
    lda tmp1
    sta tgty+1
    cli
    rts

; salto istantaneo della camera sul giocatore (nuovo piano, teletrasporto)
!zone camera_jump
camera_jump:
    jsr wait_back_free
    lda #1
    sta jump_req
    jsr set_cam_target
    ldx #0
-   lda tgtx,x
    sta sx_lo,x
    inx
    cpx #4
    bne -
    jsr coarse_s
    jsr render_view
    lda #0
    sta dirty
    lda #1
    sta back_ready
-   lda jump_req
    bne -
    jsr wait_back_free
    rts

; sx/sy -> rv_cx/rv_cy (posizione grossa)
!zone coarse_s
coarse_s:
    lda sx_hi
    sta tmp0
    lda sx_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    sta rv_cx
    lda sy_hi
    sta tmp0
    lda sy_lo
    lsr tmp0
    ror
    lsr tmp0
    ror
    lsr tmp0
    ror
    sta rv_cy
    rts

; passo di simulazione (come l'IRQ) su sx/sy, X = 0 o 2
!zone main_step
main_step:
    sec
    lda tgtx,x
    sbc sx_lo,x
    sta tmp0
    lda tgtx+1,x
    sbc sx_hi,x
    bmi .neg
    bne .pos2
    lda tmp0
    beq .tgt
    cmp #2
    bcs .pos2
.tgt:
    lda tgtx,x
    sta sx_lo,x
    lda tgtx+1,x
    sta sx_hi,x
    rts
.pos2:
    clc
    lda sx_lo,x
    adc #2
    sta sx_lo,x
    lda sx_hi,x
    adc #0
    sta sx_hi,x
    rts
.neg:
    cmp #$ff
    bne .neg2
    lda tmp0
    cmp #$fe
    bcs .tgt
.neg2:
    sec
    lda sx_lo,x
    sbc #2
    sta sx_lo,x
    lda sx_hi,x
    sbc #0
    sta sx_hi,x
    rts

; porta lo schermo allo stato attuale: completa lo scroll della camera
; disegnando in anticipo ogni nuova posizione grossa
!zone view_sync
view_sync:
.loop:
    jsr wait_back_free
    jsr wait_frame
    ldx #3
-   lda camx,x
    sta sx_lo,x
    dex
    bpl -
    ldx #3
-   lda sx_lo,x
    cmp tgtx,x
    bne .moving
    dex
    bpl -
    ; camera ferma
    lda dirty
    beq .done
    lda front_cx
    sta rv_cx
    lda front_cy
    sta rv_cy
.render:
    lda #0
    sta dirty
    jsr render_view
    lda #1
    sta back_ready
    jmp .loop
.done:
    rts
.moving:
    lda #12
    sta sim_cnt
.sim:
    ldx #0
    jsr main_step
    ldx #2
    jsr main_step
    jsr coarse_s
    lda rv_cx
    cmp front_cx
    bne .render
    lda rv_cy
    cmp front_cy
    bne .render
    ldx #3
-   lda sx_lo,x
    cmp tgtx,x
    bne +
    dex
    bpl -
    jmp .arrive
+   dec sim_cnt
    bne .sim
.arrive:
    lda dirty
    beq .loop
    lda front_cx
    sta rv_cx
    lda front_cy
    sta rv_cy
    jmp .render

; ---------------------------------------------------------------- pagine
; righe del back buffer: base + 120 + 40*r
!zone page_begin
page_begin:
    jsr wait_back_free
    jsr get_back_hi
    sta ptr0+1
    lda #120
    sta ptr0
    lda #<COLBUF
    sta ptr1
    lda #>COLBUF
    sta ptr1+1
    ldx #4
    ldy #0
    tya
-   sta (ptr0),y
    sta (ptr1),y
    iny
    bne -
    inc ptr0+1
    inc ptr1+1
    dex
    bne -
    rts

; ptr0 = indirizzo back buffer riga A col X, ptr1 = COLBUF corrispondente
!zone page_addr
page_addr:
    tay
    txa
    clc
    adc row40_lo,y
    sta ptr1
    lda row40_hi,y
    adc #0
    sta ptr1+1
    clc
    lda ptr1
    adc #120
    sta ptr0
    lda ptr1+1
    adc #0
    sta ptr0+1
    jsr get_back_hi
    clc
    adc ptr0+1
    sta ptr0+1
    clc
    lda ptr1
    adc #<COLBUF
    sta ptr1
    lda ptr1+1
    adc #>COLBUF
    sta ptr1+1
    rts

; disegna una pagina (str_ptr): blocchi col,riga,colore,lung,testo ... $FF
!zone page_draw
page_draw:
    ldy #0
    lda (str_ptr),y
    cmp #$ff
    beq .end
    tax
    iny
    lda (str_ptr),y
    sta tmp4
    iny
    lda (str_ptr),y
    sta tmp5
    iny
    lda (str_ptr),y
    sta tmp6
    lda tmp4
    jsr page_addr
    clc
    lda str_ptr
    adc #4
    sta str_ptr
    bcc +
    inc str_ptr+1
+   ldy #0
-   cpy tmp6
    beq +
    lda (str_ptr),y
    sta (ptr0),y
    lda tmp5
    sta (ptr1),y
    iny
    bne -
+   tya
    clc
    adc str_ptr
    sta str_ptr
    bcc page_draw
    inc str_ptr+1
    jmp page_draw
.end:
    rts

; msgbuf (msg_len) -> pagina in colonna X, riga A, colore tmp5
!zone page_msg
page_msg:
    jsr page_addr
    ldy #0
-   cpy msg_len
    beq +
    lda msgbuf,y
    sta (ptr0),y
    lda tmp5
    sta (ptr1),y
    iny
    bne -
+   rts

; tile (tmp4) nella pagina in colonna X, riga A
!zone page_tile
page_tile:
    sta tmp6
    stx tmp7
    jsr page_addr
    ldy tmp4
    lda tile_char,y
    ldy #0
    sta (ptr0),y
    clc
    adc #1
    iny
    sta (ptr0),y
    adc #1
    ldy #40
    sta (ptr0),y
    adc #1
    iny
    sta (ptr0),y
    ldy tmp4
    lda tile_color,y
    ldy #0
    sta (ptr1),y
    iny
    sta (ptr1),y
    ldy #40
    sta (ptr1),y
    iny
    sta (ptr1),y
    rts

!zone page_show
page_show:
    lda front_cx
    sta back_cx
    lda front_cy
    sta back_cy
    lda #1
    sta back_ready
    jsr wait_back_free
    rts

; ---------------------------------------------------------------- messaggi
!zone msg_clear
msg_clear:
    lda #0
    sta msg_len
    rts

; A = carattere
!zone msg_char
msg_char:
    ldx msg_len
    cpx #40
    bcs +
    sta msgbuf,x
    inc msg_len
+   rts

; str_ptr = stringa terminata da 0
!zone msg_str
msg_str:
    ldy #0
-   lda (str_ptr),y
    beq +
    sty tmp7
    jsr msg_char
    ldy tmp7
    iny
    bne -
+   rts

; macro: aggiunge stringa
!macro msg .s {
    lda #<.s
    sta str_ptr
    lda #>.s
    sta str_ptr+1
    jsr msg_str
}

; num_lo/num_hi in decimale senza zeri iniziali
!zone msg_num
msg_num:
    ldx #0
.dig:
    ldy #$2f
-   iny
    sec
    lda num_lo
    sbc dec_lo,x
    sta tmp0
    lda num_hi
    sbc dec_hi,x
    bcc +
    sta num_hi
    lda tmp0
    sta num_lo
    jmp -
+   tya
    sta num_digits,x
    inx
    cpx #4
    bne .dig
    lda num_lo
    ora #$30
    sta num_digits+4
    ; salta gli zeri iniziali
    ldx #0
.skip:
    lda num_digits,x
    cmp #$30
    bne .out
    inx
    cpx #4
    bne .skip
.out:
    lda num_digits,x
    stx tmp6
    jsr msg_char
    ldx tmp6
    inx
    cpx #5
    bne .out
    rts
dec_lo: !byte <10000, <1000, <100, <10
dec_hi: !byte >10000, >1000, >100, >10

; A = numero 0..255
!zone msg_byte
msg_byte:
    sta num_lo
    lda #0
    sta num_hi
    jmp msg_num

; scorre il registro messaggi: riga 1 -> riga 0, msgbuf -> riga 1
!zone msg_flush
msg_flush:
    ldx #39
-   lda SCR_STATUS+40,x
    sta SCR_STATUS,x
    lda COLRAM+40,x
    sta COLRAM,x
    dex
    bpl -
    ldx #0
-   cpx msg_len
    bcs +
    lda msgbuf,x
    bne ++
+   lda #$20
++  sta SCR_STATUS+40,x
    lda #1
    sta COLRAM+40,x
    inx
    cpx #40
    bne -
    lda #0
    sta msg_len
    rts

; ingrigisce i messaggi vecchi (nuovo turno)
!zone msg_age
msg_age:
    ldx #79
    lda #11
-   sta COLRAM,x
    dex
    bpl -
    rts

!zone msg_clear_log
msg_clear_log:
    ldx #119
-   lda #$20
    sta SCR_STATUS,x
    lda #11
    sta COLRAM,x
    dex
    bpl -
    rts

; stringa (str_ptr) diretta nella riga di stato A=riga, X=colonna, colore tmp5
!zone status_text
status_text:
    stx tmp6
    tay
    lda row40_lo,y
    clc
    adc tmp6
    sta ptr0
    sta ptr1
    lda #>SCR_STATUS
    sta ptr0+1
    lda #>COLRAM
    sta ptr1+1
    ldy #0
-   lda (str_ptr),y
    beq +
    sta (ptr0),y
    lda tmp5
    sta (ptr1),y
    iny
    bne -
+   rts

; ---------------------------------------------------------------- effetti
; gx, gy -> fx_x/fx_xh/fx_y; fx_ok = 0 se fuori dalla zona sprite
!zone fx_pos
fx_pos:
    lda #1
    sta fx_ok
    lda gx
    sec
    sbc p_x                 ; dx con segno
    sta tmp0
    lda #0
    sta tmp1
    lda tmp0
    bpl +
    lda #$ff
    sta tmp1
    lda tmp0
+   asl
    rol tmp1
    asl
    rol tmp1
    asl
    rol tmp1
    asl
    rol tmp1
    clc
    adc #HERO_SX
    sta fx_x
    lda tmp1
    adc #0
    sta fx_xh
    lda gy
    sec
    sbc p_y
    asl
    asl
    asl
    asl
    clc
    adc #HERO_SY
    sta fx_y
    cmp #98
    bcs +
    lda #0
    sta fx_ok
+   cmp #236
    bcc +
    lda #0
    sta fx_ok
+   rts

; X = sprite: posiziona da fx_x/fx_xh/fx_y
!zone fx_place
fx_place:
    lda fx_x
    sta spr_xl,x
    lda fx_y
    sta spr_y,x
    lda bitmask,x
    eor #$ff
    and spr_xmsb
    ldy fx_xh
    beq +
    ora bitmask,x
+   sta spr_xmsb
    rts
bitmask: !byte 1,2,4,8,16,32,64,128

; scintilla su gx,gy con colore A
!zone fx_spark
fx_spark:
    pha
    jsr fx_pos
    pla
    ldx fx_ok
    beq +
    sta spr_col+1
    ldx #1
    jsr fx_place
    lda #SP_SPARK1
    sta spr_ptr+1
    lda #14
    sta fx_timer
    lda spr_ena
    ora #2
    sta spr_ena
+   rts

; numero A su gx,gy con colore tmp5 (sprite 2)
!zone fx_number
fx_number:
    sta tmp4
    lda tmp5
    sta spr_col+2
    ; cancella lo sprite
    lda #0
    ldx #62
-   sta SPRDATA+(SP_NUM-SPR_PTR0)*64,x
    dex
    bpl -
    ; cifre: centinaia, decine, unità senza zeri iniziali
    lda #0
    sta tmp6                ; colonna byte
    lda tmp4
    ldx #0
-   cmp #100
    bcc +
    sbc #100
    inx
    bne -
+   sta tmp4
    txa
    beq +
    jsr fx_digit
+   lda tmp4
    ldx #0
-   cmp #10
    bcc +
    sbc #10
    inx
    bne -
+   sta tmp4
    txa
    bne +
    lda tmp6
    beq ++
    txa
+   jsr fx_digit
++  lda tmp4
    jsr fx_digit
    jsr fx_pos
    lda fx_ok
    beq +
    ldx #2
    jsr fx_place
    lda spr_y+2
    sec
    sbc #6
    sta spr_y+2
    lda #SP_NUM
    sta spr_ptr+2
    lda #34
    sta fx_timer+1
    lda spr_ena
    ora #4
    sta spr_ena
+   rts

; A = cifra -> colonna tmp6 dello sprite numerico
!zone fx_digit
fx_digit:
    sta tmp7
    asl
    asl
    asl
    sec
    sbc tmp7                ; *7
    tax
    ldy tmp6
    lda #7
    sta tmp7
-   lda digit_glyph,x
    sta SPRDATA+(SP_NUM-SPR_PTR0)*64,y
    inx
    iny
    iny
    iny
    dec tmp7
    bne -
    inc tmp6
    rts

; attende la fine degli effetti
!zone fx_wait
fx_wait:
-   lda fx_timer
    ora fx_timer+1
    bne -
    rts

; attende A frame
!zone delay
delay:
    sta tmp7
-   jsr wait_frame
    dec tmp7
    bne -
    rts

; aggiorna lo sprite eroe
!zone hero_sprite
hero_sprite:
    lda #HERO_SX
    sta spr_xl
    lda #HERO_SY
    sta spr_y
    lda spr_xmsb
    and #$fe
    sta spr_xmsb
    lda #15
    sta spr_col
    lda hero_face
    asl
    ora hero_frame
    clc
    adc #SP_HERO_R1
    sta spr_ptr
    lda spr_mc
    ora #1
    sta spr_mc
    lda spr_ena
    ora #1
    sta spr_ena
    rts
