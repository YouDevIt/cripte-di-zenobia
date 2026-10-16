; =====================================================================
;  Hardware: inizializzazione, catena di raster IRQ, scrolling fluido
;
;  Catena per frame (PAL):
;   riga 250  irq_bottom : registri area stato, sprite-maschera, passo
;                          di scroll, eventuale scambio buffer + copia
;                          color RAM (con CLI: gli altri IRQ annidano)
;   riga  74  irq_split  : fine area stato -> YSCROLL sicuro, $D016/$D018
;                          della mappa, poi YSCROLL definitivo
;   riga  96  irq_sprites: gli sprite-maschera hanno finito, si
;                          riusano gli 8 sprite per eroe ed effetti
;  Righe 75-84 sono coperte da 7 sprite neri espansi: nascondono la
;  riga di caratteri parziale e danno un bordo superiore pulito.
; =====================================================================

!zone hw_init
hw_init:
    sei
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #$35                ; RAM + I/O, niente BASIC/KERNAL
    sta $01
    lda #<nmi_handler
    sta $fffa
    lda #>nmi_handler
    sta $fffb
    lda #<irq_bottom
    sta $fffe
    lda #>irq_bottom
    sta $ffff
    ; CIA1 per tastiera
    lda #$ff
    sta $dc02
    lda #$00
    sta $dc03
    lda #$ff
    sta $dc00
    ; banco VIC 3
    lda $dd02
    ora #$03
    sta $dd02
    lda $dd00
    and #$fc
    sta $dd00
    ; schermo spento durante il setup
    lda #$0b
    sta $d011
    ; charset -> $D000 (I/O disattivato durante la copia)
    lda #$34
    sta $01
    lda #<charset_data
    sta ptr0
    lda #>charset_data
    sta ptr0+1
    lda #<CHARSET
    sta ptr1
    lda #>CHARSET
    sta ptr1+1
    ldx #8
    jsr copy_pages
    lda #$35
    sta $01
    ; sprite -> $E000
    lda #<sprite_data
    sta ptr0
    lda #>sprite_data
    sta ptr0+1
    lda #<SPRDATA
    sta ptr1
    lda #>SPRDATA
    sta ptr1+1
    ldx #3
    jsr copy_pages
    ; pulizia schermi e color RAM
    ldx #0
    lda #0
-   sta SCR_STATUS,x
    sta SCR_STATUS+$100,x
    sta SCR_STATUS+$200,x
    sta SCR_STATUS+$300,x
    sta SCR_A,x
    sta SCR_A+$100,x
    sta SCR_A+$200,x
    sta SCR_A+$300,x
    sta SCR_B,x
    sta SCR_B+$100,x
    sta SCR_B+$200,x
    sta SCR_B+$300,x
    sta COLRAM,x
    sta COLRAM+$100,x
    sta COLRAM+$200,x
    sta COLRAM+$300,x
    inx
    bne -
    ; colori VIC
    lda #0
    sta $d020
    sta $d021
    lda #12
    sta $d022
    lda #9
    sta $d023
    lda #10                 ; sprite MC0: pelle
    sta $d025
    lda #14                 ; sprite MC1: tunica azzurra
    sta $d026
    lda #0
    sta $d015
    sta $d01b
    ; SID
    ldx #$18
    lda #0
-   sta $d400,x
    dex
    bpl -
    lda #$0f
    sta $d418
    lda #0
    sta sv_on
    sta sv_on+1
    sta sv_on+2
    sta sv_req
    sta sv_req+1
    sta sv_req+2
    ; stato scroll
    lda #0
    sta back_ready
    sta swap_now
    sta jump_req
    sta front_sel
    sta dirty
    sta spr_ena
    sta spr_hide
    sta spr_xe
    sta spr_ye
    sta spr_mc
    sta spr_xmsb
    sta fx_timer
    sta fx_timer+1
    sta fx_timer+2
    sta fx_timer+3
    lda #$10
    sta split_d016
    sta split_d011
    lda #76
    sta split_line
    lda #D018_A
    sta split_d018
    ; raster IRQ
    lda #250
    sta $d012
    lda #$1b
    sta $d011
    lda #$01
    sta $d01a
    lda #$ff
    sta $d019
    cli
    rts

