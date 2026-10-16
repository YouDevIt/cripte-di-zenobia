#!/usr/bin/env python3
"""Genera gli asset per 'Le Cripte di Zenobia' (C64):
   - charset.bin   : 2 KB, font 8x8 + tile multicolor 16x16
   - sprites.bin   : dati sprite (player MC, effetti hires, maschera)
   - gen_tables.asm: costanti e tabelle tile/colori
   - gen_strings.asm: testi in italiano codificati nel charset
   - gen_sfx.asm   : effetti sonori e jingle SID
"""
import os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "."

# ---------------------------------------------------------------- font 5x7
FONT = {
' ': ["....."]*7,
'A': [".###.","#...#","#...#","#####","#...#","#...#","#...#"],
'B': ["####.","#...#","#...#","####.","#...#","#...#","####."],
'C': [".###.","#...#","#....","#....","#....","#...#",".###."],
'D': ["####.","#...#","#...#","#...#","#...#","#...#","####."],
'E': ["#####","#....","#....","####.","#....","#....","#####"],
'F': ["#####","#....","#....","####.","#....","#....","#...."],
'G': [".###.","#...#","#....","#.###","#...#","#...#",".####"],
'H': ["#...#","#...#","#...#","#####","#...#","#...#","#...#"],
'I': [".###.","..#..","..#..","..#..","..#..","..#..",".###."],
'J': ["..###","...#.","...#.","...#.","#..#.","#..#.",".##.."],
'K': ["#...#","#..#.","#.#..","##...","#.#..","#..#.","#...#"],
'L': ["#....","#....","#....","#....","#....","#....","#####"],
'M': ["#...#","##.##","#.#.#","#.#.#","#...#","#...#","#...#"],
'N': ["#...#","#...#","##..#","#.#.#","#..##","#...#","#...#"],
'O': [".###.","#...#","#...#","#...#","#...#","#...#",".###."],
'P': ["####.","#...#","#...#","####.","#....","#....","#...."],
'Q': [".###.","#...#","#...#","#...#","#.#.#","#..#.",".##.#"],
'R': ["####.","#...#","#...#","####.","#.#..","#..#.","#...#"],
'S': [".####","#....","#....",".###.","....#","....#","####."],
'T': ["#####","..#..","..#..","..#..","..#..","..#..","..#.."],
'U': ["#...#","#...#","#...#","#...#","#...#","#...#",".###."],
'V': ["#...#","#...#","#...#","#...#","#...#",".#.#.","..#.."],
'W': ["#...#","#...#","#...#","#.#.#","#.#.#","##.##","#...#"],
'X': ["#...#","#...#",".#.#.","..#..",".#.#.","#...#","#...#"],
'Y': ["#...#","#...#",".#.#.","..#..","..#..","..#..","..#.."],
'Z': ["#####","....#","...#.","..#..",".#...","#....","#####"],
'0': [".###.","#...#","#..##","#.#.#","##..#","#...#",".###."],
'1': ["..#..",".##..","..#..","..#..","..#..","..#..",".###."],
'2': [".###.","#...#","....#","..##.",".#...","#....","#####"],
'3': [".###.","#...#","....#","..##.","....#","#...#",".###."],
'4': ["...#.","..##.",".#.#.","#..#.","#####","...#.","...#."],
'5': ["#####","#....","####.","....#","....#","#...#",".###."],
'6': ["..##.",".#...","#....","####.","#...#","#...#",".###."],
'7': ["#####","....#","...#.","..#..",".#...",".#...",".#..."],
'8': [".###.","#...#","#...#",".###.","#...#","#...#",".###."],
'9': [".###.","#...#","#...#",".####","....#","...#.",".##.."],
'!': ["..#..","..#..","..#..","..#..","..#..",".....","..#.."],
'.': [".....",".....",".....",".....",".....",".....","..#.."],
',': [".....",".....",".....",".....",".....","..#..",".#..."],
"'": ["..#..","..#..",".#...",".....",".....",".....","....."],
'"': [".#.#.",".#.#.",".....",".....",".....",".....","....."],
'-': [".....",".....",".....",".###.",".....",".....","....."],
'+': [".....","..#..","..#..","#####","..#..","..#..","....."],
':': [".....","..#..",".....",".....",".....","..#..","....."],
';': [".....","..#..",".....",".....","..#..","..#..",".#..."],
'/': ["....#","....#","...#.","..#..",".#...","#....","#...."],
'(': ["...#.","..#..",".#...",".#...",".#...","..#..","...#."],
')': [".#...","..#..","...#.","...#.","...#.","..#..",".#..."],
'?': [".###.","#...#","....#","...#.","..#..",".....","..#.."],
'=': [".....",".....","#####",".....","#####",".....","....."],
'%': ["##..#","##.#.","...#.","..#..",".#...",".#.##","#..##"],
'>': [".#...","..#..","...#.","....#","...#.","..#..",".#..."],
'<': ["...#.","..#..",".#...","#....",".#...","..#..","...#."],
'*': [".....","#.#.#",".###.","#####",".###.","#.#.#","....."],
'#': [".#.#.",".#.#.","#####",".#.#.","#####",".#.#.",".#.#."],
# accentate (codici speciali): lettera compressa su 5 righe + accento
'À': [".#...","..#..",".###.","#...#","#####","#...#","#...#"],
'È': [".#...","..#..","#####","#....","####.","#....","#####"],
'É': ["...#.","..#..","#####","#....","####.","#....","#####"],
'Ì': [".#...","..#..",".###.","..#..","..#..","..#..",".###."],
'Ò': [".#...","..#..",".###.","#...#","#...#","#...#",".###."],
'Ù': [".#...","..#..","#...#","#...#","#...#","#...#",".###."],
}
# codici: ASCII $20-$5F, accentate su caratteri inutilizzati
ACC = {'À':'[','È':'\\','É':']','Ì':'^','Ò':'_','Ù':'@'}

