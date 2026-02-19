`timescale 1ns/1ps
// ============================================================================
// lif_ctl.v
// Layer controller (FSM) with ps/ns state, BUT outputs are combinational
// (so timing matches the working monolithic behavior).
//
// Outputs are 1-cycle pulses determined directly by st_ps (Moore style).
// ============================================================================
module lif_ctl(
  input  wire clk,
  input  wire rst_n,
  input  wire start,

  input  wire ini_last,
  input  wire out_last,
  input  wire fired,

  output wire done,
  output wire clr_all,
  output wire acc_init,
  output wire acc_step,
  output wire wr1,
  output wire wr0,
  output wire next_out
);

  reg [3:0] st_ps, st_ns;

  // State codes kept aligned with the original monolithic design
  localparam [3:0]
    S0  = 4'd0,   // idle
    S1  = 4'd1,   // clear/all init
    S2  = 4'd2,   // acc init for new out neuron
    S3  = 4'd3,   // accumulate loop
    S10 = 4'd10,  // decide fired
    S11 = 4'd11,  // write fired
    S12 = 4'd12,  // write not fired
    S4  = 4'd4,   // next out neuron
    S5  = 4'd5;   // done pulse

  // ps <= ns (only state is registered here)
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) st_ps <= S0;
    else       st_ps <= st_ns;
  end

  // next-state
  always @* begin
    st_ns = st_ps;
    case(st_ps)
      S0:  st_ns = start    ? S1  : S0;
      S1:  st_ns = S2;
      S2:  st_ns = S3;
      S3:  st_ns = ini_last ? S10 : S3;
      S10: st_ns = fired    ? S11 : S12;
      S11: st_ns = S4;
      S12: st_ns = S4;
      S4:  st_ns = out_last ? S5  : S2;
      S5:  st_ns = S0;
      default: st_ns = S0;
    endcase
  end

  // outputs (combinational pulses from st_ps)
  assign clr_all  = (st_ps == S1);
  assign acc_init = (st_ps == S2);
  assign acc_step = (st_ps == S3);
  assign wr1      = (st_ps == S11);
  assign wr0      = (st_ps == S12);
  assign next_out = (st_ps == S4);
  assign done     = (st_ps == S5);

endmodule
