//! @title BER COUNTER9
//! @file ber_counter.v
//! @author Felipe Montero Bruni - Curso dise�o digital Fundaci�n Fulgor 2022
//! @date 08-2022
//! @version 0.1

//! - Dual BER Counter

module ber_counter
#(
    parameter NB_INTPUT   = 12  ,                     //! NB of Input
    parameter NB_BITS_REG = 1024,                     //! NB of PRBS Input Reg
    parameter NB_COUNT    = 9   ,
    parameter NB_ADDR_REG = 10  ,
    parameter NB_SAMPLES  = 64  ,
    parameter NB_ERRORS   = 64  
)

(
    output                           o_out_bit ,
    output                           o_led     ,        //! Led
                                                        
    input signed [NB_INTPUT - 1 : 0] i_data    ,        //! Input Sample
    input        [1             : 0] i_enable  ,        //! Enable PRBS Input
    input                            i_prbs_bit,        //! PRBS Input Bit
    input                            i_EnbRx   ,        //! Enable Rx i_sw
    input                            i_rst     ,        //! Reset
    input                            clk                //! Clock
);                                                      

    reg [NB_BITS_REG - 1 : 0] prbs_input_reg;
    reg [NB_ADDR_REG - 1 : 0] input_reg_addr;
    reg [NB_COUNT    - 1 : 0] sum_reg       ;
    reg [NB_COUNT    - 1 : 0] min_sum_reg   ;
    reg [NB_ADDR_REG - 1 : 0] min_sum_addr  ;
    reg [NB_COUNT    - 1 : 0] counter       ;
    reg [NB_SAMPLES  - 1 : 0] samples       ;
    reg [NB_ERRORS   - 1 : 0] errors        ;
    reg                       stop_cal      ;
    
    always @(posedge clk) begin
        if (i_rst) begin
            prbs_input_reg <= {NB_BITS_REG{1'b0}};
            input_reg_addr <= {NB_ADDR_REG{1'b0}};
            sum_reg        <= {NB_COUNT{1'b0}   };
            min_sum_reg    <= {NB_COUNT{1'b0}   };
            min_sum_addr   <= {NB_ADDR_REG{1'b0}};
            counter        <= {NB_COUNT{1'b0}   };
            samples        <= {NB_SAMPLES{1'b0} };
            errors         <= {NB_ERRORS{1'b0}  };
            stop_cal       <= 1'b0               ;
        end
        else begin
            if (i_EnbRx == 1'b1) begin
                if (i_enable == 2'b11) begin
                    if (stop_cal == 1'b0) begin
                        prbs_input_reg <= {prbs_input_reg[NB_BITS_REG - 2 : 0], i_prbs_bit};
                        if (counter == {NB_COUNT{1'b1}}) begin
                            counter <= {NB_COUNT{1'b0}};
                            sum_reg <= {NB_COUNT{1'b0}};
                            if (input_reg_addr == {NB_ADDR_REG{1'b1}}) begin
                                input_reg_addr <= input_reg_addr;
                                stop_cal       <= 1'b1;
                                if (sum_reg < min_sum_reg) begin
                                    min_sum_reg  <= sum_reg       ;
                                    min_sum_addr <= input_reg_addr;
                                end
                                else begin
                                    min_sum_reg  <= min_sum_reg ;
                                    min_sum_addr <= min_sum_addr;
                                end
                            end
                            else if (input_reg_addr == {NB_ADDR_REG{1'b0}}) begin
                                input_reg_addr <= input_reg_addr + 1'b1;
                                stop_cal       <= stop_cal             ;
                                min_sum_reg    <= sum_reg              ;
                                min_sum_addr   <= input_reg_addr       ;
                            end
                            else begin
                                input_reg_addr <= input_reg_addr + 1'b1;
                                stop_cal       <= stop_cal             ;
                                if (sum_reg < min_sum_reg) begin
                                    min_sum_reg  <= sum_reg       ;
                                    min_sum_addr <= input_reg_addr;
                                end
                                else begin
                                    min_sum_reg  <= min_sum_reg ;
                                    min_sum_addr <= min_sum_addr;
                                end
                            end
                        end
                        else begin
                            input_reg_addr <= input_reg_addr                                                    ;
                            sum_reg        <= sum_reg + (prbs_input_reg[input_reg_addr] ^ i_data[NB_INTPUT - 1]);
                            min_sum_reg    <= min_sum_reg                                                       ;
                            min_sum_addr   <= min_sum_addr                                                      ;
                            counter        <= counter + 1'b1                                                    ;
                            samples        <= samples                                                           ;
                            errors         <= errors                                                            ;
                            stop_cal       <= stop_cal                                                          ;
                        end
                    end
                    else begin
                        prbs_input_reg <= {prbs_input_reg[NB_BITS_REG - 2 : 0], i_prbs_bit              };
                        input_reg_addr <= {NB_ADDR_REG{1'b0}                                            };
                        sum_reg        <= {NB_COUNT{1'b0}                                               };
                        min_sum_reg    <= min_sum_reg                                                    ;
                        min_sum_addr   <= min_sum_addr                                                   ;
                        counter        <= {NB_COUNT{1'b0}                                               };
                        samples        <= {samples[NB_SAMPLES - 2 : 0], i_data[NB_INTPUT - 1]           };
                        errors         <= errors + (prbs_input_reg[min_sum_addr] ^ i_data[NB_INTPUT - 1]);
                        stop_cal       <= 1'b1                                                           ;
                    end
                end
            end
            else begin
                prbs_input_reg <= prbs_input_reg;
                input_reg_addr <= input_reg_addr;
                sum_reg        <= sum_reg       ;
                min_sum_reg    <= min_sum_reg   ;
                min_sum_addr   <= min_sum_addr  ;
                counter        <= counter       ;
                samples        <= samples       ;
                errors         <= errors        ;
                stop_cal       <= stop_cal      ;
            end
        end
    end
    
    assign o_led     = (min_sum_reg == 1'b0)           ? 1'b1 : 1'b0;
    assign o_out_bit = (i_data[NB_INTPUT - 1] == 1'b0) ? 1'b0 : 1'b1;
    
endmodule