-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : EthMacPkg.vhd
-- Author     : Ryan Herbst  <rherbst@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2015-09-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;

package EthMacPkg is

   -- EOF Bit
   constant EMAC_EOFE_BIT_C : integer := 0;

   -- Ethernet AXI Stream Configuration
   constant EMAC_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 8,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NORMAL_C,
      TUSER_BITS_C  => 4,
      TUSER_MODE_C  => TUSER_NORMAL_C);

   -- Generic XMAC Configuration
   type EthMacConfigType is record
      macAddress    : slv(47 downto 0);
      filtEnable    : sl;
      pauseEnable   : sl;
      pauseTime     : slv(15 downto 0);
      interFrameGap : slv(3  downto 0);
   end record EthMacConfigType;

   constant ETH_MAC_CONFIG_INIT_C : EthMacConfigType := (
      macAddress    => (others=>'0'),
      filtEnable    => '0',
      pauseEnable   => '0',
      pauseTime     => (others=>'0'),
      interFrameGap => (others=>'0')
   );

   type EthMacConfigArray is array (natural range<>) of EthMacConfigType;


   -- Generic XMAC Status
   type EthMacStatusType is record
      rxPauseCnt    : sl;
      txPauseCnt    : sl;
      rxCountEn     : sl;
      rxCrcErrorCnt : sl;
      txCountEn     : sl;
      txUnderRunCnt : sl;
      txNotReadyCnt : sl;
   end record EthMacStatusType;

   constant ETH_MAC_STATUS_INIT_C : EthMacStatusType := (
      rxPauseCnt    => '0',
      txPauseCnt    => '0',
      rxCountEn     => '0',
      rxCrcErrorCnt => '0',
      txCountEn     => '0',
      txUnderRunCnt => '0',
      txNotReadyCnt => '0'
   );

   type EthMacStatusArray is array (natural range<>) of EthMacStatusType;

end package EthMacPkg;
