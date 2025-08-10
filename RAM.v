module RAM #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_SIZE = 8    // 2**ADDR_SIZE must be >= MEM_DEPTH
)(
    input  clk,
    input  rst_n,  
    input  rx_valid, 
    input  [9:0] din,
    output reg [7:0] dout,
    output reg tx_valid    
);
    // Opcodes
    localparam [1:0] OPC_HOLD_ADDR1 = 0 ; // capture address
    localparam [1:0] OPC_WRITE      = 1 ; // write din[7:0] to mem at held address
    localparam [1:0] OPC_HOLD_ADDR2 = 2 ; // capture address 
    localparam [1:0] OPC_READ       = 3 ; // read from held address
    localparam WORD_SIZE = 8;

    // Memory and internal registers
    reg [WORD_SIZE-1:0] mem [0:MEM_DEPTH-1];
    reg [ADDR_SIZE-1:0] address_reg;
    wire [1:0] opcode = din[9:8];
    wire [WORD_SIZE-1:0] load = din[7:0];

    always @(posedge clk) begin
        if (!rst_n) begin
            address_reg <= 0;
            dout <= 0;
            tx_valid <= 0;
        end else begin
            if(tx_valid) tx_valid <= 0;
            if (rx_valid) begin
                case (opcode)
                    OPC_HOLD_ADDR1,
                    OPC_HOLD_ADDR2: 
                        address_reg <= load[ADDR_SIZE-1:0];
                    OPC_WRITE: 
                        mem[address_reg] <= load;
                    OPC_READ: begin
                        dout <= mem[address_reg];
                        tx_valid <= 1;
                    end
                endcase
            end
        end
    end

endmodule