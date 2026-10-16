; *** generato da gen_assets.py: non modificare ***
TILE_BASE = $60
T_WALL1 = 0
T_WALL2 = 1
T_FLOOR = 2
T_CORR = 3
T_DOORC = 4
T_DOORO = 5
T_STAIRS = 6
T_RAT = 7
T_BAT = 8
T_SNAKE = 9
T_KOBOLD = 10
T_GOBLIN = 11
T_SKEL = 12
T_ORC = 13
T_WRAITH = 14
T_TROLL = 15
T_DRAGON = 16
T_POTION = 17
T_SCROLL = 18
T_SWORD = 19
T_ARMOR = 20
T_FOOD = 21
T_GOLD = 22
T_WAND = 23
T_AMULET = 24
T_AXE = 25
T_FLOOR2 = 26
NUM_TILES = 27
SPR_PTR0 = $80
SP_MASK = $80
SP_HERO_R1 = $81
SP_HERO_R2 = $82
SP_HERO_L1 = $83
SP_HERO_L2 = $84
SP_SPARK1 = $85
SP_SPARK2 = $86
SP_BOLT = $87
SP_PUFF = $88
SP_NUM = $89
SP_ZZZ = $8A
SPRITE_COUNT = 11
tile_char:
  !byte $60,$64,$68,$6C,$70,$74,$78,$7C,$80,$84,$88,$8C,$90,$94,$98,$9C,$A0,$A4,$A8,$AC,$B0,$B4,$B8,$BC,$C0,$C4,$C8
tile_color:   ; color RAM (bit 3 = multicolor)
  !byte $09,$09,$08,$08,$0F,$08,$09,$0A,$0A,$0D,$0B,$0F,$09,$0D,$0C,$0B,$0A,$0A,$0F,$09,$0B,$0F,$0F,$0B,$0B,$09,$08
digit_glyph:  ; 7 byte per cifra, 0-9 poi '-' e '+'
  !byte $3C,$66,$6E,$7E,$76,$66,$3C
  !byte $18,$38,$18,$18,$18,$18,$3C
  !byte $3C,$66,$06,$1C,$30,$60,$7E
  !byte $3C,$66,$06,$1C,$06,$66,$3C
  !byte $0C,$1C,$3C,$6C,$7E,$0C,$0C
  !byte $7E,$60,$7C,$06,$06,$66,$3C
  !byte $1C,$30,$60,$7C,$66,$66,$3C
  !byte $7E,$06,$0C,$18,$30,$30,$30
  !byte $3C,$66,$66,$3C,$66,$66,$3C
  !byte $3C,$66,$66,$3E,$06,$0C,$38
  !byte $00,$00,$00,$3C,$00,$00,$00
  !byte $00,$18,$18,$7E,$18,$18,$00
