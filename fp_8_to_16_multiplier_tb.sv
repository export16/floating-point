
`timescale 1ns/1ps

module fp_8_to_16_multiplier_tb;
    reg clk = 0;
    reg rstn = 0;
    reg [7:0] fp_data_1;
    reg [7:0] fp_data_2;
    wire [15:0] data_out;
    
    integer file;
    integer i;
    reg [15:0] expected_result;
    integer errors = 0;
    
    fp_8_to_16_multiplier uut (
        .clk(clk),
        .rstn(rstn),
        .fp_data_1(fp_data_1),
        .fp_data_2(fp_data_2),
        .data_out(data_out)
    );
    
    always #0.5ns clk = ~clk;
    
    initial begin

        i = 0;
        file = $fopen("G:/cz/fp_mul/fp_test_data.txt", "r");
        if (!file) begin
            $display("Error opening file");
            $finish;
        end
        
        #1ns;
        rstn = 1;
        
        while (!$feof(file)) begin
            $fscanf(file, "%b %b %b", fp_data_1, fp_data_2, expected_result);
            #1ns;
            
            if (data_out !== expected_result) begin
                $display("Error at test case %d: \n Expected %b, \n Got      %b", 
                         i, expected_result, data_out);
                errors = errors + 1;
            end
            i = i + 1;
        end
        
        $fclose(file);
        $display("Test completed with %0d errors", errors);
        $finish;
    end
endmodule
