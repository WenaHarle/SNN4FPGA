`timescale 1ns/1ps
// ============================================================================
// lif_dp.v
// Datapath for one LIF layer (ps/ns accumulator & spike buffer, mem array).
// Matched to monolithic behavior:
//   - fired computed from mem_plus = decay(mem) + acc_ps
//   - mem update occurs only on wr1/wr0 pulses
//   - spike bit written on wr1/wr0 pulses
// ============================================================================
module lif_dp #(
  parameter integer N_OUT = 30,
  parameter WEIGHT_FILE = "fc1_w_q44_int8.mem"
)(
  input  wire             clk,
  input  wire             rst_n,

  input  wire [29:0]      spikes_in_bits,
  input  wire [5:0]       outi_ps,
  input  wire [5:0]       ini_ps,

  input  wire             clr_all,
  input  wire             acc_init,
  input  wire             acc_step,
  input  wire             wr1,
  input  wire             wr0,

  output wire             fired,
  output wire [N_OUT-1:0] spikes_out_bits
);

  localparam integer THR_Q44     = 14;
  localparam integer DECAY_SHIFT = 4;

  reg signed [7:0] wmem [0:(N_OUT*30)-1];
  initial begin
    $readmemh(WEIGHT_FILE, wmem);
  end

  reg signed [23:0] acc_ps, acc_ns;
  reg [N_OUT-1:0]   spk_ps, spk_ns;

  reg signed [23:0] mem [0:N_OUT-1];
  integer k;

  assign spikes_out_bits = spk_ps;

  wire signed [23:0] mem_cur   = mem[outi_ps];
  wire signed [23:0] mem_decay = mem_cur - (mem_cur >>> DECAY_SHIFT);
  wire signed [23:0] mem_plus  = mem_decay + acc_ps;

  assign fired = (mem_plus >= THR_Q44);

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      acc_ps <= 24'sd0;
      spk_ps <= {N_OUT{1'b0}};
      for(k=0; k<N_OUT; k=k+1) mem[k] <= 24'sd0;
    end else begin
      acc_ps <= acc_ns;
      spk_ps <= spk_ns;

      if (wr1)      mem[outi_ps] <= mem_plus - THR_Q44;
      else if (wr0) mem[outi_ps] <= mem_plus;
    end
  end

  reg signed [7:0] w8;
  always @* begin
    acc_ns = acc_ps;
    spk_ns = spk_ps;

    if (clr_all) begin
      acc_ns = 24'sd0;
      spk_ns = {N_OUT{1'b0}};
    end

    if (acc_init) begin
      acc_ns = 24'sd0;
    end else if (acc_step) begin
      w8 = wmem[outi_ps*30 + ini_ps];
      if (spikes_in_bits[ini_ps])
        acc_ns = acc_ps + {{16{w8[7]}}, w8};
    end

    if (wr1)      spk_ns[outi_ps] = 1'b1;
    else if (wr0) spk_ns[outi_ps] = 1'b0;
  end

endmodule