!zone nmi_handler
nmi_handler:
    rti

; copia X pagine da (ptr0) a (ptr1)
!zone copy_pages
copy_pages:
    ldy #0
-   lda (ptr0),y
    sta (ptr1),y
    iny
    bne -
    inc ptr0+1
    inc ptr1+1
    dex
    bne -
    rts

; ---------------------------------------------------------------- IRQ 1
!zone irq_bottom
irq_bottom:
    pha
    txa
    pha
    tya
    pha
    lda #$01
    sta $d019
    lda #$1b                ; area stato: 25 righe, YSCROLL 3
    sta $d011
    lda #$08                ; hires, 40 colonne
    sta $d016
    lda #D018_STATUS
    sta $d018
    inc frame
    jsr scroll_step
    jsr mask_sprites
    lda #74
    sta $d012
    lda #<irq_split
    sta $fffe
    lda #>irq_split
    sta $ffff
    cli                     ; da qui gli altri IRQ possono annidarsi
    lda swap_now
    beq +
    jsr copy_colors
    lda #0
    sta swap_now
    sta back_ready
+   jsr fx_update
    jsr sfx_update
    pla
    tay
    pla
    tax
    pla
    rti

; ---------------------------------------------------------------- IRQ 2
!zone irq_split
irq_split:
    pha
    lda #$17                ; YSCROLL 7: nessuna badline per ora
    sta $d011
    lda split_d016
    sta $d016
    lda split_d018
    sta $d018
    lda split_line
-   cmp $d012
    bne -
    lda split_d011          ; YSCROLL definitivo, 24 righe
    sta $d011
    lda #$01
    sta $d019
    lda #96
    sta $d012
    lda #<irq_sprites
    sta $fffe
    lda #>irq_sprites
    sta $ffff
    pla
    rti

; ---------------------------------------------------------------- IRQ 3
!zone irq_sprites
irq_sprites:
    pha
    txa
    pha
    tya
    pha
    ldx #7
    ldy #14
-   lda spr_xl,x
    sta $d000,y
    lda spr_y,x
    sta $d001,y
    lda spr_col,x
    sta $d027,x
    dey
    dey
    dex
    bpl -
    lda spr_xmsb
    sta $d010
    lda spr_mc
    sta $d01c
    lda spr_xe
    sta $d01d
    lda spr_ye
    sta $d017
    jsr front_slots
    ldy #7
-   lda spr_ptr,y
    sta (irqp),y
    dey
    bpl -
    lda spr_hide
    beq +
    lda #0
    beq ++
+   lda spr_ena
++  sta $d015
    lda #$01
    sta $d019
    lda #250
    sta $d012
    lda #<irq_bottom
    sta $fffe
    lda #>irq_bottom
    sta $ffff
    pla
    tay
    pla
    tax
    pla
    rti

; irqp -> puntatori sprite del buffer in primo piano
!zone front_slots
front_slots:
    lda #$f8
    sta irqp
    lda front_sel
    beq +
    lda #>(SCR_B+$300)
    sta irqp+1
    rts
+   lda #>(SCR_A+$300)
    sta irqp+1
    rts

; sprite-maschera neri sulle righe 75-84
!zone mask_sprites
mask_sprites:
    lda #$7f
    sta $d015
    sta $d01d
    lda #0
    sta $d01c
    sta $d017
    sta $d01b
    lda #$60
    sta $d010
    ldx #6
    ldy #12
-   lda mask_x,x
    sta $d000,y
    lda #74
    sta $d001,y
    lda #0
    sta $d027,x
    dey
    dey
    dex
    bpl -
    jsr front_slots
    ldy #6
    lda #SP_MASK
-   sta (irqp),y
    dey
    bpl -
    rts
!zone mask_x
mask_x:
    !byte 24, 72, 120, 168, 216, <264, <312

