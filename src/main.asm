; =====================================================================
;  LE CRIPTE DI ZENOBIA
;  Roguelike con morte permanente per Commodore 64 (PAL)
;  Assemblatore: ACME
; =====================================================================
!cpu 6510
; build: acme -f cbm -o cripte.prg main.asm

!ifndef TEST { TEST = 0 }
!ifndef TEST_MON { TEST_MON = 6 }

!source "defs.asm"

; ---------------------------------------------------------------- BSS
!macro var ~.n, .s {
.n = vptr
!set vptr = vptr + .s
}
!set vptr = $9D00
+var ~spr_xl, 8
+var ~spr_xmsb, 1
+var ~spr_y, 8
+var ~spr_col, 8
+var ~spr_ptr, 8
+var ~spr_ena, 1
+var ~spr_mc, 1
+var ~spr_xe, 1
+var ~spr_ye, 1
+var ~irq_n, 4
+var ~sv_on, 3
+var ~sv_pl, 3
+var ~sv_ph, 3
+var ~sv_fr, 3
+var ~sv_fl, 3
+var ~sv_fh, 3
+var ~sv_sl, 3
+var ~sv_sh, 3
+var ~sv_ctrl, 3
+var ~sv_req, 3
+var ~msgbuf, 40
+var ~m_type, MAXMON
+var ~m_x, MAXMON
+var ~m_y, MAXMON
+var ~m_hp, MAXMON
+var ~m_flags, MAXMON
+var ~i_cls, MAXITEM
+var ~i_sub, MAXITEM
+var ~i_val, MAXITEM
+var ~i_x, MAXITEM
+var ~i_y, MAXITEM
+var ~i_tile, MAXITEM
+var ~i_col, MAXITEM
+var ~v_cls, INVSIZE
+var ~v_sub, INVSIZE
+var ~v_val, INVSIZE
+var ~v_qty, INVSIZE
+var ~r_x, MAXROOM
+var ~r_y, MAXROOM
+var ~r_w, MAXROOM
+var ~r_h, MAXROOM
+var ~r_kind, MAXROOM
+var ~pot_perm, 5
+var ~pot_known, 5
+var ~scr_perm, 4
+var ~scr_known, 4
+var ~p_hp, 1
+var ~p_maxhp, 1
+var ~p_lev, 1
+var ~p_xp, 2
+var ~p_gold, 2
+var ~p_depth, 1
+var ~p_food, 2
+var ~p_str, 1
+var ~p_weap, 1
+var ~p_armor, 1
+var ~p_turns, 2
+var ~p_regen, 1
+var ~killer, 1
+var ~game_over, 1
+var ~won, 1
+var ~spawn_ctr, 1
+var ~key_time, 1
+var ~rn_n, 1
+var ~rn_r, 1
+var ~rn_x, 1
+var ~sim_cnt, 1
+var ~inv_sel, 1
+var ~start_room, 1
+var ~stair_room, 1
+var ~num_digits, 6
+var ~fx_x, 1
+var ~fx_xh, 1
+var ~fx_y, 1
+var ~fx_ok, 1
+var ~save_a, 1
+var ~cnt_a, 1
+var ~cnt_b, 1
+var ~tmpw, 2
+var ~starve_ctr, 1
+var ~rest_cnt, 1
+var ~name_art, 1
!if vptr > $A000 { !error "BSS troppo grande" }

; ---------------------------------------------------------------- BASIC
* = $0801
    !byte $0b,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00   ; 10 SYS2061
* = $080d
    jmp start

!source "irq.asm"
!source "video.asm"
!source "input.asm"
!source "util.asm"
!source "dungeon.asm"
!source "game.asm"
!source "data.asm"
!source "gen/gen_tables.asm"
!source "gen/gen_strings.asm"
!source "gen/gen_sfx.asm"

charset_data:
    !binary "gen/charset.bin"
sprite_data:
    !binary "gen/sprites.bin"
sprite_data_end:

!if * > $8000 { !error "programma troppo grande" }
