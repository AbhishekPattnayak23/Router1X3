`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Maven silicon
// Engineer: Abhishek Pattnayak
// 
// Create Date: 04/07/2024 11:49:17 PM
// Design Name: FIFO memory
// Module Name: router_fifo
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
//
//     clock--->|          |
//     resetn-->|          |----> empty
//  write_enb-->|          |
//soft_reset--->|   FIFO   | ----> data_out(8-bit)
//  read_enb--->|          |
//data_in(8-bit)|          |-----> full
//  lfd_state-->|          |
//

module router_fifo(clk,rstn,we,re,din,lfd_state,soft_rst,empty,full,dout);

input clk,rstn,we,re,lfd_state,soft_rst;  //lfd = load first data which is used to load the header bit first
input [7:0] din;                         // soft reset is a internal reset used by memory and for fsm 
output reg [7:0] dout;                   //so that it goes back to deafult state
output empty,full;
reg [6:0] count;
reg [8:0] mem [15:0];

reg [4:0] wr_ptr;
reg [4:0] rd_ptr;

integer i;
reg lfd_state_d1;

always@(posedge clk)//delay by one clock cycle  
  begin
    if(!rstn)
       lfd_state_d1 <= 0;
    else
        lfd_state_d1 <= lfd_state;
  end 
    
//FIFO full and empty logic
assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0 ;
assign full =  (wr_ptr == {~rd_ptr[4],rd_ptr[3:0]} ) ? 1'b1 : 1'b0  ;

//the above full statement makes sure that the data is stored 15th location
// and at the 16th location the full is high/1
//for full condition wr_ptr == 4'b1111 && rd_ptr == 4'b0000

//fifo write operation
always@(posedge clk)
begin
    if(!rstn)
        begin
            wr_ptr<=0;
            for(i=0;i<16;i=i+1)
                begin
                    mem[i] <= 0;
                end
        end 
     else if(soft_rst)
        begin
            wr_ptr<=0;
            for(i=0;i<16;i=i+1)
                begin
                    mem[i] <= 0;
                end 
         end 
         else 
            begin
                if(we && ~full)
                    begin
                        wr_ptr <= wr_ptr+1;
                        mem[wr_ptr[3:0]] <= {lfd_state_d1,din};
                    end 
             end  
end 

//FIFO read operation
always@(posedge clk)
begin
    if(!rstn)
        begin
            rd_ptr<=0;
            dout<=8'h00;
        end             
    else if(soft_rst) 
        begin
            rd_ptr <= 0;
            dout <= 8'hzz; 
         end 
     else
        begin
            if(re && ~empty)
                begin
                    dout <= mem[rd_ptr[3:0]];
                    rd_ptr <= rd_ptr+1;
                end
           else if((count == 0) && (dout!=0))
                dout <= 8'dz;
        end 
end        
 
 //FIFO down-counter logic
 always@(posedge clk)
 begin
    if(!rstn)
        begin
            count<=0;
        end    
    else if(soft_rst)
        begin
            count<=0;
        end 
    else if(re && ~empty)
        begin 
            if(mem[rd_ptr[3:0]][8] == 1'b1)
                count <= mem[rd_ptr[3:0]][7:2] + 1'b1;
            else if(count != 0)
                count <= count - 1'b1;
            else
                count<=count;   
         end 
  end 
  
endmodule
