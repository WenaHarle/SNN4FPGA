// lif_layer_engine.v
// Time-multiplexed layer engine: N_IN -> N_OUT.
// Weights: signed int8 in Q4.4 (value = int/16)
// Spikes: bits 0/1
//
// Synapse: spike (0/1) gates weight via AND masking (no multiplier).
// Decay (1-cycle, no Booth): mem_decayed = mem - (mem >>> 4)  => beta = 0.9375
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
  input  wire               start,          // start one timestep (pulse or level)
  input  wire [N_IN-1:0]    spikes_in_bits,
  output reg                done,
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

  integer out_idx;
  integer in_idx;

  reg signed [23:0] acc;

  // -------------------------
  // Current weight (signed) and gated term
  // -------------------------
  wire signed [7:0] w_s8;
  assign w_s8 = wmem[out_idx*N_IN + in_idx];

  wire spike_bit;
  assign spike_bit = spikes_in_bits[in_idx];

  // AND mask gating (spike=0 -> 0, spike=1 -> w)
  wire signed [7:0] w_masked_s8;
  assign w_masked_s8 = w_s8 & {8{spike_bit}};

  // Sign-extend to 24-bit Q4.4
  wire signed [23:0] term_q44;
  assign term_q44 = {{16{w_masked_s8[7]}}, w_masked_s8};

  // -------------------------
  // Decay: mem_decayed = mem - (mem >>> DECAY_SHIFT)
  // (arithmetic shift right)
  // -------------------------
  wire signed [23:0] mem_cur_q44;
  assign mem_cur_q44 = mem[out_idx];

  wire signed [23:0] mem_shift_q44;
  assign mem_shift_q44 = (mem_cur_q44 >>> DECAY_SHIFT);

  wire signed [23:0] mem_decay_q44;
  assign mem_decay_q44 = mem_cur_q44 - mem_shift_q44;

  wire signed [23:0] mem_plus_acc;
  assign mem_plus_acc = mem_decay_q44 + acc;

  integer k;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      st <= S_IDLE;
      done <= 1'b0;
      spikes_out_bits <= {N_OUT{1'b0}};
      start_latched <= 1'b0;
      out_idx <= 0;
      in_idx  <= 0;
      acc     <= 24'sd0;
      for(k=0; k<N_OUT; k=k+1) mem[k] <= 24'sd0;
    end else begin
      done <= 1'b0;

      // latch start level so 1-cycle pulse is enough
      if(st == S_IDLE) start_latched <= 1'b0;
      if(start) start_latched <= 1'b1;

      case(st)
        S_IDLE: begin
          if(start_latched) begin
            st <= S_INIT;
          end
        end

        S_INIT: begin
          spikes_out_bits <= {N_OUT{1'b0}};
          out_idx <= 0;
          in_idx  <= 0;
          acc     <= 24'sd0;
          st      <= S_ACC;
        end

        S_ACC: begin
          // accumulate gated weight
          acc <= acc + term_q44;

          if(in_idx == N_IN-1) begin
            st <= S_NEURON;
          end else begin
            in_idx <= in_idx + 1;
          end
        end

        S_NEURON: begin
          // LIF update using decayed mem (1-cycle decay)
          if(mem_plus_acc >= THR_Q44) begin
            spikes_out_bits[out_idx] <= 1'b1;
            mem[out_idx] <= mem_plus_acc - THR_Q44;
          end else begin
            spikes_out_bits[out_idx] <= 1'b0;
            mem[out_idx] <= mem_plus_acc;
          end

          // next neuron / finish
          if(out_idx == N_OUT-1) begin
            done <= 1'b1;
            st   <= S_IDLE;
          end else begin
            out_idx <= out_idx + 1;
            in_idx  <= 0;
            acc     <= 24'sd0;
            st      <= S_ACC;
          end
        end

        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
