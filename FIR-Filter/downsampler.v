//! @title DOWNSAMPLER
//! @file downsampler.v
//! @author Felipe Montero Bruni - Curso diseño digital Fundación Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - FIR Tx Filter Downsampler

module downsampler
#(
    parameter NB_SAMPLE = 4 ,                                             //! N of Samples
    parameter NB_OUTPUT = 12,                                             //! NB of Coefficients
    parameter NB_SELECT = 2                                               //! NB of Select SW     
)
(
    output signed [NB_OUTPUT - 1 : 0] o_data         ,                    //! Output Sample
    input  signed [NB_OUTPUT - 1 : 0] i_rcTx_data    ,                    //! Input Sample
    input         [NB_SELECT - 1 : 0] i_select       ,                    //! Phase select i_sw
    input         [1             : 0] i_enable_sample,                    //! Enable Sample Output
    input                             i_rst          ,                    //! Reset
    input                             clk                                 //! Clock
);

    //! Internal Signals
    reg signed [NB_OUTPUT - 1 : 0] samples_register [NB_SAMPLE - 1 : 0];  //! Register for Channel Samples
    reg signed [NB_OUTPUT - 1 : 0] output_register                     ;  //! Ouput Sample Register

    //! Downsampler Model
    integer ptr;
    always @(posedge clk) begin
        if (i_rst) begin
            for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                samples_register[ptr] <= {NB_OUTPUT{1'b0}};
            end
            output_register <= {NB_OUTPUT{1'b0}};
        end
        else begin
            for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                if (ptr == 0) begin
                    samples_register[ptr] <= i_rcTx_data;
                end
                else begin
                    samples_register[ptr] <= samples_register[ptr - 1];
                end
            end
            if (i_enable_sample == 2'b11) begin
                if (i_select == 2'b00) begin
                    output_register <= samples_register[0];
                end
                else if (i_select == 2'b01) begin
                    output_register <= samples_register[1];
                end
                else if (i_select == 2'b10) begin
                    output_register <= samples_register[2];
                end
                else begin
                    output_register <= samples_register[3];
                end
            end
            else begin
                output_register <= output_register;
            end
        end
    end

    assign o_data = output_register;

endmodule