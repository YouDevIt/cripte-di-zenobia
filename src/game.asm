; =====================================================================
;  Logica di gioco
; =====================================================================

!zone start
start:
    ldx #$ff
    txs
    lda #116
    sta camx
    sta tgtx
    lda #180
    sta camy
    sta tgty
    lda #0
    sta camx+1
    sta tgtx+1
    sta camy+1
    sta tgty+1
    lda #14
    sta front_cx
    lda #22
    sta front_cy
    jsr hw_init
    lda #$5a
    sta rng
    lda #$a5
    sta rng+1
!if TEST {
    jsr test_init
}
title:
    jsr title_screen
new_game:
    jsr init_player
    jsr msg_clear_log
    jsr enter_level
!if TEST {
    jsr test_setup
}
    +msg m_welcome
    jsr msg_flush
    +msg m_welcome2
    jsr msg_flush

!zone game_loop
game_loop:
    jsr status_update
    jsr get_command
    pha
    jsr msg_age
    lda #0
    sta took_turn
    pla
    jsr do_command
    lda took_turn
    beq .check
    jsr view_sync
    jsr monsters_act
    lda game_over
    bne .check
    jsr upkeep
    jsr view_sync
.check:
    lda game_over
    beq +
    jmp player_dead
+   lda won
    beq game_loop
    jmp player_won

!zone get_command
get_command:
-   jsr wait_frame
    jsr poll_key
    beq -
    rts

; ---------------------------------------------------------------- titolo
!zone title_screen
title_screen:
    lda #1
    sta spr_hide
    jsr msg_clear_log
    lda #<t_title_s
    sta str_ptr
    lda #>t_title_s
    sta str_ptr+1
    lda #7
    sta tmp5
    lda #0
    ldx #10
    jsr status_text
    lda #<t_credit
    sta str_ptr
    lda #>t_credit
    sta str_ptr+1
    lda #11
    sta tmp5
    lda #2
    ldx #0
    jsr status_text
    jsr page_begin
    lda #<pg_title
    sta str_ptr
    lda #>pg_title
    sta str_ptr+1
    jsr page_draw
    ; sfilata di mostri
    lda #0
    sta cnt_a
-   ldx cnt_a
    lda mt_tile,x
    sta tmp4
    txa
    asl
    clc
    adc cnt_a
    adc #5
    tax
    lda #17
    jsr page_tile
    inc cnt_a
    lda cnt_a
    cmp #10
    bne -
    jsr page_show
    lda #SND_TITLE_A
    jsr play_sound
    lda #SND_TITLE_B
    jsr play_sound
-   jsr wait_key
    cmp #' '
    bne -
    ; seme casuale dal tempo di attesa
!if TEST { rts }
    lda frame
    eor rng
    eor $d012
    sta rng
    lda $dc04
    eor rng+1
    ora #1
    sta rng+1
    rts

; ---------------------------------------------------------------- nuova partita
!zone init_player
init_player:
    lda #15
    sta p_hp
    sta p_maxhp
    lda #1
    sta p_lev
    lda #0
    sta p_xp
    sta p_xp+1
    sta p_gold
    sta p_gold+1
    sta p_str
    sta p_turns
    sta p_turns+1
    sta p_regen
    sta game_over
    sta won
    sta hero_face
    sta hero_frame
    sta starve_ctr
    lda #1
    sta p_depth
    lda #<1300
    sta p_food
    lda #>1300
    sta p_food+1
    ldx #INVSIZE-1
    lda #0
-   sta v_cls,x
    sta v_val,x
    sta v_sub,x
    sta v_qty,x
    dex
    bpl -
    lda #IC_WEAPON
    sta v_cls
    lda #IC_ARMOR
    sta v_cls+1
    lda #IC_FOOD
    sta v_cls+2
    lda #1
    sta v_qty
    sta v_qty+1
    sta v_qty+2
    lda #0
    sta p_weap
    lda #1
    sta p_armor
    ; identificazione: permutazioni casuali
    ldx #4
-   txa
    sta pot_perm,x
    lda #0
    sta pot_known,x
    dex
    bpl -
    ldx #3
-   txa
    sta scr_perm,x
    lda #0
    sta scr_known,x
    dex
    bpl -
    ldx #4
-   inx
    txa
    dex
    jsr rnd_n               ; j in 0..x
    tay
    lda pot_perm,x
    pha
    lda pot_perm,y
    sta pot_perm,x
    pla
    sta pot_perm,y
    dex
    bne -
    ldx #3
-   inx
    txa
    dex
    jsr rnd_n
    tay
    lda scr_perm,x
    pha
    lda scr_perm,y
    sta scr_perm,x
    pla
    sta scr_perm,y
    dex
    bne -
    rts

!zone enter_level
enter_level:
    lda #1
    sta spr_hide
    jsr gen_level
    jsr camera_jump
    jsr hero_sprite
    lda #0
    sta spr_hide
    jmp status_update

; ---------------------------------------------------------------- comandi
!zone do_command
do_command:
    ldx #7
-   cmp dir_keys,x
    beq .move
    dex
    bpl -
    cmp #'S'
    beq .wait
    cmp #' '
    beq .action
    cmp #'I'
    bne +
    jmp inventory
+   cmp #'R'
    bne +
    jmp rest
+   cmp #'H'
    bne +
    jmp help
+
!if TEST {
    cmp #'*'
    bne +
    lda #1
    sta won
    rts
+   cmp #'.'
    bne +
    lda p_depth
    cmp #MAXDEPTH
    bcs +
    jmp descend
+
}
    rts
.move:
    lda dir_dx,x
    sta dir_x
    lda dir_dy,x
    sta dir_y
    jmp player_move
.wait:
    inc took_turn
    rts
.action:
    lda p_y
    jsr row_ptrs
    ldy p_x
    lda (pm),y
    and #$0f
    cmp #TR_STAIRS
    bne .wait
    jmp descend

; ---------------------------------------------------------------- movimento
!zone player_move
player_move:
    lda p_x
    clc
    adc dir_x
    sta gx
    lda p_y
    clc
    adc dir_y
    sta gy
    jsr row_ptrs
    ldy gx
    lda (pmo),y
    beq +
    tax
    dex
    stx cur_mon
    jmp player_attack
