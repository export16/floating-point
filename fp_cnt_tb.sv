`timescale 1ns / 1ps

module fp_cnt_tb();

    parameter buf_size = 64;
    parameter RLEN = 128;
    parameter sizeK = RLEN / 8;  
    parameter sizeM = RLEN / 32;

    reg clk;
    reg rstn;
    reg input_valid;
    reg [7:0] fp_data_1;
    reg [7:0] fp_data_2;
    reg [31:0] input_data;


    wire out_valid;
    wire [31:0] data_out;

    fp_cnt uut (
        .clk(clk),
        .rstn(rstn),
        .input_valid(input_valid),
        .fp_data_1(fp_data_1),
        .fp_data_2(fp_data_2),
        .input_data(input_data),
        .out_valid(out_valid),
        .data_out(data_out)
    );

    initial begin
        clk = 1;
        forever #0.5ns clk = ~clk;
    end

    initial begin
        rstn = 0;
        fp_data_1 = 0;
        fp_data_2 = 0;
        input_valid = 0;

        #8ns rstn = 1;

        #1ns;
        fp_data_1 <= 8'h3E;
        fp_data_2 <= 8'h3E;
        input_valid <= 1;
        input_data <= 32'h3E800000;

        #1ns;

        #1ns;
        #1ns;

        if(data_out != 32'h40200000) begin
            $display("the data is wrong, should not print %h", data_out);
        end 

        #10ns $finish;
    end


    initial begin
        // $monitor("Time=%0t, clk=%b, rstn=%b, rst=%b, add=%b, sub=%b, mul=%b, x=%p, y=%d, out=%p",
        //          $time, clk, rstn, rst, add_valid, sub_valid, mul_valid, data_x, data_y, data_out[2]);
    end
endmodule