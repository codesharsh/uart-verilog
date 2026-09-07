`timescale 1ns/1ns

module uart_loopback_tb;

    reg clk = 0;
    reg rst;
    reg TX_start;
    reg [7:0] TX_data_in;

    wire tx_busy;
    wire Tx_data_out;      // TX output -> RX input
    wire parity_bit_error;
    wire stop_bit_error;
    wire [7:0] rx_data_out;

    // Instantiate TX
    uart_tx UUT_TX (
        .clk(clk),
        .rst(rst),
        .TX_start(TX_start),
        .TX_data_in(TX_data_in),
        .tx_busy(tx_busy),
        .Tx_data_out(Tx_data_out)
    );

    // Instantiate RX — RX_in fed directly from TX's output
    uart_rx UUT_RX (
        .clk(clk),
        .rst(rst),
        .RX_in(Tx_data_out),
        .parity_bit_error(parity_bit_error),
        .stop_bit_error(stop_bit_error),
        .rx_data_out(rx_data_out)
    );

    // Clock generation
    always #5 clk = ~clk;   // adjust period as needed

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_loopback_tb);

        // 1. Reset
        rst = 1;
        TX_start = 0;
        TX_data_in = 8'b0;
        #20;
        rst = 0;

        // 2. Send a byte
        #20;
        TX_data_in = 8'b1010_0110;
        TX_start = 1;
        #10;
        TX_start = 0;

        // 3. Wait for transmission + reception to complete
        // (needs to be long enough for the whole frame)
        #500000;

        // 4. Check result
        if (rx_data_out == 8'b1010_0110)
            $display("PASS: received byte matches sent byte (%b)", rx_data_out);
        else
            $display("FAIL: sent %b, received %b", TX_data_in, rx_data_out);

        if (parity_bit_error)
            $display("FAIL: parity error flagged");
        if (stop_bit_error)
            $display("FAIL: stop bit error flagged");

        $finish;
    end

endmodule