def glyph_bytes(rows):
    out = []
    for r in rows:
        v = 0
        for i, ch in enumerate(r):
            if ch == '#':
                v |= 1 << (6 - i)      # colonne 1..5
        v |= v >> 1                    # grassetto stile C64
        out.append(v & 0xFF)
    out.append(0)
    return out

def enc_char(ch):
    ch = ch.upper()
    if ch in ACC:
        return ord(ACC[ch])
    if ch == '’':
        ch = "'"
    o = ord(ch)
    if 0x20 <= o <= 0x5F:
        return o
    raise ValueError("carattere non codificabile: %r" % ch)

def enc(s):
    return [enc_char(c) for c in s]

charset = bytearray(2048)
for ch, rows in FONT.items():
    code = ord(ACC[ch]) if ch in ACC else ord(ch)
    charset[code*8:code*8+8] = bytes(glyph_bytes(rows))

# caratteri UI $01-$0F (hires)
UI = {
 1: [0xFF]*8,                                       # blocco pieno
 2: [0x00,0x00,0x00,0xFF,0xFF,0x00,0x00,0x00],      # linea orizzontale
 3: [0x18]*8,                                       # linea verticale
 4: [0x00,0x00,0x00,0x1F,0x1F,0x18,0x18,0x18],      # angolo alto-sx
 5: [0x00,0x00,0x00,0xF8,0xF8,0x18,0x18,0x18],      # angolo alto-dx
 6: [0x18,0x18,0x18,0x1F,0x1F,0x00,0x00,0x00],      # angolo basso-sx
 7: [0x18,0x18,0x18,0xF8,0xF8,0x00,0x00,0x00],      # angolo basso-dx
 8: [0x00,0x66,0xFF,0xFF,0x7E,0x3C,0x18,0x00],      # cuore
 9: [0x18,0x3C,0x7E,0xFF,0x7E,0x3C,0x18,0x00],      # rombo
}
for code, b in UI.items():
    charset[code*8:code*8+8] = bytes(b)

# ---------------------------------------------------------------- tile MC 8x16
# '.'=sfondo(nero) '1'=$D022 grigio medio '2'=$D023 marrone '3'=color RAM
FLOOR_DOTS = [
"........","........",".1......","........","........",".....2..","........","........",
"........","........","...1....","........","........","......1.","........","........"]

TILES = []   # (nome, righe, colore color RAM (0-7), bake_floor)
def T(name, rows, col, bake=False):
    assert len(rows) == 16, name
    for r in rows: assert len(r) == 8, (name, r)
    TILES.append((name, rows, col, bake))

