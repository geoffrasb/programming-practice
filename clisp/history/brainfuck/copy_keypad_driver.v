module KeypadDriver_module(
    input reset,
    input keypad_clock,
    input working_clock,
    input to_mode, //0 for edit, 1 for exe
    input change_mode,
    //edit mode
    output reg [1:0]cmd_mode,
    output reg [3:0]symbol,//cmd_mode=0
    output reg cursor_move_dir,//cmd_mode=1
    output reg backspace, //cmd_mode=2
    output reg clear_memory, //cmd_mode=3
    //execute mode
    //use "symbol" port
    output reg available = 1'b0,
    input explicit_pull_key
    );
    reg mode,mode_next = 0; //0 for edit, 1 for exe
    reg [1:0]cmd_mode_next = 0;
    reg [3:0]symbol_next;
    reg cursor_move_dir_next;
    reg backspace_next;
    reg clear_memory_next;

    keypad kp(.key_available(key_available),.key(key),.pull_key(pull_key));
    wire [3:0]key;
    reg available_next = 1'b0;
    wire pull_key;
    assign pull_key = explicit_pull_key | auto_pull_key;
    wire auto_pull_key = 1'b0;
    reg aux_auto_pull_key,aux_auto_pull_key_next;
    assign auto_pull_key = aux_auto_pull_key_next & working_clock;


    parameter INIT = 2'b00,
              EDIT = 2'b01,
              EXE = 2'b10;
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

    always@(posedge working_clock,posedge reset) begin
        if(reset) begin
            _state <= INIT;
            available <= 1'b0;
        end else begin
            _state <= _state_next;
            mode <= mode_next;
            available <= available_next;
            cmd_mode <= cmd_mode_next;
            symbol <= symbol_next;
            cursor_move_dir <= cursor_move_dir_next;
            backspace <= backspace_next;
            clear_memory <= clear_memory_next;
        end
    end

    always@(*) begin
        mode_next = mode;
        _state_next = INIT;
        cmd_mode_next = 0;
        cursor_move_dir_next = 0;
        backspace_next = 0;
        clear_memory_next = 0;
        symbol_next = symbol;
        available_next = 1'b0;
        aux_auto_pull_key_next = 1'b0;
        case(_state)
            INIT: begin
                if(change_mode) begin
                    if(to_mode==1'b1)
                        _state_next = EXE;
                    else
                        _state_next = EDIT;
                end else
                    _state_next = INIT;
            end
            EDIT: begin
                if(key_available) begin
                    available_next = 1'b1;
                    case (key)
                        4'h0: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = zer;
                        end
                        4'h1: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = inp;
                        end
                        4'h2: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = oup;
                        end
                        4'h3: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = pas;
                        end
                        4'h4: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = mol;
                        end
                        4'h5: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = sub;
                        end
                        4'h6: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = lol;
                        end
                        4'h7: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = mor;
                        end
                        4'h8: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = add;
                        end
                        4'h9: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = lor;
                        end
                        4'ha: begin
                            cmd_mode_next =  2'd0;
                            symbol_next = ceo;
                        end
                        4'hb: begin
                            cmd_mode_next = 2'd2;
                            backspace_next = 1'b1;
                        end
                        4'hc: begin
                            available_next = 1'b0;
                            aux_auto_pull_key_next = 1'b1;
                        end
                        4'hd: begin
                            cmd_mode_next = 2'd1;
                            cursor_move_dir_next = 1'b1;
                        end
                        4'he: begin
                            cmd_mode_next = 2'd1;
                            cursor_move_dir_next = 1'b0;
                        end
                        4'hf: begin
                            available_next = 1'b0;
                            aux_auto_pull_key_next = 1'b1;
                        end
                        default: begin
                            available_next = 1'b0;
                        end
                    endcase
                end
                if(change_mode && to_mode==1'b1) begin
                    _state_next = EXE;
                end else begin
                    _state_next = EDIT;
                end
            end
            EXE: begin
                if(key_available) begin
                    available_next = 1'b1;
                    symbol_next = key;
                end
                if(change_mode && to_mode==1'b0) begin
                    _state_next = EDIT;
                end else begin
                    _state_next = EXE;
                end
            end
            default: begin
                _state_next = INIT;
            end
        endcase
    end


endmodule
