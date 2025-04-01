module cpu(
    input clk,
    input [15:0]op,     //[15:11]指令 [10:8]目标Reg索引 [7:0]立即数或源Reg索引
    output [7:0]R0      // R0-R7组织成寄存器组,  方便用寄存器索引 选择
);

reg[7:0]R[7:0];
assign R0 = R[0];
reg [7:0] in1,in2, out1;
always @ (*) begin
    in1 = R[op[10:8]];
    in2 = op[11]? R[op[2:0]] : op[7:0];
end

always @ (*) begin 
    case(op[15:12])
        0: out1 = in2;          // ldr
        1: out1 = in1 + in2;    // add
        2: out1 = in1 - in2;    // sub
        3: out1 = in1 & in2;    // and
        4: out1 = in1 | in2;    // or
        5: out1 = (in1 == in2);  // cmp
        default: out1 = 0;
    endcase
end

// 3-8译码器
wire [7:0]sel;
always @(*) begin
    case(op[10:8])
        3'b000: sel = 8'b0000_0001;
        3'b001: sel = 8'b0000_0010;
        3'b010: sel = 8'b0000_0100;
        3'b011: sel = 8'b0000_1000;
        3'b100: sel = 8'b0001_0000;
        3'b101: sel = 8'b0010_0000;
        3'b110: sel = 8'b0100_0000;
        3'b111: sel = 8'b1000_0000;
    endcase
end

always @(posedge clk) begin
    if(sel[0]) R[0]=out1;
    if(sel[1]) R[1]=out1;
    if(sel[2]) R[2]=out1;
    if(sel[3]) R[3]=out1;
    if(sel[4]) R[4]=out1;
    if(sel[5]) R[5]=out1;
    if(sel[6]) R[6]=out1;
    if(sel[7]) 
        R[7]=out1;
    else  
        R[7]=R[7]+1;
end

endmodule