+   lda (pm),y
    and #$0f
    sta tmp3
    jsr diag_blocked
    bcc +
    jmp .bump
+   lda tmp3
    cmp #TR_DOORC
    bne +
    lda gy
    jsr row_ptrs
    ldy gx
    lda (pm),y
    and #$f0
    ora #TR_DOORO
    sta (pm),y
    +msg m_door
    jsr msg_flush
    lda #SND_DOOR
    jsr play_sound
    lda #1
    sta dirty
    inc took_turn
    rts
+   jsr is_passable
    bcs +
    jmp .bump
+   ; spostamento
    lda gx
    sta p_x
    lda gy
    sta p_y
    lda dir_x
    beq ++
    bmi +
    lda #0
    sta hero_face
    beq ++
+   lda #1
    sta hero_face
++  lda hero_frame
    eor #1
    sta hero_frame
    jsr hero_sprite
    jsr set_cam_target
    jsr fov_update
    lda #SND_STEP
    jsr play_sound
    inc took_turn
    lda p_y
    jsr row_ptrs
    ldy p_x
    lda (pit),y
    beq +
    jmp pickup
+   lda (pm),y
    and #$0f
    cmp #TR_STAIRS
    bne +
    +msg m_onstairs
    jmp msg_flush
+   rts
.bump:
    lda #SND_BUMP
    jmp play_sound

; tmp3 = terreno destinazione: C=1 se mossa diagonale bloccata da una porta
!zone diag_blocked
diag_blocked:
    lda dir_x
    beq .ok
    lda dir_y
    beq .ok
    lda tmp3
    jsr is_door
    bcs .blk
    lda p_y
    jsr row_ptrs
    ldy p_x
    lda (pm),y
    and #$0f
    jsr is_door
    bcs .blk
.ok:
    clc
    rts
.blk:
    sec
    rts

; A = terreno: C=1 se porta
!zone is_door
is_door:
    cmp #TR_DOORC
    beq +
    cmp #TR_DOORO
    beq +
    clc
    rts
+   sec
    rts

; tmp3 = terreno: C=1 se calpestabile
!zone is_passable
is_passable:
    lda tmp3
    cmp #TR_FLOOR
    beq +
    cmp #TR_CORR
    beq +
    cmp #TR_DOORO
    beq +
    cmp #TR_STAIRS
    beq +
    clc
    rts
+   sec
    rts

; ---------------------------------------------------------------- combattimento
; statistiche arma: tmp0=min tmp1=max tmp2=incantamento
!zone weapon_stats
weapon_stats:
    ldx p_weap
    bmi .fists
    ldy v_sub,x
    lda wpn_min,y
    sta tmp0
    lda wpn_max,y
    sta tmp1
    lda v_val,x
    sta tmp2
    rts
.fists:
    lda #1
    sta tmp0
    lda #2
    sta tmp1
    lda #0
    sta tmp2
    rts

; A = difesa del giocatore
!zone player_def
player_def:
    ldx p_armor
    bmi .none
    ldy v_sub,x
    lda arm_def,y
    clc
    adc v_val,x
    adc #1
    rts
.none:
    lda #1
    rts

!zone player_attack
player_attack:
    jsr weapon_stats
    lda #20
    jsr rnd_n
    sec
    adc p_lev
    clc
    adc tmp2
    sta roll
    ldx cur_mon
    ldy m_type,x
    lda mt_def,y
    clc
    adc #6
    sta tmp3
    lda roll
    cmp tmp3
    bcc .miss
    lda tmp0
    ldx tmp1
    jsr rnd_range
    clc
    adc tmp2
    adc p_str
    sta dmg
    ldx cur_mon
    lda m_x,x
    sta gx
    lda m_y,x
    sta gy
    lda m_hp,x
    cmp dmg
    beq .kill
    bcc .kill
    jsr msg_clear
    +msg m_hit
    jsr msg_mon
    +msg m_dot
    jsr msg_flush
    lda #SND_HIT
    jsr play_sound
pa_wound:
    ldx cur_mon
    lda m_flags,x
    ora #MF_AWAKE
    sta m_flags,x
    lda m_hp,x
    sec
    sbc dmg
    sta m_hp,x
    lda #1
    jsr fx_spark
    lda #1
    sta tmp5
    lda dmg
    jsr fx_number
    inc took_turn
    jmp fx_wait
.kill:
    jsr kill_monster
    inc took_turn
    rts
.miss:
    jsr msg_clear
    +msg m_miss
    jsr msg_mon
    +msg m_dot
    jsr msg_flush
    lda #SND_MISS
    jsr play_sound
    ldx cur_mon
    lda m_flags,x
    ora #MF_AWAKE
    sta m_flags,x
    inc took_turn
    lda #8
    jmp delay

; nome del mostro cur_mon nel messaggio
!zone msg_mon
msg_mon:
    ldx cur_mon
    ldy m_type,x
    lda mname_lo,y
    sta str_ptr
    lda mname_hi,y
    sta str_ptr+1
    jmp msg_str

; danno dmg al mostro cur_mon da fonte magica (gx,gy già impostati)
!zone damage_monster
damage_monster:
    ldx cur_mon
    lda m_hp,x
    cmp dmg
    beq kill_monster
    bcc kill_monster
    jmp pa_wound

!zone kill_monster
kill_monster:
    jsr msg_clear
    +msg m_kill
    jsr msg_mon
    +msg m_excl
    jsr msg_flush
    ldx cur_mon
    lda #0
    sta m_flags,x
    lda m_y,x
    jsr row_ptrs
    ldy m_x,x
    lda #0
    sta (pmo),y
    lda #1
    sta dirty
    ldy m_type,x
    lda mt_xp,y
    clc
    adc p_xp
    sta p_xp
    bcc +
    inc p_xp+1
+   lda #SND_KILL
    jsr play_sound
    lda #7
    jsr fx_spark
    lda #1
    sta tmp5
    lda dmg
    jsr fx_number
    jsr fx_wait
    jsr view_sync
    jmp check_levelup

!zone check_levelup
check_levelup:
    ldx p_lev
    cpx #15
    bcs .done
    lda p_xp+1
    cmp xp_hi-1,x
    bcc .done
    bne .up
    lda p_xp
    cmp xp_lo-1,x
    bcc .done
