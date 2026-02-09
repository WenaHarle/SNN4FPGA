// lif_layer_engine.v
// Time-multiplexed layer engine: N_IN -> N_OUT.
// Weights: signed int8 in Q4.4 (value = int/16)
// Spikes: bits 0/1
//
// Synapse: spike (0/1) gates weight via AND masking (no multiplier).
// ACC: 1-cycle parallel reduction (no in_idx loop).
// Decay (1-cycle): mem_decayed = mem - (mem >>> DECAY_SHIFT) => beta=0.9375
// LIF: mem_next = mem_decayed + acc; threshold THR_Q44; reset subtract threshold.

`timescale 1ns/1ps
module lif_layer_engine #(
  parameter integer N_IN  = 30,
  parameter integer N_OUT = 30,
  parameter         WEIGHT_FILE = "fc1_w_q44_int8.mem",
  parameter integer THR_Q44     = 14,   // 0.875*16
  parameter integer DECAY_SHIFT = 4     // mem - (mem >>> DECAY_SHIFT)
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               start,          // 1-cycle pulse OK
  input  wire [N_IN-1:0]    spikes_in_bits,
  output reg                done,           // 1-cycle pulse
  output reg  [N_OUT-1:0]   spikes_out_bits
);

  // -------------------------
  // Weight memory: flatten [out][in], each line is 8-bit hex (two's complement).
  // -------------------------
  reg [7:0] wmem [0:N_IN*N_OUT-1];
  initial begin
    $readmemh(WEIGHT_FILE, wmem);
  end

  // -------------------------
  // Membrane per neuron: signed Q4.4 in 24-bit
  // -------------------------
  reg signed [23:0] mem [0:N_OUT-1];

  // -------------------------
  // FSM
  // -------------------------
  localparam S_IDLE   = 2'd0,
             S_INIT   = 2'd1,
             S_ACC    = 2'd2,
             S_NEURON = 2'd3;

  reg [1:0] st;
  reg start_latched;

  localparam integer OUTW = (N_OUT <= 2) ? 1 : $clog2(N_OUT);
  reg [OUTW-1:0] out_idx;

  // registered accumulator (Q4.4 in 24-bit)
  reg signed [23:0] acc;

  integer k;

  // -------------------------
  // Parallel ACC (combinational): sum_{i=0..N_IN-1} (spike[i] ? w[out,i] : 0)
  // -------------------------
  integer i;
  reg signed [23:0] acc_comb;
  reg signed [7:0]  w_s8;
  reg signed [7:0]  w_masked_s8;

  always @* begin
    acc_comb = 24'sd0;
    for (i = 0; i < N_IN; i = i + 1) begin
      w_s8 = wmem[out_idx*N_IN + i];                 // signed int8 Q4.4
      w_masked_s8 = w_s8 & {8{spikes_in_bits[i]}};   // spike gating
      acc_comb = acc_comb + {{16{w_masked_s8[7]}}, w_masked_s8}; // sign-extend
    end
  end

  // -------------------------
  // Decay + add acc (combinational)
  // -------------------------
  wire signed [23:0] mem_cur_q44   = mem[out_idx];
  wire signed [23:0] mem_shift_q44 = (mem_cur_q44 >>> DECAY_SHIFT);
  wire signed [23:0] mem_decay_q44 = mem_cur_q44 - mem_shift_q44;
  wire signed [23:0] mem_plus_acc  = mem_decay_q44 + acc;

  // -------------------------
  // Sequential
  // -------------------------
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      st <= S_IDLE;
      done <= 1'b0;
      spikes_out_bits <= {N_OUT{1'b0}};
      start_latched <= 1'b0;
      out_idx <= {OUTW{1'b0}};
      acc <= 24'sd0;
      for(k=0; k<N_OUT; k=k+1) mem[k] <= 24'sd0;
    end else begin
      done <= 1'b0;

      // ---- FIX: latch start so 1-cycle pulse is enough ----
      if (st == S_IDLE) begin
        start_latched <= start_latched | start; // hold request
      end else begin
        start_latched <= 1'b0;                  // clear after leaving IDLE
      end

      case(st)
        S_IDLE: begin
          // ---- FIX: check start OR latched ----
          if(start || start_latched) st <= S_INIT;
        end

        S_INIT: begin
          spikes_out_bits <= {N_OUT{1'b0}};
          out_idx <= {OUTW{1'b0}};
          acc <= 24'sd0;
          st  <= S_ACC;
        end

        // S_ACC cuma 1 clock: register acc from acc_comb
        S_ACC: begin
          acc <= acc_comb;
          st  <= S_NEURON;
        end

        S_NEURON: begin
          if(mem_plus_acc >= THR_Q44) begin
            spikes_out_bits[out_idx] <= 1'b1;
            mem[out_idx] <= mem_plus_acc - THR_Q44;
          end else begin
            spikes_out_bits[out_idx] <= 1'b0;
            mem[out_idx] <= mem_plus_acc;
          end

          if(out_idx == N_OUT-1) begin
            done <= 1'b1;
            st   <= S_IDLE;
          end else begin
            out_idx <= out_idx + 1'b1;
            acc     <= 24'sd0;
            st      <= S_ACC;
          end
        end

        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
