module fp_16(
    input clk,
    input rstn,
    input input_valid,
    input [7:0] fp_data_1,
    input [7:0] fp_data_2,
    input [15:0] input_data,
    output reg out_valid,
    output reg [31:0] data_out
);
    

    wire infinity_1, infinity_2;

    wire [5:0] exp_16;
    wire [5:0] sf_16;

    wire [4:0] exp_fp_1;
    wire [14:0] sf_fp_1;
    wire [4:0] exp_fp_2;
    wire [10:0] sf_fp_2;

    assign exp_16 = (fp_data_1[6:2] == 31 || fp_data_2 == 31) ? 46 : fp_data_1[6:2] + fp_data_2[6:2];
    assign sf_16 = ((fp_data_1[6:2] == 31 && fp_data_1[1:0] == 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] == 0)) ? 0 : {(fp_data_1[6:2] == 0 ? 0 : 1), fp_data_1[1:0]} * {(fp_data_2[6:2] == 0 ? 0 : 1), fp_data_2[1:0]};
    assign exp_fp_1 = (exp_16 > 15 && exp_16 != 46 && sf_16[5] == 1) ? exp_16 - 14 : (exp_16 > 15) ? exp_16 - 15 : 1;
    assign sf_fp_1 = (exp_16 > 15 && sf_16[5] == 1) ? {1'h0, sf_16, 8'h0} : (exp_16 > 15) ? {sf_16, 9'h0} : ({sf_16, 9'h0} >> (15 - exp_16)) | ((sf_16 & ((1 << (6 - exp_16)) - 1)) != 0);
    assign exp_fp_2 = (exp_fp_1 == 31) ? 31 : ((sf_fp_1 + (sf_fp_1[2] && (sf_fp_1[3] | sf_fp_1[1] | sf_fp_1[0]))) & 15'h4000) != 0 ? exp_fp_1 + 1 : exp_fp_1;
    assign sf_fp_2 = (exp_16 == 31) ? 0 : ((sf_fp_1 + (sf_fp_1[2] && (sf_fp_1[3] | sf_fp_1[1] | sf_fp_1[0]))) & 15'h4000) != 0 ? ((sf_fp_1 + (sf_fp_1[2] && (sf_fp_1[3] | sf_fp_1[1] | sf_fp_1[0]))) >> 4) : (sf_fp_1 + (sf_fp_1[2] && (sf_fp_1[3] | sf_fp_1[1] | sf_fp_1[0])) >> 3);

    wire [4:0] exp_1;
    wire [4:0] exp_2;
    wire [26:0] sf_1;
    wire [26:0] sf_2;    

    assign exp_1 = exp_fp_2 < input_data[14:10] ? input_data[14:10] : exp_fp_2;
    assign exp_2 = input_data[14:10] < exp_fp_2 ? exp_fp_2 : input_data[14:10];
    assign sf_1 = (exp_fp_2 < input_data[14:10]) ? ({sf_fp_2, 16'h0} >> (input_data[14:10] - exp_fp_2) | ({sf_fp_2, 16'h0} & ((1 << (input_data[14:10] - exp_fp_2)) - 1) != 0)) : {sf_fp_2, 16'h0};
    assign sf_2 = (input_data[14:10] < exp_fp_2) ? ({(input_data[14:10] == 0) ? 0 : 1, input_data[9:0], 16'h0} >> (exp_fp_2 - input_data[14:10]) | ({(input_data[14:10] == 0) ? 0 : 1, input_data[9:0], 16'h0} & ((1 << (exp_fp_2 - input_data[14:10])) - 1) != 0)) : {(input_data[15] == 1) ? 1 : 0, input_data[9:0], 16'h0};

    wire sign;

    assign infinity_1 = (fp_data_1[6:2] == 31 && fp_data_1[1:0] == 0 && fp_data_2[6:0] != 0) || (fp_data_2[6:2] == 31 && fp_data_2[1:0] && fp_data_1[6:0] != 0);
    assign infinity_2 = (input_data[14:10] == 31 && input_data[9:0] == 0);

    wire infinity, nan_num;

    assign nan_num = (fp_data_1[6:2] == 0 && fp_data_1[1:0] != 0) || (fp_data_2[6:2] == 0 && fp_data_2[1:0] != 0) || (input_data[14:10] == 0 && input_data[9:0] != 0) || (infinity_1 && infinity_2 && (fp_data_1[7] ^ fp_data_2[7]) != input_data[15]);
    assign infinity = !nan_num && (infinity_1 || infinity_2);

    assign sign = ((fp_data_1[7] ^ fp_data_2[7]) == input_data[15]) ? input_data[15] : (sf_1 >= sf_2) ? (fp_data_1[7] ^ fp_data_2[7]) : input_data[15];

    wire [7:0] exp_out_1;
    wire [27:0] sf_out_1;

    assign exp_out_1 = exp_1 + 112;
    assign sf_out_1 = ((fp_data_1[7] ^ fp_data_2[7]) == input_data[15]) ? sf_1 + sf_2 : (sf_1 > sf_2) ? sf_1 - sf_2 : sf_2 - sf_1;

    wire [7:0] exp_out_2;
    wire [26:0] sf_out_2;

    assign exp_out_2 = sf_out_1[27] ? exp_out_1 + 1 : sf_out_1[26:11] == 0 ? exp_out_1 - 16 : exp_out_1;
    assign sf_out_2 = sf_out_1[27] ? sf_out_1[27:1] | sf_out_1[0] : sf_out_1[26:11] == 0 ? sf_out_1 << 16 : sf_out_1[26:0];

    wire [7:0] exp_out_3;
    wire [26:0] sf_out_3;

    assign exp_out_3 = sf_out_2[26:19] == 0 ? exp_out_2 - 8 : exp_out_2;
    assign sf_out_3 = sf_out_2[26:19] == 0 ? sf_out_2 << 8 : sf_out_2;

    wire [7:0] exp_out_4;
    wire [26:0] sf_out_4;
    
    assign exp_out_4 = sf_out_3[26:23] == 0 ? exp_out_3 - 4 : exp_out_3;
    assign sf_out_4 = sf_out_3[26:23] == 0 ? sf_out_3 << 4 : sf_out_3;

    wire [7:0] exp_out_5;
    wire [26:0] sf_out_5;
    
    assign exp_out_5 = sf_out_4[26:25] == 0 ? exp_out_4 - 2 : exp_out_4;
    assign sf_out_5 = sf_out_4[26:25] == 0 ? sf_out_4 << 2 : sf_out_4;
    
    wire [7:0] exp_out_6;
    wire [26:0] sf_out_6;
    
    assign exp_out_6 = sf_out_5[26] == 0 ? exp_out_5 - 1 : exp_out_5;
    assign sf_out_6 = sf_out_5[26] == 0 ? sf_out_5 << 1 : sf_out_5;
    
    wire [7:0] exp_out;
    wire [26:0] sf_out;

    assign exp_out = ((sf_out_6 + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) & 28'h8000000) == 28'h8000000 ? exp_out_6 + 1 : exp_out_6;
    assign sf_out = ((sf_out_6 + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) & 28'h8000000) == 28'h8000000 ? ((sf_out_6 + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0]))) >> 1) : (sf_out_6 + (sf_out_6[2] && (sf_out_6[3] || sf_out_6[1] || sf_out_6[0])));

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_out <= 0;
        end
        else if(input_valid) begin
            if(infinity)
                data_out <= {sign, 8'hFF, 23'h0};
            else if(nan_num)
                data_out <= {sign, 8'hFF, 23'h7FFFFF};
            else
                data_out <= {sign, exp_out, sf_out[25:3]};
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            out_valid <= 0;
        end
        else begin
            out_valid <= input_valid;
        end
    end

endmodule