.up:
    inc p_lev
    lda #6
    jsr rnd_n
    clc
    adc #3
    sta tmp0
    clc
    adc p_maxhp
    bcs .done
    cmp #250
    bcs .done
    sta p_maxhp
    lda p_hp
    clc
    adc tmp0
    cmp p_maxhp
    bcc +
    lda p_maxhp
+   sta p_hp
    jsr msg_clear
    +msg m_levelup
    lda p_lev
    jsr msg_byte
    +msg m_excl
    jsr msg_flush
    lda #SND_LEVEL
    jsr play_sound
    jsr status_update
    jmp check_levelup
.done:
    rts

; ---------------------------------------------------------------- mostri
!zone monsters_act
monsters_act:
    lda #0
    sta cur_mon
-   ldx cur_mon
    lda m_flags,x
    bpl +
    jsr monster_turn
    lda game_over
    bne .end
+   inc cur_mon
    lda cur_mon
    cmp #MAXMON
    bne -
.end:
    rts

!zone monster_turn
monster_turn:
    ldx cur_mon
    ldy m_type,x
    lda mt_flags,y
    and #MA_REGEN
    beq +
    lda m_hp,x
    cmp mt_hp,y
    bcs +
    inc m_hp,x
+   lda m_x,x
    sta gx
    lda m_y,x
    sta gy
    lda m_flags,x
    and #MF_AWAKE
    bne .awake
    jsr tile_visible
    bcc .ret
    lda #3
    jsr rnd_n
    bne .ret
    ldx cur_mon
    lda m_flags,x
    ora #MF_AWAKE
    sta m_flags,x
.ret:
    rts
.awake:
    lda p_x
    sec
    sbc gx
    sta gdx
    lda p_y
    sec
    sbc gy
    sta gdy
    lda gdx
    jsr abs
    cmp #2
    bcs .chase
    lda gdy
    jsr abs
    cmp #2
    bcs .chase
    jmp monster_attack
.chase:
    ldx cur_mon
    ldy m_type,x
    lda mt_flags,y
    and #MA_ERRATIC
    beq .direct
    lda #2
    jsr rnd_n
    bne .direct
    lda #3
    jsr rnd_n
    sec
    sbc #1
    sta dir_x
    lda #3
    jsr rnd_n
    sec
    sbc #1
    sta dir_y
    jmp try_move
.direct:
    lda gdx
    jsr sign
    sta dir_x
    lda gdy
    jsr sign
    sta dir_y
    jsr try_move
    bcs .done
    lda dir_x
    beq .vert
    lda dir_y
    beq .horiz
    ; diagonale fallita: prova i due assi
    lda dir_y
    pha
    lda #0
    sta dir_y
    jsr try_move
    pla
    sta dir_y
    bcs .done
    lda dir_x
    pha
    lda #0
    sta dir_x
    jsr try_move
    pla
    sta dir_x
    rts
.vert:
    lda #1
    sta dir_x
    jsr try_move
    bcs .done
    lda #$ff
    sta dir_x
    jmp try_move
.horiz:
    lda #1
    sta dir_y
    jsr try_move
    bcs .done
    lda #$ff
    sta dir_y
    jmp try_move
.done:
    rts

; mostro cur_mon prova a muoversi di dir_x,dir_y: C=1 riuscito
!zone try_move
try_move:
    lda dir_x
    ora dir_y
    bne +
    clc
    rts
+
    ldx cur_mon
    lda m_x,x
    clc
    adc dir_x
    sta tmp4
    lda m_y,x
    clc
    adc dir_y
    sta tmp5
    cmp p_y
    bne +
    lda tmp4
    cmp p_x
    beq .fail
+   ; terreno di partenza (per le porte in diagonale)
    lda dir_x
    beq .nodiag
    lda dir_y
    beq .nodiag
    lda m_y,x
    jsr row_ptrs
    ldy m_x,x
    lda (pm),y
    and #$0f
    jsr is_door
    bcs .fail
    lda tmp5
    jsr row_ptrs
    ldy tmp4
    lda (pm),y
    and #$0f
    jsr is_door
    bcs .fail
.nodiag:
    lda tmp5
    jsr row_ptrs
    ldy tmp4
    lda (pmo),y
    bne .fail
    lda (pm),y
    and #$0f
    sta tmp3
    cmp #TR_DOORC
    bne +
    lda (pm),y
    and #$f0
    ora #TR_DOORO
    sta (pm),y
    lda #1
    sta dirty
    sec
    rts
+   jsr is_passable
    bcc .fail
    ldx cur_mon
    lda m_y,x
    jsr row_ptrs
    ldy m_x,x
    lda #0
    sta (pmo),y
    lda tmp4
    sta m_x,x
    lda tmp5
    sta m_y,x
    jsr row_ptrs
    ldy tmp4
    inx
    txa
    sta (pmo),y
    lda #1
    sta dirty
    sec
    rts
.fail:
    clc
    rts

!zone monster_attack
monster_attack:
    jsr view_sync
    ldx cur_mon
    ldy m_type,x
    lda #20
    jsr rnd_n
    sec
    adc mt_att,y
    sta roll
    jsr player_def
    clc
    adc #6
    sta tmp3
    ldx cur_mon
    ldy m_type,x
    lda roll
    cmp tmp3
    bcs .hit
    jsr msg_clear
    jsr msg_mon
    +msg m_missyou
    jsr msg_flush
    lda #SND_MISS
    jsr play_sound
    lda #8
    jmp delay
.hit:
    lda mt_dmin,y
    pha
    lda mt_dmax,y
    tax
    pla
    jsr rnd_range
    sta dmg
    jsr msg_clear
    jsr msg_mon
    +msg m_hitsyou
    jsr msg_flush
    lda p_x
    sta gx
    lda p_y
    sta gy
    lda #10
    jsr fx_spark
    lda #10
    sta tmp5
    lda dmg
    jsr fx_number
    lda #SND_HURT
    jsr play_sound
    lda p_hp
    cmp dmg
    beq .dead
    bcc .dead
    sbc dmg
    sta p_hp
    ; risucchio dello spettro
    ldx cur_mon
    ldy m_type,x
    lda mt_flags,y
    and #MA_DRAIN
    beq +
    lda #3
    jsr rnd_n
    bne +
    lda p_maxhp
    cmp #8
    bcc +
    dec p_maxhp
    lda p_hp
    cmp p_maxhp
    bcc ++
    lda p_maxhp
    sta p_hp
