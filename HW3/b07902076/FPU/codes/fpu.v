module fpu #(
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 1
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_valid
);
    // wires and reg
    reg [DATA_WIDTH-1:0]    o_data_r;
    reg                     o_valid_r, o_valid_w;


    reg                     o_sign;
    reg [7:0]               o_exponent;
    reg [24:0]              o_fraction;

    wire [7:0]              a_exponent;
    wire [23:0]             a_fraction;

    wire [7:0]              b_exponent;
    wire [23:0]             b_fraction; 

    reg [7:0]               exponent_diff;
    reg [23:0]              remain_fraction;
    reg [23:0]              tmp_fraction;

    // continuous assignment
    assign o_data = o_data_r;
    assign o_valid = o_valid_r;

    assign a_sign = i_data_a[31];
    assign a_exponent = i_data_a[30:23];
    assign a_fraction = {1'b1, i_data_a[22:0]};

    assign b_sign = i_data_b[31];
    assign b_exponent = i_data_b[30:23];
    assign b_fraction = {1'b1, i_data_b[22:0]};

    // combinational part
    always @(*) begin
        if (i_valid) begin
            case(i_inst)
            1'd0: begin // adder
                if (a_exponent == b_exponent) begin    // exp(a) == exp(b)
                    o_exponent = a_exponent;
                    remain_fraction = 0;
                    if (a_sign == b_sign) begin        // sgn(a) == sgn(b)
                        o_fraction = a_fraction + b_fraction;
                        o_sign = a_sign;
                    end else begin                     // sgn(a) != sgn(b)
                        if( a_fraction > b_fraction) begin
                            o_fraction = a_fraction - b_fraction;
                            o_sign = a_sign;
                        end else begin              
                            o_fraction = b_fraction - a_fraction;
                            o_sign = b_sign;
                        end
                    end
                end else begin                          // exp(a) != exp(b)
                    if (a_exponent > b_exponent) begin  // exp(a) > exp(b)
                        o_exponent = a_exponent;
                        exponent_diff = a_exponent - b_exponent;
                        o_sign = a_sign;
                        tmp_fraction = b_fraction >> exponent_diff;
                        if (a_sign == b_sign) begin
                            o_fraction = a_fraction + tmp_fraction;
                            remain_fraction = b_fraction << (24 - exponent_diff);
                        end else begin
                            o_fraction = a_fraction - tmp_fraction - 1;
                            remain_fraction = ~(b_fraction << (24 - exponent_diff)) + 1;
                        end
                    end else begin                      // exp(a) < exp(b)
                        o_exponent = b_exponent;
                        exponent_diff = b_exponent - a_exponent;
                        o_sign = b_sign;
                        tmp_fraction = a_fraction >> exponent_diff;
                        if (a_sign == b_sign) begin
                            o_fraction = tmp_fraction + b_fraction;
                            remain_fraction = a_fraction << (24 - exponent_diff);
                        end else begin
                            o_fraction = b_fraction - tmp_fraction - 1;
                            remain_fraction = ~(a_fraction << (24 - exponent_diff)) + 1;
                        end
                    end
                end
                if (o_fraction[24] == 1) begin  // normalization
                    o_exponent = o_exponent + 1;
                    remain_fraction = remain_fraction >> 1;
                    remain_fraction[23] = o_fraction[0];
                    o_fraction = o_fraction >> 1;
                end else if(o_fraction[23] == 0 && o_exponent != 0) begin
                    while(o_fraction[23] == 0 && o_exponent != 0) begin
                        o_exponent = o_exponent - 1;
                        o_fraction = o_fraction << 1;
                        o_fraction[0] = remain_fraction[23];
                        remain_fraction = remain_fraction << 1;
                    end
                end
                if(remain_fraction[23] == 1 && remain_fraction[22:0] == 0 && o_fraction[0] == 1) begin  // rounding
                    o_fraction = o_fraction + 1;
                end else if(remain_fraction[23] == 1 && remain_fraction[22:0] != 0) begin
                    o_fraction = o_fraction + 1;
                end 
                o_valid_w = 1;
            end
            1'd1: begin // mul
                o_sign = a_sign ^ b_sign;
                o_exponent = a_exponent + b_exponent - 127;
                {o_fraction, remain_fraction[23:1]} = a_fraction * b_fraction;
                if (o_fraction[24] == 1) begin  // normalization
                    o_exponent = o_exponent + 1;
                    remain_fraction = remain_fraction >> 1;
                    remain_fraction[23] = o_fraction[0];
                    o_fraction = o_fraction >> 1;
                end else if(o_fraction[23] == 0 && o_exponent != 0) begin
                    while(o_fraction[23] == 0 && o_exponent != 0) begin
                        o_exponent = o_exponent - 1;
                        o_fraction = o_fraction << 1;
                        o_fraction[0] = remain_fraction[23];
                        remain_fraction = remain_fraction << 1;
                    end
                end
                if(remain_fraction[23] == 1 && remain_fraction[22:0] == 0 && o_fraction[0] == 1) begin  // rounding
                    o_fraction = o_fraction + 1;
                end else if(remain_fraction[23] == 1 && remain_fraction[22:0] != 0) begin
                    o_fraction = o_fraction + 1;
                end
                
                o_valid_w = 1;
            end
            endcase
        end
    end
    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_data_r <= 0;
            o_valid_r <= 0;
        end else begin
            o_data_r <= {o_sign, o_exponent, o_fraction[22:0]};
            o_valid_r <= o_valid_w;
    end
end
    

endmodule