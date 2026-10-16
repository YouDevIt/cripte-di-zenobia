; =====================================================================
;  LE CRIPTE DI ZENOBIA - definizioni, mappa di memoria, zero page
; =====================================================================

; ---------------- mappa di memoria (banco VIC 3: $C000-$FFFF)
SCR_STATUS  = $C000         ; schermo righe 0-2 (stato/messaggi)
SCR_A       = $C400         ; buffer mappa A
SCR_B       = $C800         ; buffer mappa B
CHARSET     = $D000         ; charset (RAM sotto l'I/O)
SPRDATA     = $E000         ; sprite (RAM sotto il KERNAL)
COLRAM      = $D800

MAP         = $8000         ; 64x32 terreno (bit7 = esplorato)
MONAT       = $8800         ; 64x32 indice mostro+1
ITEMAT      = $9000         ; 64x32 indice oggetto+1
COLBUF      = $9800         ; 880 byte colori del back buffer
LC0         = $9C00         ; buffer riga caratteri (metà alta)
LC1         = $9C40         ; buffer riga caratteri (metà bassa)
LCOL        = $9C80         ; buffer riga colori

MAPW        = 64
MAPH        = 32

D018_STATUS = $04           ; schermo $C000, charset $D000
D018_A      = $14
D018_B      = $24

; ---------------- terreno
TR_ROCK   = 0
TR_WALL   = 1
TR_FLOOR  = 2
TR_CORR   = 3
TR_DOORC  = 4
TR_DOORO  = 5
TR_STAIRS = 6
EXPLORED  = $80

; ---------------- classi oggetto
IC_NONE   = 0
IC_POTION = 1
IC_SCROLL = 2
IC_WEAPON = 3
IC_ARMOR  = 4
IC_FOOD   = 5
IC_GOLD   = 6
IC_WAND   = 7
IC_AMULET = 8

MAXMON    = 24
MAXITEM   = 40
INVSIZE   = 12
MAXROOM   = 12
MAXDEPTH  = 10

; flag mostri
MF_ALIVE  = $80
MF_AWAKE  = $01
MF_ASLEEP_FX = $02          ; addormentato da effetto (non usato)

; attributi tipo mostro
MA_ERRATIC = $01
MA_REGEN   = $02
MA_DRAIN   = $04

; posizione sprite eroe (al centro della finestra)
HERO_SX   = 171
HERO_SY   = 159

; ---------------- zero page
!zone zp
tmp0 = $02
tmp1 = $03
tmp2 = $04
tmp3 = $05
tmp4 = $06
tmp5 = $07
tmp6 = $08
tmp7 = $09
ptr0 = $0a          ; 2
ptr1 = $0c          ; 2
ptr2 = $0e          ; 2
ptr3 = $10          ; 2
pm   = $12          ; puntatore MAP
pmo  = $14          ; puntatore MONAT
pit  = $16          ; puntatore ITEMAT
rng  = $18          ; 2 seme xorshift
frame = $1a         ; contatore frame (IRQ)
irqp  = $1b         ; 2 puntatore per IRQ
irqt  = $1d         ; temp IRQ
irqt2 = $1e
; variabili camera/scroll (condivise main/IRQ)
camx  = $20         ; 2
camy  = $22         ; 2
tgtx  = $24         ; 2
tgty  = $26         ; 2
front_cx = $28
front_cy = $29
back_cx  = $2a
back_cy  = $2b
back_ready = $2c
front_sel  = $2d    ; 0 = A in primo piano, 1 = B
swap_now   = $2e
jump_req   = $2f
split_d016 = $30
split_d011 = $31
split_line = $32
split_d018 = $33
dirty      = $34
; render
rv_cx  = $35
rv_cy  = $36
rv_tx0 = $37        ; tile x iniziale (con segno)
rv_sub = $38        ; parità colonna
rv_ty  = $39        ; tile y corrente (con segno)
rv_row = $3a        ; riga schermo corrente 0..21
rv_vlo = $3b
rv_vhi = $3c
rv_tx  = $3d
rv_scr = $3e        ; 2 puntatore riga schermo back buffer
rv_col = $40        ; 2 puntatore riga COLBUF
rv_half = $42
; scroll simulazione
sx_lo = $43
sx_hi = $44
sy_lo = $45
sy_hi = $46
; messaggi
msg_len = $47
; input
key_last = $48
key_hold = $49
key_delay = $4a
; giocatore (in zp per velocità)
p_x    = $50
p_y    = $51
p_room = $52        ; stanza corrente o $FF
; effetti sprite (gestiti nell'IRQ)
fx_timer = $53      ; 4 slot: sparkle, numero, proiettile, zzz
; ($53-$56)
fx_anim  = $57
spr_hide = $58
; temporanei logica
gx  = $59
gy  = $5a
gdx = $5b
gdy = $5c
gi  = $5d
gj  = $5e
gk  = $5f
num_lo = $60
num_hi = $61
took_turn = $62
cur_mon = $63
hero_frame = $64
hero_face  = $65
spr_line = $66      ; ultima riga raster letta
test_ptr = $67      ; 2 (input scriptato)
test_cnt = $69
dir_x = $6a
dir_y = $6b
roll  = $6c
dmg   = $6d
sfx_req = $6e
str_ptr = $70       ; 2