T("WALL1", [
"3333333.","3111112.","3111112.","3111112.","3111112.","3111112.","2222222.","........",
"332.3333","112.3111","112.3111","112.3111","112.3111","112.3111","222.2222","........"], 1)
T("WALL2", [
"3333333.","3112112.","3111112.","3121112.","3111212.","3111112.","2222222.","........",
"332.3333","112.3121","112.3111","212.3111","112.3112","112.3111","222.2222","........"], 1)
T("FLOOR", FLOOR_DOTS, 0)
T("CORR", [
"........","..2.....","........","......1.",".2......","........","....2...",".1......",
"........",".....2..","..1.....","........","......2.","...2....",".1......","........"], 0)
T("DOORC", [
"11111111","12222221","12.22.21","12.22.21","12222221","12.22.21","12.22.21","12222331",
"12222331","12.22.21","12.22.21","12222221","12.22.21","12.22.21","12222221","11111111"], 7)
T("DOORO", [
"11111111","122....1","122....1","122....1","122....1","122....1","122....1","122....1",
"122....1","122....1","122....1","122....1","122....1","122....1","122....1","12222221"], 0)
T("STAIRS", [
"........","33333333","11111111","2.......","2.333333","2.111111","2.2.....","2.2.3333",
"2.2.1111","2.2.2...","2.2.2.33","2.2.2.11","2.2.2.2.","2.2.2.2.","2.2.2.2.","........"], 1)
# --- mostri
T("RAT", [
"........","........","........","........","........","........","..1.....",".131....",
"1111111.","31111111",".1111111","..1..1.3","..2..2.3","......33","........","........"], 2, True)
T("BAT", [
"........","........","3......3","33....33","332..233","3321.233","3.2312.3","...22...",
"...22...","........","........","........","........","........","........","........"], 2, True)
T("SNAKE", [
"........","........","........","....33..","...3133.","....33.2","...33...","..33....",
"..33....","...33...","....33..","..3333..",".33..33.","33....33","........","........"], 5, True)
T("KOBOLD", [
"........","........","..3333..",".313313.","..3333..","...33..1",".233332.","2.3333.1",
"..3333.1","..2222.1","..2..2..","..2..2..",".33..33.","........","........","........"], 3, True)
T("GOBLIN", [
"........","..1..1..","..3333..",".331133.","..3223..","...33...",".222222.","3.2222.3",
"3.2222.3","..2222..","..1111..","..3..3..","..3..3..",".22..22.","........","........"], 7, True)
T("SKEL", [
"........","..3333..",".313313.",".333333.","..3.3...","...33...",".333333.","3..33..3",
"3.3333.3",".1.33.1.","...33...","..3..3..","..3..3..","..3..3..",".33..33.","........"], 1, True)
T("ORC", [
"........","..3333..",".333333.",".3.33.3.",".333333.","..1111..","11222211","13222231",
"33222233","3.2222.3","..1111..","..2..2..","..3..3..","..3..3..",".22..22.","........"], 5, True)
T("WRAITH", [
"...33...","..3333..",".33..33.",".3.33.3.",".333333.","..3333..",".333333.","33333333",
"3.3333.3","..3333..",".333333.",".333333.","33333333","3.3.3.3.","3...3...","........"], 4, True)
T("TROLL", [
".333333.","33333333","31333313","33333333","33.22.33",".333333.","33333333","33233233",
"33333333","3.3333.3","2.3333.2","..3333..","..33.33.",".333.333","2222.222","........"], 3, True)
T("DRAGON", [
"3.....3.","33...33.",".33333..","3131333.","3333333.",".2.2333.","...33333","..333333",
"33333333","32333332","33333333",".333333.","..3..3..",".33..33.","22...22.","........"], 2, True)
# --- oggetti
T("POTION", [
"........","........","...22...","...22...","...11...","...11...","..1..1..",".1....1.",
".133331.",".133331.",".133331.","..1331..","...11...","........","........","........"], 2, True)
T("SCROLL", [
"........","........","........",".2....2.",".233332.",".231312.",".233332.",".213132.",
".233332.",".231132.",".233332.",".2....2.","........","........","........","........"], 7, True)
T("SWORD", [
"........","........","......3.",".....31.","....31..","...31...","..31....",".21.....",
"2.2.....",".2.2....","2...2...","........","........","........","........","........"], 1, True)
T("ARMOR", [
"........","........",".11..11.",".131131.",".111111.",".131131.",".111111.","..1311..",
"..1111..","..1311..","..1111..","...11...","........","........","........","........"], 3, True)
T("FOOD", [
"........","........","........","........","..2222..",".223322.","2232232.","2222222.",
"2323232.",".222222.","........","........","........","........","........","........"], 7, True)
T("GOLD", [
"........","........","........","........","........","...33...","..3223..","...33...",
".33..33.","3223322.",".33.3223","..33.33.",".3223...","..33....","........","........"], 7, True)
T("WAND", [
"........","........",".1...1..","...3....","..131...","...3....","....2...",".....2..",
"......2.",".......2","........","........","........","........","........","........"], 3, True)
T("AMULET", [
"........","........","..1111..",".1....1.","1......1","1......1",".1....1.","..1..1..",
"...33...","..3113..","..3333..","...33...","........","........","........","........"], 3, True)
T("AXE", [
"........","........","..33....",".3111...",".31112..",".3112...","..12.2..","......2.",
".......2","........","........","........","........","........","........","........"], 1, True)
T("FLOOR2", [
"........","........",".1......","........","........",".....2..","........","...2....",
"....2...","........","...1....","........","........","......1.","........","........"], 0)

