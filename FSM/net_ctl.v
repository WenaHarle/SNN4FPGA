`timescale 1ns/1ps
// ============================================================================
// net_ctl.v
// Top-level controller sequencing 3 layers (st1, st2, st3)
// ============================================================================
module net_ctl(
  input  wire clk,
  input  wire rst_n,
  input  wire go,
  input  wire d1,
  input  wire d2,
  input  wire d3,
  output wire st1,
  output wire st2,
  output wire st3,
  output wire done
);

  reg [3:0] t_ps, t_ns;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) t_ps <= 4'd0;
    else      t_ps <= t_ns;
  end

  always @* begin
    t_ns = t_ps;
    case(t_ps)
      4'd0: t_ns = go ? 4'd1 : 4'd0;
      4'd1: t_ns = 4'd2;
      4'd2: t_ns = d1 ? 4'd3 : 4'd2;
      4'd3: t_ns = 4'd4;
      4'd4: t_ns = d2 ? 4'd5 : 4'd4;
      4'd5: t_ns = 4'd6;
      4'd6: t_ns = d3 ? 4'd7 : 4'd6;
      4'd7: t_ns = 4'd0;
      default: t_ns = t_ps;
    endcase
  end

  // outputs are combinational pulses from state
  assign st1  = (t_ps == 4'd1);
  assign st2  = (t_ps == 4'd3);
  assign st3  = (t_ps == 4'd5);
  assign done = (t_ps == 4'd7);

endmodule
