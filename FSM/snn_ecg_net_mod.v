`timescale 1ns/1ps
// ============================================================================
// snn_ecg_net_mod.v
// 3-layer SNN top: 30 -> 30 -> 30 -> 5
// start: one timestep request (pulse ok). done: 1-cycle pulse when outputs valid.
// ============================================================================
module snn_ecg_net_mod(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        start,
  input  wire [29:0] spikes_in_bits,
  output wire        done,
  output wire [4:0]  spikes_out_bits
);

  wire start_pulse = start;

  wire [29:0] spk1, spk2;
  wire [4:0]  spk3;

  wire d1, d2, d3;
  wire st1, st2, st3;

  assign spikes_out_bits = spk3;

  net_ctl UTOP(
    .clk(clk), .rst_n(rst_n),
    .go(start_pulse),
    .d1(d1), .d2(d2), .d3(d3),
    .st1(st1), .st2(st2), .st3(st3),
    .done(done)
  );

  lif_eng #(.N_OUT(30), .WEIGHT_FILE("fc1_w_q44_int8.mem")) L1(
    .clk(clk), .rst_n(rst_n),
    .start(st1),
    .spikes_in_bits(spikes_in_bits),
    .done(d1),
    .spikes_out_bits(spk1)
  );

  lif_eng #(.N_OUT(30), .WEIGHT_FILE("fc2_w_q44_int8.mem")) L2(
    .clk(clk), .rst_n(rst_n),
    .start(st2),
    .spikes_in_bits(spk1),
    .done(d2),
    .spikes_out_bits(spk2)
  );

  lif_eng #(.N_OUT(5), .WEIGHT_FILE("fc3_w_q44_int8.mem")) L3(
    .clk(clk), .rst_n(rst_n),
    .start(st3),
    .spikes_in_bits(spk2),
    .done(d3),
    .spikes_out_bits(spk3)
  );

endmodule
