module mem_arbiter #(
    parameter FIFO_DEPTH     = 4,
    parameter TIMEOUT_CYCLES = 8
)(
    input  wire        clk,
    input  wire        rst_n,

    // Port A - Master Request Interface
    input  wire        a_req_valid,
    output wire        a_req_ready,
    input  wire [2:0]  a_req_addr,
    input  wire [7:0]  a_req_wdata,
    input  wire        a_req_wr,

    // Port A - Master Response Interface
    output reg         a_resp_valid,
    input  wire        a_resp_ready,
    output reg  [7:0]  a_resp_rdata,
    output reg         a_resp_err,

    // Port B - Master Request Interface
    input  wire        b_req_valid,
    output wire        b_req_ready,
    input  wire [2:0]  b_req_addr,
    input  wire [7:0]  b_req_wdata,
    input  wire        b_req_wr,

    // Port B - Master Response Interface
    output reg         b_resp_valid,
    input  wire        b_resp_ready,
    output reg  [7:0]  b_resp_rdata,
    output reg         b_resp_err,

    // Memory Interface
    output reg         mem_req,
    output reg  [2:0]  mem_addr,
    output reg  [7:0]  mem_wdata,
    output reg         mem_wr,
    input  wire [7:0]  mem_rdata,
    input  wire        mem_ack,
    input  wire        mem_err,

    // Status
    output wire        busy,
    output wire        active_port,
    output reg  [7:0]  err_count
);

    // ----------------------------------------------------------------
    // FSM State Encoding
    // ----------------------------------------------------------------
    localparam [2:0] S_IDLE     = 3'd0,
                     S_MEM_REQ  = 3'd1,
                     S_WAIT_ACK = 3'd2,
                     S_RESP     = 3'd3,
                     S_ERROR    = 3'd4;

    reg [2:0] state, state_nxt;

    // ----------------------------------------------------------------
    // Transaction Registers
    // ----------------------------------------------------------------
    reg [2:0]  txn_addr;
    reg [7:0]  txn_wdata;
    reg        txn_wr;
    reg        txn_port;    // 0 = Port A, 1 = Port B
    reg        txn_error;
    reg [7:0]  txn_rdata;

    // ----------------------------------------------------------------
    // Round-Robin Arbitration
    // ----------------------------------------------------------------
    reg rr_priority;  // 0 = Port A has priority, 1 = Port B

    // ----------------------------------------------------------------
    // Timeout
    // ----------------------------------------------------------------
    reg  [7:0] timeout_cnt;
    wire       timeout = (timeout_cnt >= TIMEOUT_CYCLES);

    // ----------------------------------------------------------------
    // Port A FIFO
    // ----------------------------------------------------------------
    wire        fifo_a_wr   = a_req_valid && a_req_ready;
    wire [11:0] fifo_a_din  = {a_req_addr, a_req_wdata, a_req_wr};
    wire [11:0] fifo_a_dout;
    wire        fifo_a_full, fifo_a_empty;
    wire        fifo_a_rd;

    sync_fifo #(.DATA_WIDTH(12), .DEPTH(FIFO_DEPTH)) u_fifo_a (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (fifo_a_wr),
        .wr_data (fifo_a_din),
        .rd_en   (fifo_a_rd),
        .rd_data (fifo_a_dout),
        .full    (fifo_a_full),
        .empty   (fifo_a_empty)
    );

    // ----------------------------------------------------------------
    // Port B FIFO
    // ----------------------------------------------------------------
    wire        fifo_b_wr   = b_req_valid && b_req_ready;
    wire [11:0] fifo_b_din  = {b_req_addr, b_req_wdata, b_req_wr};
    wire [11:0] fifo_b_dout;
    wire        fifo_b_full, fifo_b_empty;
    wire        fifo_b_rd;

    sync_fifo #(.DATA_WIDTH(12), .DEPTH(FIFO_DEPTH)) u_fifo_b (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (fifo_b_wr),
        .wr_data (fifo_b_din),
        .rd_en   (fifo_b_rd),
        .rd_data (fifo_b_dout),
        .full    (fifo_b_full),
        .empty   (fifo_b_empty)
    );

    // ----------------------------------------------------------------
    // req_ready Generation
    // ----------------------------------------------------------------
    assign a_req_ready = rst_n ? ~fifo_a_full : 1'b1;
    assign b_req_ready = rst_n ? ~fifo_b_full : 1'b1;

    // ----------------------------------------------------------------
    // Arbitration Logic
    // ----------------------------------------------------------------
    wire a_has_req = !fifo_a_empty;
    wire b_has_req = !fifo_b_empty;
    wire any_req   = a_has_req || b_has_req;

    // sel_port: 0 = select A, 1 = select B
    wire sel_port  = b_has_req && (!a_has_req || rr_priority);

    assign fifo_a_rd = (state == S_IDLE) && any_req && !sel_port;
    assign fifo_b_rd = (state == S_IDLE) && any_req &&  sel_port;

    wire [11:0] selected_data = sel_port ? fifo_b_dout : fifo_a_dout;

    // ----------------------------------------------------------------
    // Response Routing Helpers
    // ----------------------------------------------------------------
    wire resp_ready_mux = txn_port ? b_resp_ready : a_resp_ready;
    wire resp_valid_mux = txn_port ? b_resp_valid : a_resp_valid;

    assign active_port = txn_port;
    assign busy        = (state != S_IDLE);

    // ----------------------------------------------------------------
    // FSM: State Register
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= S_IDLE;
        else        state <= state_nxt;

    // ----------------------------------------------------------------
    // FSM: Next State Logic
    // ----------------------------------------------------------------
    always @(*) begin
        state_nxt = state;
        case (state)
            S_IDLE:
                if (any_req)
                    state_nxt = S_MEM_REQ;

            S_MEM_REQ:
                state_nxt = S_WAIT_ACK;

            S_WAIT_ACK:
                if (timeout)
                    state_nxt = S_ERROR;
                else if (mem_ack) begin
                    if (mem_err)
                        state_nxt = S_ERROR;
                    else
                        state_nxt = S_RESP;
                end

            S_RESP:
                if (resp_valid_mux && resp_ready_mux)
                    state_nxt = S_IDLE;

            S_ERROR:
                state_nxt = S_RESP;

            default:
                state_nxt = S_IDLE;
        endcase
    end

    // ----------------------------------------------------------------
    // Datapath
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txn_addr     <= 3'd0;
            txn_wdata    <= 8'd0;
            txn_wr       <= 1'b0;
            txn_port     <= 1'b0;
            txn_error    <= 1'b0;
            txn_rdata    <= 8'd0;
            rr_priority  <= 1'b0;
            timeout_cnt  <= 8'd0;
            mem_req      <= 1'b0;
            mem_addr     <= 3'd0;
            mem_wdata    <= 8'd0;
            mem_wr       <= 1'b0;
            a_resp_valid <= 1'b0;
            a_resp_rdata <= 8'd0;
            a_resp_err   <= 1'b0;
            b_resp_valid <= 1'b0;
            b_resp_rdata <= 8'd0;
            b_resp_err   <= 1'b0;
            err_count    <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    a_resp_valid <= 1'b0;
                    b_resp_valid <= 1'b0;
                    mem_req      <= 1'b0;
                    txn_error    <= 1'b0;
                    timeout_cnt  <= 8'd0;
                    if (any_req) begin
                        txn_port <= sel_port;
                        {txn_addr, txn_wdata, txn_wr} <= selected_data;
                    end
                end

                S_MEM_REQ: begin
                    mem_req     <= 1'b1;
                    mem_addr    <= txn_addr;
                    mem_wdata   <= txn_wdata;
                    mem_wr      <= txn_wr;
                    timeout_cnt <= 8'd0;
                end

                S_WAIT_ACK: begin
                    timeout_cnt <= timeout_cnt + 8'd1;
                    if (mem_ack) begin
                        mem_req <= 1'b0;
                        if (!txn_wr)
                            txn_rdata <= mem_rdata;
                        if (mem_err) begin
                            txn_error <= 1'b1;
                            err_count <= err_count + 8'd1;
                        end
                    end
                end

                S_RESP: begin
                    if (!txn_port) begin
                        a_resp_valid <= 1'b1;
                        a_resp_rdata <= txn_rdata;
                        a_resp_err   <= txn_error;
                        if (a_resp_valid && a_resp_ready)
                            a_resp_valid <= 1'b0;
                    end else begin
                        b_resp_valid <= 1'b1;
                        b_resp_rdata <= txn_rdata;
                        b_resp_err   <= txn_error;
                        if (b_resp_valid && b_resp_ready)
                            b_resp_valid <= 1'b0;
                    end
                    if (resp_valid_mux && resp_ready_mux)
                        rr_priority <= ~txn_port;
                end

                S_ERROR: begin
                    txn_error <= 1'b1;
                    mem_req   <= 1'b0;
                end
            endcase
        end
    end

endmodule
