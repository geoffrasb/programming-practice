module Console_module (
    input reset,
    output [7:0] LCD_DATA,
    output LCD_ENABLE,
    output LCD_RW,
    output LCD_RSTN,
    output LCD_CS1,
    output LCD_CS2,
    output LCD_DI,
    input working_clock,
    //abstract interface
    input to_mode,
    input change_mode,
    input please_wait,
    input [13:0]mem_monitor2,
    input [3:0]symbol_to_insert,
    input insert,
    input delete,
    input cursor_dir,
    input move_cursor,
    output available
    );

    parameter ceo = 4'b1001,

    reg output_device = 0;
    reg output_device_next = 0;

    LCD_display lcd(
        .lcd_clock(lcd_clock),
        .working_clock(working_clock),
        .LCD_DATA(LCD_DATA),
        .LCD_ENABLE(LCD_ENABLE),
        .LCD_RW(LCD_RW),
        .LCD_RSTN(LCD_RSTN),
        .LCD_CS1(LCD_CS1),
        .LCD_CS2(LCD_CS2),
        .LCD_DI(LCD_DI),
        .to_mode(to_mode),
        .change_mode(change_mode),
        .please_wait(please_wait),
        .mem_monitor(mem_monitor2),
        .output_device(1'b0),
        .symbol_to_insert(symbol_to_insert),
        .insert(insert),
        .delete(delete),
        .cursor_dir(cursor_dir),
        .move_cursor(move_cursor),
        .available(available),
        .resetn(reset)
    );
/*
    always@(posedge working_clock) begin
        output_device <= output_device_next;
    end

    always@(*) begin
        output_device_next = output_device;
        if(insert && symbol_to_insert == ceo) 
            output_device_next = output_device+1;
        else if(delete && mem_monitor1[7:0]==ceo)
            output_device_next = output_device+1;
        else if(move_cursor)
            if(move_dir==1'b1 && mem_monitor2[7:0]==ceo)
                output_device_next = output_device+1;
            else if(move_dir==1'b0 && mem_monitor1[7:0]==ceo)
                output_device_next = output_device+1;
    end
*/
endmodule