TILE_BASE = 0x60
assert TILE_BASE + 4*len(TILES) <= 256

def mc_byte(cells):
    v = 0
    for c in cells:
        v = (v << 2) | ".123".index(c)
    return v

for t, (name, rows, col, bake) in enumerate(TILES):
    if bake:
        rows = ["".join(FLOOR_DOTS[y][x] if rows[y][x] == '.' else rows[y][x]
                        for x in range(8)) for y in range(16)]
    base = (TILE_BASE + 4*t) * 8
    for q, (x0, y0) in enumerate([(0,0),(4,0),(0,8),(4,8)]):
        for r in range(8):
            charset[base + q*8 + r] = mc_byte(rows[y0+r][x0:x0+4])

with open(os.path.join(OUT, "charset.bin"), "wb") as f:
    f.write(charset)

# ---------------------------------------------------------------- sprite
SPRITES = []
def sp_hires(name, rows):
    data = bytearray(64)
    for y, r in enumerate(rows):
        r = r.ljust(24, '.')
        for b in range(3):
            v = 0
            for i in range(8):
                v = (v << 1) | (1 if r[b*8+i] == '#' else 0)
            data[y*3+b] = v
    SPRITES.append((name, data))

def sp_mc(name, rows):
    data = bytearray(64)
    for y, r in enumerate(rows):
        r = r.ljust(12, '.')
        for b in range(3):
            data[y*3+b] = mc_byte(r[b*4:b*4+4])
    SPRITES.append((name, data))

def mirror_mc(rows):
    return ["".join(reversed(r.ljust(8, '.')[:8])) for r in rows]

# 0: maschera (10 righe piene)
SPRITES.append(("MASK", bytearray([0xFF]*30 + [0]*34)))
# eroe (MC): '1'=pelle $D025, '2'=armatura (colore sprite), '3'=tunica $D026
HERO_R1 = [
"...222..","..22222.","..22121.","..22111.","...222..","..33332.",".333332.",".1333312",
"..33332.","..2222..","..3..3..","..3..3..","..2..2..",".22..22.","........","........"]
HERO_R2 = [
"...222..","..22222.","..22121.","..22111.","...222..","..33332.",".333332.",".1333312",
"..33332.","..2222..","..3.3...",".3...3..",".2....2.","22....22","........","........"]
HERO_AT = [
"...222..","..22222.","..22121.","..22111.","...222..","..333322",".3333322",".1333312",
"..33332.","..2222..","..3..3..","..3..3..","..2..2..",".22..22.","........","........"]
sp_mc("HERO_R1", HERO_R1)
sp_mc("HERO_R2", HERO_R2)
sp_mc("HERO_L1", mirror_mc(HERO_R1))
sp_mc("HERO_L2", mirror_mc(HERO_R2))
sp_hires("SPARK1", [
"","","","","",".......#........",
"....#..#..#.....",".....#.#.#......","......###.......","....#######.....",
"......###.......",".....#.#.#......","....#..#..#.....",".......#........"])
sp_hires("SPARK2", [
"","","","##.....#.....##",".##....#....##",
"..##...#...##","...##.###.##","....#######",".....#####","###########...",
".....#####","....#######","...##.###.##","..##...#...##",".##....#....##","##.....#.....##"])
sp_hires("BOLT", [
"","","","","","",".......##",
"......####",".....######","......####",".......##"])
sp_hires("PUFF", [
"","","....##..##","..#..####..#",".#.##....##.#",
"..#..#..#..#",".#.#..##..#.#","..#..#..#..#",".#.##....##.#","..#..####..#",
"....##..##"])
SPRITES.append(("NUM", bytearray(64)))   # numero dinamico
sp_hires("ZZZ", [
"","","..........#####",".............#","............#","...........#",
"..........#####","....####","......#",".....#","....####"])
SPR_PTR0 = 0x80
with open(os.path.join(OUT, "sprites.bin"), "wb") as f:
    for name, d in SPRITES:
        f.write(bytes(d))

# ---------------------------------------------------------------- tabelle
L = []
L.append("; *** generato da gen_assets.py: non modificare ***")
L.append("TILE_BASE = $%02X" % TILE_BASE)
for t, (name, rows, col, bake) in enumerate(TILES):
    L.append("T_%s = %d" % (name, t))
L.append("NUM_TILES = %d" % len(TILES))
L.append("SPR_PTR0 = $%02X" % SPR_PTR0)
for i, (name, d) in enumerate(SPRITES):
    L.append("SP_%s = $%02X" % (name, SPR_PTR0 + i))
