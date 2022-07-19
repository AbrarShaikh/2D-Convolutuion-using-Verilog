`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2021 13:44:46
// Design Name: 
// Module Name: CntrLogic
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

// control logic
module CntrLogic 
                //parameterizing the variable order for different filter dimensions
                ( input clk,  //synchronous clock
                input reset, //active high reset
                input [7:0] input_data, // each pixel is 1 byte
                input is_valid_input, // valid signal for input data
                output is_valid_output , // valid signal for output data 
                output reg [71:0] output_data,//output data for MAC operation which takes 9 pixels at a time
                output reg intr_signal 
);

reg [8:0]counter_pixel; // count of pixels for writing operation
reg [8:0]counter_read;  // count of pixels for reading operation
reg [1:0] current_buffer_write;// tells on which line buffer currently the contents are being written
reg [1:0]current_buffer_read;  //tells on which line buffer currently the contents are being read
reg [3:0] linebuffer_read; // passing control signal in line buffer for read operation
reg [3:0] linebuffer_valid;// passing control signal in line buffer for write operation
reg read_buffer; // vaid signal for reading from line buffers
reg [11:0] total_pixel_counter;
reg read_state;

wire [23:0] datalb0; //contents of first line buffer
wire [23:0] datalb1; //contents of second line buffer
wire [23:0] datalb2; // contents of third line buffer
wire [23:0] datalb3; // contents of fourth line buffer

localparam IDLE='b0,
            reading_state='b1;
            
            
assign is_valid_output=read_buffer;


// for MAC operation to occur sufficient amount of data should be there
// hence the minimum amount of data required is 512x3=1536 bits
// Now, two conditions arises
always@(posedge clk) begin
if(reset)
total_pixel_counter<=0;
else begin
if(is_valid_input & !read_buffer) // first condition is that input data is not sufficient in number for MAC operation
total_pixel_counter<=total_pixel_counter+1; // hence in this case counter will be incremented
else if(!is_valid_input & read_buffer) // second case is that input data is sufficient for MAC operation
total_pixel_counter<=total_pixel_counter-1; // as data is read counter is decremented
end
end

// state machine for determination of read_buffer signal
always@(posedge clk) begin
if(reset) begin
read_state<=IDLE;  //reset case
read_buffer<=0;
intr_signal<='b0;

end

else 
begin
case(read_state) //only two states are there 
IDLE: begin
       intr_signal<='b0; 
      if(total_pixel_counter>=1536) // as soon as input data is sufficient in number read_buffer signal will get high and MAC operation will occur
      begin
      read_buffer<=1; // read_buffer gets high and activates the  line buffers which is dependent on value of current_read_buffer 
      read_state<=reading_state;  
      intr_signal<='b0;
      end
      end
      
reading_state: begin
             if(counter_read==511) //after reading whole row, machine will go again to idle state to check for sufficient data for MAC operation
             begin
             read_state<=IDLE;
             read_buffer<=0;
             intr_signal<='b1;
             end
             end
endcase
end
end


// counter for counting the number of bytes for write operation
always@(posedge clk) begin
if(reset)
counter_pixel<=0;
else if(is_valid_input)
counter_pixel<=counter_pixel+'b1;
end

// current buffer is incremented as soon as the counter reaches 511th byte
// after that write operation continues in different line buffer
always@(posedge clk) begin
if(reset)
current_buffer_write<=0;
else if(counter_pixel==511 & is_valid_input) // for flagging of overflow condition 
current_buffer_write<=current_buffer_write+'b1;
end

// valid signal is applicable only for a particular line buffer at a time
// on which contents are being written
always@(*) begin
linebuffer_valid=0;
linebuffer_valid[current_buffer_write]=is_valid_input;
end

//....//

//read operation which takes place from three line buffers at a time
// counter for counting the number of bytes for read operation
always@(posedge clk) begin
if(reset)
counter_read<=0;
else if(read_buffer)
counter_read<=counter_read+'b1;
end

// Similar to write operation
always@(posedge clk) begin
if(reset)
current_buffer_read<=0;
else if(counter_read==511 & read_buffer ) // for flagging of overflow condition 
current_buffer_read<=current_buffer_read+1;
end

// As there are four line buffers current_buffer_read takes values from 0 to 3
// logic is implemented as a combinational logic to avoid delay and support prefetching
always@(*) begin
case(current_buffer_read)
0: begin
   output_data={datalb2,datalb1,datalb0}; //case 0: first second and third line buffers data is being fetched to output
   end
1: begin
    output_data={datalb3,datalb2,datalb1};//case 1:second,third and fourth line buffers data is being fetched to output
    end
2: begin
    output_data={datalb0,datalb3,datalb2};//case 2:third,fourth,first line buffers data is being fetched to output
    end
3: begin
   output_data={datalb1,datalb0,datalb3};//case 3:fourth, first and second line buffers data is being fetched to output
    end
// again it repeats in a similar fashion
endcase
end

// passing of valid signal to the line buffers which are eligible for 
// assigning the output 
// line buffers are four in number for providing pipelined architecture
always@(*) begin
if(current_buffer_read==2'b00) begin
linebuffer_read[0]=read_buffer;
linebuffer_read[1]=read_buffer;
linebuffer_read[2]=read_buffer;
linebuffer_read[3]=0;
end

else if(current_buffer_read==2'b01) begin
linebuffer_read[0]=0;
linebuffer_read[1]=read_buffer;
linebuffer_read[2]=read_buffer;
linebuffer_read[3]=read_buffer;
end 

else if(current_buffer_read==2'b10) begin
linebuffer_read[0]=read_buffer;
linebuffer_read[1]=0;
linebuffer_read[2]=read_buffer;
linebuffer_read[3]=read_buffer;
end

else if(current_buffer_read==2'b11) begin
linebuffer_read[0]=read_buffer;
linebuffer_read[1]=read_buffer;
linebuffer_read[2]=0;
linebuffer_read[3]=read_buffer;
end
end

// instantiation of line buffers 
LineBuffer line_buffer0( .clk(clk), 
              .reset(reset), 
              .input_data(input_data), 
              .is_valid_data(linebuffer_valid[0]),   //instantiation for line buffer one
              .read_data(linebuffer_read[0]), 
              . output_data(datalb0));  

LineBuffer line_buffer1( .clk(clk), 
              .reset(reset), 
              .input_data(input_data), 
              .is_valid_data(linebuffer_valid[1]), //instantiation for line buffer second
              .read_data(linebuffer_read[1]), 
              . output_data(datalb1));  


LineBuffer line_buffer2( .clk(clk), 
              .reset(reset), 
              .input_data(input_data), 
              .is_valid_data(linebuffer_valid[2]), //instantiation for line buffer third
              .read_data(linebuffer_read[2]), 
              . output_data(datalb2));  

LineBuffer line_buffer3( .clk(clk), 
              .reset(reset), 
              .input_data(input_data), 
              .is_valid_data(linebuffer_valid[3]), //instantiation for line buffer fourth
              .read_data(linebuffer_read[3]), 
              . output_data(datalb3));  
endmodule
