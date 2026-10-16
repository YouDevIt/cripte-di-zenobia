; =====================================================================
;  Tabelle di gioco
; =====================================================================

; direzioni: W E D C X Z A Q (N, NE, E, SE, S, SO, O, NO)
dir_keys: !byte 'W','E','D','C','X','Z','A','Q'
dir_dx:   !byte 0, 1, 1, 1, 0, $ff, $ff, $ff
dir_dy:   !byte $ff, $ff, 0, 1, 1, 1, 0, $ff

; ---- mostri: ratto pipistrello serpente coboldo goblin scheletro
;              orco spettro troll drago
mt_tile:  !byte T_RAT, T_BAT, T_SNAKE, T_KOBOLD, T_GOBLIN, T_SKEL, T_ORC, T_WRAITH, T_TROLL, T_DRAGON
mt_hp:    !byte 3, 4, 6, 7, 10, 14, 20, 22, 36, 60
mt_att:   !byte 1, 2, 2, 3, 4, 5, 6, 7, 8, 10
mt_dmin:  !byte 1, 1, 1, 1, 2, 2, 3, 3, 4, 4
mt_dmax:  !byte 3, 3, 4, 5, 6, 7, 9, 8, 12, 14
mt_def:   !byte 1, 3, 2, 2, 3, 4, 4, 5, 5, 7
mt_xp:    !byte 2, 3, 5, 6, 10, 16, 25, 40, 70, 250
mt_depth: !byte 1, 1, 2, 2, 3, 4, 5, 6, 7, 99
mt_flags: !byte 0, MA_ERRATIC, 0, 0, 0, 0, 0, MA_DRAIN, MA_REGEN, 0

; ---- esperienza per passare al livello successivo (indice = livello-1)
xp_lo: !byte <10,<25,<50,<90,<150,<250,<400,<650,<1000,<1500,<2200,<3000,<4000,<5500
xp_hi: !byte >10,>25,>50,>90,>150,>250,>400,>650,>1000,>1500,>2200,>3000,>4000,>5500

; ---- oggetti
item_class_tab:
    !byte IC_GOLD, IC_GOLD, IC_GOLD, IC_GOLD, IC_GOLD, IC_GOLD
    !byte IC_POTION, IC_POTION, IC_POTION, IC_POTION
    !byte IC_SCROLL, IC_SCROLL, IC_SCROLL
    !byte IC_FOOD, IC_FOOD
    !byte IC_WEAPON, IC_WEAPON
    !byte IC_ARMOR, IC_ARMOR
    !byte IC_WAND
potion_sub_tab: !byte 0, 0, 0, 1, 2, 2, 3, 4
scroll_sub_tab: !byte 0, 0, 1, 1, 2, 3
pot_colors:     !byte 2, 3, 4, 5, 7      ; rossa azzurra viola verde gialla

; pugnale mazza spada ascia
wpn_min: !byte 1, 2, 2, 3
wpn_max: !byte 4, 6, 8, 10
; cuoio maglia piastre
arm_def: !byte 2, 4, 6

class_tile:
    !byte 0, T_POTION, T_SCROLL, T_SWORD, T_ARMOR, T_FOOD, T_GOLD, T_WAND, T_AMULET
; indice del nome base per classe
name_base:
    !byte 0, 0, 1, 2, 6, 9, 0, 10, 11
inm_lo: !byte <in_potion, <in_scroll, <in_dagger, <in_mace, <in_sword, <in_axe
        !byte <in_leather, <in_chain, <in_plate, <in_food, <in_wand, <in_amulet
inm_hi: !byte >in_potion, >in_scroll, >in_dagger, >in_mace, >in_sword, >in_axe
        !byte >in_leather, >in_chain, >in_plate, >in_food, >in_wand, >in_amulet

; righe da 40
row40_lo:
!for .r, 0, 24 { !byte <(.r*40) }
row40_hi:
!for .r, 0, 24 { !byte >(.r*40) }

!if TEST {
; script di test: (tasto, frame)
test_script:
    !source "test_script.asm"
    !byte $ff
}
