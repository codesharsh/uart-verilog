module uart_rx (
    input clk,
    input rst,
    input RX_in,
    output parity_bit_error,
    output stop_bit_error,
    output wire [7:0]rx_data_out
);
wire w1,w2,w3,w4,w5,w6;
baud_gen f0(clk,rst,w6);
RX_fsm f1(w6,clk,rst,w1,w2,w4,w5);
detect_start f2(clk,rst,RX_in,w1);
sipo f3(RX_in,w2,clk,rst,w3);
parity_check f4(rst,clk,w4,w3,RX_in,parity_bit_error);
stop_bit_check f5(clk,rst,w5,RX_in,stop_bit_error);
// w1--start bit,w2--shift,w3--transfer,parityload--w4,w6--tick,w5--stopload
assign rx_data_out=w3;
endmodule
module detect_start(
    input clk,
    input rst,
    input RX_in,
    output reg start_bit
);
reg temp;
always @(posedge clk or posedge rst) begin
    temp<=RX_in;
    if(rst)begin
        start_bit<=0;
    end  
    else if(temp & ~RX_in) begin
        start_bit<=1;
    end
    else begin
        start_bit<=0;
    end
end
endmodule
module sipo(
    input RX_in,
    input shift,
    input clk,
    input rst,
    output wire [7:0] transfer
);
    reg [7:0] temp;

    assign transfer = temp;

    always @(posedge clk or posedge rst) begin
        if (rst)
            temp <= 0;
        else if (shift)
            temp <= {RX_in, temp[7:1]};
    end
endmodule
module parity_check(
    input rst,
    input clk,
    input parity_load,
    input wire[7:0] transfer,
    input RX_in,
    output wire parity_bit_error
);
reg [8:0] temp;
always @(posedge clk or posedge rst) begin
    if(rst)begin
        temp<=0;
    end
    else if(parity_load)begin
        temp<={RX_in,transfer};
    end
end
assign parity_bit_error=^temp;
endmodule
module stop_bit_check(
    input clk,
    input rst,
    input stop_load,
    input RX_in,
    output reg stop_bit_error
);
always @(posedge clk or posedge rst) begin
    if(rst)begin
        stop_bit_error<=0;
    end
    else if (stop_load) begin
        stop_bit_error<=(~RX_in);
    end
end
endmodule
module RX_fsm(
    input tick,
    input clk,
    input rst,
    input start_bit,
    output reg shift,
    output reg parity_load,
    output reg stop_load
);
localparam IDLE  = 3'b000;
localparam START = 3'b001;
localparam DATA  = 3'b010;
localparam PARITY= 3'b011;
localparam STOP  = 3'b100;

reg[2:0]current_state;
reg[2:0]next_state;
reg[2:0] tick_data_count;
always@(posedge clk or posedge rst) begin
    if(rst)begin
        current_state<=IDLE;
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
always@(*)begin
    case (current_state)
    IDLE:  next_state=(start_bit)?START:IDLE;
    START: next_state = (tick) ? DATA : START;
    DATA:  next_state=(tick_data_count==3'b111 && tick)?PARITY:DATA;
    PARITY:next_state=(tick)?STOP:PARITY;
    STOP:  next_state=(tick)?IDLE:STOP;
    endcase
end
always@(*) begin
    case (current_state)
    IDLE:begin
        shift=1'b0;
        parity_load=1'b0;
        stop_load=1'b0;
    end
    START: begin
        shift = 1'b0;
        parity_load = 1'b0;
        stop_load = 1'b0;
    end
    DATA:begin
        shift=(tick)? 1:0;
        parity_load=1'b0;
        stop_load=1'b0;
    end
    PARITY:begin
        shift=1'b0;
        parity_load=1'b1;
        stop_load=1'b0;
    end
    STOP:begin
        shift=1'b0;
        parity_load=1'b0;
        stop_load=1'b1;
    end
    default:begin
        shift=1'b0;
        parity_load=1'b0;
        stop_load=1'b0;
    end
    endcase
end
endmodule