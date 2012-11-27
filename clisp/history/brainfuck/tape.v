
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
    output reg available = 1'b0,
    output [6:0]tape_address
    );
    reg available_next = 1'b0;

    reg [0:511]tape,tape_next = 512'd0; //128*4bit symbols
    //reg [8:0]tape_ptr=0;
    //reg [8:0]tape_ptr_next;
    assign tape_symbol = tape[0:3];

    reg [6:0]counter,counter_next = 7'd0;
    reg [6:0]mov_counter,mov_counter_next;
    assign tape_address = counter;

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
    parameter INIT = 2'd0,
              WAIT = 2'd1,
              MOVL = 2'd2,
              MOVR = 2'd3;
    reg [1:0]_state = INIT;
    reg [1:0]_state_next = INIT;


    always@(posedge working_clock,posedge reset) begin
        if(reset) begin
            _state <= INIT;
            available <= 1'b0;
            counter <= 7'd0;
            mov_counter <= 7'd0;
        end else begin
            _state <= _state_next;
            tape <= tape_next;
            //tape_ptr <= tape_ptr_next;
            available <= available_next;
            counter <= counter_next;
            mov_counter <= mov_counter_next;
        end
    end

    always@(*) begin
        //tape_ptr_next = tape_ptr;
        tape_next = tape;
        available_next = 1'b0;
        mov_counter_next = mov_counter;
        case(_state) 
            INIT: begin
                tape_next = 512'd0;
                //tape_ptr_next = 9'd0;
                _state_next = WAIT;
                available_next = 1'b1;
                counter_next = 7'd0;
                mov_counter_next = 7'd0;
            end
            WAIT: begin
                if(tape_set_symbol) begin
                    tape_next = {tape_new_symbol,tape[4:511]};
                    _state_next = WAIT;
                    available_next = 1'b1;
                end else if(tape_move &&
                            tape_move_dir==1'b1 &&
                            counter<7'd127) begin
                    mov_counter_next = 7'd1;
                    _state_next = MOVR;
                end else if(tape_move &&
                            tape_move_dir==1'b0 &&
                            counter>7'd0) begin
                    mov_counter_next = 7'd1;
                    _state_next = MOVL;
                end else if(roll_back && counter>7'd0) begin
                    _state_next = MOVL;
                    mov_counter_next = counter;
                end else if(tape_delete) begin
                    tape_next = {hat,tape[4:511]};
                    _state_next = WAIT;
                    available_next = 1'b1;
                end else begin
                    _state_next = WAIT;
                    available_next = 1'b1;
                end
            end
            MOVL: begin
                tape_next = {tape[508:511],tape[0:507]};
                if(mov_counter == 7'd1) begin
                    mov_counter_next = 7'd0;
                    _state_next = WAIT;
                    available_next = 1'b1;
                    counter_next = counter - 1;
                end else begin
                    mov_counter_next = mov_counter - 1;
                    counter_next = counter - 1;
                    _state_next = MOVL;
                end
            end
            MOVR: begin
                tape_next = {tape[4:511],tape[0:3]};
                if(mov_counter == 7'd1) begin
                    mov_counter_next = 7'd0;
                    _state_next = WAIT;
                    available_next = 1'b1;
                    counter_next = counter + 1;
                end else begin
                    mov_counter_next = mov_counter - 1;
                    counter_next = counter + 1;
                    _state_next = MOVR;
                end
            end
            default:
                _state_next = INIT;
        endcase
    end
endmodule
