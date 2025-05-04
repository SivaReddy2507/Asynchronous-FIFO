module asynfifo_design #(
        DEPTH = 16, WIDTH = 4                                   // Can be overridden at compile time
    ) (
        input rd_clk, wr_clk, rst,
        input rd_enable, wr_enable,
        input [WIDTH-1:0]wr_data,
        output reg [WIDTH-1:0]rd_data,
        output reg full, overflow, empty, underflow
    );

    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [ADDR_WIDTH:0]wr_addr, rd_addr;
    reg [WIDTH-1:0]fifo[DEPTH-1:0];                             // Declaration of fifo memory
    reg [ADDR_WIDTH:0]gray_wr_addr, gray_rd_addr;
    reg [ADDR_WIDTH:0]wr_addr_flop1, wr_addr_flop2;
    reg [ADDR_WIDTH:0]rd_addr_flop1, rd_addr_flop2;


    always_ff @(posedge wr_clk or posedge rst) begin            // Asynchronous Active high reset
        if(rst) begin
            wr_addr = 'b0;
        end else if(wr_enable && !full) begin
            fifo[wr_addr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_addr <= wr_addr + 1;
        end
    end

    always_ff @(posedge rd_clk or posedge rst) begin
        if(rst) begin
            rd_addr = 'b0;
        end else if(rd_enable && !empty) begin
            rd_data <= fifo[rd_addr[ADDR_WIDTH-1:0]];
            rd_addr <= rd_addr + 1;
        end
    end

    always_comb begin
        gray_wr_addr = wr_addr ^ (wr_addr >> 1);
    end

    always_comb begin
        gray_rd_addr = rd_addr ^ (rd_addr >> 1);
    end

    always_ff @(posedge rd_clk or posedge rst) begin
        if(rst) begin
            wr_addr_flop1 = 'b0;
            wr_addr_flop2 = 'b0;
        end else begin
            wr_addr_flop1 <= gray_wr_addr;
            wr_addr_flop2 <= wr_addr_flop1;
        end
    end

    always_ff @(posedge wr_clk or posedge rst) begin
        if(rst) begin
            rd_addr_flop1 = 'b0;
            rd_addr_flop2 = 'b0;
        end else begin
            rd_addr_flop1 <= gray_rd_addr;
            rd_addr_flop2 <= rd_addr_flop1;
        end
    end

    always_comb begin
        full = {~gray_wr_addr[ADDR_WIDTH:ADDR_WIDTH-1],gray_wr_addr[ADDR_WIDTH-2:0]} == rd_addr_flop2;
    end

    always_comb begin
        empty = gray_rd_addr == wr_addr_flop2;
    end

    always_comb begin
        overflow = full && wr_enable;
    end

    always_comb begin
        underflow = empty && rd_enable;
    end

endmodule : asynfifo_design
