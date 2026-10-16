; =====================================================================
;  Input: tastiera (matrice CIA1) e joystick in porta 2
;  Il joystick e i tasti cursore vengono tradotti nei tasti Q W E A D
;  Z X C, il fuoco in SPAZIO: il gioco vede un'unica sorgente.
; =====================================================================

; A = codice del tasto premuto ora (0 = nessuno)
!zone scan_input
scan_input:
!if TEST {
    jmp test_input
}
    lda #$ff
    sta $dc00
    lda $dc00
    and #$1f
    eor #$1f
    beq .kbd
    tax
    lda joy_map,x
    rts
.kbd:
    lda #0
    sta $dc00
    lda $dc01
    cmp #$ff
    bne +
    lda #$ff
    sta $dc00
    lda #0
    rts
+   lda #0
    sta tmp2                ; shift
    sta tmp3                ; risultato
    ldx #0                  ; colonna
.col:
    lda colsel,x
    sta $dc00
    lda $dc01
    sta tmp1
    txa
    asl
    asl
    asl
    tay                     ; indice matrice
    lda #8
    sta tmp0
-   lsr tmp1
    bcs .nxt
    lda key_matrix,y
    beq .nxt
    cmp #1
    bne +
    sta tmp2
    jmp .nxt
+   ldx tmp3
    bne +
    sta tmp3
+   txa                     ; (X sovrascritto: lo ricalcoliamo)
.nxt:
    iny
    dec tmp0
    bne -
    tya
    lsr
    lsr
    lsr
    tax
    cpx #8
    bne .col
    lda #$ff
    sta $dc00
    lda tmp3
    ldx tmp2
    beq .ret
    cmp #$11                ; shift + cursore giù = su
    bne +
    lda #'W'
    rts
+   cmp #$1d                ; shift + cursore destra = sinistra
    bne .ret
    lda #'A'
    rts
.ret:
    cmp #$11
    bne +
    lda #'X'
    rts
+   cmp #$1d
    bne +
    lda #'D'
+   rts

colsel: !byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f

; matrice C64: colonna*8 + riga ; 1 = shift
!zone key_matrix
key_matrix:
    !byte $14,$0d,$1d,0,0,0,0,$11          ; DEL RET CRSR-> F7 F1 F3 F5 CRSR-v
    !byte '3','W','A','4','Z','S','E',1
    !byte '5','R','D','6','C','F','T','X'
    !byte '7','Y','G','8','B','H','U','V'
    !byte '9','I','J','0','M','K','O','N'
    !byte '+','P','L','-','.',':',0,','
    !byte 0,'*',';',0,1,'=',0,'/'
    !byte '1',0,0,'2',' ',0,'Q',$03       ; ... SPAZIO C= Q RUN/STOP

; joystick: bit 0 su, 1 giù, 2 sinistra, 3 destra, 4 fuoco
!zone joy_map
joy_map:
    !byte 0,'W','X',0,'A','Q','Z',0,'D','E','C',0,0,0,0,0
    !fill 16, ' '

; ---------------------------------------------------------------- ripetizione
; A = nuovo evento tasto (con auto-ripetizione) oppure 0
!zone poll_key
poll_key:
    jsr scan_input
    cmp key_last
    beq .same
    sta key_last
    ldx frame
    stx key_time
    ldx #14
    stx key_delay
    rts
.same:
    cmp #0
    beq .none
    lda frame
    sec
    sbc key_time
    cmp key_delay
    bcc .none
    lda frame
    sta key_time
    lda #4
    sta key_delay
    lda key_last
    rts
.none:
    lda #0
    rts

; attende un tasto nuovo (dopo aver rilasciato tutto)
!zone wait_key
wait_key:
-   jsr wait_frame
    jsr scan_input
    bne -
    sta key_last
-   jsr wait_frame
    jsr poll_key
    beq -
    rts

!if TEST {
; input scriptato per i test automatici: coppie (tasto, frame)
!zone test_input
test_input:
    lda test_cnt
    bne .hold
    ldy #0
    lda (test_ptr),y
    cmp #$ff
    beq .end
    iny
    lda (test_ptr),y
    sta test_cnt
    clc
    lda test_ptr
    adc #2
    sta test_ptr
    bcc .hold
    inc test_ptr+1
.hold:
    dec test_cnt
    ldy #0
    sec
    lda test_ptr
    sbc #2
    sta ptr3
    lda test_ptr+1
    sbc #0
    sta ptr3+1
    lda (ptr3),y
    rts
.end:
    lda #0
    rts
!zone test_init
test_init:
    lda #<test_script
    sta test_ptr
    lda #>test_script
    sta test_ptr+1
    lda #0
    sta test_cnt
    rts
}