L.append("SPRITE_COUNT = %d" % len(SPRITES))
L.append("tile_char:")
L.append("  !byte " + ",".join("$%02X" % (TILE_BASE + 4*t) for t in range(len(TILES))))
L.append("tile_color:   ; color RAM (bit 3 = multicolor)")
L.append("  !byte " + ",".join("$%02X" % (8 | c) for (_, _, c, _) in TILES))
# glifi cifre per lo sprite numerico (riga 0..6 di '0'..'9' e '-')
L.append("digit_glyph:  ; 7 byte per cifra, 0-9 poi '-' e '+'")
for ch in "0123456789-+":
    g = glyph_bytes(FONT[ch])[:7]
    L.append("  !byte " + ",".join("$%02X" % b for b in g))
with open(os.path.join(OUT, "gen_tables.asm"), "w") as f:
    f.write("\n".join(L) + "\n")

# ---------------------------------------------------------------- testi
S = []
def text(label, s, term=True):
    b = enc(s) + ([0] if term else [])
    S.append("%s: !byte %s" % (label, ",".join("$%02X" % x for x in b)))

def table(label, items):
    S.append("%s_lo: !byte %s" % (label, ",".join("<%s" % i for i in items)))
    S.append("%s_hi: !byte %s" % (label, ",".join(">%s" % i for i in items)))

# nomi mostri con articolo (maiuscolo)
MON = [("RATTO","IL RATTO"),("PIPISTRELLO","IL PIPISTRELLO"),("SERPENTE","IL SERPENTE"),
       ("COBOLDO","IL COBOLDO"),("GOBLIN","IL GOBLIN"),("SCHELETRO","LO SCHELETRO"),
       ("ORCO","L'ORCO"),("SPETTRO","LO SPETTRO"),("TROLL","IL TROLL"),("DRAGO","IL DRAGO")]
for i, (n, a) in enumerate(MON):
    text("mname%d" % i, a)
table("mname", ["mname%d" % i for i in range(len(MON))])
# "UN RATTO" per l'epitaffio
MON_INDEF = ["UN RATTO","UN PIPISTRELLO","UN SERPENTE","UN COBOLDO","UN GOBLIN",
             "UNO SCHELETRO","UN ORCO","UNO SPETTRO","UN TROLL","IL DRAGO",
             "LA FAME","UNA POZIONE"]
for i, n in enumerate(MON_INDEF):
    text("killer%d" % i, n)
table("killer", ["killer%d" % i for i in range(len(MON_INDEF))])

# oggetti: nome base con articolo + lunghezza articolo
ITEM_NAMES = [
 ("in_potion",  "UNA POZIONE"),
 ("in_scroll",  "UNA PERGAMENA"),
 ("in_dagger",  "UN PUGNALE"),
 ("in_mace",    "UNA MAZZA"),
 ("in_sword",   "UNA SPADA"),
 ("in_axe",     "UN'ASCIA"),
 ("in_leather", "UN'ARMATURA DI CUOIO"),
 ("in_chain",   "UNA COTTA DI MAGLIA"),
 ("in_plate",   "UN'ARMATURA A PIASTRE"),
 ("in_food",    "UNA RAZIONE DI CIBO"),
 ("in_wand",    "UNA BACCHETTA DEL FULMINE"),
 ("in_amulet",  "L'AMULETO DI ZENOBIA"),
]
for lab, s in ITEM_NAMES:
    art = s.index(' ') + 1 if not s.startswith(("UN'", "L'")) else s.index("'") + 1
    S.append("%s: !byte %d" % (lab, art))
    text(lab + "_s", s)
POT_COL_NAMES = ["ROSSA","AZZURRA","VIOLA","VERDE","GIALLA"]
POT_TYPES = ["DI GUARIGIONE","DI VIGORE","DI VELENO","DI FORZA","DI ESPERIENZA"]
SCR_NAMES = ["'ZORGAL'","'MIRADU'","'KEPHRA'","'ULTIMOR'"]
SCR_TYPES = ["DI MAPPATURA","DI TELETRASPORTO","DI AFFILATURA","DI PROTEZIONE"]
for i, s in enumerate(POT_COL_NAMES): text("potcol%d" % i, s)
for i, s in enumerate(POT_TYPES): text("pottyp%d" % i, s)
for i, s in enumerate(SCR_NAMES): text("scrnam%d" % i, s)
for i, s in enumerate(SCR_TYPES): text("scrtyp%d" % i, s)
table("potcol", ["potcol%d" % i for i in range(5)])
table("pottyp", ["pottyp%d" % i for i in range(5)])
table("scrnam", ["scrnam%d" % i for i in range(4)])
table("scrtyp", ["scrtyp%d" % i for i in range(4)])

