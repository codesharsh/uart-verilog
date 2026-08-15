module uart_tx(
    input clk,
    input rst,
    input TX_start,
    input [7:0] TX_data_in,
    output tx_busy,
    output Tx_data_out
);
wire w1,w2,w3,w4,w5,w6;
baud_gen f0(clk,rst,w6);
Tx_fsm f1(clk,rst,w6,TX_start,w1,w2,w3,tx_busy);
piso f2(clk,rst,TX_data_in,w1,w2,w4);
parity_gen f3(TX_data_in,w5);
mux f4(w3,w4,w5,Tx_data_out);
//     output wire parity_bit //w5
//     output reg data_out //w4
    // output wire shift,//w1
    // output wire load_data,//w2
    // output reg[1:0] select,//w3
    //w6 tick
endmodule
module Tx_fsm(
    input clk,
    input rst,
    input tick,
    input TX_start,
    output wire shift,//w1
    output wire load_data,//w2
    output reg[1:0] select,//w3
    output wire tx_busy
);
// STATES 
localparam IDLE  =3'b000;
localparam START =3'b001;
localparam DATA  =3'b010;
localparam PARITY=3'b011;
localparam STOP  =3'b100;
// variables
reg [2:0]current_state;
reg [2:0]next_state;
reg[2:0] tick_data_count;
//logic
always@(posedge clk or posedge rst) 
begin
    if(rst) begin
        current_state<=IDLE;
        tick_data_count<=3'b000;
    end
    else begin
        current_state<=next_state;
    end
end
always@(posedge clk)begin
    if(current_state==DATA && tick)
    begin
        tick_data_count<=tick_data_count+1;
    end
    else if(current_state!=DATA)
    begin
        tick_data_count<=0;
    end
end
always@(*) begin
    case(current_state)
    IDLE:  next_state=(TX_start) ? START : IDLE ;
    START: next_state=(tick) ? DATA :  START ;
    DATA:  next_state=(tick_data_count==3'b111 && tick) ? PARITY : DATA ;
    PARITY:next_state=(tick) ? STOP : PARITY ;
    STOP : next_state=(tick) ? IDLE : STOP ;
    endcase
end 
always@(*) begin
    case (current_state)
        IDLE:begin
            load_data=0;
            shift=0;
            select=2'b00;//no idea i think its dont care so;
            tx_busy=0;
        end
        START:begin
            load_data=1;
            shift=0;
            select=2'b00;
            tx_busy=1;
        end
        DATA:begin
            load_data=0;
            shift=(tick) ? 1:0;
            select=2'b01;
            tx_busy=1;
        end
        PARITY:begin
            load_data=0;
            shift=0;
            select=2'b10;
            tx_busy=1;
        end
        STOP:begin
            load_data=0;
            shift=0;
            select=2'b11;
            tx_busy=1;
        end
        default:begin
            load_data=0;
            shift=0;
            select=2'b00;
            tx_busy=0;
        end
    endcase
end 
endmodule
module piso(
    input clk,
    input rst,
    input [7:0]TX_data_in,
    input shift,
    input load_data,
    output reg data_out
);
reg[7:0] data_register;
assign data_out = data_register[0];
//Inputs: clk, rst, load_data, shift, TX_data_in [7:0]
always@(posedge clk or posedge rst) begin
    if(rst)
    begin
        data_register<=0;
    end
    else if(load_data)
    begin
        data_register<=TX_data_in;
    end
    else if(shift)
    begin
        data_register <= data_register >> 1;
    end
end
endmodule
module parity_gen(
    input [7:0] TX_data_in,
    output wire parity_bit
);
    assign parity_bit = ^TX_data_in;
endmodule
module mux(
input [1:0] select,
input data_out,
input parity_bit,
output reg Tx_data_out
);
always@(*)begin
    case (select)
    2'b00:begin
        Tx_data_out=0;
    end
    2'b01: begin
        Tx_data_out=data_out;
    end
    2'b10:begin
        Tx_data_out=parity_bit;
    end
    2'b11:begin
        Tx_data_out=1;
    end
    default:begin
        Tx_data_out=1;
    end
    endcase
end
endmodule