++  +msg m_drain
    jsr msg_flush
+   jsr status_update
    jmp fx_wait
.dead:
    lda #0
    sta p_hp
    ldx cur_mon
    lda m_type,x
    sta killer
    lda #1
    sta game_over
    jsr status_update
    jmp fx_wait

; ---------------------------------------------------------------- turno
!zone upkeep
upkeep:
    inc p_turns
    bne +
    inc p_turns+1
+   ; fame
    lda p_food
    ora p_food+1
    beq .starve
    lda p_food
    bne +
    dec p_food+1
+   dec p_food
    lda p_food+1
    cmp #>300
    bne +
    lda p_food
    cmp #<300
    bne .regen
    +msg m_hungry
    jsr msg_flush
    jmp .regen
+   cmp #0
    bne .regen
    lda p_food
    cmp #100
    bne .regen
    +msg m_weak
    jsr msg_flush
.starve:
    inc starve_ctr
    lda starve_ctr
    cmp #4
    bcc .spawn
    lda #0
    sta starve_ctr
    +msg m_starve
    jsr msg_flush
    dec p_hp
    bne .spawn
    lda #10
    sta killer
    lda #1
    sta game_over
    rts
.regen:
    ; nota: 300 > 255, la soglia "fame" con byte alto 1 è gestita in status
    inc p_regen
    lda p_lev
    asl
    sta tmp0
    lda #22
    sec
    sbc tmp0
    cmp #4
    bcs +
    lda #4
+   cmp p_regen
    beq +
    bcs .spawn
+   lda #0
    sta p_regen
    lda p_hp
    cmp p_maxhp
    bcs .spawn
    inc p_hp
.spawn:
    inc spawn_ctr
    lda spawn_ctr
    cmp #150
    bcc .done
    lda #0
    sta spawn_ctr
    jsr pick_room
    cmp p_room
    beq .done
    jsr room_point_free
    bcc .done
    jsr random_montype
    jsr spawn_monster
    bcc .done
    lda m_flags,x
    ora #MF_AWAKE
    sta m_flags,x
.done:
    rts

; ---------------------------------------------------------------- generazione
; A = tipo mostro casuale adatto al piano
!zone random_montype
random_montype:
-   lda #9
    jsr rnd_n
    tax
    lda mt_depth,x
    cmp p_depth
    beq +
    bcs -
+   clc
    adc #4
    cmp p_depth
    bcc -
    txa
    rts

; A = tipo, gx/gy -> nuovo mostro (C=1, X=indice)
!zone spawn_monster
spawn_monster:
    sta tmp0
    ldx #0
-   lda m_flags,x
    bpl +
    inx
    cpx #MAXMON
    bne -
    clc
    rts
+   lda tmp0
    sta m_type,x
    tay
    lda mt_hp,y
    sta m_hp,x
    lda gx
    sta m_x,x
    lda gy
    sta m_y,x
    lda #10
    jsr rnd_n
    cmp #4
    lda #MF_ALIVE
    bcs +
    ora #MF_AWAKE
+   sta m_flags,x
    lda gy
    jsr row_ptrs
    ldy gx
    inx
    txa
    sta (pmo),y
    dex
    sec
    rts

; A = tipo, accanto a tmpw/tmpw+1
!zone spawn_near
spawn_near:
    sta cnt_b
    ldx #7
-   lda tmpw
    clc
    adc dir_dx,x
    sta gx
    lda tmpw+1
    clc
    adc dir_dy,x
    sta gy
    stx tmp7
    jsr cell_free
    ldx tmp7
    bcs +
    dex
    bpl -
    rts
+   lda cnt_b
    jsr spawn_monster
    bcc +
    lda #MF_ALIVE           ; il drago dorme
    sta m_flags,x
+   rts

; gi, gj, gk = classe, sottotipo, valore casuali
!zone random_item
random_item:
    lda #20
    jsr rnd_n
    tax
    lda item_class_tab,x
    sta gi
    lda #0
    sta gj
    sta gk
    lda gi
    cmp #IC_POTION
    bne +
    lda #8
    jsr rnd_n
    tax
    lda potion_sub_tab,x
    sta gj
    rts
+   cmp #IC_SCROLL
    bne +
    lda #6
    jsr rnd_n
    tax
    lda scroll_sub_tab,x
    sta gj
    rts
+   cmp #IC_WEAPON
    bne +
    lda p_depth
    lsr
    lsr
    clc
    adc #2
    jsr rnd_n
    cmp #4
    bcc ++
    lda #3
++  sta gj
    jmp .ench
+   cmp #IC_ARMOR
    bne +
    lda p_depth
    lsr
    lsr
    clc
    adc #1
    jsr rnd_n
    cmp #3
    bcc ++
    lda #2
++  sta gj
.ench:
    lda #4
    jsr rnd_n
    bne ++
    lda #2
    jsr rnd_n
    clc
    adc #1
    sta gk
++  rts
+   cmp #IC_GOLD
    bne +
    lda p_depth
    asl
    asl
    asl
    clc
    adc #8
    jsr rnd_n
    clc
    adc #5
    sta gk
    rts
+   cmp #IC_WAND
    bne +
    lda #4
    jsr rnd_n
    clc
    adc #3
    sta gk
+   rts

; gi,gj -> tmp1 tile, tmp2 colore
!zone item_visual
item_visual:
    ldx gi
    lda class_tile,x
    sta tmp1
    cpx #IC_WEAPON
    bne +
    lda gj
    and #1
    beq +
    lda #T_AXE
    sta tmp1
+   ldy tmp1
    lda tile_color,y
    sta tmp2
    cpx #IC_POTION
    bne +
    ldy gj
    lda pot_perm,y
    tay
    lda pot_colors,y
    ora #8
    sta tmp2
+   rts

; posa oggetto gi/gj/gk in gx,gy (C=1 se riuscito)
!zone place_item
place_item:
    ldx #0