MSGS = {
 "m_hit":      "COLPISCI ",
 "m_miss":     "MANCHI ",
 "m_kill":     "UCCIDI ",
 "m_hitsyou":  " TI COLPISCE.",
 "m_missyou":  " TI MANCA.",
 "m_dot":      ".",
 "m_excl":     "!",
 "m_door":     "APRI LA PORTA.",
 "m_mdoor":    "SENTI UNA PORTA CIGOLARE.",
 "m_pickup":   "RACCOGLI ",
 "m_gold1":    "TROVI ",
 "m_gold2":    " MONETE D'ORO.",
 "m_full":     "LO ZAINO È PIENO.",
 "m_stairs":   "SCENDI LE SCALE... PIANO ",
 "m_nostairs": "NON CI SONO SCALE QUI.",
 "m_welcome":  "BENVENUTO NELLE CRIPTE DI ZENOBIA!",
 "m_welcome2": "TROVA L'AMULETO AL DECIMO PIANO.",
 "m_levelup":  "SALI AL LIVELLO ",
 "m_hungry":   "HAI FAME.",
 "m_weak":     "SEI DEBOLE PER LA FAME!",
 "m_starve":   "STAI MORENDO DI FAME!",
 "m_eat":      "GNAM! TI SENTI SAZIO.",
 "m_heal":     "TI SENTI MOLTO MEGLIO.",
 "m_vigor":    "UN VIGORE NUOVO TI PERVADE!",
 "m_poison":   "BLEAH! ERA VELENO!",
 "m_strength": "I TUOI MUSCOLI SI GONFIANO!",
 "m_exper":    "UNA NUOVA SAGGEZZA TI ILLUMINA.",
 "m_map":      "UNA MAPPA SI DISEGNA NELLA TUA MENTE.",
 "m_teleport": "VIENI TRASPORTATO ALTROVE!",
 "m_sharp":    "LA TUA ARMA BRILLA DI LUCE AZZURRA.",
 "m_protect":  "LA TUA ARMATURA BRILLA D'ARGENTO.",
 "m_nothing":  "SENTI UN FORMICOLIO... NULLA.",
 "m_wield":    "ORA IMPUGNI: ",
 "m_wear":     "ORA INDOSSI: ",
 "m_drop":     "LASCI ",
 "m_noroom":   "NON C'È SPAZIO PER POSARLO QUI.",
 "m_zap":      "UN FULMINE SCATURISCE DALLA BACCHETTA!",
 "m_nocharge": "LA BACCHETTA È SCARICA.",
 "m_whichdir": "IN QUALE DIREZIONE?",
 "m_cancel":   "LASCI PERDERE.",
 "m_amulet":   "HAI L'AMULETO DI ZENOBIA!",
 "m_wakes":    " SI SVEGLIA!",
 "m_drain":    "TI SENTI PIÙ DEBOLE...",
 "m_rest":     "TI RIPOSI UN PO'.",
 "m_restno":   "NON PUOI RIPOSARE: CI SONO NEMICI!",
 "m_ishere":   "QUI C'È ",
 "m_bump":     "",
 "m_flee":     "",
 "m_regen":    "",
 "m_sp":       " ",
 "m_slash":    "/",
 "m_already":  "È GIÀ IN USO.",
 "m_bolthit":  "IL FULMINE COLPISCE ",
 "t_title_s":  "LE CRIPTE DI ZENOBIA",
 "m_onstairs": "UNA SCALA SCENDE NEL BUIO (SPAZIO).",
}
for k, v in MSGS.items():
    text(k, v)

# pagine di testo: (colonna, riga, colore, testo)
def page(label, lines):
    out = []
    for (c, r, col, s) in lines:
        b = enc(s)
        assert c >= 1 and c + len(b) <= 37, (label, s, c + len(b))
        assert col < 8 and 1 <= r <= 20, (label, s)
        out += [c, r, col, len(b)] + b
    out.append(0xFF)
    S.append("%s: !byte %s" % (label, ",".join("$%02X" % x for x in out)))

