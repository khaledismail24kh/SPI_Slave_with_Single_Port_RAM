module SPI_RAM (
    // SPI external interface
    input        MOSI,
    output       MISO,
    input        SS_n,
    input        clk,
    input        rst_n
);

    // Wires between SPI and RAM
    wire [9:0] spi_rx_data;
    wire       spi_rx_valid;
    wire [7:0] spi_tx_data;
    wire       spi_tx_valid;

    // Instantiate SPI slave
    SPI spi_inst (
        .tx_data  (spi_tx_data),     // from RAM dout
        .MOSI     (MOSI),
        .SS_n     (SS_n),
        .clk      (clk),
        .rst_n    (rst_n),
        .tx_valid (spi_tx_valid),    // from RAM tx_valid
        .rx_data  (spi_rx_data),
        .MISO     (MISO),
        .rx_valid (spi_rx_valid)
    );

    // Instantiate single-port RAM
    RAM ram_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx_valid (spi_rx_valid),    // from SPI
        .din      (spi_rx_data),     // from SPI
        .dout     (spi_tx_data),     // to SPI
        .tx_valid (spi_tx_valid)     // to SPI
    );

endmodule
