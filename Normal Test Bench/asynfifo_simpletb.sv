// Total 2 Set of Test Cases

// First Set: write opeation fast read operation slow.
//          Test Case 1: simultaneous read and write.
//          Test Case 2: write until fifo full and read until fifo empty
//          loop goes on.
//
// Second Set: write operation slow read operation fast.
//          Same Test Cases as above


`timescale 1ns/1ns                      // Delay values of rounded off to integers
`include "asynfifo_design.sv"

module asynfifo_simpletb;
    parameter WIDTH = 4;
    reg rd_clk, wr_clk, rst, rd_enable, wr_enable;
    reg [WIDTH-1:0]wr_data;
    wire [WIDTH-1:0]rd_data;
    wire full, overflow, empty, underflow;
    enum {start_wr,start_rd} phase;

    asynfifo_design #(32) d1(
        rd_clk, wr_clk, rst, rd_enable,
        wr_enable, wr_data, rd_data, full,
        overflow, empty, underflow
    );

    `ifdef rd_fast_wr_slow              // wr_clk with 50Mhz frequency
        always #10 begin                // rd_clk with 100Mhz frequency
            wr_clk = ~wr_clk;
        end

        always #5 begin
            rd_clk = ~rd_clk;
        end

    `else                               // wr_clk with 100Mhz frequency
        always #5 begin                 // rd_clk with 50Mhz frequency
            wr_clk = ~wr_clk;
        end

        always #10 begin
            rd_clk = ~rd_clk;
        end

    `endif

    `ifdef wr_after_rd
        task write;
            forever begin
                @(negedge wr_clk);
                if(phase == start_wr) begin
                    if(!rst) begin
                        if(!full) begin
                            wr_enable = 1;
                            wr_data = $random;
                        end else if(full) begin
                            wr_enable = 0;
                            wr_data = 'bx;
                            phase = start_rd;
                        end
                    end
                end
            end
        endtask : write

        task read;
            forever begin
                @(negedge rd_clk);
                if(phase == start_rd) begin
                    if(!rst) begin
                        if(!empty) begin
                            rd_enable = 1;
                        end else if(empty) begin
                            rd_enable = 0;
                            phase = start_wr;
                        end
                    end
                end
            end
        endtask : read

    `else
        task write;
            forever begin
                @(negedge wr_clk);
                if(!rst) begin
                    if(!full) begin
                        wr_data = $random;
                        wr_enable = 1;
                    end else if (full) begin
                        wr_data = 'bx;
                        wr_enable = 0;
                    end
                end
            end
        endtask : write

        task read;
            forever begin
                @(negedge rd_clk);
                if(!rst) begin
                    if(!empty) begin
                        rd_enable = 1;
                    end else if(empty) begin
                        rd_enable = 0;
                    end
                end
            end
        endtask : read

    `endif

    initial begin
        wr_clk = 0;
        rd_clk = 0;
        phase = start_wr;
    end

    initial begin
        rst = 1;
        @(posedge wr_clk);
        rst = 0;
    end

    initial begin
        #5000 $finish;
    end

    initial fork
        write;
        read;
    join

endmodule
