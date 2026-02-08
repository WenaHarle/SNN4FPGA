// lif_layer_engine_parallel_fixed.v
`timescale 1ns/1ps
module lif_layer_engine_parallel #(
  parameter integer N_IN  = 30,
  parameter integer N_OUT = 30,
  parameter         WEIGHT_FILE = "fc1_w_q44_int8.mem",
  parameter integer THR_Q44     = 14,
  parameter integer DECAY_SHIFT = 4
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               start,
  input  wire [N_IN-1:0]    spikes_in_bits,
  output reg                done,
  output reg  [N_OUT-1:0]   spikes_out_bits
);

  (* rom_style = "block" *) reg signed [7:0] wmem [0:N_IN*N_OUT-1];
  initial begin
    $readmemh(WEIGHT_FILE, wmem);
  end

  reg signed [23:0] mem [0:N_OUT-1];

  // combinational acc for each neuron
  reg signed [23:0] acc_vec [0:N_OUT-1];
  integer i, j;

  always @* begin
    for (i=0; i<N_OUT; i=i+1) begin
      acc_vec[i] = 24'sd0;
      for (j=0; j<N_IN; j=j+1) begin
        if (spikes_in_bits[j]) begin
          acc_vec[i] = acc_vec[i] + {{16{wmem[i*N_IN+j][7]}}, wmem[i*N_IN+j]};
        end
      end
    end
  end

  reg start_d;
  integer k;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      done <= 1'b0;
      start_d <= 1'b0;
      spikes_out_bits <= {N_OUT{1'b0}};
      for(k=0; k<N_OUT; k=k+1) mem[k] <= 24'sd0;
    end else begin
      done <= 1'b0;
      start_d <= start;

      if(start) begin
        for(k=0; k<N_OUT; k=k+1) begin
          // inline computations (no reg declared inside loop)
          // decay
          // mem_decayed = mem - (mem >>> DECAY_SHIFT)
          // mem_plus = mem_decayed + acc
          // threshold + reset
          if( (mem[k] - (mem[k] >>> DECAY_SHIFT) + acc_vec[k]) >= THR_Q44 ) begin
            spikes_out_bits[k] <= 1'b1;
            mem[k] <= (mem[k] - (mem[k] >>> DECAY_SHIFT) + acc_vec[k]) - THR_Q44;
          end else begin
            spikes_out_bits[k] <= 1'b0;
            mem[k] <= (mem[k] - (mem[k] >>> DECAY_SHIFT) + acc_vec[k]);
          end
        end
      end

      if(start_d) done <= 1'b1;
    end
  end

endmodule
