module fp_16_to_32_adder(
    input clk,
    input rstn,
    input [15:0] fp_data_1,
    input [15:0] fp_data_2,
    output reg [31:0] data_out
);
    
    wire nan_num_1;
    wire nan_num_2;
    
    assign nan_num_1 = (fp_data_1[14:10] == 5'h1F && fp_data_1[9:0] != 0);
    assign nan_num_2 = (fp_data_2[14:10] == 5'h1F && fp_data_2[9:0] != 0);

    wire infinity_1;
    wire infinity_2;
    
    assign infinity_1 = (fp_data_1[14:10] == 5'h1F && fp_data_1[9:0] == 0);
    assign infinity_2 = (fp_data_2[14:10] == 5'h1F && fp_data_2[9:0] == 0);
    
    wire [26:0] fp_data_sf_1;
    wire [26:0] fp_data_sf_2;

    assign fp_data_sf_1 = {(fp_data_1[14:10] == 0) ? 0 : 1, fp_data_1[9:0], 16'h0};
    assign fp_data_sf_2 = {(fp_data_2[14:10] == 0) ? 0 : 1, fp_data_2[9:0], 16'h0};

    wire nan_num;
    wire infinity;

    wire [4:0] exp_1;
    wire [4:0] exp_2;
    wire [26:0] sf_1;
    wire [26:0] sf_2;    

    assign exp_1 = fp_data_1[14:10] < fp_data_2[14:10] ? fp_data_2[14:10] : fp_data_1[14:10];
    assign exp_2 = fp_data_2[14:10] < fp_data_1[14:10] ? fp_data_1[14:10] : fp_data_2[14:10];
    assign sf_1 = (fp_data_1[14:10] < fp_data_2[14:10]) ? ((fp_data_sf_1 >> (fp_data_2[14:10] - fp_data_1[14:10]) | ((fp_data_sf_1 & ((1 << (fp_data_2[14:10] - fp_data_1[14:10])) - 1)) != 0))) : fp_data_sf_1;
    assign sf_2 = (fp_data_2[14:10] < fp_data_1[14:10]) ? ((fp_data_sf_2 >> (fp_data_1[14:10] - fp_data_2[14:10]) | ((fp_data_sf_2 & ((1 << (fp_data_1[14:10] - fp_data_2[14:10])) - 1)) != 0))) : fp_data_sf_2;

    wire sign;

    assign nan_num = nan_num_1 || nan_num_2 || (infinity_1 && infinity_2 && fp_data_1[15] != fp_data_2[15]);
    assign infinity = !nan_num && (infinity_1 || infinity_2);

    assign sign = (fp_data_1[15] == fp_data_2[15]) ? fp_data_2[15] : (sf_1 >= sf_2) ? fp_data_1[15] : fp_data_2[15];

    wire [7:0] exp_out_1;
    wire [27:0] sf_out_1;

    assign exp_out_1 = exp_1 + 112;
    assign sf_out_1 = (fp_data_1[15] == fp_data_2[15]) ? sf_1 + sf_2 : (sf_1 > sf_2) ? sf_1 - sf_2 : sf_2 - sf_1;

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

    assign exp_out = ((sf_out_6[26:3] + (sf_out_6[2] & (sf_out_6[3] | sf_out_6[1] | sf_out_6[0]))) & 25'h1000000) != 25'h0 ? exp_out_6 + 1 : exp_out_6;
    assign sf_out = ((sf_out_6[26:3] + (sf_out_6[2] & (sf_out_6[3] | sf_out_6[1] | sf_out_6[0]))) & 25'h1000000) != 25'h0 ? {sf_out_6[26:3] + (sf_out_6[2] & (sf_out_6[3] | sf_out_6[1] | sf_out_6[0])), 2'h0} : {sf_out_6[26:3] + (sf_out_6[2] & (sf_out_6[3] | sf_out_6[1] | sf_out_6[0])), 3'h0};
    
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_out <= 0;
        end
        else begin
            if(infinity)
                data_out <= {sign, 8'hFF, 23'h0};
            else if(nan_num)
                data_out <= {sign, 8'hFF, 23'h7FFFFF};
            else
                data_out <= {sign, exp_out, sf_out[22:0]};
        end
    end

endmodule