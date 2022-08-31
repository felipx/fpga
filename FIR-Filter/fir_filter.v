//! @title DUAL FIR FILTER
//! @file fir_filter_dual.v
//! @author Felipe Montero Bruni - Curso diseño digital Fundación Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - TX FIR Filter

module fir_filter
#(
    parameter NB_SAMPLE  = 6 ,                                           //! NB of Samples Register
    parameter N_COEFF    = 6 ,                                           //! Number of Phase Coefficients
    parameter NB_COEFF   = 12,                                           //! NB of Coefficients
    parameter NB_OUTPUT  = 12                                            //! NB of Output
)
(
    output signed [NB_OUTPUT - 1 : 0] o_rcTx_data   ,                    //! Output Sample
                                                       
    input         [1             : 0] i_select_phase,                    //! Phase Select Input
    input                             i_rcTx_input  ,                    //! input Bit
    input                             i_EnbTx       ,                    //! Enable
    input                             i_rst         ,                    //! Reset
    input                             clk                                //! Clock
);

    localparam NB_PROD = NB_COEFF        ;                               //! NB of Product Registers
    localparam N_PROD  = N_COEFF         ;                               //! Number of Product Registers
    localparam N_SUM   = N_COEFF  - 1    ;                               //! Number of Sum Registers
    localparam NB_SUM  = NB_COEFF + N_SUM;                               //! NB of Sum Registers
    

    reg         [NB_SAMPLE - 1 : 0] samples_register                  ;  //! Samples Register
    reg signed  [NB_PROD   - 1 : 0] prod             [N_PROD  - 1 : 0];  //! Matrix for Products

    wire signed [NB_COEFF - 1 : 0] phase0            [N_COEFF - 1 : 0];  //! Matrix for phase0 Coefficients
    wire signed [NB_COEFF - 1 : 0] phase1            [N_COEFF - 1 : 0];  //! Matrix for phase1 Coefficients
    wire signed [NB_COEFF - 1 : 0] phase2            [N_COEFF - 1 : 0];  //! Matrix for phase2 Coefficients
    wire signed [NB_COEFF - 1 : 0] phase3            [N_COEFF - 1 : 0];  //! Matrix for phase3 Coefficients
    wire signed [NB_SUM   - 1 : 0] sum               [N_SUM   - 1 : 0];  //! Addition Matrix

    //! Coeffs fValues:
    //! phase[0]: [0.0, -0.0009765625, 0.0, 1.0, -0.0009765625, 0.0]
    //! phase[1]: [0.00390625, -0.0576171875, 0.26171875, 0.88671875, -0.123046875, 0.0224609375]
    //! phase[2]: [0.0166015625, -0.1201171875, 0.599609375, 0.599609375, -0.1201171875, 0.0166015625]
    //! phase[3]: [0.0224609375, -0.123046875, 0.88671875, 0.26171875, -0.0576171875, 0.00390625]
    
    //! Coeffs intvalues:
    //! phase[0]: [0, 4095, 0, 1024, 4095, 0]
    assign phase0[0] = 12'b0000_0000_0000;  // 0
    assign phase0[1] = 12'b1111_1111_1111;  // 4095
    assign phase0[2] = 12'b0000_0000_0000;  // 0
    assign phase0[3] = 12'b0100_0000_0000;  // 1024
    assign phase0[4] = 12'b1111_1111_1111;  // 4095
    assign phase0[5] = 12'b0000_0000_0000;  // 0
    
    //! phase[1]: [4, 4037, 268, 908, 3970, 23]
    assign phase1[0] = 12'b0000_0000_0100;  // 4
    assign phase1[1] = 12'b1111_1100_0101;  // 4037
    assign phase1[2] = 12'b0001_0000_1100;  // 268
    assign phase1[3] = 12'b0011_1000_1100;  // 908
    assign phase1[4] = 12'b1111_1000_0010;  // 3970
    assign phase1[5] = 12'b0000_0001_0111;  // 23
    
    //! phase[2]: [17, 3973, 614, 614, 3973, 17]
    assign phase2[0] = 12'b0000_0001_0001;  // 17
    assign phase2[1] = 12'b1111_1000_0101;  // 3973
    assign phase2[2] = 12'b0010_0110_0110;  // 614
    assign phase2[3] = 12'b0010_0110_0110;  // 614
    assign phase2[4] = 12'b1111_1000_0101;  // 3973
    assign phase2[5] = 12'b0000_0001_0001;  // 17

    //! phase[3]: [23, 3970, 908, 268, 4037, 4]
    assign phase3[0] = 12'b0000_0001_0111;  // 23
    assign phase3[1] = 12'b1111_1000_0010;  // 3970
    assign phase3[2] = 12'b0011_1000_1100;  // 908
    assign phase3[3] = 12'b0001_0000_1100;  // 268    
    assign phase3[4] = 12'b1111_1100_0101;  // 4037
    assign phase3[5] = 12'b0000_0000_0100;  // 4

    integer ptr;
    always @(posedge clk) begin
        if (i_rst) begin
            samples_register <= {NB_SAMPLE{1'b0}};
            for (ptr = 0; ptr < N_PROD; ptr = ptr + 1) begin
                prod[ptr] <= {NB_PROD{1'b0}};
            end
        end
        else begin
            if (i_EnbTx == 1'b1) begin
                if (i_select_phase == 2'b11) begin
                    samples_register <= {samples_register[NB_SAMPLE - 2 : 0], i_rcTx_input};
                end
                else begin
                    samples_register <= samples_register;
                end
                if (i_select_phase == 2'b00) begin
                    for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                        if (samples_register[ptr] == 1'b0) begin
                            prod[ptr] <= phase0[ptr];
                        end
                        else begin
                            prod[ptr] <= -phase0[ptr];
                        end
                    end
                end
                else if (i_select_phase == 2'b01) begin
                    for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                        if (samples_register[ptr] == 1'b0) begin
                            prod[ptr] <= phase1[ptr];
                        end
                        else begin
                            prod[ptr] <= -phase1[ptr];
                        end
                    end
                end
                else if (i_select_phase == 2'b10) begin
                    for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                        if (samples_register[ptr] == 1'b0) begin
                            prod[ptr] <= phase2[ptr];
                        end
                        else begin
                            prod[ptr] <= -phase2[ptr];
                        end
                    end
                end
                else begin
                    for (ptr = 0; ptr < NB_SAMPLE; ptr = ptr + 1) begin
                        if (samples_register[ptr] == 1'b0) begin
                            prod[ptr] <= phase3[ptr];
                        end
                        else begin
                            prod[ptr] <= -phase3[ptr];
                        end
                    end
                end
            end
            else begin
                samples_register <= samples_register;
                for (ptr = 0; ptr < N_PROD; ptr = ptr + 1) begin
                    prod[ptr] <= prod[ptr];
                end
            end
        end
    end

    generate
        genvar ptr2;
        for(ptr2 = 0; ptr2 < N_SUM; ptr2 = ptr2 + 1) begin
            if (ptr2 == 0) begin 
                assign sum[ptr2] = prod[ptr2] + prod[ptr2 + 1];
            end
            else begin
                assign sum[ptr2] = sum[ptr2 - 1] + prod[ptr2 + 1];
            end
        end
    endgenerate

    assign o_rcTx_data = ( ~|sum[4][NB_SUM-1 -: N_SUM] || &sum[4][NB_SUM-1 -: N_SUM]) ? sum[4][0 +: NB_OUTPUT] :
                          (sum[4][NB_SUM-1]) ? {{1'b1},{NB_OUTPUT-1{1'b0}}} : {{1'b0},{NB_OUTPUT-1{1'b1}}};

endmodule