-------------------------------------------------------------------------------
-- Title      : CoaXPress Protocol: http://jiia.org/wp-content/themes/jiia/pdf/standard_dl/coaxpress/CXP-001-2021.pdf
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: CoaXPress Transmit
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.CoaXPressPkg.all;

entity CoaXPressTx is
   generic (
      TPD_G         : time := 1 ns;
      NUM_LANES_G   : positive := 1;
      AXIS_CONFIG_G : AxiStreamConfigType);
   port (
      -- Clock and Reset
      txClk       : in  slv(NUM_LANES_G-1 downto 0);
      txRst       : in  slv(NUM_LANES_G-1 downto 0);
      -- Config Interface
      cfgTxMaster : in  AxiStreamMasterType;
      cfgTxSlave  : out AxiStreamSlaveType;
      -- Tx Interface
      txData      : out slv32Array(NUM_LANES_G-1 downto 0);
      swTrig      : in  sl;
      txRate      : in  sl;
      txTrig      : in  sl;
      txTrigDrop  : out sl);
end entity CoaXPressTx;

architecture mapping of CoaXPressTx is

   signal txStrobe      : sl;
   signal txDecodeData  : slv(7 downto 0);
   signal txDecodeDataK : sl;

   signal txEncodeValid : sl;
   signal txEncodeData  : slv(9 downto 0);
   signal txbit         : slv(NUM_LANES_G-1 downto 0);

   signal gearboxReady : sl;
   signal gearboxbit   : sl;

   signal trigger : sl;

begin

   -------------
   -- FSM Module
   -------------
   U_Fsm : entity surf.CoaXPressTxFsm
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         txClk        => txClk(0),
         txRst        => txRst(0),
         -- Config Interface
         cfgMaster    => cfgTxMaster,
         cfgSlave     => cfgTxSlave,
         -- Trigger Interface
         txTrig       => trigger,
         txTrigDrop   => txTrigDrop,
         -- TX PHY Interface
         txRate       => txRate,
         gearboxReady => gearboxReady,
         txStrobe     => txStrobe,
         txData       => txDecodeData,
         txDataK      => txDecodeDataK);

   trigger <= txTrig or swTrig;

   ----------------
   -- 8B10B Encoder
   ----------------
   U_Encode : entity surf.Encoder8b10b
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',         -- active HIGH reset
         FLOW_CTRL_EN_G => true,
         RST_ASYNC_G    => false,
         NUM_BYTES_G    => 1)
      port map (
         -- Clock and Reset
         clk        => txClk(0),
         rst        => txRst(0),
         -- Decoded Interface
         validIn    => txStrobe,
         dataIn     => txDecodeData,
         dataKIn(0) => txDecodeDataK,
         -- Encoded Interface
         validOut   => txEncodeValid,
         dataOut    => txEncodeData);

   ---------------
   -- 10:1 Gearbox
   ---------------
   U_Serializer : entity surf.Gearbox
      generic map (
         TPD_G               => TPD_G,
         SLAVE_WIDTH_G       => 10,
         SLAVE_BIT_REVERSE_G => false,
         MASTER_WIDTH_G      => 1)
      port map (
         -- Clock and Reset
         clk           => txClk(0),
         rst           => txRst(0),
         -- Slave Interface
         slaveValid    => txEncodeValid,
         slaveData     => txEncodeData,
         -- Master Interface
         masterData(0) => gearboxbit,
         masterReady   => gearboxReady);

   GEN_LANE : for i in NUM_LANES_G-1 downto 0 generate

      U_SyncFifo : entity surf.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            COMMON_CLK_G => ite(i = 0, true, false),
            DATA_WIDTH_G => 1)
         port map (
            -- Asynchronous Reset
            rst     => txRst(i),
            -- Write Ports (wr_clk domain)
            wr_clk  => txClk(0),
            din(0)  => gearboxbit,
            -- Read Ports (rd_clk domain)
            rd_clk  => txClk(i),
            dout(0) => txbit(i));

      -- Serial rate = TX clock frequency
      txData(i) <= (others => txbit(i));

   end generate GEN_LANE;

end mapping;