; ---------------------------------------------------------------- scroll
; Avanza la camera di 2 pixel verso il bersaglio. Quando il passo
; richiede una nuova posizione "grossa" (a caratteri) scambia i buffer
; solo se il back buffer è pronto ed è stato disegnato proprio per
; quella posizione; altrimenti attende (nessun tearing).
!zone scroll_step
scroll_step:
    lda jump_req
    beq .normal
    lda back_ready
    beq .regs
    lda tgtx
    sta camx
    lda tgtx+1
    sta camx+1
    lda tgty
    sta camy
    lda tgty+1
    sta camy+1
    jsr do_swap
    lda #0
    sta jump_req
    jmp .regs
.normal:
    ldx #0
    jsr irq_step_axis
    ldx #2
    jsr irq_step_axis
    ldx #0
    jsr irq_coarse
    sta irqt2
    ldx #2
    jsr irq_coarse
    cmp front_cy
    bne .newc
    ldx irqt2
    cpx front_cx
    bne .newc
    ; stessa posizione grossa: muovi; eventuale ridisegno sul posto
    jsr commit_n
    lda back_ready
    beq .regs
    lda back_cx
    cmp front_cx
    bne .regs
    lda back_cy
    cmp front_cy
    bne .regs
    jsr do_swap
    jmp .regs
.newc:
    ldx back_ready
    beq .regs
    cmp back_cy
    bne .regs
    lda irqt2
    cmp back_cx
    bne .regs
    jsr commit_n
    jsr do_swap
.regs:
    lda camx
    and #7
    eor #7
    ora #$10                ; multicolor, 38 colonne
    sta split_d016
    lda camy
    and #7
    sta irqt
    lda #84
    sec
    sbc irqt                ; prima badline della mappa (77..84)
    and #7
    sta irqt
    ora #$10
    sta split_d011
    ldx #76
    lda irqt
    cmp #4
    bne +
    ldx #77
+   stx split_line
    lda front_sel
    beq +
    lda #D018_B
    bne ++
+   lda #D018_A
++  sta split_d018
    rts

!zone commit_n
commit_n:
    lda irq_n
    sta camx
    lda irq_n+1
    sta camx+1
    lda irq_n+2
    sta camy
    lda irq_n+3
    sta camy+1
    rts

!zone do_swap
do_swap:
    lda front_sel
    eor #1
    sta front_sel
    lda back_cx
    sta front_cx
    lda back_cy
    sta front_cy
    lda #1
    sta swap_now
    rts

; X = 0 (asse x) o 2 (asse y): irq_n = passo da cam verso tgt
!zone irq_step_axis
irq_step_axis:
    sec
    lda tgtx,x
    sbc camx,x
    sta irqt
    lda tgtx+1,x
    sbc camx+1,x
    bmi .neg
    bne .pos2
    lda irqt
    beq .tgt
    cmp #2
    bcs .pos2
.tgt:
    lda tgtx,x
    sta irq_n,x
    lda tgtx+1,x
    sta irq_n+1,x
    rts
.pos2:
    clc
    lda camx,x
    adc #2
    sta irq_n,x
    lda camx+1,x
    adc #0
    sta irq_n+1,x
    rts
.neg:
    cmp #$ff
    bne .neg2
    lda irqt
    cmp #$fe
    bcs .tgt
.neg2:
    sec
    lda camx,x
    sbc #2
    sta irq_n,x
    lda camx+1,x
    sbc #0
    sta irq_n+1,x
    rts

; A = irq_n(X) >> 3
!zone irq_coarse
irq_coarse:
    lda irq_n+1,x
    sta irqt
    lda irq_n,x
    lsr irqt
    ror
    lsr irqt
    ror
    lsr irqt
    ror
    rts

; ---------------------------------------------------------------- color RAM
; righe 3..24 da COLBUF, a coppie dall'alto: resta sempre davanti al raggio
!zone copy_colors
copy_colors:
!for .p, 0, 10 {
    ldx #39
-   lda COLBUF + .p*80, x
    sta COLRAM + 120 + .p*80, x
    lda COLBUF + .p*80 + 40, x
    sta COLRAM + 160 + .p*80, x
    dex
    bpl -
}
    rts

