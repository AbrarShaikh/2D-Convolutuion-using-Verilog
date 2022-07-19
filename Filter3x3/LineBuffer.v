`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2021 17:29:57
// Design Name: 
// Module Name: LineBuffer
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

// line buffer module, similar to RAM model
module LineBuffer 
               //parameterizing the variable order for different filter dimensions
               (input clk, 
               input reset, // active high reset
               input [7:0] input_data, // each pixel is 1 byte
               input is_valid_data, // valid signals for writing
               input read_data, //valid signals for reading
               output [23:0] output_data);  // 24 bits in one shot, can be implemented through 2-D memory technique
                
reg [7:0] mem [511:0]; //line buffer, width equal to 1 byte and depth of 512 as image is a standard gray scale image of 512x512 bytes
reg [8:0]wraddr; // address pointer, where data has to be written (log2(D)) where D is depth of the memory
reg [8:0] rdaddr; // read pointer, from where data has to be read

always@(posedge clk) begin
if(is_valid_data)
mem[wraddr]<=input_data;
end
// if valid signal is high then data will be written to the buffer

always@(posedge clk) begin
if(reset)
wraddr=0;
else if(is_valid_data) 
wraddr=wraddr+1;
end
// write pointer will be incremented for next content to be written

assign output_data={mem[rdaddr],mem[rdaddr+1],mem[rdaddr+2]};  

// no latency
always@(posedge clk)begin
if(reset) 
rdaddr=0;
else if(read_data) 
rdaddr=rdaddr+1;
end
// after 24 bits are written to the memory, read pointer will be incremented by one as striding 
// of kernel is equal to one for our design

endmodule
