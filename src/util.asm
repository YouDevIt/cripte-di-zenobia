; =====================================================================
;  Utilità: numeri casuali e piccoli calcoli
; =====================================================================

; xorshift a 16 bit (7,9,8) -> A
!zone rnd
rnd:
    lda rng+1
    lsr
    lda rng
    ror
    eor rng+1
    sta rng+1
    ror
    eor rng
    sta rng
    eor rng+1
    sta rng+1
    rts

; A = n -> A = 0..n-1 (preserva X e Y)
!zone rnd_n
rnd_n:
    stx rn_x
    sty save_a
    sta rn_n
    jsr rnd
    sta rn_r
    lda #0
    ldx #8
    lsr rn_n
-   bcc +
    clc
    adc rn_r
+   ror
    ror rn_n
    dex
    bne -
    ldx rn_x
    ldy save_a
    rts

; A = min, X = max -> A in [min, max]
!zone rnd_range
rnd_range:
    sta tmp6
    txa
    sec
    sbc tmp6
    clc
    adc #1
    jsr rnd_n
    clc
    adc tmp6
    rts

; A = valore con segno -> A = -1, 0, +1
!zone sign
sign:
    cmp #0
    beq +
    bmi ++
    lda #1
+   rts
++  lda #$ff
    rts

; A = valore con segno -> valore assoluto
!zone abs
abs:
    cmp #0
    bpl +
    eor #$ff
    clc
    adc #1
+   rts
