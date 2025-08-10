module SPI (
    input [7:0] tx_data,
    input MOSI, SS_n, clk, rst_n, tx_valid,
    output reg [9:0] rx_data,
    output reg MISO, rx_valid
);

    // State encoding
    localparam IDLE       = 3'b000;
    localparam WRITE      = 3'b001;
    localparam CHK_CMD    = 3'b010;
    localparam READ_ADD   = 3'b011;
    localparam READ_DATA  = 3'b100;

    reg [2:0] cs, ns;
    reg read_add_done;
    reg [9:0] serial_to_parallel;
    reg [7:0] parallel_to_serial;

    // State memory and reset
    always @(posedge clk) begin
        if (!rst_n)
            cs <= IDLE, ns <= IDLE,
            read_add_done <= 0,
            serial_to_parallel <= 0,
            parallel_to_serial <= 0,
            rx_valid <= 0,
            rx_data <= 0,
            MISO <= 0;
        else
            cs <= ns;
    end

    // Next state logic
    always @(posedge clk) begin
        case (cs)
            IDLE:
                if (SS_n) ns <= IDLE; 
                else ns <= CHK_CMD;

            WRITE:
                if (~SS_n) ns <= WRITE; 
                else ns <= IDLE;

            READ_ADD:
                if (~SS_n) ns <= READ_ADD; 
                else ns <= IDLE;

            READ_DATA:
                if (~SS_n) ns <= READ_DATA; 
                else ns <= IDLE;

            CHK_CMD:
                if (SS_n) ns <= IDLE;
                else if (~MOSI) ns <= WRITE;
                else if (read_add_done) ns <= READ_DATA;
                else ns <= READ_ADD;
        endcase
    end

    // Output logic
    always @(posedge clk) begin
        // Shift in MOSI and shift out MISO
        serial_to_parallel <= {serial_to_parallel[8:0], MOSI};
        parallel_to_serial <= {parallel_to_serial[6:0], 1'b0};
        MISO <= parallel_to_serial[7];

        // Output valid data when SS_n goes high
        if ((cs == READ_ADD || cs == READ_DATA || cs == WRITE) && SS_n)begin
            rx_valid <= 1;
            rx_data <= serial_to_parallel;
        end

        // Clear rx_valid when transitioning to IDLE
        if ((cs == READ_ADD || cs == READ_DATA || cs == WRITE) && ns == IDLE)
            rx_valid <= 0;

        // Reset input shift register on transition from IDLE
        if (cs == IDLE && (ns == READ_ADD || ns == READ_DATA || ns == WRITE))
            serial_to_parallel <= 0;

        // Manage address read status
        if (cs == READ_ADD && ns == IDLE) read_add_done <= 1;
        if (cs == READ_DATA && ns == IDLE) read_add_done <= 0;

        // Load transmit data
        if (tx_valid) parallel_to_serial <= tx_data;
    end

endmodule
