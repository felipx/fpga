//! @title PRBS9
//! @file prbs.v
//! @author Felipe Montero Bruni - Curso diseño digital Fundación Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - 9 Bit Pseudo Random Binary Sequence

module prbs9
#(
    parameter NB_REG = 9           ,  //! NB of REG
    parameter SEED   = 9'b110101010   //! PRBS9 seed
)
(
    output         o_out_bit      ,   //! Output bit
    input  [1 : 0] i_enable_sample,   //! Enable Sample Output
    input          i_EnbTx        ,   //! Enable Tx
    input          i_rst          ,   //! Reset
    input          clk                //! Clock
);

    //! Internal Signals
    reg [NB_REG - 1 : 0] bit_reg;     //! Bits register
    reg                  init   ;     //! Init Register

    //! PRBS9 Model
    always @(posedge clk) begin
        if (i_rst) begin
            bit_reg <= {NB_REG{1'b0}};
            init    <= 1'b0          ;
        end
        else begin
            if (init == 1'b0) begin
                bit_reg <= SEED;
                init    <= 1'b1;
            end
            else begin
                if ((i_EnbTx == 1'b1) && (i_enable_sample == 2'b11) && (init == 1'b1)) begin
                    bit_reg <= {bit_reg[NB_REG - 2 : 0], bit_reg[8] ^ bit_reg[4]};
                end
                else begin
                  bit_reg <= bit_reg;
                end
            end
        end
    end

    assign o_out_bit = bit_reg[NB_REG - 1];

endmodule