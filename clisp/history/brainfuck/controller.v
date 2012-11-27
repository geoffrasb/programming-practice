module Controller_module (
    input controller_change_mode, //async var
    input reset_machine,
    input [0:3]port_kp_col,
    output [0:3]port_kp_row,
    output [7:0]ports_led,
    output [0:3] ports_14seg_dig,
    output [0:14]ports_14seg_seg
    output [7:0] LCD_DATA,
    output LCD_ENABLE,
    output LCD_RW,
    output LCD_RSTN,
    output LCD_CS1,
    output LCD_CS2,
    output LCD_DI,
    input working_clock
    );
    reg controller_mode=0;

    parameter hat = 4'b0000,
              add = 4'b0001,
              sub = 4'b0010,
              mol = 4'b0011,
              mor = 4'b0100,
              inp = 4'b0101,
              oup = 4'b0110,
              lol = 4'b0111,
              lor = 4'b1000,
              ceo = 4'b1001,
              zer = 4'b1010,
              pas = 4'b1011;


//signals
    wire console_reset = 1'b1;
    reg aux_console_reset,aux_console_reset_next = 0;
    wire seg_reset = 1'b1;
    reg aux_seg_reset,aux_seg_reset_next = 0;
    wire led_reset = 1'b1;
    reg aux_led_reset,aux_led_reset_next = 0;
    wire tape_reset = 1'b1;
    reg aux_tape_reset,aux_tape_reset_next = 0;
    wire mem_reset = 1'b1;
    reg aux_mem_reset,aux_mem_reset_next = 0;
    assign console_reset = working_clock & aux_console_reset;
    assign seg_reset = working_clock & aux_seg_reset;
    assign led_reset = working_clock & aux_led_reset;
    assign tape_reset = working_clock & aux_tape_reset;
    assign mem_reset = working_clock & aux_mem_reset;


    //tape
    wire tape_available;
    wire [3:0]tape_symbol;
    wire [6:0]tape_address;
    //reg [3:0]tape_new_symbol;
    reg tape_move_dir;
    reg tape_set_symbol,    tape_set_symbol_next;
    reg tape_move,          tape_move_next;
    reg tape_roll_back,     tape_roll_back_next;
    reg tape_delete,        tape_delete_next;
    Tape_module tape(
        .working_clock(working_clock),
        .tape_new_symbol(keypad_symbol),
        .tape_set_symbol(tape_set_symbol),
        .tape_move_dir(tape_move_dir),
        .tape_move(tape_move),
        .tape_symbol(tape_symbol),
        .reset(tape_reset),
        .roll_back(tape_roll_back),
        .tape_delete(tape_delete),
        .available(tape_available),
        .tape_address(tape_address)
        );

    //memory
    wire mem_available;
    wire [7:0]ptr_value;
    wire [13:0]mem_monitor2;
    reg [7:0]ptr_new_value;
    reg ptr_move_dir;
    reg ptr_set_value,      ptr_set_value_next;
    reg ptr_move,           ptr_move_next;
    reg ptr_roll_back,      ptr_roll_back_next;
    Memory_module memory(
        .working_clock(working_clock),
        .ptr_value(ptr_value),
        .ptr_new_value(ptr_new_value),
        .ptr_move_dir(ptr_move_dir),
        .ptr_set_value(ptr_set_value),
        .ptr_move(ptr_move),
        .reset(mem_reset),
        .roll_back(ptr_roll_back),
        .mem_monitor2(mem_monitor2),
        .available(mem_available)
        );

    //keypaddriver,facilities are not assign yet //OK
    wire cmd_mode;
    wire [3:0]keypad_symbol;
    wire keypad_available;
    //reg keypad_to_mode;
    reg keypad_change_mode,     keypad_change_mode_next;
    reg keypad_pull_key,        keypad_pull_key_next;
    KeypadDriver_module keypad_driver(
        .reset(keypad_reset),
        .working_clock(working_clock),
        .to_mode(controller_mode), 
        .change_mode(keypad_change_mode),
        .cmd_mode(cmd_mode),
        .symbol(keypad_symbol),
        .available(keypad_available),
        .explicit_pull_key(keypad_pull_key),
        .port_kp_col(port_kp_col),
        .port_kp_row(port_kp_row)
        );

    //led ,facilities are not assign yet //OK
    reg [7:0]led_char;
    reg led_update, led_update_next;
    LED_display led(
        .chara(led_char),
        .update(led_update),
        .display_buffer(ports_led),
        .resetn(led_reset)
    );

    //14seg ,facilities are not assign yet //OK
    reg [7:0]seg_char;
    reg seg_update,     seg_update_next;
    seg14_display seg14(
        .clk(working_clock),
        .chara(seg_char),
        .update(seg_update),
        .resetn(seg_reset),
        .dig(ports_14seg_dig),
        .seg(ports_14seg_seg)
    );

    //Console ,facilities are not assign yet //OK
    wire console_available;
    //reg console_to_mode;
    reg console_cursor_dir;
    reg console_change_mode,    console_change_mode_next;
    reg console_please_wait,    console_please_wait_next;
    reg console_insert,         console_insert_next;
    reg console_delete,         console_delete_next;
    reg console_move_cursor,    console_move_cursor_next;
    Console_module console(
        .LCD_DATA(LCD_DATA),
        .LCD_ENABLE(LCD_ENABLE),
        .LCD_RW(LCD_RW),
        .LCD_RSTN(LCD_RSTN),
        .LCD_CS1(LCD_CS1),
        .LCD_CS2(LCD_CS2),
        .LCD_DI(LCD_DI),
        .reset(console_reset),
        .to_mode(controller_mode),
        .change_mode(console_change_mode),
        .please_wait(console_please_wait),
        .mem_monitor2(mem_monitor2),
        .symbol_to_insert({keypad_symbol,4'b1111}),
        .insert(console_insert),
        .delete(console_delete),
        .cursor_dir(console_cursor_dir),
        .move_cursor(console_move_cursor),
        .available(console_available)
        );

    //controller's registers
    reg [6:0]tape_address_to_recover,tape_address_to_recover_next;
    reg output_device=1'b0;
    reg output_device_next;
    reg [3:0]pause_counter = 4'd0;
    reg [3:0]pause_counter_next;
    reg [4:0]loop_stack = 5'd0;
    reg [4:0]loop_stack_next;
    reg [4:0]search_stack = 5'd0;
    reg [4:0]search_stack_next;

    always@(posedge working_clock,posedge controller_change_mode,posedge reset_machine) begin
        if(controller_change_mode)begin
            _state <= CHANGE_MODE_AUX;
        end else if(reset_machine)begin
            _state <= INIT;
        end else if(working_clock)begin
            //copy code from code generated by SMDL compiler
            console_please_wait <= console_please_wait_next;
            ptr_roll_back <= ptr_roll_back_next;
            tape_set_symbol <= tape_set_symbol_next;
            console_insert <= console_insert_next;
            tape_delete <= tape_delete_next;
            console_delete <= console_delete_next;
            keypad_pull_key <= keypad_pull_key_next;
            tape_roll_back <= tape_roll_back_next;
            tape_address_to_recover <= tape_address_to_recover_next;
            keypad_change_mode <= keypad_change_mode_next;
            console_change_mode <= console_change_mode_next;
            ptr_move <= ptr_move_next;
            led_update <= led_update_next;
            seg_update <= seg_update_next;
            output_device <= output_device_next;
            ptr_set_value <= ptr_set_value_next;
            pause_counter <= pause_counter_next;
            loop_stack <= loop_stack_next;
            search_stack <= search_stack_next;
            console_move_cursor <= console_move_cursor_next;
            tape_move <= tape_move_next;
            aux_console_reset <= aux_console_reset_next;
            aux_seg_reset <= aux_seg_reset_next;
            aux_led_reset <= aux_led_reset_next;
            aux_tape_reset <= aux_tape_reset_next;
            aux_mem_reset <= aux_mem_reset_next;
            _state <= _state_next;
        end
    end

//{----------------code generated by SMDL compiler----------------------

// state definition
    reg [5:0]_state,_state_next;
    parameter LOR_AUX_MOVE = 6'd0,
              LOR_SUB_SEARCH_STACK = 6'd1,
              LOR_ADD_SEARCH_STACK = 6'd2,
              LOR_SEARCH_NOT_DESIRED = 6'd3,
              LOR_SEARCH_LOL = 6'd4,
              LOR_AUX_TRANS = 6'd5,
              WAIT_TO_LOR_AUX_MOVE = 6'd6,
              WAIT_BACK_TO_LOR = 6'd7,
              BEFORE_LOR_SEARCH_LOL_S3 = 6'd8,
              BEFORE_LOR_MOV_S2 = 6'd9,
              BEFORE_LOR_SEARCH_LOL_S2 = 6'd10,
              BEFORE_LOR_MOV_S1 = 6'd11,
              BEFORE_LOR_SEARCH_LOL_S1 = 6'd12,
              LOL_SUB_SEARCH_STACK = 6'd13,
              LOL_ADD_SEARCH_STACK = 6'd14,
              LOL_SEARCH_NOT_DESIRED = 6'd15,
              LOL_SEARCH_LOR = 6'd16,
              EXE_ADD_LOOP_STACK = 6'd17,
              WAIT_BACK_TO_LOL = 6'd18,
              EXE_WAIT_FOR_ALL = 6'd19,
              EXE_PAUSE = 6'd20,
              EXE_ZER = 6'd21,
              EXE_CEO = 6'd22,
              EXE_OUP = 6'd23,
              EXE_INP = 6'd24,
              EXE_MOR = 6'd25,
              EXE_MOL = 6'd26,
              EXE_SUB = 6'd27,
              EXE_ADD = 6'd28,
              EXE_HALT = 6'd29,
              EXE = 6'd30,
              EXE_TO_EDIT_CHECK = 6'd31,
              EXE_TO_EDIT_RECOVER_TAPE = 6'd32,
              EXE_TO_EDIT = 6'd33,
              EDIT_TO_EXE_S2 = 6'd34,
              EDIT_TO_EXE = 6'd35,
              EDIT_WAIT_ALL = 6'd36,
              EDIT_MOVE_TAPEL = 6'd37,
              EDIT_MOVE_TAPER = 6'd38,
              EDIT_DELETE_SYMBOL = 6'd39,
              EDIT_INSERT_SYMBOL = 6'd40,
              EDIT = 6'd41,
              INIT = 6'd42,
              CHANGE_MODE_AUX = 6'd43;

    always@(*) begin
        aux_console_reset_next = 1'b0;
        aux_seg_reset_next = 1'b0;
        aux_led_reset_next = 1'b0;
        aux_tape_reset_next = 1'b0;
        aux_mem_reset_next = 1'b0;
        _state_next = INIT;
        tape_set_symbol_next = 1'b0;
        tape_move_next = 1'b0;
        tape_roll_back_next = 1'b0;
        tape_delete_next = 1'b0;
        ptr_set_value_next = 1'b0;
        ptr_move_next = 1'b0;
        ptr_roll_back_next = 1'b0;
        keypad_change_mode_next = 1'b0;
        led_update_next = 1'b0;
        seg_update_next = 1'b0;
        console_change_mode_next = 1'b0;
        console_please_wait_next = 1'b0;
        console_insert_next = 1'b0;
        console_delete_next = 1'b0;
        console_move_cursor_next = 1'b0;
        output_device_next = output_device;
        pause_counter_next = pause_counter;
        loop_stack_next = loop_stack;
        search_stack_next = search_stack;
        keypad_pull_key_next = 1'b0;
        tape_move_dir = 1'b0;
        tape_new_symbol = 3'b000;
        ptr_move_dir = 1'b0;
        ptr_new_value = 8'd0;
        console_cursor_dir = 1'b0;
        controller_mode = 1'b0;

        case (_state) begin
            LOR_AUX_MOVE: begin
                tape_move_next = 1'b1;
                console_move_cursor_next = 1'b1;
                tape_move_dir = 1'b1;
                console_cursor_dir = 1'b1;
                _state_next = LOR_AUX_TRANS;
                end
            LOR_SUB_SEARCH_STACK: begin
                search_stack_next = search_stack-1;
                if((search_stack==5'd0)) begin
                    _state_next = WAIT_TO_LOR_AUX_MOVE;
                end else if((search_stack!=5'd0)) begin
                    _state_next = WAIT_BACK_TO_LOR;
                end
                end
            LOR_ADD_SEARCH_STACK: begin
                search_stack_next = search_stack+1;
                _state_next = WAIT_BACK_TO_LOR;
                end
            LOR_SEARCH_NOT_DESIRED: begin
                _state_next = WAIT_BACK_TO_LOR;
                end
            LOR_SEARCH_LOL: begin
                tape_move_next = 1'b1;
                console_move_cursor_next = 1'b1;
                tape_move_dir = 1'b0;
                console_cursor_dir = 1'b0;
                if((tape_symbol==lor)) begin
                    _state_next = LOR_ADD_SEARCH_STACK;
                end else if((tape_symbol==lol)) begin
                    _state_next = LOR_SUB_SEARCH_STACK;
                end else if(((tape_symbol!=lol) || (tape_symbol!=lor))) begin
                    _state_next = LOL_SEARCH_NOT_DESIRED;
                end
                end
            LOR_AUX_TRANS: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = EXE;
                end else begin
                    _state_next = LOR_AUX_TRANS;
                end
                end
            WAIT_TO_LOR_AUX_MOVE: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = LOR_AUX_MOVE;
                end else begin
                    _state_next = WAIT_TO_LOR_AUX_MOVE;
                end
                end
            WAIT_BACK_TO_LOR: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = LOR_SEARCH_LOL;
                end else begin
                    _state_next = WAIT_BACK_TO_LOR;
                end
                end
            BEFORE_LOR_SEARCH_LOL_S3: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = LOR_SEARCH_LOL;
                end else begin
                    _state_next = BEFORE_LOR_SEARCH_LOL_S3;
                end
                end
            BEFORE_LOR_MOV_S2: begin
                tape_move_dir = 1'b0;
                console_cursor_dir = 1'b0;
                _state_next = BEFORE_LOR_SEARCH_LOL_S3;
                end
            BEFORE_LOR_SEARCH_LOL_S2: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = BEFORE_LOR_MOV_S2;
                end else begin
                    _state_next = BEFORE_LOR_SEARCH_LOL_S2;
                end
                end
            BEFORE_LOR_MOV_S1: begin
                tape_move_dir = 1'b0;
                console_cursor_dir = 1'b0;
                _state_next = BEFORE_LOR_SEARCH_LOL_S2;
                end
            BEFORE_LOR_SEARCH_LOL_S1: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = BEFORE_LOR_MOV_S1;
                end else begin
                    _state_next = BEFORE_LOR_SEARCH_LOL_S1;
                end
                end
            LOL_SUB_SEARCH_STACK: begin
                search_stack_next = search_stack-1;
                if((search_stack==5'd0)) begin
                    _state_next = EXE_WAIT_FOR_ALL;
                end else if((search_stack!=5'd0)) begin
                    _state_next = WAIT_BACK_TO_LOL;
                end
                end
            LOL_ADD_SEARCH_STACK: begin
                search_stack_next = search_stack+1;
                _state_next = WAIT_BACK_TO_LOL;
                end
            LOL_SEARCH_NOT_DESIRED: begin
                _state_next = WAIT_BACK_TO_LOL;
                end
            LOL_SEARCH_LOR: begin
                tape_move_next = 1'b1;
                console_move_cursor_next = 1'b1;
                tape_move_dir = 1'b1;
                console_cursor_dir = 1'b1;
                if((tape_symbol==lor)) begin
                    _state_next = LOL_SUB_SEARCH_STACK;
                end else if((tape_symbol==lol)) begin
                    _state_next = LOL_ADD_SEARCH_STACK;
                end else if(((tape_symbol!=lol) || (tape_symbol!=lor))) begin
                    _state_next = LOL_SEARCH_NOT_DESIRED;
                end
                end
            EXE_ADD_LOOP_STACK: begin
                loop_stack_next = loop_stack+1;
                if((ptr_value==8'd0)) begin
                    _state_next = WAIT_BACK_TO_LOL;
                end else if((ptr_value!=8'd0)) begin
                    _state_next = EXE_WAIT_FOR_ALL;
                end
                end
            WAIT_BACK_TO_LOL: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = LOL_SEARCH_LOR;
                end else begin
                    _state_next = WAIT_BACK_TO_LOL;
                end
                end
            EXE_WAIT_FOR_ALL: begin
                if((((tape_available==1'b1) && (console_available==1'b1)) && (mem_available==1'b1))) begin
                    _state_next = EXE;
                end else begin
                    _state_next = EXE_WAIT_FOR_ALL;
                end
                end
            EXE_PAUSE: begin
                pause_counter_next = pause_counter+1;
                if((pause_counter==4'b1111)) begin
                    _state_next = EXE_WAIT_FOR_ALL;
                end else begin
                    _state_next = EXE_PAUSE;
                end
                end
            EXE_ZER: begin
                ptr_set_value_next = 1'b1;
                ptr_new_value = 8'd0;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_CEO: begin
                output_device_next = ~output_device;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_OUP: begin
                if((output_device==1'b0)) begin
                    seg_update_next = 1'b1;
                end
                if((output_device==1'b1)) begin
                    led_update_next = 1'b1;
                end
                seg_char = ptr_value;
                led_char = ptr_value;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_INP: begin
                if((keypad_available==1'b1)) begin
                    ptr_set_value_next = 1'b1;
                    keypad_pull_key_next = 1'b1;
                end
                ptr_new_value = {4'd0,keypad_symbol};
                if((keypad_available==1'b1)) begin
                    _state_next = EXE_WAIT_FOR_ALL;
                end else begin
                    _state_next = EXE_INP;
                end
                end
            EXE_MOR: begin
                ptr_move_next = 1'b1;
                ptr_move_dir = 1'b1;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_MOL: begin
                ptr_move_next = 1'b1;
                ptr_move_dir = 1'b0;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_SUB: begin
                ptr_set_value_next = 1'b1;
                ptr_new_value = ptr_value-1;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_ADD: begin
                ptr_set_value_next = 1'b1;
                ptr_new_value = ptr_value+1;
                _state_next = EXE_WAIT_FOR_ALL;
                end
            EXE_HALT: begin
                _state_next = EXE_HALT;
                end
            EXE: begin
                tape_move_next = 1'b1;
                console_move_cursor_next = 1'b1;
                search_stack_next = 5'd0;
                tape_move_dir = 1'b1;
                console_cursor_dir = 1'b1;
                if((tape_symbol==pas)) begin
                    _state_next = EXE_PAUSE;
                end else if((tape_symbol==zer)) begin
                    _state_next = EXE_ZER;
                end else if((tape_symbol==ceo)) begin
                    _state_next = EXE_CEO;
                end else if((tape_symbol==lor)) begin
                    _state_next = BEFORE_LOR_SEARCH_LOL_S1;
                end else if((tape_symbol==lol)) begin
                    _state_next = EXE_ADD_LOOP_STACK;
                end else if((tape_symbol==oup)) begin
                    _state_next = EXE_OUP;
                end else if((tape_symbol==inp)) begin
                    _state_next = EXE_INP;
                end else if((tape_symbol==mor)) begin
                    _state_next = EXE_MOR;
                end else if((tape_symbol==mol)) begin
                    _state_next = EXE_MOL;
                end else if((tape_symbol==sub)) begin
                    _state_next = EXE_SUB;
                end else if((tape_symbol==add)) begin
                    _state_next = EXE_ADD;
                end else begin
                    _state_next = EXE_HALT;
                end
                end
            EXE_TO_EDIT_CHECK: begin
                if(((tape_available==1'b1) && (console_available==1'b0))) begin
                    _state_next = EXE_TO_EDIT_CHECK;
                end else if((((tape_available==1'b1) && (tape_address==tape_address_to_recover)) && (console_available==1'b1))) begin
                    _state_next = EDIT;
                    aux_mem_reset_next = 1'b1;
                end else if((tape_available==1'b0)) begin
                    _state_next = EXE_TO_EDIT_CHECK;
                end else if(((tape_available==1'b1) && (tape_address<tape_address_to_recover))) begin
                    _state_next = EXE_TO_EDIT_RECOVER_TAPE;
                end
                end
            EXE_TO_EDIT_RECOVER_TAPE: begin
                tape_move_next = 1'b1;
                tape_move_dir = 1'b1;
                _state_next = EXE_TO_EDIT_CHECK;
                end
            EXE_TO_EDIT: begin
                console_change_mode_next = 1'b1;
                keypad_change_mode_next = 1'b1;
                controller_mode = 1'b0;
                _state_next = EXE_TO_EDIT_CHECK;
                end
            EDIT_TO_EXE_S2: begin
                if(((console_available==1'b1) && (tape_available==1'b1))) begin
                    _state_next = EXE;
                end else begin
                    _state_next = EDIT_TO_EXE_S2;
                end
                end
            EDIT_TO_EXE: begin
                console_change_mode_next = 1'b1;
                keypad_change_mode_next = 1'b1;
                tape_address_to_recover_next = tape_address;
                tape_roll_back_next = 1'b1;
                controller_mode = 1'b1;
                _state_next = EDIT_TO_EXE_S2;
                end
            EDIT_WAIT_ALL: begin
                if(((tape_available==1'b1) && (console_available==1'b1))) begin
                    _state_next = EDIT;
                end else begin
                    _state_next = EDIT_WAIT_ALL;
                end
                end
            EDIT_MOVE_TAPEL: begin
                tape_move_next = 1'b1;
                keypad_pull_key_next = 1'b1;
                tape_move_dir = 1'b0;
                _state_next = EDIT_WAIT_ALL;
                end
            EDIT_MOVE_TAPER: begin
                tape_move_next = 1'b1;
                keypad_pull_key_next = 1'b1;
                tape_move_dir = 1'b1;
                _state_next = EDIT_WAIT_ALL;
                end
            EDIT_DELETE_SYMBOL: begin
                console_delete_next = 1'b1;
                tape_delete_next = 1'b1;
                console_delete_next = 1'b1;
                _state_next = EDIT_MOVE_TAPEL;
                end
            EDIT_INSERT_SYMBOL: begin
                console_insert_next = 1'b1;
                tape_set_symbol_next = 1'b1;
                console_insert_next = 1'b1;
                _state_next = EDIT_MOVE_TAPER;
                end
            EDIT: begin
                if(((keypad_available==1'b1) && (cmd_mode==1'd1))) begin
                    _state_next = EDIT_DELETE_SYMBOL;
                end else if(((keypad_available==1'b1) && (cmd_mode==1'd0))) begin
                    _state_next = EDIT_INSERT_SYMBOL;
                end else begin
                    _state_next = EDIT;
                end
                end
            INIT: begin
                keypad_change_mode_next = 1'b1;
                console_change_mode_next = 1'b1;
                output_device_next = 1'b0;
                pause_counter_next = 4'd0;
                loop_stack_next = 5'd0;
                search_stack_next = 5'd0;
                controller_mode = 1'b0;
                _state_next = EDIT;
                aux_tape_reset_next = 1'b1;
                aux_mem_reset_next = 1'b1;
                aux_led_reset_next = 1'b1;
                aux_seg_reset_next = 1'b1;
                aux_console_reset_next = 1'b1;
                end
            CHANGE_MODE_AUX: begin
                if((controller_mode==1'b1)) begin
                    _state_next = EXE_TO_EDIT;
                end else if((controller_mode==1'b0)) begin
                    _state_next = EDIT_TO_EXE;
                end
                end
            default: begin
                _state_next = INIT;
                end
        endcase
    end
//}^^^^^^^^^^^^^^^^code generated by SMDL compiler^^^^^^^^^^^^^^^^^^^^^^

endmodule

/*SMDL {{{
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
                ("console_change_mode"  "1'b0")
                ("console_please_wait"  "1'b0")
                ("console_insert"       "1'b0")
                ("console_delete"       "1'b0")
                ("console_move_cursor"  "1'b0")
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
                ("console_cursor_dir"   "1'b0")
                ("controller_mode"      "1'b0")
                ))
        (change_mode_aux)
        (init
            (sync-var
                ("keypad_change_mode"  "1'b1")
                ("console_change_mode" "1'b1")
                ("output_device"       "1'b0")
                ("pause_counter"       "4'd0")
                ("loop_stack"          "5'd0")
                ("search_stack"        "5'd0"))
            (reg
                ("controller_mode"  "1'b0")))
        (edit)
        (edit_insert_symbol
            (sync-var
                ("console_insert"  "1'b1")
                ("tape_set_symbol" "1'b1")
                ("console_insert" "1'b1")))
        (edit_delete_symbol
            (sync-var
                ("console_delete" "1'b1")
                ("tape_delete"    "1'b1")
                ("console_delete" "1'b1")))
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
                ("console_change_mode" "1'b1")
                ("keypad_change_mode"  "1'b1")
                ("tape_address_to_recover" "tape_address")
                ("tape_roll_back" "1'b1"))
            (reg
                ("controller_mode" "1'b1")))
        (edit_to_exe_s2)

        (exe_to_edit
            (sync-var
                ("console_change_mode" "1'b1")
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
                ("console_move_cursor" "1'b1")
                ("search_stack" "5'd0"))
            (reg
                ("tape_move_dir" "1'b1")
                ("console_cursor_dir" "1'b1")))
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
                ("output_device" "~output_device")))
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
                ("tape_move" "1'b1")
                ("console_move_cursor" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")
                ("console_cursor_dir" "1'b1")))
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
                ("tape_move" "1'b1")
                ("console_move_cursor" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")
                ("console_cursor_dir" "1'b0")))
        (before_lor_search_lol_s2)
        (before_lor_mov_s2
            (sync   
                ("tape_move" "1'b1")
                ("console_move_cursor" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")
                ("console_cursor_dir" "1'b0")))
        (before_lor_search_lol_s3)
        (wait_back_to_lor)
        (wait_to_lor_aux_move)
        (lor_aux_trans)
        (lor_search_lol
            (sync-var
                ("tape_move" "1'b1")
                ("console_move_cursor" "1'b1"))
            (reg
                ("tape_move_dir" "1'b0")
                ("console_cursor_dir" "1'b0")))
        (lor_search_not_desired)
        (lor_add_search_stack
            (sync-var
                ("search_stack" "search_stack+1")))
        (lor_sub_search_stack
            (sync-var
                ("search_stack" "search_stack-1")))
        (lor_aux_move
            (sync-var 
                ("tape_move" "1'b1")
                ("console_move_cursor" "1'b1"))
            (reg
                ("tape_move_dir" "1'b1")
                ("console_cursor_dir" "1'b1")))
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
                  "seg_reset"
                  "console_reset"))
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
        ((edit_to_exe_s2 (and ("console_available" "==" "1'b1")
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
                                 ("console_available" "==" "1'b1")))
            (edit "mem_reset"))
        ((exe_to_edit_check (and ("tape_available" "==" "1'b1")
                                 ("console_available" "==" "1'b0")))
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
                                     ("console_available" "==" "1'b1"))
                                ("mem_available" "==" "1'b1")))
            (exe))
        ((exe_wait_for_all) (exe_wait_for_all)) 
;--lol
        ((wait_back_to_lol (and ("tape_available" "==" "1'b1")
                                ("console_available" "==" "1'b1"))) 
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
                                        ("console_available" "==" "1'b1")))
            (before_lor_mov_s1))
        ((before_lor_search_lol_s1) (before_lor_search_lol_s1))
        ((before_lor_mov_s1) (before_lor_search_lol_s2))
        ((before_lor_search_lol_s2 (and ("tape_available" "==" "1'b1")
                                        ("console_available" "==" "1'b1")))
            (before_lor_mov_s2))
        ((before_lor_search_lol_s2) (before_lor_search_lol_s2))
        ((before_lor_mov_s2) (before_lor_search_lol_s3))
        ((before_lor_search_lol_s3 (and ("tape_available" "==" "1'b1")
                                        ("console_available" "==" "1'b1")))
            (lor_search_lol))
        ((before_lor_search_lol_s3) (before_lor_search_lol_s3))

        ((wait_back_to_lor (and ("tape_available" "==" "1'b1")
                                ("console_available" "==" "1'b1")))
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
                                    ("console_available" "==" "1'b1")))
            (lor_aux_move))
        ((wait_to_lor_aux_move) (wait_to_lor_aux_move))
        ((lor_aux_move) (lor_aux_trans))
        ((lor_aux_trans (and ("tape_available" "==" "1'b1")
                             ("console_available" "==" "1'b1")))
            (exe))
        ((lor_aux_trans) (lor_aux_trans))
    ))

}}}*/
