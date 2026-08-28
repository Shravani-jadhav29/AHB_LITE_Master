`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2026 11:24:10 PM
// Design Name: 
// Module Name: AHB_lite
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


module AHB_lite(

 
   

  
    input  wire        HCLK,
    input  wire        HRESETn,

    // User command interface
  
    input  wire        start,
    input  wire        write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,

    // 1 = single
    // 4 = four-beat burst
    input  wire [3:0]  beat_length,

    // 1 = WRAP4
    // 0 = INCR4
    input  wire        wrap_en,

    
    // AHB-Lite slave inputs

    input  wire        HREADY,
    input  wire [1:0]  HRESP,
    input  wire [31:0] HRDATA,

 
    // AHB-Lite master outputs

    output reg  [31:0] HADDR,
    output reg         HWRITE,
    output reg  [2:0]  HSIZE,
    output reg  [2:0]  HBURST,
    output reg  [1:0]  HTRANS,
    output reg  [31:0] HWDATA,

    // ----------------------------------------------------
    // User status
    // ----------------------------------------------------
    output reg         busy,
    output reg         done,
    output reg         error,
    output reg  [31:0] read_data
);

    
    // AHB-Lite HTRANS
  

    localparam [1:0]
        HTRANS_IDLE   = 2'b00,
        HTRANS_BUSY   = 2'b01,
        HTRANS_NONSEQ = 2'b10,
        HTRANS_SEQ    = 2'b11;


    // AHB-Lite HBURST
   

    localparam [2:0]
        HBURST_SINGLE = 3'b000,
        HBURST_WRAP4  = 3'b010,
        HBURST_INCR4  = 3'b011;


   

    localparam [1:0]
        HRESP_OKAY  = 2'b00,
        HRESP_ERROR = 2'b01;


   
    // FSM
  

    localparam [2:0]
        ST_IDLE  = 3'd0,
        ST_ADDR  = 3'd1,
        ST_DATA  = 3'd2,
        ST_ERROR = 3'd3,
        ST_DONE  = 3'd4;

    reg [2:0] state;



    reg [31:0] addr_reg;
    reg [31:0] write_data_reg;

    reg        write_reg;

    reg [2:0]  burst_reg;

    // Current beat: 0,1,2,3
    reg [1:0]  beat_count;

    // WRAP4 boundary
    reg [31:0] wrap_base;


   
    // Sequential logic
   

    always @(posedge HCLK or negedge HRESETn) begin

        if (!HRESETn) begin

            state         <= ST_IDLE;

            addr_reg      <= 32'b0;
            write_data_reg <= 32'b0;

            write_reg     <= 1'b0;
            burst_reg     <= HBURST_SINGLE;

            beat_count    <= 2'd0;
            wrap_base     <= 32'b0;

            busy          <= 1'b0;
            done          <= 1'b0;
            error         <= 1'b0;

            read_data     <= 32'b0;

        end

        else begin

            // Default one-cycle pulses
            done  <= 1'b0;
            error <= 1'b0;


            case (state)

               
                // IDLE
               

                ST_IDLE:
                begin

                    busy <= 1'b0;

                    if (start) begin

                        // Capture transaction
                        addr_reg       <= addr;
                        write_data_reg <= write_data;
                        write_reg      <= write;

                        beat_count <= 2'd0;

                      
                        // Select burst
                       

                        if (beat_length == 4) begin

                            if (wrap_en) begin

                                burst_reg <= HBURST_WRAP4;

                                // 4 beats × 4 bytes = 16 bytes
                                wrap_base <= addr & 32'hFFFF_FFF0;

                            end

                            else begin

                                burst_reg <= HBURST_INCR4;

                            end

                        end

                        else begin

                            burst_reg <= HBURST_SINGLE;

                        end

                        busy  <= 1'b1;

                        state <= ST_ADDR;

                    end

                end


               
                // ADDRESS PHASE
              

                ST_ADDR:
                begin

                    busy <= 1'b1;

                   
                    if (HREADY) begin

                        state <= ST_DATA;

                    end

                end


                
                // DATA PHASE
            

                ST_DATA:
                begin

                    busy <= 1'b1;


                    if (HREADY) begin

                        
                        // ERROR response
                        
                        if (HRESP == HRESP_ERROR) begin

                            state <= ST_ERROR;

                        end

                        
                        // READ DATA
                     

                        else begin

                            if (!write_reg) begin

                                read_data <= HRDATA;

                            end


                            
                            // SINGLE transfer complete
                         

                            if (burst_reg == HBURST_SINGLE) begin

                                state <= ST_DONE;

                            end


                            

                            else if (beat_count == 2'd3) begin

                                state <= ST_DONE;

                            end


                           

                            else begin

                                beat_count <= beat_count + 1'b1;


                                // INCR4
                                if (burst_reg == HBURST_INCR4) begin

                                    addr_reg <= addr_reg + 32'd4;

                                end


                                // WRAP4
                                else if (burst_reg == HBURST_WRAP4) begin

                                    if (addr_reg ==
                                        (wrap_base + 32'd12)) begin

                                        addr_reg <= wrap_base;

                                    end

                                    else begin

                                        addr_reg <= addr_reg + 32'd4;

                                    end

                                end

                                state <= ST_ADDR;

                            end

                        end

                    end

                end


             
                ST_ERROR:
                begin

                    busy  <= 1'b0;
                    error <= 1'b1;

                    state <= ST_IDLE;

                end


               

                ST_DONE:
                begin

                    busy <= 1'b0;
                    done <= 1'b1;

                    state <= ST_IDLE;

                end


                default:
                begin

                    state <= ST_IDLE;

                end

            endcase

        end

    end


  
    always @(*) begin

      

        HADDR  = 32'b0;
        HWRITE = 1'b0;
        HSIZE  = 3'b010;        // 32-bit word
        HBURST = HBURST_SINGLE;
        HTRANS = HTRANS_IDLE;
        HWDATA = 32'b0;


        case (state)

            
            ST_ADDR:
            begin

                HADDR  = addr_reg;
                HWRITE = write_reg;

                // 32-bit transfer
                HSIZE = 3'b010;

                HBURST = burst_reg;

              

                if (beat_count == 2'd0)

                    HTRANS = HTRANS_NONSEQ;

                else

                    HTRANS = HTRANS_SEQ;

            end


        
            ST_DATA:
            begin
              

                if (burst_reg == HBURST_SINGLE) begin

                    HADDR  = addr_reg;
                    HWRITE = write_reg;
                    HSIZE  = 3'b010;
                    HBURST = HBURST_SINGLE;

                    HTRANS = HTRANS_IDLE;

                end

                else begin

                    HADDR  = addr_reg;
                    HWRITE = write_reg;
                    HSIZE  = 3'b010;
                    HBURST = burst_reg;

                    HTRANS = HTRANS_SEQ;

                end

                HWDATA = write_data_reg;

            end


           

            default:
            begin

                HADDR  = 32'b0;
                HWRITE = 1'b0;
                HSIZE  = 3'b010;
                HBURST = HBURST_SINGLE;
                HTRANS = HTRANS_IDLE;
                HWDATA = 32'b0;

            end

        endcase

    end

endmodule
