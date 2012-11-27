
module Memory_module (
    input working_clock,
    output [7:0]ptr_value,
    input [7:0]ptr_new_value,
    input ptr_move_dir,
    input ptr_set_value, //signal
    input ptr_move, //signal
    input reset,
    input roll_back,
    //output [13:0]mem_monitor1,//{mem_addr,mem_content}
    output [13:0]mem_monitor2,
    //output [13:0]mem_monitor3
    output reg available = 1'b0
    );
    reg available_next = 1'b0;

    reg [0:511]memory,memory_next; //8bit * 128
    //reg [8:0]ptr = 9'd0;
    //reg [8:0]ptr_next;
    assign ptr_value = memory[0:7];

    reg [5:0]address = 6'd0;
    reg [5:0]address_next;
    reg [5:0]mov_counter,mov_counter_next;

    //assign mem_monitor1 = {address-6'd1,memory[508:511]};
    assign mem_monitor2 = {address,ptr_value};
    //assign mem_monitor3 = {address+6'd1,memory[8:15]};


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
            address <= 6'd0;
            mov_counter <= 6'd0;
        end else begin
            _state <= _state_next;
            memory <= memory_next;
            //ptr <= ptr_next;
            address <= address_next;
            available <= available_next;
            mov_counter <= mov_counter_next;
        end
    end

    always@(*) begin
        //ptr_next = ptr;
        memory_next = memory;
        address_next = address;
        available_next = 1'b0;
        mov_counter_next = mov_counter;
        case(_state) 
            INIT: begin
                memory_next = 512'd0;
                _state_next = WAIT;
                //ptr_next = 9'd0;
                address_next = 6'd0;
                available_next = 1'b1;
                mov_counter_next = 6'b0;
            end
            WAIT: begin
                if(ptr_set_value) begin
                    memory_next = {ptr_new_value,memory[8:511]};
                    _state_next = WAIT;
                    available_next = 1'b1;
                end else if(ptr_move &&
                        ptr_move_dir==1'b1 &&
                        address < 6'd63) begin
                    mov_counter_next = 6'd1;
                    _state_next = MOVR;
                end else if(ptr_move &&
                        ptr_move_dir==1'b0 &&
                        address > 6'd0) begin
                    mov_counter_next = 6'd1;
                    _state_next = MOVL;
                end else if(roll_back && address>6'd0) begin
                    _state_next = MOVL;
                    mov_counter_next = address;
                end else begin
                    _state_next = WAIT;
                    available_next = 1'b1;
                end
            end
            MOVL: begin
                memory_next = {memory[504:511],memory[0:503]};
                if(mov_counter == 6'd1) begin
                    mov_counter_next = 6'd0;
                    _state_next = WAIT;
                    available_next = 1'b1;
                    address_next = address - 1;
                end else begin
                    mov_counter_next = mov_counter - 1;
                    address_next = address - 1;
                    _state_next = MOVL;
                end
            end
            MOVR: begin
                memory_next = {memory[8:511],memory[0:7]};
                if(mov_counter == 6'd1) begin
                    mov_counter_next = 6'd0;
                    _state_next = WAIT;
                    available_next = 1'b1;
                    address_next = address + 1;
                end else begin
                    mov_counter_next = mov_counter - 1;
                    address_next = address + 1;
                    _state_next = MOVR;
                end
            end
            default:
                _state_next = INIT;
        endcase
    end

endmodule
