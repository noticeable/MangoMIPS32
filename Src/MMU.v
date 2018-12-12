/********************MangoMIPS32*******************
Filename:   MMU.v
Author:     RickyTino
Version:    v1.0.1
**************************************************/
`include "Defines.v"

module MMU
(   
    input  wire            en,
    input  wire [`ByteWEn] wen,
    input  wire [`AddrBus] vaddr,
    input  wire [`DataBus] wdata,
    output wire [`DataBus] rdata,

    output reg             bus_en,
    output wire [`ByteWEn] bus_wen,
    output reg  [`AddrBus] bus_paddr,
    output wire [`DataBus] bus_wdata,
    input  wire [`DataBus] bus_rdata,
    input  wire            bus_streq,
    output reg             bus_cached,

    output reg             tlb_en,
    output reg  [`AddrBus] tlb_vaddr,
    output reg             tlb_refs,
    input  wire            tlb_rdy,
    input  wire [`AddrBus] tlb_paddr,
    input  wire            tlb_cat,

    input  wire            exc_flag,
    input  wire [`DataBus] cp0_Status,
    input  wire [`DataBus] cp0_Config,
    output wire            stallreq
);

`ifdef Fixed_Mapping_MMU

    assign bus_wen   = en ? wen : `WrDisable;
    assign bus_wdata = wdata;
    assign rdata     = en ? bus_rdata : `ZeroWord;
    assign stallreq  = bus_streq;

    always @(*) begin
        bus_en     <= `false;
        bus_paddr  <= `ZeroWord;
        bus_cached <= `false;

        if(en && !exc_flag) begin
            bus_en <= `true;
            case (vaddr[`Seg])
                `kseg0: begin  //kseg0: unmapped
                    bus_paddr  <= {3'b000, vaddr[28:0]};
                    bus_cached <= cp0_Config[`K0];
                end
                
                `kseg1: begin //kseg1: unmapped, uncached
                    bus_paddr  <= {3'b000, vaddr[28:0]};
                    bus_cached <= `false;
                end
                
                `kseg2, `kseg3: begin //kseg2 & kseg3: mapped
                    bus_paddr  <= vaddr;
                    bus_cached <= cp0_Config[`K23];
                end

                default: begin //kuseg: mapped
                    bus_paddr  <= cp0_Status[`ERL] ? vaddr : {vaddr[31:28] + 4'd4, vaddr[27:0]};
                    bus_cached <= cp0_Config[`KU];
                end
            endcase
        end
    end

`else //TLB-based MMU

    reg  tlb_streq;

    assign bus_wen   = en ? wen : `WrDisable;
    assign bus_wdata = wdata;
    assign rdata     = en ? bus_rdata : `ZeroWord;
    assign stallreq  = bus_streq || tlb_streq;

    always @(*) begin
        tlb_en     <= `false;
        tlb_vaddr  <= `ZeroWord;
        tlb_refs   <= `false;
        tlb_streq  <= `false;
        bus_en     <= `false;
        bus_paddr  <= `ZeroWord;
        bus_cached <= `false;

        if(en && !exc_flag) begin
            case (vaddr[`Seg])
                `kseg0: begin //kseg0: unmapped
                    bus_paddr  <= {3'b000, vaddr[28:0]};
                    bus_en     <= `true;
                    bus_cached <= cp0_Config[`K0];
                end
                
                `kseg1: begin //kseg1: unmapped, uncached
                    bus_paddr  <= {3'b000, vaddr[28:0]};
                    bus_en     <= `true;
                    bus_cached <= `false;
                end
                
                default: begin //kseg2, kseg3, kuseg: mapped
                    if(cp0_Status[`ERL]) begin
                        bus_paddr  <= {3'b000, vaddr[28:0]};
                        bus_en     <= `true;
                        bus_cached <= `false;
                    end
                    else if(en) begin
                        tlb_en     <= `true;
                        tlb_refs   <= wen != `WrDisable;
                        tlb_vaddr  <= vaddr;
                        tlb_streq  <= !tlb_rdy;
                        bus_paddr  <= tlb_paddr;
                        bus_en     <= tlb_rdy;
                        bus_cached <= tlb_cat;
                    end
                end
            endcase
        end
    end
`endif

endmodule