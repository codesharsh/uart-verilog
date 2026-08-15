module baud_gen
    #(parameter CLK_FREQ =50000000,
    parameter baud_rate=9600,)
    (input wire clk,
    input wire rst,
    output reg tick);
    localparam integer clK_per_bit = CLK_FREQ / baud_rate; //5208 cycles
    integer i;
    always@(posedge clk)
    begin
        if(rst==1)
        begin
            tick<=0;
            i<=0
        end
        else
        begin
            if(i==clK_per_bit-1)
                begin 
                    tick<=1;
                    i<=0;
                end
            else
            begin
                i<=i+1;
                tick<=0;
            end
        end
    end 
endmodule