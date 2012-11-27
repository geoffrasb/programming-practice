
module Tape_module (
    input working_clock,
    input [3:0]tape_new_symbol,
    input tape_set_symbol,
    input tape_move_dir,
    input tape_move,
    output [3:0]tape_symbol,
    input reset,
    input roll_back,
    input tape_delete,
    output reg available = 1'b0
    );

    reg [0:511]tape,tape_next = 512'd0; //256*4bit symbols
    reg [8:0]tape_ptr=0;
    reg [8:0]tape_ptr_next;
    wire [0:511]setted_tape;
    wire [3:0]setting;
    assign setting = tape_set_symbol ?
                        tape_new_symbol:
                        4'b0000;
    mux512_4 mux(  .selector(tape_ptr),
                    .vector(tape),
                    .setting(setting),
                    .result(setted_tape));
    assign tape_symbol = tape[tape_ptr*4+:4];

    parameter tape_length = 8'd128;
    reg [7:0]counter,counter_next = 8'd0;

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
    parameter INIT = 1'b0,
              WAIT = 1'b1;
    reg _state = INIT;
    reg _state_next = INIT;


    always@(posedge working_clock,posedge reset) begin
        if(reset)
            _state <= INIT;
        else begin
            _state <= _state_next;
            tape <= tape_next;
            tape_ptr <= tape_ptr_next;
        end
    end

    always@(*) begin
        tape_ptr_next = tape_ptr;
        tape_next = tape;
        case(_state) 
            INIT: begin
                tape_next = 512'd0;
                _state_next = WAIT;
                tape_ptr_next = 9'd0;
            end
            WAIT: begin
                _state_next = WAIT;
                if(tape_set_symbol) 
                    tape_next = setted_tape;
                else if(tape_move) begin
                    if(tape_move_dir==1'b1 && tape_ptr<9'd508)
                        tape_ptr_next = tape_ptr+4;
                    else if(tape_ptr>9'd0)
                        tape_ptr_next = tape_ptr-4;
                end else if(roll_back)
                    tape_ptr_next = 9'd0;
                else if(tape_delete) begin
                    //tape_set_symbol must be 0
                    //so setting must be 4'b0
                    tape_next = setted_tape;
                end
            end
            default:
                _state_next = INIT;
        endcase
    end
endmodule