; ---------------------------------------------------------------- effetti
; slot 0: scintilla (sprite 1)   slot 1: numero (sprite 2)
!zone fx_update
fx_update:
    lda fx_timer
    beq .n1
    dec fx_timer
    bne +
    lda spr_ena
    and #%11111101
    sta spr_ena
    jmp .n1
+   lda fx_timer
    and #4
    beq +
    lda #SP_SPARK1
    bne ++
+   lda #SP_SPARK2
++  sta spr_ptr+1
.n1:
    lda fx_timer+1
    beq .n2
    dec fx_timer+1
    bne +
    lda spr_ena
    and #%11111011
    sta spr_ena
    jmp .n2
+   lda fx_timer+1
    and #1
    bne .n2
    lda spr_y+2
    cmp #100
    bcc .n2
    dec spr_y+2
.n2:
    rts

; ---------------------------------------------------------------- SID
; Ogni suono: AD, SR, PWhi, voce, poi passi (ctrl, flo, fhi, slo, shi,
; frame) terminati da ctrl=0. Il programma principale chiede un suono
; scrivendo sv_req[voce] = id+1 (play_sound); l'IRQ lo avvia.
sid_off: !byte 0, 7, 14

!zone sfx_update
sfx_update:
    ldx #0
.voice:
    lda sv_req,x
    beq .run
    sec
    sbc #1
    tay
    lda #0
    sta sv_req,x
    lda snd_lo,y
    sta irqp
    lda snd_hi,y
    sta irqp+1
    ldy sid_off,x
    lda #0
    sta $d404,y
    sty irqt
    ldy #0
    lda (irqp),y
    pha
    iny
    lda (irqp),y
    pha
    iny
    lda (irqp),y
    ldy irqt
    sta $d403,y
    lda #0
    sta $d402,y
    pla
    sta $d406,y
    pla
    sta $d405,y
    clc
    lda irqp
    adc #4
    sta sv_pl,x
    lda irqp+1
    adc #0
    sta sv_ph,x
    jsr sfx_load
    jmp .next
.run:
    lda sv_on,x
    beq .next
    dec sv_fr,x
    bne +
    jsr sfx_load
    jmp .next
+   clc
    lda sv_fl,x
    adc sv_sl,x
    sta sv_fl,x
    lda sv_fh,x
    adc sv_sh,x
    sta sv_fh,x
    ldy sid_off,x
    lda sv_fl,x
    sta $d400,y
    lda sv_fh,x
    sta $d401,y
.next:
    inx
    cpx #3
    beq +
    jmp .voice
+    rts

; carica il passo successivo della voce X
!zone sfx_load
sfx_load:
    lda sv_pl,x
    sta irqp
    lda sv_ph,x
    sta irqp+1
    ldy #0
    lda (irqp),y
    bne +
    lda sv_ctrl,x           ; fine: gate off
    and #$fe
    ldy sid_off,x
    sta $d404,y
    lda #0
    sta sv_on,x
    rts
+   sta sv_ctrl,x
    iny
    lda (irqp),y
    sta sv_fl,x
    iny
    lda (irqp),y
    sta sv_fh,x
    iny
    lda (irqp),y
    sta sv_sl,x
    iny
    lda (irqp),y
    sta sv_sh,x
    iny
    lda (irqp),y
    sta sv_fr,x
    clc
    lda irqp
    adc #6
    sta sv_pl,x
    lda irqp+1
    adc #0
    sta sv_ph,x
    ldy sid_off,x
    lda sv_fl,x
    sta $d400,y
    lda sv_fh,x
    sta $d401,y
    lda sv_ctrl,x
    sta $d404,y
    lda #1
    sta sv_on,x
    rts

; A = id suono: richiesta all'IRQ
!zone play_sound
play_sound:
    tay
    lda snd_lo,y
    sta ptr3
    lda snd_hi,y
    sta ptr3+1
    sty save_a
    ldy #3
    lda (ptr3),y
    tay
    ldx save_a
    inx
    txa
    sta sv_req,y
    rts
