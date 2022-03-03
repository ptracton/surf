# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado/proc.tcl

# Load Source Code
if { $::env(VIVADO_VERSION) >= 2018.3 } {
   loadSource -lib surf -dir  "$::DIR_PATH/rtl"

   # loadIpCore -path "$::DIR_PATH/ip/TenGigEthGtyUltraScale156p25MHzCore.xci"
   loadSource -lib surf -path "$::DIR_PATH/ip/TenGigEthGtyUltraScale156p25MHzCore.dcp"
} else {
   puts "\n\nWARNING: $::DIR_PATH requires Vivado 2018.3 (or later)\n\n"
}