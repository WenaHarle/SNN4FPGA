`timescale 1ns/1ps
// ============================================================================
// lif_dp.v
// LIF Datapath
// Menghitung akumulasi bobot, decay membrane, dan update spike.
// Semua kontrol (acc_step, mem_we, mem_sub) berasal dari FSM di lif_ctl.
// ============================================================================
module lif_dp #(
  parameter integer N_OUT = 30,
  parameter WEIGHT_FILE   = "fc1_w_q44_int8.mem"
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [29:0]      spikes_in_bits,

  input  wire [5:0]       outi_ps,
  input  wire [5:0]       ini_ps,

  input  wire             clr_all,
  input  wire             acc_init,
  input  wire             acc_step,

  input  wire             wr1,     // write fired
  input  wire             wr0,     // write not fired

  output wire             fired,
  output wire [N_OUT-1:0] spikes_out_bits
);

  localparam signed [23:0] THRESHOLD   = 24'sd14;
  localparam integer       DECAY_SHIFT = 4;

  // ---------------- Weight Memory ----------------
  (* ram_style = "block" *)
  reg signed [7:0] weight_mem [0:(N_OUT*30)-1];
  initial $readmemh(WEIGHT_FILE, weight_mem);

  // ---------------- Registers ----------------
  reg  signed [23:0] acc_reg;
  reg  signed [23:0] membrane [0:N_OUT-1];
  reg  [N_OUT-1:0]   spike_reg;

  assign spikes_out_bits = spike_reg;

  // ---------------- Membrane Calculation ----------------
  wire signed [23:0] mem_current = membrane[outi_ps];
  wire signed [23:0] mem_decay   = mem_current - (mem_current >>> DECAY_SHIFT);
  wire signed [23:0] mem_sum     = mem_decay + acc_reg;

  assign fired = (mem_sum >= THRESHOLD);

  // Data yang ditulis ke membrane (ditentukan FSM)
  wire mem_we  = (wr1 | wr0);
  wire mem_sub = wr1;

  wire signed [23:0] mem_wdata = mem_sub ? (mem_sum - THRESHOLD) : mem_sum;

  // ---------------- Accumulator Logic ----------------
  // BRAM-friendly: baca weight secara sinkron + pipeline 1 tahap.
  // acc_step: tahap "capture" (alamat & spike). Penjumlahan terjadi pada siklus berikutnya.

  reg signed [7:0]  w_q;
  reg               spike_q;
  reg               valid_q;

  wire [15:0] waddr = (outi_ps * 16'd30) + ini_ps;

  // ---------------- Sequential Update ----------------
  integer i;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      acc_reg   <= 24'sd0;
      w_q       <= 8'sd0;
      spike_q   <= 1'b0;
      valid_q   <= 1'b0;

      spike_reg <= {N_OUT{1'b0}};
      for(i=0;i<N_OUT;i=i+1)
        membrane[i] <= 24'sd0;
    end else begin
      // Default: hold
      // 1) Accumulator update (pakai data yang di-capture pada siklus sebelumnya)
      if (clr_all || acc_init) begin
        acc_reg <= 24'sd0;
        valid_q <= 1'b0; // flush pipeline saat reset accumulator
      end else if (valid_q && spike_q) begin
        acc_reg <= acc_reg + {{16{w_q[7]}}, w_q}; // sign extend
      end

      // 2) Capture weight + spike untuk siklus berikutnya
      if (acc_step) begin
        w_q     <= weight_mem[waddr];
        spike_q <= spikes_in_bits[ini_ps];
        valid_q <= 1'b1;
      end else if (!(clr_all || acc_init)) begin
        valid_q <= 1'b0;
      end

      // 3) Membrane + spike writeback (dikontrol FSM)
      if (mem_we) begin
        membrane[outi_ps]   <= mem_wdata;
        spike_reg[outi_ps]  <= mem_sub; // 1 kalau fired, 0 kalau not fired
      end
    end
  end

endmodule
