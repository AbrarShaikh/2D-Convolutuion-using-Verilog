`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.05.2021 00:13:10
// Design Name: 
// Module Name: TopModule
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

// top module, IP packaging
module TopModule(
input axis_clk,  // clock applied for AXIS stream between IP and memory
input axis_resetn, // global reset
//Here the IP is acting in a slave mode as the data is being written on it for processing

input i_datavalid, // input data is valid or not
input [7:0] idata, //input data from image matrix
output s_axis_ready,// output from IP, signifying if it is ready to accept data from FIFO for processing.

// Here the IP is acting as master, as it is giving convolved data back.
output o_datavalid, // output data is valid or not
output [7:0] odata,// output of convolution
input m_axis_ready,// If the FIFO is ready to accept the dataor not.

// active high interrupt signifying if the line buffer is empty or not.
output intr
    );

wire [7:0] conv_data;
wire conv_data_valid;

wire [71:0] pixeldata;
wire pixeldata_valid;

wire axis_prog_full;


assign s_axis_ready=!axis_prog_full;

// instantiation of control logic module which takes the input from the image matrix and provides 
// the data for convolution operation
 CntrLogic UUT1 (  .clk(axis_clk),  
            .reset(!axis_resetn),  
          .input_data(idata), 
           .is_valid_input(i_datavalid), 
           .is_valid_output(pixeldata_valid) ,  
          .output_data (pixeldata),
          .intr_signal(intr)
);
//Takes the data from the line buffer which are multiplexed and performs the MAC operation
// which is multiplication and accumulation.
MulAcc UUT2 (. clk(axis_clk),
        .pixel_data(pixeldata), 
        .is_valid_pdata(pixeldata_valid), 
        . is_valid_odata(conv_data_valid), 
        . pixel_odata(conv_data) );
        
 // Transmission of data through IP takes place with the help of FIFO generator.
output_buffer fifo_buffer  (
  .wr_rst_busy(),        // output wire wr_rst_busy
  .rd_rst_busy(),        // output wire rd_rst_busy
  .s_aclk(axis_clk),                  // input wire s_aclk
  .s_aresetn(axis_resetn),            // input wire s_aresetn
  .s_axis_tvalid(conv_data_valid),    // input wire s_axis_tvalid
  .s_axis_tready(),    // output wire s_axis_tready
  .s_axis_tdata(conv_data), // input wire [7 : 0] s_axis_tdata
  
  .m_axis_tvalid(o_datavalid),    // output wire m_axis_tvalid
  .m_axis_tready(m_axis_ready),    // input wire m_axis_tready
  .m_axis_tdata(odata),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);
endmodule