-   lda i_cls,x
    beq +
    inx
    cpx #MAXITEM
    bne -
    clc
    rts
+   stx cnt_b
    lda gi
    sta i_cls,x
    lda gj
    sta i_sub,x
    lda gk
    sta i_val,x
    lda gx
    sta i_x,x
    lda gy
    sta i_y,x
    jsr item_visual
    ldx cnt_b
    lda tmp1
    sta i_tile,x
    lda tmp2
    sta i_col,x
    lda gy
    jsr row_ptrs
    ldy gx
    inx
    txa
    sta (pit),y
    lda #1
    sta dirty
    sec
    rts

; ---------------------------------------------------------------- oggetti
; nome dell'oggetto gi/gj/gk nel messaggio; name_art=1 con articolo
!zone item_name
item_name:
    ldx gi
    lda name_base,x
    cpx #IC_WEAPON
    beq +
    cpx #IC_ARMOR
    bne ++
+   clc
    adc gj
++  tax
    lda inm_lo,x
    sta str_ptr
    lda inm_hi,x
    sta str_ptr+1
    ldy #0
    lda (str_ptr),y         ; lunghezza articolo
    ldx name_art
    beq +
    lda #0
+   sec                     ; +1 per saltare il byte di lunghezza
    adc str_ptr
    sta str_ptr
    bcc +
    inc str_ptr+1
+   jsr msg_str
    lda gi
    cmp #IC_POTION
    bne .scroll
    lda #' '
    jsr msg_char
    ldx gj
    lda pot_known,x
    beq +
    lda pottyp_lo,x
    sta str_ptr
    lda pottyp_hi,x
    sta str_ptr+1
    jmp msg_str
+   lda pot_perm,x
    tax
    lda potcol_lo,x
    sta str_ptr
    lda potcol_hi,x
    sta str_ptr+1
    jmp msg_str
.scroll:
    cmp #IC_SCROLL
    bne .ench
    lda #' '
    jsr msg_char
    ldx gj
    lda scr_known,x
    beq +
    lda scrtyp_lo,x
    sta str_ptr
    lda scrtyp_hi,x
    sta str_ptr+1
    jmp msg_str
+   lda scr_perm,x
    tax
    lda scrnam_lo,x
    sta str_ptr
    lda scrnam_hi,x
    sta str_ptr+1
    jmp msg_str
.ench:
    cmp #IC_WEAPON
    beq +
    cmp #IC_ARMOR
    bne .wand
+   lda gk
    beq .r
    lda #' '
    jsr msg_char
    lda #'+'
    jsr msg_char
    lda gk
    jmp msg_byte
.wand:
    cmp #IC_WAND
    bne .r
    +msg t_paren_o
    lda gk
    jsr msg_byte
    lda #')'
    jmp msg_char
.r: rts

; carica lo slot X in gi/gj/gk
!zone slot_load
slot_load:
    lda v_cls,x
    sta gi
    lda v_sub,x
    sta gj
    lda v_val,x
    sta gk
    rts

; raccoglie l'oggetto sotto il giocatore
!zone pickup
pickup:
    lda p_y
    jsr row_ptrs
    ldy p_x
    lda (pit),y
    bne +
    rts
+   tax
    dex
    stx cnt_a
    lda i_cls,x
    sta gi
    lda i_sub,x
    sta gj
    lda i_val,x
    sta gk
    lda gi
    cmp #IC_GOLD
    bne .notgold
    lda gk
    clc
    adc p_gold
    sta p_gold
    bcc +
    inc p_gold+1
+   jsr msg_clear
    +msg m_gold1
    lda gk
    jsr msg_byte
    +msg m_gold2
    jsr msg_flush
    lda #SND_GOLD
    jsr play_sound
    jmp remove_item
.notgold:
    cmp #IC_AMULET
    bne +
    lda #1
    sta won
    +msg m_amulet
    jsr msg_flush
    lda #SND_FANFARE
    jsr play_sound
    jmp remove_item
+   jsr inv_add
    bcs +
    jsr msg_clear
    +msg m_full
    jsr msg_flush
    rts
+   jsr msg_clear
    +msg m_pickup
    lda #1
    sta name_art
    jsr item_name
    +msg m_dot
    jsr msg_flush
    lda #SND_PICKUP
    jsr play_sound
    ; (cade in remove_item)
; rimuove l'oggetto cnt_a dal pavimento
remove_item:
    ldx cnt_a
    lda #0
    sta i_cls,x
    lda i_y,x
    jsr row_ptrs
    ldy i_x,x
    lda #0
    sta (pit),y
    lda #1
    sta dirty
    rts

; aggiunge gi/gj/gk allo zaino: C=1 riuscito, X = slot
!zone inv_add
inv_add:
    lda gi
    cmp #IC_POTION
    beq .stack
    cmp #IC_SCROLL
    beq .stack
    cmp #IC_FOOD
    bne .new
.stack:
    ldx #0
-   lda v_cls,x
    cmp gi
    bne +
    lda v_sub,x
    cmp gj
    bne +
    lda v_qty,x
    cmp #99
    bcs +
    inc v_qty,x
    sec
    rts
+   inx
    cpx #INVSIZE
    bne -
.new:
    ldx #0
-   lda v_cls,x
    beq +
    inx
    cpx #INVSIZE
    bne -
    clc
    rts
+   lda gi
    sta v_cls,x
    lda gj
    sta v_sub,x
    lda gk
    sta v_val,x
    lda #1
    sta v_qty,x
    sec
    rts

; consuma una unità dello slot X
!zone consume
consume:
    dec v_qty,x
    bne +
    lda #0
    sta v_cls,x
    cpx p_weap
    bne ++
    lda #$ff
    sta p_weap
++  cpx p_armor
    bne +
    lda #$ff
    sta p_armor
+   rts

; ---------------------------------------------------------------- zaino
!zone inventory
inventory:
    lda #1
    sta spr_hide
    lda #$ff
    sta inv_sel
.draw:
    jsr page_begin
    lda #<pg_inv_head
    sta str_ptr
    lda #>pg_inv_head
    sta str_ptr+1
    jsr page_draw
    lda #0
    sta cnt_a
