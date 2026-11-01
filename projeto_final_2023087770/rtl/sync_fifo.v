module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 4,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,

    input  wire                    rd_en,
    output wire [DATA_WIDTH-1:0]   rd_data,

    output wire                    full,
    output wire                    empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   wr_ptr;
    reg [ADDR_WIDTH:0]   rd_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (rd_en && !empty)
            rd_ptr <= rd_ptr + 1'b1;
    end

    assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];

    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

    assign empty = (wr_ptr == rd_ptr);
endmodule
