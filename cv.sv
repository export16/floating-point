module fp32_adder(
    input clk,
    input rstn,
    input input_valid,
    input [7:0] fp_data_1,
    input [7:0] fp_data_2,
    input [15:0] input_data,
    output out_valid,
    output reg [31:0] data_out
);
    wire infinity, nan_num;


    wire [4:0] exp_16;
    wire [5:0] sf_16;
    wire [4:0] exp_x;
    wire [10:0] sf_x;

    assign exp_16 = fp_data_1[1:0] + fp_data_2[6:2];
    assign sf_16 = {(fp_data_1[6:2] == 0 ? 0 : 1), fp_data_1[1:0]} * {(fp_data_2[6:2] == 0 ? 0 : 1), fp_data_2[1:0]};
    assign exp_x = (exp_16 >= 46) ? 31 : (exp_16 < 15) ? 0 : (exp_16 - 15);
    assign sf_x = exp_16 >= 46 || exp_16 < 15 ? 0 : {sf_16, 5'h0};

    wire [4:0] exp_1;
    wire [4:0] exp_2;
    wire [23:0] sf_1;
    wire [23:0] sf_2;    

    assign exp_1 = exp_x < input_data[14:10] ? input_data[14:10] : exp_x;
    assign exp_2 = input_data[14:10] < exp_x ? exp_x : input_data[14:10];
    assign sf_1 = (exp_x < input_data[14:10]) ? {sf_x, 12'h0} >> (input_data[14:10] - exp_x) : {sf_x, 12'h0};
    assign sf_2 = (input_data[14:10] < exp_x) ? {input_data[9:0], 12'h0} >> (exp_x - input_data[14:10]) : {input_data[9:0], 12'h0};

    wire sign;

    assign sign = ((fp_data_1[7] ^ fp_data_2[7]) == input_data[15]) ? input_data[15] : (sf_1 >= sf_2) ? sf_1 : sf_2;

    wire [7:0] exp_out_1;
    wire [24:0] sf_out_1;

    assign exp_out_1 = exp_1 + 112;
    assign sf_out_1 = ((fp_data_1[7] ^ fp_data_2[7]) == input_data[15]) ? sf_1 + sf_2 : (sf_1 > sf_2) ? sf_1 - sf_2 : sf_2 - sf_1;

    wire [7:0] exp_out_2;
    wire [23:0] sf_out_2;

    assign exp_out_2 = sf_out_1[24] ? exp_out_1 + 1 : sf_out_1[23:8] == 0 ? exp_1 - 16 : exp_1;
    assign sf_out_2 = sf_out_1[24] ? sf_out_1[24:1] : sf_out_1[23:8] == 0 ? sf_out_1 << 16 : sf_out_1[23:0];

    wire [7:0] exp_out_3;
    wire [23:0] sf_out_3;

    assign exp_out_3 = sf_out_2[23:16] == 0 ? exp_out_2 - 8 : exp_out_2;
    assign sf_out_3 = sf_out_2[23:16] == 0 ? sf_out_2 << 8 : sf_out_2;

    wire [7:0] exp_out_4;
    wire [23:0] sf_out_4;
    
    assign exp_out_4 = sf_out_3[23:20] == 0 ? exp_out_3 - 4 : exp_out_3;
    assign sf_out_4 = sf_out_3[23:20] == 0 ? sf_out_3 << 4 : sf_out_3;

    wire [7:0] exp_out_5;
    wire [23:0] sf_out_5;
    
    assign exp_out_5 = sf_out_4[23:22] == 0 ? exp_out_4 - 2 : exp_out_4;
    assign sf_out_5 = sf_out_4[23:22] == 0 ? sf_out_4 << 2 : sf_out_4;
    
    wire [7:0] exp_out_6;
    wire [23:0] sf_out_6;
    
    assign exp_out_6 = sf_out_5[23] == 0 ? exp_out_5 - 1 : exp_out_5;
    assign sf_out_6 = sf_out_5[23] == 0 ? sf_out_5 << 1 : sf_out_5;


    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_out <= 0;
        end
        else if(input_valid && !nan_num && !infinity) begin
            data_out <= {sign, exp_out_6, sf_out_6};
        end
    end

endmodule