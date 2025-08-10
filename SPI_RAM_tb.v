`timescale 1ns/1ps

module SPI_RAM_tb;
    // SPI external pins
    reg        MOSI;
    wire       MISO;
    reg        SS_n;
    reg        clk;
    reg        rst_n;

    // Instantiate top-level DUT (Device Under Test)
    SPI_RAM uut (
        .MOSI  (MOSI),
        .MISO  (MISO),
        .SS_n  (SS_n),
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Helper registers
    reg [9:0] data_reg;   // Data to be transmitted (10-bit frame)
    reg [7:0] data_got;   // Data received from MISO

    // Clock: 50MHz (20ns period)
    initial clk = 0;
    always #10 clk = ~clk;

    integer i;

    initial begin
        // Reset phase
        rst_n = 0;
        SS_n = 1;
        MOSI = 1;
        data_got = 0;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // -------- WRITE phase --------
        // Transaction 1: Write to address 3
        SS_n = 0;
        @(negedge clk);
        MOSI = 0; // Command bit = 0 → WRITE
        data_reg = 10'b00_0000_0011; // Addr = 3
        @(negedge clk);

        for (i = 9; i >= 0; i = i - 1) begin
            MOSI = data_reg[i];
            @(negedge clk);
        end

        // Deassert SS to latch and trigger rx_valid
        SS_n = 1;
        @(negedge clk);
        @(negedge clk);

        // Transaction 2: Write to address 7
        SS_n = 0;
        @(negedge clk);
        MOSI = 0; // Command bit = 0 → WRITE
        data_reg = 10'b01_0000_0111; // Addr = 7
        @(negedge clk);

        for (i = 9; i >= 0; i = i - 1) begin
            MOSI = data_reg[i];
            @(negedge clk);
        end

        // Deassert SS to latch and trigger rx_valid
        SS_n = 1;
        @(negedge clk);
        @(negedge clk);

        // -------- READ phase --------
        // Transaction 3: Read from address 3
        SS_n = 0;
        @(negedge clk);
        MOSI = 1; // Command bit = 1 → READ
        data_reg = 10'b10_0000_0011;
        @(negedge clk);

        for (i = 9; i >= 0; i = i - 1) begin
            MOSI = data_reg[i];
            @(negedge clk);
        end

        // Deassert SS to latch and trigger rx_valid
        SS_n = 1;
        @(negedge clk);
        @(negedge clk);

        // Transaction 4: Read (read command + dummy bits)
        SS_n = 0;
        @(negedge clk);
        MOSI = 1; // Command bit = 1 → READ
        data_reg = 10'b11_0000_0011;
        @(negedge clk);

        for (i = 9; i >= 0; i = i - 1) begin
            MOSI = data_reg[i];
            @(negedge clk);
        end

        // Deassert SS to latch and prepare for read
        SS_n = 1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        // Capture 8-bit output from MISO
        for (i = 7; i >= 0; i = i - 1) begin
            data_got = {data_got[6:0], MISO};
            @(negedge clk);
        end

        // Check received data
        if (data_got == 8'd7)
            $display("Test passed: Received data = Expected value = %0d", data_got);
        else
            $display("Test failed: Expected 7, but got %0d", data_got);


        @(negedge clk);
        $stop;
    end

endmodule
