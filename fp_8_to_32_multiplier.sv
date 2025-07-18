module fp_8_to_32_multiplier(
    input clk,
    input rstn,
    input input_valid,
    input [7:0] fp_data_1,
    input [7:0] fp_data_2,
    output nan_num,
    output infinity,
    output [31:0] data_out
);

    wire [7:0] exp_1;
    wire [5:0] sf_1;

    wire [7:0] exp_2;
    wire [4:0] sf_2;

    assign exp_1 = (fp_data_1[6:0] == 0 || fp_data_2[6:0] == 0) ? 0 : (fp_data_1[6:2] == 0 ? 1 : fp_data_1[6:2]) + (fp_data_2[6:2] == 0 ? 1 : fp_data_2[6:2]) + 97;
    assign sf_1 = {(fp_data_1[6:2] == 0 ? 0 : 1), fp_data_1[1:0]} * {(fp_data_2[6:2] == 0 ? 0 : 1), fp_data_2[1:0]};
    assign exp_2 = (exp_1 == 0) ? 0 : (sf_1[5] == 1) ? exp_1 + 1 : (sf_1[4:1] == 0) ? exp_1 - 4 : (sf_1[4:2] == 0) ? exp_1 - 3 : (sf_1[4:3] == 0) ? exp_1 - 2 : (sf_1[4] == 0) ? exp_1 - 1 : exp_1;
    assign sf_2 = (exp_1 == 0) ? 0 : (sf_1[5] == 1) ? sf_1[4:0] : (sf_1[4:1] == 0) ? 5'h0 : (sf_1[4:2] == 0) ? {sf_1[0], 4'h0} : (sf_1[4:3] == 0) ? {sf_1[1:0], 3'h0} : (sf_1[4] == 0) ? {sf_1[2:0], 2'h0} : {sf_1[3:0], 1'h0};

    assign nan_num = ((fp_data_1[6:2] == 31 && fp_data_1[1:0] != 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] != 0));
    assign infinity = !nan_num && ((fp_data_1[6:2] == 31 && fp_data_1[1:0] == 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] == 0 && fp_data_1[6:0] != 0));

    assign data_out = nan_num ? {sign, 31'h7FFFFFFF} : infinity ? {sign, 8'hFF, 23'h0} : {sign, exp_2, sf_2, 18'h0};

endmodule