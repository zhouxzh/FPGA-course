module display_control_model(
    input [1:0] display_mode,
    input [7:0] threshold,
    input overlay_enable,
    input [23:0] rgb_pixel,
    input [7:0] edge_pixel,
    output reg [23:0] rgb_out
);

localparam MODE_ORIGINAL = 2'd0;
localparam MODE_GRAY     = 2'd1;
localparam MODE_EDGE     = 2'd2;
localparam MODE_OVERLAY  = 2'd3;

wire [15:0] gray_sum;
wire [7:0] gray;
wire edge_on;
wire overlay_active;

assign gray_sum = ({8'd0, rgb_pixel[23:16]} * 8'd77) +
                  ({8'd0, rgb_pixel[15:8]}  * 8'd150) +
                  ({8'd0, rgb_pixel[7:0]}   * 8'd29);
assign gray = gray_sum[15:8];
assign edge_on = (edge_pixel >= threshold);
assign overlay_active = overlay_enable || (display_mode == MODE_OVERLAY);

always @(*) begin
    case (display_mode)
        MODE_GRAY: begin
            rgb_out = {gray, gray, gray};
        end

        MODE_EDGE: begin
            rgb_out = edge_on ? 24'hffffff : 24'h000000;
        end

        default: begin
            rgb_out = rgb_pixel;
        end
    endcase

    if ((display_mode != MODE_EDGE) && overlay_active && edge_on) begin
        rgb_out = 24'hff2020;
    end
end

endmodule
