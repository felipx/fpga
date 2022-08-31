//! @title CONTROL
//! @file control.v
//! @author Felipe Montero Bruni - Curso diseño digital Fundación Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - Tx FIR Filter Control Module

module control
#(
    parameter NB_COUNTER = 2                //! NB of COUNTER REG
)
(
    output [NB_COUNTER - 1 : 0] o_counter,  //! Output
    input                       i_rst    ,  //! Reset
    input                       clk         //! Clock
);

    //! Internal Signals
    reg [NB_COUNTER - 1 : 0] counter;       //! Counter Reg

    //! Counter Model
    always @(posedge clk) begin
        if (i_rst) begin
            counter <= {NB_COUNTER{1'b0}};
        end
        else begin
            if (counter == 2'b11) begin
                counter <= 2'b00;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

    assign o_counter = counter;
    
endmodule