`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2021 12:12:19
// Design Name: 
// Module Name: MulAcc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// MAC operation
module MulAcc 
               //parameterizing the variable order for different filter dimensions
               (input clk,
               input [71:0] pixel_data, // At each time nine pixels are taken into account hence the width will be 9x8=72 bits
               input is_valid_pdata, // valid signal for input data
               output reg is_valid_odata, // valid signal for output data
               output reg [7:0] pixel_odata ); //output data of MAC operation
integer i;               
reg [7:0] kernel [8:0]; // kernel filter declared as 2-D memory
reg [15:0] o_data_mult [8:0]; // output of multiplication operation
reg [15:0] o_data_sum; // storage variable
reg [15:0] o_data_sumf; // output variable of addition operation
reg multdatavalid;
reg sumdatavalid;

// kernel initialization according to the application like blurring, edge detection etc. 
initial 
begin

kernel[0]=0;
kernel[1]=-1;
kernel[2]=0;
kernel[3]=-1;
kernel[4]=5;
kernel[5]=-1;
kernel[6]=0;
kernel[7]=-1;
kernel[8]=0;

end
//multiplication operation 
// working synchronously with positive edge of the clock

always@(posedge clk) 
begin
for(i=0;i<9;i=i+1) 
begin
o_data_mult[i]<=$signed(kernel[i])*$signed({1'b0,pixel_data[i*8+:8]});
end
multdatavalid<=is_valid_pdata;
end

//addition operation, implemented in a combinational block because
// o_data_sum might have some previous value if non blocking assignments are used
always@(*) begin
o_data_sum=0;
for(i=0;i<9;i=i+1)
begin
o_data_sum=$signed(o_data_sum)+$signed(o_data_mult[i]);
end
end

//assign o_data_sumf = o_data_sum[15] ? -o_data_sum : o_data_sum; 

//always @*
//begin
//    if(o_data_sum[15])
//    begin
//        o_data_sumf=-o_data_sum;
//    end
//    else begin
//        o_data_sumf=o_data_sum;
//    end
//end

always @(posedge clk)
begin
    if(o_data_sum[15])
    begin
        o_data_sumf<=-o_data_sum;
    end
    else begin
        o_data_sumf<=o_data_sum;
    end
    sumdatavalid<=multdatavalid;
end


// result transferred on positive edge of the clock of addition operation


// Finally dividing the sum by 9 due to the filter properties
always@(posedge clk) begin
pixel_odata<= o_data_sumf;
is_valid_odata<=sumdatavalid;
end


endmodule
