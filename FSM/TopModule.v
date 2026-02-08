// snn_ecg_net.v
// 3-layer SNN: 30->30->30->5, sequential per layer per timestep.
// start: one timestep request (pulse ok). done: 1-cycle pulse when outputs valid.
`timescale 1ns/1ps
module snn_ecg_net #(
  parameter integer N_IN = 30
)(
  input  wire            clk,
  input  wire            rst_n,
  input  wire            start,
  input  wire [N_IN-1:0] spikes_in_bits,
  output reg             done,
  output wire [4:0]      spikes_out_bits
);

  // Explicit regs declared BEFORE instantiation (avoid implicit nets)
  reg start_l1, start_l2, start_l3;

  wire l1_done, l2_done, l3_done;
  wire [29:0] spk1_bits;
  wire [29:0] spk2_bits;
  wire [4:0]  spk3_bits;

  assign spikes_out_bits = spk3_bits;

  lif_layer_engine #(
    .N_IN(30), .N_OUT(30),
    .WEIGHT_FILE("fc1_w_q44_int8.mem"),
    .THR_Q44(14),
    .DECAY_SHIFT(4)
  ) layer1 (
    .clk(clk), .rst_n(rst_n),
    .start(start_l1),
    .spikes_in_bits(spikes_in_bits),
    .done(l1_done),
    .spikes_out_bits(spk1_bits)
  );

  lif_layer_engine #(
    .N_IN(30), .N_OUT(30),
    .WEIGHT_FILE("fc2_w_q44_int8.mem"),
    .THR_Q44(14),
    .DECAY_SHIFT(4)
  ) layer2 (
    .clk(clk), .rst_n(rst_n),
    .start(start_l2),
    .spikes_in_bits(spk1_bits),
    .done(l2_done),
    .spikes_out_bits(spk2_bits)
  );

  lif_layer_engine #(
    .N_IN(30), .N_OUT(5),
    .WEIGHT_FILE("fc3_w_q44_int8.mem"),
    .THR_Q44(14),
    .DECAY_SHIFT(4)
  ) layer3 (
    .clk(clk), .rst_n(rst_n),
    .start(start_l3),
    .spikes_in_bits(spk2_bits),
    .done(l3_done),
    .spikes_out_bits(spk3_bits)
  );

  // Top FSM Moore
  localparam T_IDLE=2'd0, T_L1=2'd1, T_L2=2'd2, T_L3=2'd3;
  reg [1:0] tst;
  reg start_latched;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tst <= T_IDLE;
      done <= 1'b0;
      start_l1 <= 1'b0;
      start_l2 <= 1'b0;
      start_l3 <= 1'b0;
      start_latched <= 1'b0;
    end else begin
      done <= 1'b0;
      start_l1 <= 1'b0;
      start_l2 <= 1'b0;
      start_l3 <= 1'b0;

      if(tst == T_IDLE) start_latched <= 1'b0;
      if(start) start_latched <= 1'b1;

      case(tst)
        T_IDLE: begin
          if(start_latched) begin
            start_l1 <= 1'b1;
            tst <= T_L1;
          end
        end

        T_L1: begin
          if(l1_done) begin
            start_l2 <= 1'b1;
            tst <= T_L2;
          end
        end

        T_L2: begin
          if(l2_done) begin
            start_l3 <= 1'b1;
            tst <= T_L3;
          end
        end

        T_L3: begin
          if(l3_done) begin
            done <= 1'b1;
            tst <= T_IDLE;
          end
        end
      endcase
    end
  end
endmodule
