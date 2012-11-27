(state-machine
    (clock "working_clock")
    (init-state init)
    (state
        (default
            (sync-var
                ("tape_set_symbol"      "1'b0")
                ("tape_move"            "1'b0")
                ("tape_roll_back"       "1'b0")
                ("tape_delete"          "1'b0")
                ("ptr_set_value"        "1'b0")
                ("ptr_move"             "1'b0")
                ("ptr_roll_back"        "1'b0")
                ("keypad_change_mode"   "1'b0")
                ("led_update"           "1'b0")
                ("seg_update"           "1'b0")
                ("output_device"        "output_device")
                ("pause_counter"        "pause_counter")
                ("loop_stack"           "loop_stack")
                ("search_stack"         "search_stack")
                ("keypad_pull_key"      "1'b0")
                )
            (reg
                ("tape_move_dir"        "1'b0")
                ("ptr_move_dir"         "1'b0")
                ("ptr_new_value"        "8'd0")
                ("controller_mode"      "1'b0")
                ))
        (change_mode_aux)
        (init
            (sync-var
                ("keypad_change_mode"  "1'b1")
                ("output_device"       "1'b0")
                ("pause_counter"       "4'd0")
                ("loop_stack"          "5'd0")
                ("search_stack"        "5'd0"))
            (reg
                ("controller_mode"  "1'b0")))
        (edit)
        (edit_insert_symbol
            (sync-var
                ("tape_set_symbol" "1'b1")))
        (edit_delete_symbol
            (sync-var
                ("tape_delete"    "1'b1")))
        (edit_move_tapeR
            (sync-var
                ("tape_move" "1'b1")
                ("keypad_pull_key" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")))
        (edit_move_tapeL
            (sync-var
                ("tape_move" "1'b1")
                ("keypad_pull_key" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")))
        (edit_wait_all)

;transition
        (edit_to_exe
            (sync-var
                ("keypad_change_mode"  "1'b1")
                ("tape_address_to_recover" "tape_address")
                ("tape_roll_back" "1'b1"))
            (reg
                ("controller_mode" "1'b1")))
        (edit_to_exe_s2)

        (exe_to_edit
            (sync-var
                ("keypad_change_mode" "1'b1"))
            (reg
                ("controller_mode" "1'b0")))
        (exe_to_edit_recover_tape
            (sync-var
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")))
        (exe_to_edit_check)
;end of transition

        (exe
            (sync-var
                ("tape_move" "1'b1")
                ("search_stack" "5'd0"))
            (reg
                ("tape_move_dir" "1'b1")))
        (exe_halt)
        (exe_add
            (sync-var
                ("ptr_set_value" "1'b1"))
            (reg
                ("ptr_new_value" "ptr_value+1")))
        (exe_sub
            (sync-var
                ("ptr_set_value" "1'b1"))
            (reg
                ("ptr_new_value" "ptr_value-1")))
        (exe_mol
            (sync-var
                ("ptr_move" "1'b1"))
            (reg
                ("ptr_move_dir" "1'b0")))
        (exe_mor
            (sync-var
                ("ptr_move" "1'b1"))
            (reg
                ("ptr_move_dir" "1'b1")))
        (exe_inp
            (sync-var
                ( ("keypad_available" "==" "1'b1")
                    ("ptr_set_value" "1'b1")
                    ("keypad_pull_key" "1'b1")))
            (reg
                ("ptr_new_value" "{4'd0,keypad_symbol}")))
        (exe_oup
            (sync-var
                (("output_device" "==" "1'b0")
                    ("seg_update" "1'b1"))
                (("output_device" "==" "1'b1")
                    ("led_update" "1'b1")))
            (reg
                ("seg_char" "ptr_value")
                ("led_char" "ptr_value")))
        (exe_ceo
            (sync-var
                ("output_device" "!output_device")))
        (exe_zer
            (sync-var
                ("ptr_set_value" "1'b1"))
            (reg
                ("ptr_new_value" "8'd0")))
        (exe_pause
            (sync-var
                ("pause_counter" "pause_counter+1")))
        (exe_wait_for_all)
;--lol
        (wait_back_to_lol)
        (exe_add_loop_stack ;notusing stack
            (sync-var
                ("loop_stack" "loop_stack+1")))
        (lol_search_lor
            (sync-var
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")))
        (lol_search_not_desired)
        (lol_add_search_stack
            (sync-var
                ("search_stack" "search_stack+1")))
        (lol_sub_search_stack
            (sync-var
                ("search_stack" "search_stack-1")))
;--lor
        (before_lor_search_lol_s1)
        (before_lor_mov_s1
            (sync   
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")))
        (before_lor_search_lol_s2)
        (before_lor_mov_s2
            (sync   
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")))
        (before_lor_search_lol_s3)
        (wait_back_to_lor)
        (wait_to_lor_aux_move)
        (lor_aux_trans)
        (lor_search_lol
            (sync-var
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")))
        (lor_search_not_desired)
        (lor_add_search_stack
            (sync-var
                ("search_stack" "search_stack+1")))
        (lor_sub_search_stack
            (sync-var
                ("search_stack" "search_stack-1")))
        (lor_aux_move
            (sync-var 
                ("tape_move" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")))
    )
    (trans-func ;------------------------------------------------------
        ((change_mode_aux ("controller_mode" "==" "1'b0"))
            (edit_to_exe))
        ((change_mode_aux ("controller_mode" "==" "1'b1"))
            (exe_to_edit))
        ((init)
            (edit "tape_reset" 
                  "mem_reset"
                  "led_reset"
                  "seg_reset"))
;edit transfunc
        ((edit (and
                ("keypad_available" "==" "1'b1")
                ("cmd_mode" "==" "1'd0")))
            (edit_insert_symbol))
        ((edit (and
                ("keypad_available" "==" "1'b1")
                ("cmd_mode" "==" "1'd1")))
            (edit_delete_symbol))
        ((edit) (edit))

        ((edit_insert_symbol) (edit_move_tapeR))
        ((edit_delete_symbol) (edit_move_tapeL))
        ((edit_move_tapeR) (edit_wait_all))
        ((edit_move_tapeL) (edit_wait_all))
        ((edit_wait_all (and ("tape_available" "==" "1'b1")
                             ("console_available" "==" "1'b1")))
            (edit))
        ((edit_wait_all) (edit_wait_all))

;gray area
        ((edit_to_exe) (edit_to_exe_s2))       
        ((edit_to_exe_s2 (and ("1'b1" "==" "1'b1")
                              ("tape_available" "==" "1'b1")))
            (exe))
        ((edit_to_exe_s2) (edit_to_exe_s2))

        ((exe_to_edit) (exe_to_edit_check))
        ((exe_to_edit_recover_tape) (exe_to_edit_check))
        ((exe_to_edit_check (and ("tape_available" "==" "1'b1")
                                 ("tape_address" "<" "tape_address_to_recover")))
            (exe_to_edit_recover_tape))
        ((exe_to_edit_check ("tape_available" "==" "1'b0"))
            (exe_to_edit_check))
        ((exe_to_edit_check (and (and ("tape_available" "==" "1'b1")
                                      ("tape_address" "==" "tape_address_to_recover"))
                                 ("1'b1" "==" "1'b1")))
            (edit "mem_reset"))
        ((exe_to_edit_check (and ("tape_available" "==" "1'b1")
                                 ("1'b0" "==" "1'b0")))
            (exe_to_edit_check))

;exe trans funcs
        ((exe ("tape_symbol" "==" "add"))
            (exe_add))
        ((exe ("tape_symbol" "==" "sub"))
            (exe_sub))
        ((exe ("tape_symbol" "==" "mol"))
            (exe_mol))
        ((exe ("tape_symbol" "==" "mor"))
            (exe_mor))
        ((exe ("tape_symbol" "==" "inp"))
            (exe_inp))
        ((exe ("tape_symbol" "==" "oup"))
            (exe_oup))
        ((exe ("tape_symbol" "==" "lol"))
            (exe_add_loop_stack))
        ((exe ("tape_symbol" "==" "lor"))
            (before_lor_search_lol_s1))
        ((exe ("tape_symbol" "==" "ceo"))
            (exe_ceo))
        ((exe ("tape_symbol" "==" "zer"))
            (exe_zer))
        ((exe ("tape_symbol" "==" "pas"))
            (exe_pause))
        ((exe) (exe_halt))
        ((exe_halt) (exe_halt))
        ((exe_add) (exe_wait_for_all))
        ((exe_sub) (exe_wait_for_all))
        ((exe_mol) (exe_wait_for_all))
        ((exe_mor) (exe_wait_for_all))
        ((exe_inp ("keypad_available" "==" "1'b1"))
            (exe_wait_for_all))
        ((exe_inp) (exe_inp))
        ((exe_oup) (exe_wait_for_all))
        ((exe_ceo) (exe_wait_for_all))
        ((exe_zer) (exe_wait_for_all))
        ((exe_pause ("pause_counter" "==" "4'b1111"))
            (exe_wait_for_all))
        ((exe_pause) (exe_pause))
        ((exe_wait_for_all (and (and ("tape_available" "==" "1'b1")
                                     ("1'b1" "==" "1'b1"))
                                ("mem_available" "==" "1'b1")))
            (exe))
        ((exe_wait_for_all) (exe_wait_for_all)) 
;--lol
        ((wait_back_to_lol (and ("tape_available" "==" "1'b1")
                                ("1'b1" "==" "1'b1"))) 
            (lol_search_lor))
        ((wait_back_to_lol) (wait_back_to_lol))

        ((exe_add_loop_stack ("ptr_value" "!=" "8'd0"))
            (exe_wait_for_all))
        ((exe_add_loop_stack ("ptr_value" "==" "8'd0"))
            (wait_back_to_lol))

        ((lol_search_lor (or ("tape_symbol" "!=" "lol")
                             ("tape_symbol" "!=" "lor")))
            (lol_search_not_desired))
        ((lol_search_lor ("tape_symbol" "==" "lol"))
            (lol_add_search_stack))
        ((lol_search_lor ("tape_symbol" "==" "lor"))
            (lol_sub_search_stack))
        ((lol_search_not_desired) (wait_back_to_lol))
        ((lol_add_search_stack) (wait_back_to_lol))
        ((lol_sub_search_stack ("search_stack" "!=" "5'd0"))
            (wait_back_to_lol))
        ((lol_sub_search_stack ("search_stack" "==" "5'd0"))
            (exe_wait_for_all))
;--lor
        ((before_lor_search_lol_s1 (and ("tape_available" "==" "1'b1")
                                        ("1'b1" "==" "1'b1")))
            (before_lor_mov_s1))
        ((before_lor_search_lol_s1) (before_lor_search_lol_s1))
        ((before_lor_mov_s1) (before_lor_search_lol_s2))
        ((before_lor_search_lol_s2 (and ("tape_available" "==" "1'b1")
                                        ("1'b1" "==" "1'b1")))
            (before_lor_mov_s2))
        ((before_lor_search_lol_s2) (before_lor_search_lol_s2))
        ((before_lor_mov_s2) (before_lor_search_lol_s3))
        ((before_lor_search_lol_s3 (and ("tape_available" "==" "1'b1")
                                        ("1'b1" "==" "1'b1")))
            (lor_search_lol))
        ((before_lor_search_lol_s3) (before_lor_search_lol_s3))

        ((wait_back_to_lor (and ("tape_available" "==" "1'b1")
                                ("1'b1" "==" "1'b1")))
            (lor_search_lol))
        ((wait_back_to_lor) (wait_back_to_lor))
        ((lor_search_lol (or ("tape_symbol" "!=" "lol")
                             ("tape_symbol" "!=" "lor")))
            (lol_search_not_desired))
        ((lor_search_lol ("tape_symbol" "==" "lol"))
            (lor_sub_search_stack))
        ((lor_search_lol ("tape_symbol" "==" "lor"))
            (lor_add_search_stack))
        ((lor_search_not_desired) (wait_back_to_lor))
        ((lor_add_search_stack) (wait_back_to_lor))
        ((lor_sub_search_stack ("search_stack" "!=" "5'd0"))
            (wait_back_to_lor))
        ((lor_sub_search_stack ("search_stack" "==" "5'd0"))
            (wait_to_lor_aux_move))
        ((wait_to_lor_aux_move (and ("tape_available" "==" "1'b1")
                                    ("1'b1" "==" "1'b1")))
            (lor_aux_move))
        ((wait_to_lor_aux_move) (wait_to_lor_aux_move))
        ((lor_aux_move) (lor_aux_trans))
        ((lor_aux_trans (and ("tape_available" "==" "1'b1")
                             ("1'b1" "==" "1'b1")))
            (exe))
        ((lor_aux_trans) (lor_aux_trans))
    ))