.line:
    jsr msg_clear
    lda cnt_a
    clc
    adc #'A'
    jsr msg_char
    lda #')'
    jsr msg_char
    lda #' '
    jsr msg_char
    lda #1
    sta tmp5
    ldx cnt_a
    lda v_cls,x
    bne +
    lda #6
    sta tmp5
    +msg t_inv_empty
    jmp .out
+   cpx inv_sel
    bne +
    lda #7
    sta tmp5
+   jsr slot_load
    lda #0
    sta name_art
    jsr item_name
    ldx cnt_a
    lda v_qty,x
    cmp #2
    bcc +
    +msg t_x
    ldx cnt_a
    lda v_qty,x
    jsr msg_byte
+   ldx cnt_a
    cpx p_weap
    bne +
    +msg t_inhand
+   ldx cnt_a
    cpx p_armor
    bne .out
    +msg t_worn
.out:
    lda cnt_a
    clc
    adc #3
    ldx #2
    jsr page_msg
    inc cnt_a
    lda cnt_a
    cmp #INVSIZE
    beq +
    jmp .line
+    jsr msg_clear
    lda inv_sel
    bmi +
    +msg t_inv_act
    jmp ++
+   +msg t_inv_help
++  lda #3
    sta tmp5
    lda #17
    ldx #3
    jsr page_msg
    jsr msg_clear
    jsr page_show
.key:
    jsr wait_key
    ldx inv_sel
    bpl .action
    cmp #'A'
    bcc .exit
    cmp #'A'+INVSIZE
    bcs .exit
    sec
    sbc #'A'
    tax
    lda v_cls,x
    beq .key
    stx inv_sel
    jmp .draw
.action:
    cmp #'U'
    beq .use
    cmp #' '
    beq .use
    cmp #'L'
    beq .drop
    lda #$ff
    sta inv_sel
    jmp .draw
.exit:
    jsr inv_close
    rts
.use:
    jsr inv_close
    ldx inv_sel
    jmp use_item
.drop:
    jsr inv_close
    ldx inv_sel
    jmp drop_item

!zone inv_close
inv_close:
    lda #0
    sta spr_hide
    lda #1
    sta dirty
    jmp view_sync

; ---------------------------------------------------------------- uso oggetti
!zone use_item
use_item:
    stx inv_sel
    jsr slot_load
    inc took_turn
    lda gi
    cmp #IC_POTION
    bne +
    jmp drink
+   cmp #IC_SCROLL
    bne +
    jmp read_scroll
+   cmp #IC_WEAPON
    bne +
    stx p_weap
    jsr msg_clear
    +msg m_wield
    jmp .named
+   cmp #IC_ARMOR
    bne +
    stx p_armor
    jsr msg_clear
    +msg m_wear
.named:
    lda #0
    sta name_art
    jsr item_name
    jmp msg_flush
+   cmp #IC_FOOD
    bne +
    jsr consume
    clc
    lda p_food
    adc #<1100
    sta p_food
    lda p_food+1
    adc #>1100
    sta p_food+1
    cmp #>2000
    bcc ++
    lda #<2000
    sta p_food
    lda #>2000
    sta p_food+1
++  +msg m_eat
    jsr msg_flush
    lda #SND_DRINK
    jmp play_sound
+   cmp #IC_WAND
    bne +
    jmp zap
+   +msg m_amulet
    jmp msg_flush

!zone drink
drink:
    jsr consume
    ldx gj
    lda #1
    sta pot_known,x
    lda #SND_DRINK
    jsr play_sound
    lda p_x
    sta gx
    lda p_y
    sta gy
    lda gj
    bne .vigor
    ; guarigione
    lda #8
    jsr rnd_n
    clc
    adc #8
    adc p_lev
    sta dmg
    clc
    adc p_hp
    bcs +
    cmp p_maxhp
    bcc ++
+   lda p_maxhp
++  sta p_hp
    +msg m_heal
    jsr msg_flush
    lda #5
    sta tmp5
    lda dmg
    jsr fx_number
    jmp fx_wait
.vigor:
    cmp #1
    bne .poison
    lda p_maxhp
    cmp #246
    bcs +
    adc #4
    sta p_maxhp
+   lda p_maxhp
    sta p_hp
    +msg m_vigor
    jmp msg_flush
.poison:
    cmp #2
    bne .str
    lda #5
    jsr rnd_n
    clc
    adc #3
    sta dmg
    +msg m_poison
    jsr msg_flush
    lda #10
    sta tmp5
    lda dmg
    jsr fx_number
    lda p_hp
    cmp dmg
    beq +
    bcc +
    sbc dmg
    sta p_hp
    jmp fx_wait
+   lda #0
    sta p_hp
    lda #11
    sta killer
    lda #1
    sta game_over
    jmp fx_wait
.str:
    cmp #3
    bne .exp
    inc p_str
    +msg m_strength
    jmp msg_flush
.exp:
    +msg m_exper
    jsr msg_flush
    ldx p_lev
    cpx #15
    bcs +
    lda xp_lo-1,x
    sta p_xp
    lda xp_hi-1,x
    sta p_xp+1
    jsr check_levelup
+   rts

!zone read_scroll
read_scroll:
    jsr consume
    ldx gj
    lda #1
    sta scr_known,x
    lda #SND_MAGIC
    jsr play_sound
    lda gj
    bne .tele
    jsr reveal_map
    +msg m_map
    jmp msg_flush
.tele:
    cmp #1
    bne .sharp
    +msg m_teleport
    jsr msg_flush
-   jsr pick_room
    cmp p_room
    beq -
    jsr room_point_free
    bcc -
    lda gx
    sta p_x
    lda gy
    sta p_y
    jsr fov_update
    jsr camera_jump
    rts
.sharp:
    cmp #2
    bne .prot
    ldx p_weap
    bmi .nothing
    inc v_val,x
    +msg m_sharp
    jmp msg_flush
.prot:
    ldx p_armor
    bmi .nothing
    inc v_val,x
    +msg m_protect
    jmp msg_flush
.nothing:
    +msg m_nothing
    jmp msg_flush

; bacchetta del fulmine
!zone zap
zap:
    lda v_val,x
    bne +
    +msg m_nocharge
    jmp msg_flush
