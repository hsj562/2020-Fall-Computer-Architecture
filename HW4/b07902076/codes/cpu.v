module cpu #( // Do not modify interface
	parameter ADDR_W = 64,
	parameter INST_W = 32,
	parameter DATA_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_i_valid_inst, // from instruction memory
    input  [ INST_W-1 : 0 ] i_i_inst,       // from instruction memory
    input                   i_d_valid_data, // from data memory
    input  [ DATA_W-1 : 0 ] i_d_data,       // from data memory
    output                  o_i_valid_addr, // to instruction memory
    output [ ADDR_W-1 : 0 ] o_i_addr,       // to instruction memory
    output [ DATA_W-1 : 0 ] o_d_w_data,       // to data memory
    output [ ADDR_W-1 : 0 ] o_d_w_addr,       // to data memory
    output [ ADDR_W-1 : 0 ] o_d_r_addr,       // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);
    // wires and regs
    reg                     o_i_valid_addr_r, o_i_valid_addr_w = 1;
    reg signed [ADDR_W-1:0] o_i_addr_r, o_i_addr_w = 0;
    reg [DATA_W-1:0]        regi [31:0];
    reg [DATA_W-1:0]        o_d_data_r, o_d_data_w = 0;
    reg [ADDR_W-1:0]        o_d_addr_r, o_d_addr_w;
    reg                     o_d_MemRead_r, o_d_MemRead_w = 0;
    reg                     o_d_MemWrite_r, o_d_MemWrite_w = 0;
    reg                     o_finish_r, o_finish_w = 0;
    reg [4:0]               rd = 0;
    reg signed [12:0]       imm = 13'b0000000000000;
    reg [3:0]               cs = 0, ns;
    reg [INST_W-1:0]        inst;
    integer i;
    
    // continuous assignment
    assign o_d_w_addr = o_d_addr_r;
    assign o_d_r_addr = o_d_addr_r;
    assign o_d_w_data = o_d_data_r;
    assign o_i_addr = o_i_addr_r;
    assign o_i_valid_addr = o_i_valid_addr_r;
    assign o_d_MemRead = o_d_MemRead_r;
    assign o_d_MemWrite = o_d_MemWrite_r;
    assign o_finish = o_finish_r;
   
    // combinational part
    always @(*) begin         // instruction fetch
        if(cs == 0 && i_i_valid_inst) begin
            inst = i_i_inst;
        end
    end

    always @(*) begin         
        if(cs == 0) begin
            case({inst[6:0]})
                7'b0000011: begin   // LD
                    o_d_MemRead_w = 1;
                    o_d_MemWrite_w = 0;
                    
                    imm[12:0] ={1'b0, inst[31:20]};

                    o_d_addr_w = regi[inst[19:15]] + imm[11:0];
                    o_i_addr_w = o_i_addr_w + 4;
                    rd = inst[11:7];
                end 
                7'b0100011: begin   // SD
                    o_d_MemRead_w = 0;
                    o_d_MemWrite_w = 1;
                    imm[12:0] = {1'b0, inst[31:25], inst[11:7]};
                    o_d_addr_w = regi[inst[19:15]] + imm[11:0];
                    o_d_data_w = regi[inst[24:20]];
                    o_i_addr_w = o_i_addr_w + 4;
                end
                7'b1100011: begin   
                    if(inst[14:12] == 3'b000) begin // BEQ
                        if(regi[inst[19:15]] == regi[inst[24:20]]) begin 
                            imm = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
			    o_i_addr_w = o_i_addr_r + imm;
                        end else 
                            o_i_addr_w = o_i_addr_r + 4;
                    end else if(inst[14:12] == 3'b001) begin // BNE
                        if(regi[inst[19:15]] != regi[inst[24:20]]) begin
                            imm = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
                            o_i_addr_w = o_i_addr_r + imm;
                        end else 
                            o_i_addr_w = o_i_addr_r + 4;
                    end
                end
                7'b0010011: begin   
                    o_i_addr_w = o_i_addr_w + 4;
                    o_d_MemRead_w = 0;
                    o_d_MemWrite_w = 0;
                    imm[12:0] = {1'b0,inst[31:20]};
                    case(inst[14:12])
                        3'b000: begin // ADDI
                            regi[inst[11:7]] = regi[inst[19:15]] + imm[11:0];
                        end
                        3'b100: begin // XORI
                            regi[inst[11:7]] = regi[inst[19:15]] ^ imm[11:0];
                        end
                        3'b110: begin // ORI
                            regi[inst[11:7]] = regi[inst[19:15]] | imm[11:0];
                            
                        end
                        3'b111: begin // ANDI
                            regi[inst[11:7]] = regi[inst[19:15]] & imm[11:0];
                        end
                        3'b001: begin // SLLI
                            regi[inst[11:7]] = regi[inst[19:15]] << imm[11:0];
                            
                        end
                        3'b101: begin // SRLI
                            regi[inst[11:7]] = regi[inst[19:15]] >> imm[11:0];
                        end
                    endcase
                end
                
                7'b0110011: begin   
                    o_i_addr_w = o_i_addr_w + 4;
                    o_d_MemRead_w = 0;
                    o_d_MemWrite_w = 0;
                    if(inst[30] == 1'b1) begin // SUB
                        regi[inst[11:7]] = regi[inst[19:15]] - regi[inst[24:20]];
                    end else begin
                        case(inst[14:12])
                            3'b000: begin // ADD
                                regi[inst[11:7]] = regi[inst[19:15]] + regi[inst[24:20]];
                            end
                            3'b100: begin // XOR
                                regi[inst[11:7]] = regi[inst[19:15]] ^ regi[inst[24:20]];
                            end
                            3'b110: begin // OR
                                regi[inst[11:7]] = regi[inst[19:15]] | regi[inst[24:20]];
                            end
                            3'b111: begin // AND
                                regi[inst[11:7]] = regi[inst[19:15]] & regi[inst[24:20]];
                            end
                        endcase
                    end
                end
                7'b1111111: begin   // EOF
                    o_finish_w = 1;
                end
            endcase
        end else if(i_d_valid_data && o_d_MemRead_w) begin
	    regi[rd] = i_d_data;	
	end
    end

    always @(*) begin
        case (cs)
        	0: ns = (i_i_valid_inst)? 1 : 0;
        	1: ns = 2;
        	2: ns = 3;
        	3: ns = 0;
        endcase
    end
    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            for(i = 0; i < 32; i = i + 1) begin
                regi[i] <= 0;
            end
            o_i_addr_r <= 0;
            o_d_addr_r <= 0;
            o_d_data_r <= 0;
            o_d_MemRead_r <= 0;
            o_d_MemWrite_r <= 0;
            o_i_valid_addr_r <= 0;
            o_finish_r <= 0;
            cs <= 0;
        end else begin
            o_i_addr_r <= o_i_addr_w;
            o_d_addr_r <= o_d_addr_w;
            o_d_data_r <= o_d_data_w;
            o_i_valid_addr_r <= o_i_valid_addr_w;
            o_d_MemRead_r <= o_d_MemRead_w;
            o_d_MemWrite_r <= o_d_MemWrite_w;
            o_finish_r <= o_finish_w;
            cs <= ns;
        end
    end

endmodule

