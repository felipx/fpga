//! @title TX FIR FILTER TOP LEVEL
//! @file top.v
//! @author Felipe Montero Bruni - Curso diseño digital Fundación Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - TX FIR Filter Top Level

module top
#(
    parameter NB_LEDS        = 4           ,
    parameter NB_SW          = 4           ,

    // Control Module Parameters
    parameter NB_COUNTER     = 2           ,  //! NB of COUNTER REG

    // PRBS9 Paramaters
    parameter NB_REG         = 9           ,  //! NB of REG
    parameter SEED_I         = 9'b110101010,  //! PRBS_I seed
    parameter SEED_Q         = 9'b111111110,  //! PRBS_Q seed

    // FIR Filter Parameters
    parameter NB_SAMPLE      = 5           ,  //! Samples Register Length
    parameter N_COEFF        = 6           ,  //! Number of Phase Coefficients
    parameter NB_COEFF       = 12          ,  //! NB of Coefficients
    parameter NB_OUTPUT      = 12          ,  //! NB of Output

    // Downsampler Parameters
    parameter NB_DOWNSAMPLER = 4           ,  //! NB of Downsampler
    parameter NB_SELECT      = 2           ,  //! NB of Select SW 

    // BER Counter Parameters
    parameter NB_INTPUT    = 12  ,            //! NB of Input
    parameter NB_BITS_REG  = 1024,            //! NB of PRBS Input Reg
    parameter NB_COUNT     = 9   , 
    parameter NB_ADDR_REG = 10   ,
    parameter NB_SAMPLES  = 64   ,
    parameter NB_ERRORS   = 64 
)
(
    output [NB_LEDS - 1  : 0] o_led,
    input  [NB_SW   - 1  : 0] i_sw ,
    input                     i_rst,
    input                     clk
);

    wire [NB_COUNTER - 1 : 0] connect_control_counter             ;  //! Control Counter
    wire                      connect_prbs9I_output               ;  //! Output I Bit
    wire                      connect_prbs9Q_output               ;  //! Output Q Bit
    wire [NB_OUTPUT  - 1 : 0] connect_rcTxI_downsampler_I         ;  //! Output I Sample
    wire [NB_OUTPUT  - 1 : 0] connect_rcTxQ_downsampler_Q         ;  //! Output Q Sample
    wire [NB_OUTPUT  - 1 : 0] connect_downsamplerI_to_berI_counter;  //! Output I Sample
    wire [NB_OUTPUT  - 1 : 0] connect_downsamplerQ_to_berQ_counter;  //! Output Q Sample
    
    wire                      out_ber_bit_I                       ;
    wire                      out_ber_bit_Q                       ;

    control
    #(
        .NB_COUNTER(NB_COUNTER)
    )
        u_control
        (
            .o_counter (connect_control_counter),
            .i_rst     (~i_rst                 ),
            .clk       (clk                    )
        );
        
    prbs9
    #(
        .NB_REG (NB_REG),
        .SEED   (SEED_I)
    )
        u_prbs9_I
        (
            .o_out_bit       (connect_prbs9I_output  ),
            .i_enable_sample (connect_control_counter),
            .i_EnbTx         (i_sw[0]                ),
            .i_rst           (~i_rst                 ),
            .clk             (clk                    )
        );
    
    prbs9
    #(
        .NB_REG (NB_REG),
        .SEED   (SEED_Q)
    )
        u_prbs9_Q
        (
            .o_out_bit       (connect_prbs9Q_output  ),
            .i_enable_sample (connect_control_counter),
            .i_EnbTx         (i_sw[0]                ),
            .i_rst           (~i_rst                 ),
            .clk             (clk                    )
        );
    
    fir_filter
    #(
        .NB_SAMPLE (NB_SAMPLE),
        .N_COEFF   (N_COEFF  ),
        .NB_COEFF  (NB_COEFF ),
        .NB_OUTPUT (NB_OUTPUT)
    )
        u_fir_filter_I
        (
            .o_rcTx_data    (connect_rcTxI_downsampler_I),  //! Output I Sample
            .i_rcTx_input   (connect_prbs9I_output      ),  //! I input
            .i_select_phase (connect_control_counter    ),  //! Control Counter
            .i_EnbTx        (i_sw[0]                    ),  //! Enable
            .i_rst          (~i_rst                     ),  //! Reset
            .clk            (clk                        )   //! Clock
        );
    
    fir_filter
    #(
        .NB_SAMPLE (NB_SAMPLE),
        .N_COEFF   (N_COEFF  ),
        .NB_COEFF  (NB_COEFF ),
        .NB_OUTPUT (NB_OUTPUT)
    )
        u_fir_filter_Q
        (
            .o_rcTx_data    (connect_rcTxQ_downsampler_Q),  //! Output Q Sample
            .i_rcTx_input   (connect_prbs9Q_output      ),  //! Q input
            .i_select_phase (connect_control_counter    ),  //! Control Counter
            .i_EnbTx        (i_sw[0]                    ),  //! Enable
            .i_rst          (~i_rst                     ),  //! Reset
            .clk            (clk                        )   //! Clock
        );
    
    downsampler
    #(
        .NB_SAMPLE (NB_DOWNSAMPLER),  //! N of Samples
        .NB_OUTPUT (NB_OUTPUT     ),  //! NB of Coefficients
        .NB_SELECT (NB_SELECT     )   //! NB of Select SW
    )
        u_downsampler_I
        (
            .o_data          (connect_downsamplerI_to_berI_counter),  //! Output Sample
            .i_rcTx_data     (connect_rcTxI_downsampler_I         ),  //! Input Sample
            .i_select        (i_sw[NB_SW - 1 -: 2]                ),  //! Phase select i_sw
            .i_enable_sample (connect_control_counter             ),  //! Control Counter
            .i_rst           (~i_rst                              ),  //! Reset
            .clk             (clk                                 )   //! Clock
        );
    
    downsampler
    #(
        .NB_SAMPLE (NB_DOWNSAMPLER),  //! N of Samples
        .NB_OUTPUT (NB_OUTPUT     ),  //! NB of Coefficients
        .NB_SELECT (NB_SELECT     )   //! NB of Select SW
    )
        u_downsampler_Q
        (
            .o_data          (connect_downsamplerQ_to_berQ_counter),  //! Output Sample
            .i_rcTx_data     (connect_rcTxQ_downsampler_Q         ),  //! Input Sample
            .i_select        (i_sw[NB_SW - 1 -: 2]                ),  //! Phase select i_sw
            .i_enable_sample (connect_control_counter             ),  //! Control Counter
            .i_rst           (~i_rst                              ),  //! Reset
            .clk             (clk                                 )   //! Clock
        );
    
    ber_counter
    #(
        .NB_INTPUT    (NB_INTPUT   ),  //! NB of Input
        .NB_BITS_REG  (NB_BITS_REG ),  //! NB of PRBS Input Reg
        .NB_COUNT     (NB_COUNT    ), 
        .NB_ADDR_REG  (NB_ADDR_REG ),
        .NB_SAMPLES   (NB_SAMPLES  ),
        .NB_ERRORS    (NB_ERRORS   )
    )
        u_ber_counter_I
        (
            .o_out_bit  (out_ber_bit_I                       ),  //! Out I Bit
            .o_led      (o_led[0]                            ),  //! led
            .i_data     (connect_downsamplerI_to_berI_counter),  //! Input I Data
            .i_enable   (connect_control_counter             ),  //! Control Counter
            .i_prbs_bit (connect_prbs9I_output               ),  //! Input prbsI Bit
            .i_EnbRx    (i_sw[1]                             ),  //! Enable Rx
            .i_rst      (~i_rst                              ),  //! Reset
            .clk        (clk                                 )   //! Clock
        );
            
    ber_counter
    #(
        .NB_INTPUT    (NB_INTPUT   ),  //! NB of Input
        .NB_BITS_REG  (NB_BITS_REG ),  //! NB of PRBS Input Reg
        .NB_COUNT     (NB_COUNT    ),
        .NB_ADDR_REG  (NB_ADDR_REG ),
        .NB_SAMPLES   (NB_SAMPLES  ),
        .NB_ERRORS    (NB_ERRORS   )
    )
        u_ber_counter_Q
        (
            .o_out_bit  (out_ber_bit_Q                       ),  //! Out I Bit
            .o_led      (o_led[1]                            ),  //! led
            .i_data     (connect_downsamplerQ_to_berQ_counter),  //! Input I Data
            .i_enable   (connect_control_counter             ),  //! Control Counter
            .i_prbs_bit (connect_prbs9Q_output               ),  //! Input prbsI Bit
            .i_EnbRx    (i_sw[1]                             ),  //! Enable Rx
            .i_rst      (~i_rst                              ),  //! Reset
            .clk        (clk                                 )   //! Clock
        );
            
endmodule