page("pg_title", [
 (10, 2, 7, "LE CRIPTE DI ZENOBIA"),
 (5, 3, 3, "UN ROGUELIKE PER COMMODORE 64"),
 (3, 5, 1, "NEL DECIMO PIANO DELLE CRIPTE"),
 (3, 6, 1, "GIACE L'AMULETO DI ZENOBIA,"),
 (3, 7, 1, "CUSTODITO DA UN DRAGO."),
 (3, 8, 2, "SE MUORI, MUORI PER SEMPRE."),
 (3, 10, 3, "MUOVITI: Q W E  OPPURE JOYSTICK"),
 (3, 11, 3, "         A S D  IN PORTA 2"),
 (3, 12, 3, "         Z X C  (S = ATTENDI)"),
 (3, 13, 3, "SPAZIO/FUOCO: SCENDI LE SCALE"),
 (3, 14, 3, "I: ZAINO  R: RIPOSA  H: AIUTO"),
 (3, 19, 7, "PREMI SPAZIO O FUOCO PER GIOCARE"),
])
page("pg_help", [
 (12, 2, 7, "COME SI GIOCA"),
 (2, 4, 1, "MUOVITI CON Q W E A D Z X C,"),
 (2, 5, 1, "I CURSORI O IL JOYSTICK (PORTA 2)."),
 (2, 6, 1, "CAMMINA CONTRO UN MOSTRO PER"),
 (2, 7, 1, "ATTACCARLO. S: ATTENDI UN TURNO."),
 (2, 9, 1, "GLI OGGETTI SI RACCOLGONO"),
 (2, 10, 1, "CAMMINANDOCI SOPRA. ZAINO (I):"),
 (2, 11, 1, "SCEGLI LA LETTERA, POI U = USA"),
 (2, 12, 1, "OPPURE L = LASCIA."),
 (2, 14, 1, "POZIONI E PERGAMENE SONO IGNOTE"),
 (2, 15, 1, "FINCHÉ NON LE PROVI. MANGIA!"),
 (2, 16, 1, "SPAZIO SULLE SCALE: SCENDI."),
 (2, 17, 1, "R: RIPOSA FINCHÉ NON GUARISCI."),
 (6, 19, 7, "PREMI UN TASTO PER TORNARE"),
])
page("pg_inv_head", [
 (3, 1, 7, "ZAINO"),
])
page("pg_dead", [
 (12, 3, 1, "RIPOSA IN PACE"),
 (10, 5, 3, "QUI GIACE UN EROE"),
 (10, 6, 3, "CHE FU UCCISO DA"),
])
page("pg_win", [
 (7, 3, 7, "HAI VINTO! L'AMULETO DI"),
 (7, 4, 7, "ZENOBIA È FINALMENTE TUO."),
 (4, 6, 1, "LE CRIPTE TREMANO MENTRE RISALI"),
 (4, 7, 1, "VERSO LA LUCE DEL SOLE..."),
])
text("t_piano", "AL PIANO ")
text("t_livello", "LIVELLO RAGGIUNTO: ")
text("t_oro", "ORO RACCOLTO: ")
text("t_punti", "PUNTEGGIO: ")
text("t_again", "SPAZIO O FUOCO: NUOVA PARTITA")
text("t_inv_help", "LETTERA: SCEGLI   SPAZIO: ESCI")
text("t_inv_act", "U: USA  L: LASCIA  ALTRO: ANNULLA")
text("t_inv_empty", "(VUOTO)")
text("t_inhand", " (IN MANO)")
text("t_worn", " (INDOSSATA)")
text("t_x", " X")
text("t_pv", "PV ")
text("t_liv", " LIV ")
text("t_piano2", " PIANO ")
text("t_oro2", " ORO ")
text("t_fame", " FAME")
text("t_debole", " DEBOLE")
text("t_credit", "    (C) 2026 YOUDEV.IT - PER C64 PAL")
text("t_charges", " CARICHE")
text("t_paren_o", " (")
text("t_paren_c", ")")
with open(os.path.join(OUT, "gen_strings.asm"), "w") as f:
    f.write("; *** generato da gen_assets.py: non modificare ***\n")
    f.write("\n".join(S) + "\n")

# ---------------------------------------------------------------- suoni
def fq(hz):
    return int(round(hz * 16777216 / 985248))
NOTE_BASE = {'C':0,'C#':1,'D':2,'D#':3,'E':4,'F':5,'F#':6,'G':7,'G#':8,'A':9,'A#':10,'B':11}
def note(n):
    name, octv = n[:-1], int(n[-1])
    semis = NOTE_BASE[name] + 12*(octv+1) - 69
    return fq(440.0 * 2**(semis/12))

TRI, SAW, PUL, NOI = 0x11, 0x21, 0x41, 0x81
SND = []
def sound(name, voice, ad, sr, pw, steps):
    # steps: (ctrl, freq, slide, frames)
    b = [ad, sr, pw, voice]
    for (ctrl, fr, sl, n) in steps:
        sl &= 0xFFFF
        b += [ctrl, fr & 0xFF, fr >> 8, sl & 0xFF, sl >> 8, n]
    b.append(0)
    SND.append((name, b))

