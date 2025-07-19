module fp_32_adder(
    input clk,
    input rstn,
    input [31:0] fp_data_1,
    input [31:0] fp_data_2,
    output [31:0] data_out
);

    wire nan_num_1;
    wire nan_num_2;
    
    assign nan_num_1 = (fp_data_1[30:23] == 8'hFF && fp_data_1[22:0] != 0);
    assign nan_num_2 = (fp_data_2[30:23] == 8'hFF && fp_data_2[22:0] != 0);

    wire infinity_1;
    wire infinity_2;
    
    assign infinity_1 = (fp_data_1[30:23] == 8'hFF && fp_data_1[22:0] == 0);
    assign infinity_2 = (fp_data_2[30:23] == 8'hFF && fp_data_2[22:0] == 0);
    
    wire [26:0] fp_data_sf_1;
    wire [26:0] fp_data_sf_2;

    assign fp_data_sf_1 = {(fp_data_1[30:23] == 0 ? 0 : 1), fp_data_1[22:0], 3'h0};
    assign fp_data_sf_2 = {(fp_data_2[30:23] == 0 ? 0 : 1), fp_data_2[22:0], 3'h0};


    wire [26:0] sf_1;
    wire [26:0] sf_2;

    assign sf_1 = (fp_data_1[30:23] < fp_data_2[30:23]) ? (fp_data_sf_1 >> (fp_data_2[30:23] - fp_data_1[30:23]) | ((fp_data_sf_1 & ((1 << (fp_data_2[30:23] - fp_data_1[30:23])) - 1)) != 0)) : fp_data_sf_1;
    assign sf_2 = (fp_data_2[30:23] < fp_data_1[30:23]) ? (fp_data_sf_2 >> (fp_data_1[30:23] - fp_data_2[30:23]) | ((fp_data_sf_2 & ((1 << (fp_data_1[30:23] - fp_data_2[30:23])) - 1)) != 0)) : fp_data_sf_2;

    wire sign;

    assign sign = (fp_data_1[31] == fp_data_2[31]) ? fp_data_2[31] : (sf_1 >= sf_2) ? fp_data_1[31] : fp_data_2[31];

    wire [7:0] exp_out_1;
    wire [27:0] sf_out_1;

    assign exp_out_1 = fp_data_1[30:23] < fp_data_2[30:23] ? fp_data_2[30:23] : fp_data_1[30:23];
    assign sf_out_1 = (fp_data_1[31] == fp_data_2[31]) ? sf_1 + sf_2 : (sf_1 > sf_2) ? sf_1 - sf_2 : sf_2 - sf_1;

    wire [7:0] exp_out_2;
    wire [26:0] sf_out_2;

    assign exp_out_2 = sf_out_1[27] ? exp_out_1 + 1 : (sf_out_1[26:11] == 0 && exp_out_1 > 16) ? exp_out_1 - 16 : exp_out_1;
    assign sf_out_2 = sf_out_1[27] ? sf_out_1[27:1] | sf_out_1[0] : (sf_out_1[26:11] == 0 && exp_out_1 > 16) ? sf_out_1 << 16 : sf_out_1[26:0];


    assign nan_num = nan_num_1 || nan_num_2 || (infinity_1 && infinity_2 && fp_data_1[31] != fp_data_2[31]);
    assign infinity = !nan_num && (infinity_1 || infinity_2 || exp_out_2 >= 255);

    wire [7:0] exp_out_3;
    wire [26:0] sf_out_3;

    assign exp_out_3 = (sf_out_2[26:19] == 0 && exp_out_2 > 8) ? exp_out_2 - 8 : exp_out_2;
    assign sf_out_3 = (sf_out_2[26:19] == 0 && exp_out_2 > 8) ? sf_out_2 << 8 : sf_out_2;

    wire [7:0] exp_out_4;
    wire [26:0] sf_out_4;
    
    assign exp_out_4 = (sf_out_3[26:23] == 0 && exp_out_3 > 4) ? exp_out_3 - 4 : exp_out_3;
    assign sf_out_4 = (sf_out_3[26:23] == 0 && exp_out_3 > 4) ? sf_out_3 << 4 : sf_out_3;

    wire [7:0] exp_out_5;
    wire [26:0] sf_out_5;
    
    assign exp_out_5 = (sf_out_4[26:25] == 0 && exp_out_4 > 2) ? exp_out_4 - 2 : exp_out_4;
    assign sf_out_5 = (sf_out_4[26:25] == 0 && exp_out_4 > 2) ? sf_out_4 << 2 : sf_out_4;
    
    wire [7:0] exp_out_6;
    wire [26:0] sf_out_6;
    
    assign exp_out_6 = (sf_out_5[26] == 0 && exp_out_5 > 1) ? exp_out_5 - 1 : exp_out_5;
    assign sf_out_6 = (sf_out_5[26] == 0 && exp_out_5 > 1) ? sf_out_5 << 1 : sf_out_5;
    
    wire [7:0] exp_out;
    wire [23:0] sf_out;

    assign exp_out = (((sf_out_6 >> 3) + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) & 25'h1000000) == 25'h1000000 ? exp_out_6 + 1 : exp_out_6;
    assign sf_out = (((sf_out_6 >> 3) + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) & 25'h1000000) == 25'h1000000 ? (((sf_out_6 >> 3) + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) >> 1) : ((sf_out_6 >> 3) + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0])));

    assign data_out = infinity ? {sign, 8'hFF, 23'h0} : nan_num ? {sign, 8'hFF, 23'h7FFFFF} : {sign, exp_out, sf_out[22:0]};

endmodule