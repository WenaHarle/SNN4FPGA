#######################################################################
# snn_ecg_net.xdc  (Template)
# Device: xc7z010clg400-1
# Notes:
# - Replace <PIN_...> with your board's PACKAGE_PIN assignments
# - Adjust IOSTANDARD if your bank voltage differs (commonly LVCMOS33)
#######################################################################

########################
# CLOCK CONSTRAINT
########################
# Example: 100 MHz clock
set_property -dict { PACKAGE_PIN <PIN_CLK> IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -name clk -period 10.000 [get_ports clk]   ;# 100 MHz

# (Optional) If you want stricter timing:
# set_clock_uncertainty 0.200 [get_clocks clk]

########################
# RESET & CONTROL PINS
########################
# rst_n : active-low reset
set_property -dict { PACKAGE_PIN <PIN_RSTN> IOSTANDARD LVCMOS33 PULLUP true } [get_ports rst_n]

# start : 1-cycle pulse request
set_property -dict { PACKAGE_PIN <PIN_START> IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports start]

# done : 1-cycle pulse
set_property -dict { PACKAGE_PIN <PIN_DONE> IOSTANDARD LVCMOS33 } [get_ports done]

########################
# INPUT BUS: spikes_in_bits[29:0]
########################
# Option A (recommended): declare each bit explicitly
# Replace <PIN_IN0>.. <PIN_IN29>
set_property -dict { PACKAGE_PIN <PIN_IN0>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[0]}]
set_property -dict { PACKAGE_PIN <PIN_IN1>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[1]}]
set_property -dict { PACKAGE_PIN <PIN_IN2>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[2]}]
set_property -dict { PACKAGE_PIN <PIN_IN3>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[3]}]
set_property -dict { PACKAGE_PIN <PIN_IN4>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[4]}]
set_property -dict { PACKAGE_PIN <PIN_IN5>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[5]}]
set_property -dict { PACKAGE_PIN <PIN_IN6>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[6]}]
set_property -dict { PACKAGE_PIN <PIN_IN7>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[7]}]
set_property -dict { PACKAGE_PIN <PIN_IN8>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[8]}]
set_property -dict { PACKAGE_PIN <PIN_IN9>  IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[9]}]
set_property -dict { PACKAGE_PIN <PIN_IN10> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[10]}]
set_property -dict { PACKAGE_PIN <PIN_IN11> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[11]}]
set_property -dict { PACKAGE_PIN <PIN_IN12> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[12]}]
set_property -dict { PACKAGE_PIN <PIN_IN13> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[13]}]
set_property -dict { PACKAGE_PIN <PIN_IN14> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[14]}]
set_property -dict { PACKAGE_PIN <PIN_IN15> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[15]}]
set_property -dict { PACKAGE_PIN <PIN_IN16> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[16]}]
set_property -dict { PACKAGE_PIN <PIN_IN17> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[17]}]
set_property -dict { PACKAGE_PIN <PIN_IN18> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[18]}]
set_property -dict { PACKAGE_PIN <PIN_IN19> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[19]}]
set_property -dict { PACKAGE_PIN <PIN_IN20> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[20]}]
set_property -dict { PACKAGE_PIN <PIN_IN21> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[21]}]
set_property -dict { PACKAGE_PIN <PIN_IN22> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[22]}]
set_property -dict { PACKAGE_PIN <PIN_IN23> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[23]}]
set_property -dict { PACKAGE_PIN <PIN_IN24> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[24]}]
set_property -dict { PACKAGE_PIN <PIN_IN25> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[25]}]
set_property -dict { PACKAGE_PIN <PIN_IN26> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[26]}]
set_property -dict { PACKAGE_PIN <PIN_IN27> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[27]}]
set_property -dict { PACKAGE_PIN <PIN_IN28> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[28]}]
set_property -dict { PACKAGE_PIN <PIN_IN29> IOSTANDARD LVCMOS33 } [get_ports {spikes_in_bits[29]}]

########################
# OUTPUT BUS: spikes_out_bits[4:0]
########################
# Replace <PIN_OUT0>.. <PIN_OUT4>
set_property -dict { PACKAGE_PIN <PIN_OUT0> IOSTANDARD LVCMOS33 } [get_ports {spikes_out_bits[0]}]
set_property -dict { PACKAGE_PIN <PIN_OUT1> IOSTANDARD LVCMOS33 } [get_ports {spikes_out_bits[1]}]
set_property -dict { PACKAGE_PIN <PIN_OUT2> IOSTANDARD LVCMOS33 } [get_ports {spikes_out_bits[2]}]
set_property -dict { PACKAGE_PIN <PIN_OUT3> IOSTANDARD LVCMOS33 } [get_ports {spikes_out_bits[3]}]
set_property -dict { PACKAGE_PIN <PIN_OUT4> IOSTANDARD LVCMOS33 } [get_ports {spikes_out_bits[4]}]

########################
# (Optional) Drive strength / Slew (if needed)
########################
# set_property SLEW FAST [get_ports {spikes_out_bits[*] done}]
# set_property DRIVE 8 [get_ports {spikes_out_bits[*] done}]
