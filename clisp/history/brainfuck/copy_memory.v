
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

    reg [0:511]memory,memory_next; //8bit * 128
    wire [0:511]setted_mem;
    reg [8:0]ptr = 9'd0;
    reg [8:0]ptr_next;
    mux512_8 mux(  .selector(ptr),
                   .vector(memory),
                   .setting(ptr_new_value),
                   .result(setted_mem));
    assign ptr_value = memory[ptr*8+:8];




    reg [5:0]address = 6'd0;
    reg [5:0]address_next;

    //assign mem_monitor1 = {address-6'd1,memory[508:511]};
    assign mem_monitor2 = {address,ptr_value};
    //assign mem_monitor3 = {address+6'd1,memory[8:15]};


    parameter INIT = 1'b0,
              WAIT = 1'b1;
    reg _state = INIT;
    reg _state_next = INIT;


    always@(posedge working_clock,posedge reset) begin
        if(reset) begin
            _state <= INIT;
        end else begin
            _state <= _state_next;
            memory <= memory_next;
            ptr <= ptr_next;
            address <= address_next;
        end
    end

    always@(*) begin
        ptr_next = ptr;
        memory_next = memory;
        address_next = address;
        case(_state) 
            INIT: begin
                memory_next = 512'd0;
                _state_next = WAIT;
                ptr_next = 9'd0;
                address_next = 6'd0;
            end
            WAIT: begin
                _state_next = WAIT;
                if(ptr_set_value) 
                    memory_next = setted_mem;
                else if(ptr_move) begin
                    if(ptr_move_dir==1'b1 && ptr<9'd508) begin
                        ptr_next = ptr+8;
                        address_next = address+1;
                    end else if(ptr>9'd0) begin
                        ptr_next = ptr-8;
                        address_next = address-1;
                    end
                end else if(roll_back)
                    ptr_next = 9'd0;
            end
            default:
                _state_next = INIT;
        endcase
    end


endmodule
