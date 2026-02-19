`timescale 1ns/1ps
// ============================================================================
// lif_eng.v
// Layer engine: lif_ctl + lif_cnt + lif_dp
// ============================================================================
module lif_eng #(
  parameter integer N_OUT = 30,
  parameter WEIGHT_FILE = "fc1_w_q44_int8.mem"
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire             start,
  input  wire [29:0]      spikes_in_bits,
  output wire             done,
  output wire [N_OUT-1:0] spikes_out_bits
);

  wire ini_last, out_last, fired;
  wire clr_all, acc_init, acc_step, wr1, wr0, next_out;
  wire [5:0] outi_ps, ini_ps;

  lif_ctl U_CTL(
    .clk(clk), .rst_n(rst_n), .start(start),
    .ini_last(ini_last), .out_last(out_last), .fired(fired),
    .done(done),
    .clr_all(clr_all), .acc_init(acc_init), .acc_step(acc_step),
    .wr1(wr1), .wr0(wr0), .next_out(next_out)
  );

  lif_cnt #(.N_OUT(N_OUT)) U_CNT(
    .clk(clk), .rst_n(rst_n),
    .clr_all(clr_all), .acc_init(acc_init), .acc_step(acc_step), .next_out(next_out),
    .outi(outi_ps), .ini(ini_ps),
    .ini_last(ini_last), .out_last(out_last)
  );

  lif_dp #(.N_OUT(N_OUT), .WEIGHT_FILE(WEIGHT_FILE)) U_DP(
    .clk(clk), .rst_n(rst_n),
    .spikes_in_bits(spikes_in_bits),
    .outi_ps(outi_ps), .ini_ps(ini_ps),
    .clr_all(clr_all), .acc_init(acc_init), .acc_step(acc_step),
    .wr1(wr1), .wr0(wr0),
    .fired(fired),
    .spikes_out_bits(spikes_out_bits)
  );

endmodule
