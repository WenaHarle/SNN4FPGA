`timescale 1ns/1ps
// ============================================================================
// snn_ecg_net_mod.v
// Top network: 30 -> 30 -> 30 -> 5 (sequential layers).
// Uses memory filenames:
//   fc1_w_q44_int8.mem, fc2_w_q44_int8.mem, fc3_w_q44_int8.mem
// ============================================================================
module snn_ecg_net_mod(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        start,
  input  wire [29:0] spikes_in_bits,
  output wire        done,
  output wire [4:0]  spikes_out_bits
);

  // rising-edge detect on start -> start_pulse (1 cycle)
  reg s1, s2;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin s1<=1'b0; s2<=1'b0; end
    else begin s1<=start; s2<=s1; end
  end
  wire start_pulse = (s1 && !s2);

  wire [29:0] spk1, spk2;
  wire [4:0]  spk3;
  wire d1, d2, d3;

  assign spikes_out_bits = spk3;

  wire st1, st2, st3;

  net_ctl UTOP(
    .clk(clk), .rst_n(rst_n),
    .go(start_pulse),
    .d1(d1), .d2(d2), .d3(d3),
    .st1(st1), .st2(st2), .st3(st3),
    .done(done)
  );

  lif_eng #(.N_OUT(30), .WEIGHT_FILE("fc1_w_q44_int8.mem"))
  L1(.clk(clk), .rst_n(rst_n), .start(st1), .spikes_in_bits(spikes_in_bits), .done(d1), .spikes_out_bits(spk1));

  lif_eng #(.N_OUT(30), .WEIGHT_FILE("fc2_w_q44_int8.mem"))
  L2(.clk(clk), .rst_n(rst_n), .start(st2), .spikes_in_bits(spk1), .done(d2), .spikes_out_bits(spk2));

  lif_eng #(.N_OUT(5),  .WEIGHT_FILE("fc3_w_q44_int8.mem"))
  L3(.clk(clk), .rst_n(rst_n), .start(st3), .spikes_in_bits(spk2), .done(d3), .spikes_out_bits(spk3));

endmodule