+   +msg m_whichdir
    jsr msg_flush
    jsr wait_key
    ldx #7
-   cmp dir_keys,x
    beq +
    dex
    bpl -
    dec took_turn
    +msg m_cancel
    jmp msg_flush
+   lda dir_dx,x
    sta dir_x
    lda dir_dy,x
    sta dir_y
    ldx inv_sel
    dec v_val,x
    +msg m_zap
    jsr msg_flush
    lda #SND_ZAP
    jsr play_sound
    ; traccia il raggio
    lda p_x
    sta gx
    lda p_y
    sta gy
    lda #0
    sta cnt_a               ; caselle percorse
    lda #$ff
    sta cur_mon
.trace:
    lda gx
    clc
    adc dir_x
    sta tmp4
    lda gy
    clc
    adc dir_y
    sta tmp5
    jsr row_ptrs
    ldy tmp4
    lda (pm),y
    and #$0f
    sta tmp3
    jsr is_passable
    bcc .stop
    lda tmp4
    sta gx
    lda tmp5
    sta gy
    inc cnt_a
    lda (pmo),y
    beq +
    tax
    dex
    stx cur_mon
    jmp .stop
+   lda cnt_a
    cmp #9
    bne .trace
.stop:
    ; animazione del proiettile (sprite 3)
    lda gx
    pha
    lda gy
    pha
    lda p_x
    sta gx
    lda p_y
    sta gy
    jsr fx_pos
    pla
    sta gy
    pla
    sta gx
    lda #SP_BOLT
    sta spr_ptr+3
    lda #7
    sta spr_col+3
    ldx #3
    jsr fx_place
    lda spr_ena
    ora #8
    sta spr_ena
    lda cnt_a
    asl
    asl
    sta cnt_b
    beq .anim_end
.anim:
    jsr wait_frame
    lda dir_x
    asl
    asl                     ; 4*dx con segno
    pha
    clc
    adc fx_x
    sta fx_x
    pla
    bmi +
    lda fx_xh
    adc #0
    jmp ++
+   lda fx_xh
    adc #$ff
++  and #1
    sta fx_xh
    lda dir_y
    asl
    asl
    clc
    adc fx_y
    sta fx_y
    cmp #100
    bcc .anim_end
    cmp #236
    bcs .anim_end
    ldx #3
    jsr fx_place
    dec cnt_b
    bne .anim
.anim_end:
    lda spr_ena
    and #%11110111
    sta spr_ena
    lda cur_mon
    bmi .done
    lda #10
    jsr rnd_n
    clc
    adc #6
    sta dmg
    jsr msg_clear
    +msg m_bolthit
    jsr msg_mon
    +msg m_dot
    jsr msg_flush
    lda #SND_HIT
    jsr play_sound
    jmp damage_monster
.done:
    rts

!zone drop_item
drop_item:
    stx inv_sel
    lda p_y
    jsr row_ptrs
    ldy p_x
    lda (pit),y
    bne .noroom
    lda (pm),y
    and #$0f
    cmp #TR_STAIRS
    beq .noroom
    jsr slot_load
    lda p_x
    sta gx
    lda p_y
    sta gy
    jsr place_item
    bcc .noroom
    ldx inv_sel
    jsr consume
    jsr msg_clear
    +msg m_drop
    lda #1
    sta name_art
    jsr item_name
    +msg m_dot
    jsr msg_flush
    inc took_turn
    rts
.noroom:
    +msg m_noroom
    jmp msg_flush

; ---------------------------------------------------------------- riposo
; C=1 se un mostro sveglio è in vista
!zone enemy_in_view
enemy_in_view:
    ldx #MAXMON-1
-   stx cnt_b
    lda m_flags,x
    bpl +
    and #MF_AWAKE
    beq +
    lda m_x,x
    sta gx
    lda m_y,x
    sta gy
    jsr tile_visible
    bcs .yes
+   ldx cnt_b
    dex
    bpl -
    clc
.yes:
    rts

!zone rest
rest:
    jsr enemy_in_view
    bcc +
    +msg m_restno
    jmp msg_flush
+   +msg m_rest
    jsr msg_flush
    lda #0
    sta rest_cnt
.loop:
    jsr monsters_act
    lda game_over
    bne .end
    jsr upkeep
    lda game_over
    bne .end
    lda p_hp
    cmp p_maxhp
    bcs .end
    jsr enemy_in_view
    bcs .end
    inc rest_cnt
    lda rest_cnt
    cmp #100
    bne .loop
.end:
    jsr status_update
    jmp view_sync

!zone help
help:
    lda #1
    sta spr_hide
    jsr page_begin
    lda #<pg_help
    sta str_ptr
    lda #>pg_help
    sta str_ptr+1
    jsr page_draw
    jsr page_show
    jsr wait_key
    jmp inv_close

; ---------------------------------------------------------------- scale
!zone descend
descend:
    inc p_depth
    lda #SND_STAIRS
    jsr play_sound
    jsr msg_clear
    +msg m_stairs
    lda p_depth
    jsr msg_byte
    jsr msg_flush
    jmp enter_level

; ---------------------------------------------------------------- stato
!zone status_update
status_update:
    jsr msg_clear
    +msg t_pv
    lda p_hp
    jsr msg_byte
    lda #'/'
    jsr msg_char
    lda p_maxhp
    jsr msg_byte
    lda msg_len
    sta cnt_b               ; fine del campo PV
    +msg t_liv
    lda p_lev
    jsr msg_byte
    +msg t_piano2
    lda p_depth
    jsr msg_byte
    +msg t_oro2
    lda p_gold
    sta num_lo
    lda p_gold+1
    sta num_hi
    jsr msg_num
    lda msg_len
    sta cnt_a               ; inizio campo fame
    lda #0
    sta tmp4                ; colore fame
    lda p_food+1
    cmp #>300
    bcc +
    bne .nofame
    lda p_food
    cmp #<300
    bcs .nofame
+   lda p_food+1
    bne .fame
    lda p_food
    cmp #100
    bcs .fame
    +msg t_debole
    lda #2
    sta tmp4
    jmp .nofame
.fame:
    +msg t_fame
    lda #7
    sta tmp4
