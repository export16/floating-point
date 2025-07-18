module fp_8_to_16_multiplier(
    input clk,
    input rstn,
    input [7:0] fp_data_1,
    input [7:0] fp_data_2,
    output [15:0] data_out
);

    wire [5:0] exp_16;
    wire [5:0] sf_16;

    assign exp_16 = (fp_data_1[6:0] == 0 || fp_data_2[6:0] == 0) ? 0 : (fp_data_1[6:2] == 0 ? 1 : fp_data_1[6:2]) + (fp_data_2[6:2] == 0 ? 1 : fp_data_2[6:2]);
    assign sf_16 = {(fp_data_1[6:2] == 0 ? 0 : 1), fp_data_1[1:0]} * {(fp_data_2[6:2] == 0 ? 0 : 1), fp_data_2[1:0]};

    wire [4:0] exp_1;
    wire [14:0] sf_1;
    wire [4:0] exp_2;
    wire [14:0] sf_2;

    assign exp_1 = (exp_16 > 15 && sf_16[5] == 1) ? exp_16 - 14 : (exp_16 > 15) ? exp_16 - 15 : 1;
    assign sf_1 = (exp_16 > 15 && sf_16[5] == 1) ? {1'h0, sf_16, 8'h0} : (exp_16 > 15) ? {sf_16, 9'h0} : (exp_16 >= 6) ? ({sf_16, 9'h0} >> (15 - exp_16)) : ({sf_16, 9'h0} >> (15 - exp_16)) | ((sf_16 & ((1 << (6 - exp_16)) - 1)) != 0);
    assign exp_2 = (exp_1 > 2 && sf_1[13:12] == 0) ? exp_1 - 2 : (exp_1 > 1 && sf_1[13] == 0) ? exp_1 - 1 : exp_1;
    assign sf_2 = (exp_1 > 2 && sf_1[13:12] == 0) ? (sf_1 << 2) : (exp_1 > 1 && sf_1[13] == 0) ? (sf_1 << 1) : sf_1;

    wire [4:0] exp_2;
    wire [10:0] sf_2;

    assign exp_3 = (exp_2 == 1 && sf_2[13] == 0) ? 0 : exp_2;
    assign sf_3 = (sf_2 >> 3) + (sf_2[2] & (sf_2[3] | sf_2[1] | sf_2[0]));

    wire sign;

    assign sign = fp_data_1[7] ^ fp_data_2[7];

    assign nan_num = (fp_data_1[6:2] == 31 && fp_data_1[1:0] != 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] != 0);
    assign infinity = !nan_num && ((fp_data_1[6:2] == 31 && fp_data_1[1:0] == 0 && fp_data_2[6:0] != 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] && fp_data_1[6:0] != 0));

    assign data_out = nan_num ? {sign, 15'h7FFF} : infinity ? {sign, 5'h1F, 10'h0} : {sign, exp_3, sf_3[9:0]};

endmodule