sound("STEP",   0, 0x00, 0x00, 0x08, [(TRI, fq(110), -20, 2)])
sound("BUMP",   0, 0x00, 0x00, 0x08, [(NOI, fq(300), 0, 2)])
sound("HIT",    0, 0x00, 0x09, 0x08, [(NOI, fq(1600), -120, 5)])
sound("MISS",   0, 0x00, 0x05, 0x08, [(NOI, fq(2500), 200, 3)])
sound("KILL",   0, 0x00, 0x0A, 0x08, [(SAW, fq(700), -40, 3), (NOI, fq(900), -60, 8)])
sound("HURT",   1, 0x00, 0x09, 0x08, [(SAW, fq(240), -12, 6), (NOI, fq(500), -20, 4)])
sound("PICKUP", 2, 0x00, 0x08, 0x08, [(TRI, note('E5'), 0, 3), (TRI, note('A5'), 0, 3), (TRI, note('E6'), 0, 5)])
sound("GOLD",   2, 0x00, 0x0A, 0x08, [(PUL, note('B5'), 0, 3), (PUL, note('E6'), 0, 8)])
sound("DOOR",   2, 0x00, 0x04, 0x08, [(SAW, fq(160), 4, 10)])
sound("STAIRS", 2, 0x00, 0x0A, 0x08, [(TRI, fq(900), -14, 28)])
sound("DRINK",  2, 0x00, 0x04, 0x08, [(TRI, note('C5'), 0, 3), (TRI, note('G5'), 0, 3), (TRI, note('D5'), 0, 3), (TRI, note('A5'), 0, 4)])
sound("ZAP",    2, 0x00, 0x09, 0x08, [(PUL, fq(400), 140, 14), (NOI, fq(2000), -60, 8)])
sound("LEVEL",  2, 0x00, 0x0A, 0x08, [(PUL, note('C5'), 0, 4), (PUL, note('E5'), 0, 4), (PUL, note('G5'), 0, 4), (PUL, note('C6'), 0, 10)])
sound("MAGIC",  2, 0x00, 0x0A, 0x08, [(TRI, fq(600), 90, 18)])
sound("DEATH",  1, 0x00, 0x0C, 0x08, [(SAW, fq(400), -3, 70)])
sound("WAKE",   1, 0x00, 0x06, 0x08, [(SAW, fq(140), 6, 6)])

def tune(name, voice, ad, sr, pw, wave, notes, gap=1):
    steps = []
    for (n, dur) in notes:
        if n == 'R':
            steps.append((wave & 0xFE, 0, 0, dur))
        else:
            steps.append((wave, note(n), 0, dur - gap))
            steps.append((wave & 0xFE, note(n), 0, gap))
    sound(name, voice, ad, sr, pw, steps)

Q = 12  # frame per croma
tune("TITLE_A", 0, 0x09, 0x46, 0x06, PUL, [
 ('A4',Q),('C5',Q),('E5',Q),('A5',2*Q),('G5',Q),('E5',Q),('F5',2*Q),('E5',Q),('D5',Q),('E5',3*Q),('R',Q),
 ('A4',Q),('C5',Q),('E5',Q),('A5',2*Q),('B5',Q),('C6',Q),('B5',2*Q),('G#5',Q),('E5',Q),('A5',4*Q)])
tune("TITLE_B", 1, 0x0A, 0x38, 0x08, TRI, [
 ('A2',4*Q),('A2',4*Q),('D3',4*Q),('E3',4*Q),
 ('A2',4*Q),('F3',4*Q),('E3',4*Q),('A2',4*Q)])
tune("DIRGE", 0, 0x0A, 0x48, 0x08, TRI, [
 ('E4',2*Q),('D4',Q),('C4',2*Q),('B3',Q),('A3',4*Q),('R',Q),('E3',2*Q),('A3',5*Q)])
tune("FANFARE", 0, 0x08, 0x48, 0x06, PUL, [
 ('C5',Q//2),('C5',Q//2),('C5',Q//2),('G5',2*Q),('E5',Q),('G5',Q),('C6',4*Q)])

A = ["; *** generato da gen_assets.py: non modificare ***"]
for i, (name, b) in enumerate(SND):
    A.append("SND_%s = %d" % (name, i))
for name, b in SND:
    A.append("snd_%s: !byte %s" % (name.lower(), ",".join("$%02X" % x for x in b)))
A.append("snd_lo: !byte " + ",".join("<snd_%s" % n.lower() for n, _ in SND))
A.append("snd_hi: !byte " + ",".join(">snd_%s" % n.lower() for n, _ in SND))
with open(os.path.join(OUT, "gen_sfx.asm"), "w") as f:
    f.write("\n".join(A) + "\n")

print("tile:", len(TILES), "sprite:", len(SPRITES), "suoni:", len(SND))
