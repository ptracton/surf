-------------------------------------------------------------------------------
-- Title      : CoaXPress Protocol: http://jiia.org/wp-content/themes/jiia/pdf/standard_dl/coaxpress/CXP-001-2021.pdf
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: CoaXPress Core
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.CoaXPressPkg.all;

entity CoaXPressCore is
   generic (
      TPD_G              : time                   := 1 ns;
      NUM_LANES_G        : positive               := 1;
      STATUS_CNT_WIDTH_G : positive range 1 to 32 := 12;
      AXIS_CONFIG_G      : AxiStreamConfigType;
      AXIL_CLK_FREQ_G    : real                   := 156.25E+6);
   port (
      -- Data Interface (dataClk domain)
      dataClk         : in  sl;
      dataRst         : in  sl;
      dataMaster      : out AxiStreamMasterType;
      dataSlave       : in  AxiStreamSlaveType;
      -- Config Interface (cfgClk domain)
      cfgClk          : in  sl;
      cfgRst          : in  sl;
      cfgIbMaster     : in  AxiStreamMasterType;
      cfgIbSlave      : out AxiStreamSlaveType;
      cfgObMaster     : out AxiStreamMasterType;
      cfgObSlave      : in  AxiStreamSlaveType;
      -- Tx Interface (txClk domain)
      txClk           : in  slv(NUM_LANES_G-1 downto 0);
      txRst           : in  slv(NUM_LANES_G-1 downto 0);
      txData          : out slv32Array(NUM_LANES_G-1 downto 0);
      txTrig          : in  sl;
      txLinkUp        : in  sl;
      -- Rx Interface (rxClk domain)
      rxClk           : in  slv(NUM_LANES_G-1 downto 0);
      rxRst           : in  slv(NUM_LANES_G-1 downto 0);
      rxData          : in  slv32Array(NUM_LANES_G-1 downto 0);
      rxDataK         : in  Slv4Array(NUM_LANES_G-1 downto 0);
      rxDispErr       : in  slv(NUM_LANES_G-1 downto 0);
      rxDecErr        : in  slv(NUM_LANES_G-1 downto 0);
      rxLinkUp        : in  slv(NUM_LANES_G-1 downto 0);
      -- AXI-Lite Register Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end entity CoaXPressCore;

architecture mapping of CoaXPressCore is

   signal configTimerSize : slv(23 downto 0);
   signal configErrResp   : slv(1 downto 0);
   signal cfgTxMaster     : AxiStreamMasterType;
   signal cfgTxSlave      : AxiStreamSlaveType;
   signal cfgRxMaster     : AxiStreamMasterType;

   signal swTrig     : sl;
   signal txRate     : sl;
   signal txTrigDrop : sl;

   signal rxFifoRst      : sl;
   signal rxDataDrop     : sl;
   signal rxFifoOverflow : slv(NUM_LANES_G-1 downto 0);

begin

   U_Config : entity surf.CoaXPressConfig
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => AXIS_CONFIG_G)
      port map (
         -- Config Interface (cfgClk domain)
         cfgClk          => cfgClk,
         cfgRst          => cfgRst,
         configTimerSize => configTimerSize,
         configErrResp   => configErrResp,
         cfgIbMaster     => cfgIbMaster,
         cfgIbSlave      => cfgIbSlave,
         cfgObMaster     => cfgObMaster,
         cfgObSlave      => cfgObSlave,
         -- TX Interface (txClk domain)
         txClk           => txClk(0),
         txRst           => txRst(0),
         cfgTxMaster     => cfgTxMaster,
         cfgTxSlave      => cfgTxSlave,
         -- RX Interface (rxClk[0] domain)
         rxClk           => rxClk(0),
         rxRst           => rxRst(0),
         cfgRxMaster     => cfgRxMaster);

   U_Tx : entity surf.CoaXPressTx
      generic map (
         TPD_G         => TPD_G,
         NUM_LANES_G   => NUM_LANES_G,
         AXIS_CONFIG_G => AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         txClk       => txClk,
         txRst       => txRst,
         -- Config Interface
         cfgTxMaster => cfgTxMaster,
         cfgTxSlave  => cfgTxSlave,
         -- Tx Interface
         txData      => txData,
         swTrig      => swTrig,
         txRate      => txRate,
         txTrig      => txTrig,
         txTrigDrop  => txTrigDrop);

   U_Rx : entity surf.CoaXPressRx
      generic map (
         TPD_G         => TPD_G,
         NUM_LANES_G   => NUM_LANES_G,
         AXIS_CONFIG_G => AXIS_CONFIG_G)
      port map (
         -- Data Interface (dataClk domain)
         dataClk        => dataClk,
         dataRst        => dataRst,
         dataMaster     => dataMaster,
         dataSlave      => dataSlave,
         -- Config Interface (rxClk[0] domain)
         cfgRxMaster    => cfgRxMaster,
         -- Rx Interface (rxClk domain)
         rxClk          => rxClk,
         rxRst          => rxRst,
         rxFifoRst      => rxFifoRst,
         rxDataDrop     => rxDataDrop,
         rxFifoOverflow => rxFifoOverflow,
         rxData         => rxData,
         rxDataK        => rxDataK,
         rxLinkUp       => rxLinkUp);

   U_Axil : entity surf.CoaXPressAxiL
      generic map (
         TPD_G              => TPD_G,
         NUM_LANES_G        => NUM_LANES_G,
         STATUS_CNT_WIDTH_G => STATUS_CNT_WIDTH_G,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         -- Tx Interface (txClk domain)
         txClk           => txClk(0),
         txRst           => txRst(0),
         txTrig          => txTrig,
         swTrig          => swTrig,
         txRate          => txRate,
         txTrigDrop      => txTrigDrop,
         txLinkUp        => txLinkUp,
         -- Rx Interface (rxClk domain)
         rxClk           => rxClk,
         rxRst           => rxRst,
         rxDispErr       => rxDispErr,
         rxDecErr        => rxDecErr,
         rxFifoRst       => rxFifoRst,
         rxDataDrop      => rxDataDrop,
         rxFifoOverflow  => rxFifoOverflow,
         rxLinkUp        => rxLinkUp,
         -- Config Interface (cfgClk domain)
         cfgClk          => cfgClk,
         cfgRst          => cfgClk,
         configTimerSize => configTimerSize,
         configErrResp   => configErrResp,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end mapping;