.nofame:
    ; colore PV in base alla percentuale
    lda p_maxhp
    lsr
    lsr
    cmp p_hp
    bcc +
    lda #2
    bne ++
+   lda p_maxhp
    lsr
    cmp p_hp
    bcc +
    lda #7
    bne ++
+   lda #5
++  sta tmp5
    ldx #0
-   cpx msg_len
    bcs +
    lda msgbuf,x
    bne ++
+   lda #$20
++  sta SCR_STATUS+80,x
    lda #15
    cpx cnt_b
    bcs +
    lda tmp5
+   cpx cnt_a
    bcc +
    ldy tmp4
    beq +
    tya
+   sta COLRAM+80,x
    inx
    cpx #40
    bne -
    jmp msg_clear

; ---------------------------------------------------------------- fine partita
!zone player_dead
player_dead:
    jsr view_sync
    lda #SND_DEATH
    jsr play_sound
    lda #40
    sta cnt_a
-   jsr wait_frame
    lda cnt_a
    and #4
    beq +
    lda #2
    bne ++
+   lda #15
++  sta spr_col
    dec cnt_a
    bne -
    lda #1
    sta spr_hide
    lda #30
    jsr delay
    lda #SND_DIRGE
    jsr play_sound
    jsr page_begin
    jsr draw_stone
    lda #<pg_dead
    sta str_ptr
    lda #>pg_dead
    sta str_ptr+1
    jsr page_draw
    jsr msg_clear
    ldx killer
    lda killer_lo,x
    sta str_ptr
    lda killer_hi,x
    sta str_ptr+1
    jsr msg_str
    lda #8
    jsr page_center
    jsr msg_clear
    +msg t_piano
    lda p_depth
    jsr msg_byte
    lda #9
    jsr page_center
    lda #0
    jmp end_stats

!zone player_won
player_won:
    jsr view_sync
    lda #1
    sta spr_hide
    lda #60
    jsr delay
    jsr page_begin
    lda #<pg_win
    sta str_ptr
    lda #>pg_win
    sta str_ptr+1
    jsr page_draw
    lda #1
    jmp end_stats

; statistiche finali e attesa (A=1 vittoria)
!zone end_stats
end_stats:
    sta cnt_b
    jsr msg_clear
    +msg t_livello
    lda p_lev
    jsr msg_byte
    lda #12
    jsr page_center
    jsr msg_clear
    +msg t_oro
    lda p_gold
    sta num_lo
    lda p_gold+1
    sta num_hi
    jsr msg_num
    lda #13
    jsr page_center
    ; punteggio = oro + esperienza + 100*piano (+2000 se vittoria)
    lda p_gold
    clc
    adc p_xp
    sta tmpw
    lda p_gold+1
    adc p_xp+1
    sta tmpw+1
    ldx p_depth
-   lda tmpw
    clc
    adc #100
    sta tmpw
    bcc +
    inc tmpw+1
+   dex
    bne -
    lda cnt_b
    beq +
    lda tmpw
    clc
    adc #<2000
    sta tmpw
    lda tmpw+1
    adc #>2000
    sta tmpw+1
+   jsr msg_clear
    +msg t_punti
    lda tmpw
    sta num_lo
    lda tmpw+1
    sta num_hi
    jsr msg_num
    lda #7
    sta tmp5
    lda #15
    jsr page_center_c
    jsr msg_clear
    +msg t_again
    lda #3
    sta tmp5
    lda #19
    jsr page_center_c
    jsr page_show
    lda #60
    jsr delay
-   jsr wait_key
    cmp #' '
    bne -
    jmp title

; msgbuf centrato nella riga A (colore bianco / tmp5)
!zone page_center
page_center:
    pha
    lda #1
    sta tmp5
    pla
page_center_c:
    pha
    lda #40
    sec
    sbc msg_len
    lsr
    tax
    pla
    jmp page_msg

; lapide per la schermata di morte
!zone draw_stone
draw_stone:
    lda #1
    sta tmp5
    ; angoli e bordi
    lda #1
    sta cnt_a               ; riga
-   lda cnt_a
    ldx #7
    jsr page_addr
    ldy #0
    lda cnt_a
    cmp #1
    bne .mid
    lda #4
    sta (ptr0),y
    lda #2
    ldy #1
--  sta (ptr0),y
    iny
    cpy #25
    bne --
    lda #5
    sta (ptr0),y
    jmp .col
.mid:
    lda #3
    sta (ptr0),y
    ldy #25
    sta (ptr0),y
.col:
    lda tmp5
    ldy #25
--  sta (ptr1),y
    dey
    bpl --
    inc cnt_a
    lda cnt_a
    cmp #17
    bne -
    rts

!if TEST {
; prepara una situazione di prova: mostri vicini e zaino pieno
!zone test_setup
test_setup:
!ifdef TEST_REVEAL { jsr reveal_map }
    ldx #0
-   lda test_inv,x
    sta v_cls+3,x
    lda test_inv+9,x
    sta v_sub+3,x
    lda test_inv+18,x
    sta v_val+3,x
    lda #1
    sta v_qty+3,x
    inx
    cpx #9
    bne -
    lda #TEST_MON
    sta cnt_b
    lda p_x
    sta tmpw
    lda p_y
    sta tmpw+1
    ldy #0
-   ldx test_dirs,y
    sty tmp6
    lda tmpw
    clc
    adc dir_dx,x
    adc dir_dx,x
    sta gx
    lda tmpw+1
    clc
    adc dir_dy,x
    adc dir_dy,x
    sta gy
    jsr cell_free
    ldy tmp6
    bcs +
    iny
    cpy #8
    bne -
    rts
+   lda cnt_b
    jsr spawn_monster
    lda #MF_ALIVE|MF_AWAKE
    sta m_flags,x
    jsr fov_update
    jmp view_sync
test_dirs: !byte 2,6,0,4,1,3,5,7
test_inv:
    !byte IC_POTION,IC_POTION,IC_POTION,IC_POTION,IC_POTION,IC_SCROLL,IC_SCROLL,IC_WAND,IC_WEAPON
    !byte 0,1,2,3,4,0,2,0,2
    !byte 0,0,0,0,0,0,0,5,1
}
