-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Pgp2bGtp7FixedLatWrapper.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-29
-- Last update: 2016-11-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: PGP Wrapper
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP2B Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP2B Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.Pgp2bPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Pgp2bGtp7FixedLatWrapper is
   generic (
      TPD_G                   : time                 := 1 ns;
      SIM_GTRESET_SPEEDUP_G   : string               := "FALSE";
      SIM_VERSION_G           : string               := "1.0";
      SIMULATION_G            : boolean              := false;
      -- PGP Settings
      VC_INTERLEAVE_G         : integer              := 0;         -- No interleave Frames
      PAYLOAD_CNT_TOP_G       : integer              := 7;         -- Top bit for payload counter
      NUM_VC_EN_G             : integer range 1 to 4 := 4;
      AXI_ERROR_RESP_G        : slv(1 downto 0)      := AXI_RESP_DECERR_C;
      TX_ENABLE_G             : boolean              := true;      -- Enable TX direction
      RX_ENABLE_G             : boolean              := true;      -- Enable RX direction
      -- CM Configurations
      TX_CM_EN_G              : boolean              := false;
      TX_CM_TYPE_G            : string               := "MMCM";
      TX_CM_CLKIN_PERIOD_G    : real                 := 8.000;
      TX_CM_DIVCLK_DIVIDE_G   : natural              := 8;
      TX_CM_CLKFBOUT_MULT_F_G : real                 := 8.000;
      TX_CM_CLKOUT_DIVIDE_F_G : real                 := 8.000;
      RX_CM_EN_G              : boolean              := false;
      RX_CM_TYPE_G            : string               := "MMCM";
      RX_CM_CLKIN_PERIOD_G    : real                 := 8.000;
      RX_CM_DIVCLK_DIVIDE_G   : natural              := 8;
      RX_CM_CLKFBOUT_MULT_F_G : real                 := 8.000;
      RX_CM_CLKOUT_DIVIDE_F_G : real                 := 8.000;
      -- MGT Configurations
      PMA_RSV_G               : bit_vector           := x"00018480";
      RX_OS_CFG_G             : bit_vector           := "0000010000000";        -- Set by wizard
      RXCDR_CFG_G             : bit_vector           := x"03000023ff40200020";  -- Set by wizard
      RXDFEXYDEN_G            : sl                   := '0';       -- Set by wizard
      -- PLL and clock configurations
      STABLE_CLK_SRC_G        : string               := "gtClk0";  -- or "gtClk0" or "gtClk1"
      TX_REFCLK_SRC_G         : string               := "gtClk0";
      RX_REFCLK_SRC_G         : string               := "gtClk1";
      PLL0_CFG_G              : Gtx7CPllCfgType      := getGtp7QPllCfg(250.0E6, 3.125E9);
      PLL1_CFG_G              : Gtx7QPllCfgType      := getGtp7QPllCfg(156.25e6, 3.125e9);
      TX_PLL_G                : string               := "PLL0";
      RX_PLL_G                : string               := "PLL1");
   port (
      -- Manual Reset
      stableClkIn      : in  sl                               := '0';
      extRst           : in  sl;
      -- Status and Clock Signals
      txPllLock        : out sl;
      rxPllLock        : out sl;
      -- Output internally configured clocks
      pgpTxClkOut      : out sl;
      pgpTxRstOut : out sl;
      pgpRxClkOut      : out sl;
      pgpRxRstOut      : out sl;
      stableClkOut     : out sl;
      -- Non VC Rx Signals
      pgpRxIn          : in  Pgp2bRxInType;
      pgpRxOut         : out Pgp2bRxOutType;
      -- Non VC Tx Signals
      pgpTxIn          : in  Pgp2bTxInType;
      pgpTxOut         : out Pgp2bTxOutType;
      -- Frame Transmit Interface - 1 Lane, Array of 4 VCs
      pgpTxMasters     : in  AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      pgpTxSlaves      : out AxiStreamSlaveArray(3 downto 0);
      -- Frame Receive Interface - 1 Lane, Array of 4 VCs
      pgpRxMasters     : out AxiStreamMasterArray(3 downto 0);
      pgpRxMasterMuxed : out AxiStreamMasterType;
      pgpRxCtrl        : in  AxiStreamCtrlArray(3 downto 0);
      -- GT Pins
      gtgClk           : in  sl                               := '0';
      gtClk0P          : in  sl                               := '0';
      gtClk0N          : in  sl                               := '0';
      gtClk1P          : in  sl                               := '0';
      gtClk1N          : in  sl                               := '0';
      gtTxP            : out sl;
      gtTxN            : out sl;
      gtRxP            : in  sl;
      gtRxN            : in  sl;
      -- Debug Interface 
      txPreCursor      : in  slv(4 downto 0)                  := (others => '0');
      txPostCursor     : in  slv(4 downto 0)                  := (others => '0');
      txDiffCtrl       : in  slv(3 downto 0)                  := "1000";
      -- AXI-Lite Interface 
      axilClk          : in  sl                               := '0';
      axilRst          : in  sl                               := '0';
      axilReadMaster   : in  AxiLiteReadMasterType            := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType           := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave   : out AxiLiteWriteSlaveType);
end Pgp2bGtp7FixedLatWrapper;

architecture rtl of Pgp2bGtp7FixedLatWrapper is

   constant TX_QPLL_CFG_C : Gtp7CfgType := ite(TX_PLL_G = "PLL0", PLL0_CFG_G, PLL1_CFG_G);
   constant RX_QPLL_CFG_C : Gtp7CfgType := ite(RX_PLL_G = "PLL0", PLL0_CFG_G, PLL1_CFG_G);   

   signal gtClk0 : sl := '0';
   signal gtClk1 : sl := '0';

   signal txRefClk : sl := '0';
   signal txOutClk : sl := '0';
   signal rxRefClk : sl := '0';

   signal stableClkRef  : sl := '0';
   signal stableClkRefG : sl := '0';
   signal stableClk     : sl := '0';
   signal stableRst     : sl := '0';

   signal pgpTxClkBase : sl;
   signal pgpTxClk     : sl;
   signal pgpTxReset   : sl;

   signal pgpRxRecClk     : sl;
   signal pgpRxRecClkRst  : sl;
   signal pgpRxClkLoc     : sl;
   signal pgpRxReset      : sl;
   signal pgpRxMmcmReset  : sl;
   signal pgpRxMmcmLocked : sl;

   signal qPllRefClk     : slv(1 downto 0) := "00";
   signal qPllOutClk     : slv(1 downto 0) := "00";
   signal qPllOutRefClk  : slv(1 downto 0) := "00";
   signal qPllLock       : slv(1 downto 0) := "00";
   signal pllLockDetClk  : slv(1 downto 0) := "00";
   signal qPllRefClkLost : slv(1 downto 0) := "00";
   signal qPllReset      : slv(1 downto 0) := "00";

begin



   -------------------------------------------------------------------------------------------------
   -- Bring in the refclocks through IBUFDS_GTE2 instances
   -------------------------------------------------------------------------------------------------
   BUFDS_GTE2_0_GEN : if (TX_REFCLK_SRC_G = "gtClk0" or RX_REFCLK_SRC_G = "gtClk0") generate
      IBUFDS_GTE2_0 : IBUFDS_GTE2
         port map (
            I     => gtClk0P,
            IB    => gtClk0N,
            CEB   => '0',
            ODIV2 => open,
            O     => gtClk0);
   end generate;

   IBUFDS_GTE2_1_GEN : if (TX_REFCLK_SRC_G = "gtClk1" or RX_REFCLK_SRC_G = "gtClk1") generate
      IBUFDS_GTE2_1 : IBUFDS_GTE2
         port map (
            I     => gtClk1P,
            IB    => gtClk1N,
            CEB   => '0',
            ODIV2 => open,
            O     => gtClk1);
   end generate;

   -------------------------------------------------------------------------------------------------
   -- Create the stable clock and reset
   -------------------------------------------------------------------------------------------------
   stableClkRef <= gtClk0 when STABLE_CLK_SRC_G = "gtClk0" else
                   gtClk1 when STABLE_CLK_SRC_G = "gtClk1" else
                   '0';


   BUFG_stableClkRef : BUFG
      port map (
         I => stableClkRef,
         O => stableClkRefG);

   stableClk <= stableClkIn when STABLE_CLK_SRC_G = "stableClkIn" else
                stableClkRefG;


   -- Power Up Reset      
   PwrUpRst_Inst : entity work.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         arst   => extRst,
         clk    => stableClk,
         rstOut => stableRst);

   -------------------------------------------------------------------------------------------------
   -- Select the rxRefClk
   -------------------------------------------------------------------------------------------------
   rxRefClk <= gtClk0 when RX_REFCLK_SRC_G = "gtClk0" else
               gtClk1 when RX_REFCLK_SRC_G = "gtClk1" else
               gtgClk when TX_REFCLK_SRC_G = "gtgClk" else
               '0';

   -------------------------------------------------------------------------------------------------
   -- Select the txRefClk
   -- Generate TX user (PGP) clock
   -- Might want option to bypass MMCM
   -------------------------------------------------------------------------------------------------
   txRefClk <= gtClk0 when TX_REFCLK_SRC_G = "gtClk0" else
               gtClk1 when TX_REFCLK_SRC_G = "gtClk1" else
               gtgClk when TX_REFCLK_SRC_G = "gtgClk" else
               '0';


   -- pgpTxClk and stable clock might be the same
   pgpTxClkBase <= stableClk when STABLE_CLK_SRC_G = TX_REFCLK_SRC_G else
                   txRefClk;

   TX_CM_GEN : if (TX_CM_EN_G) generate
      ClockManager7_TX : entity work.ClockManager7
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => TX_CM_TYPE_G,
            INPUT_BUFG_G       => (TX_REFCLK_SRC_G /= STABLE_CLK_SRC_G),
            FB_BUFG_G          => true,
            RST_IN_POLARITY_G  => '1',
            NUM_CLOCKS_G       => 1,
            -- MMCM attributes
            BANDWIDTH_G        => "OPTIMIZED",
            CLKIN_PERIOD_G     => TX_CM_CLKIN_PERIOD_G,
            DIVCLK_DIVIDE_G    => TX_CM_DIVCLK_DIVIDE_G,
            CLKFBOUT_MULT_F_G  => TX_CM_CLKFBOUT_MULT_F_G,
            CLKOUT0_DIVIDE_F_G => TX_CM_CLKOUT_DIVIDE_F_G,
            CLKOUT0_RST_HOLD_G => 16)
         port map(
            clkIn     => pgpTxClkBase,
            rstIn     => stableRst,
            clkOut(0) => pgpTxClk,
            rstOut(0) => pgpTxReset);
   end generate TX_CM_GEN;

   NO_TX_CM_GEN : if (not TX_CM_EN_G) generate
      PGP_TX_CLK_BUFG : if (TX_REFCLK_SRC_G /= STABLE_CLK_SRC_G) generate
         BUFG_pgpTxClk : BUFG
            port map (
               i => pgpTxClkBase,
               o => pgpTxClk);

         RstSync_pgpTxRst : entity work.RstSync
            generic map (
               TPD_G           => TPD_G,
               RELEASE_DELAY_G => 16,
               OUT_REG_RST_G   => true)
            port map (
               clk      => pgpTxClk,     -- [in]
               asyncRst => extRst,       -- [in]
               syncRst  => pgpTxReset);  -- [out]
      end generate PGP_TX_CLK_BUFG;
      NO_PGP_TX_CLK_BUFG : if (TX_REFCLK_SRC_G = STABLE_CLK_SRC_G) generate
         pgpTxClk   <= pgpTxClkBase;
         pgpTxReset <= stableRst;
      end generate;
   end generate NO_TX_CM_GEN;

   pgpTxRstOut <= pgpTxReset;      

   -- PGP RX Reset
   PGP_RX_RST : if (RX_REFCLK_SRC_G /= STABLE_CLK_SRC_G) generate
      RstSync_pgpTxRst : entity work.RstSync
         generic map (
            TPD_G           => TPD_G,
            RELEASE_DELAY_G => 16,
            OUT_REG_RST_G   => true)
         port map (
            clk      => pgpRxClkLoc,    -- [in]
            asyncRst => extRst,         -- [in]
            syncRst  => pgpRxReset);    -- [out]
   end generate;

   PGP_RX_RST_STABLE_RST : if (RX_REFCLK_SRC_G = STABLE_CLK_SRC_G) generate
      pgpRxReset <= stableRst;
   end generate;



   -------------------------------------------------------------------------------------------------
   -- Determine PLL clocks
   -------------------------------------------------------------------------------------------------
   qPllRefClk(0) <= txRefClk when (TX_PLL_G = "PLL0") else
                    rxRefClk when (RX_PLL_G = "PLL0") else
                    '0';

   qPllRefClk(1) <= txRefClk when (TX_PLL_G = "PLL1") else
                    rxRefClk when (RX_PLL_G = "PLL1") else
                    '0';

   -- Double check this. I think the pllLockDetClk must be different from the pll refclk
   pllLockDetClk <= stableClk;

   -- Set the status outputs
   txPllLock <= ite((TX_PLL_G = "PLL0"), qPllLock(0), qPllLock(1));
   rxPllLock <= ite((RX_PLL_G = "PLL0"), qPllLock(0), qPllLock(1));


      QPllCore_0 : entity work.Gtx7QuadPll
         generic map (
            QPLL_REFCLK_SEL_G  => "001",
            QPLL_FBDIV_G       => PLL0_CFG_G.QPLL_FBDIV_G,
            QPLL_FBDIV_RATIO_G => PLL0_CFG_G.QPLL_FBDIV_RATIO_G,
            QPLL_REFCLK_DIV_G  => PLL0_CFG_G.QPLL_REFCLK_DIV_G)
         port map (
            qPllRefClk     => qPllRefClk(0),
            qPllOutClk     => qPllOutClk(0),
            qPllOutRefClk  => qPllOutRefClk(0),
            qPllLock       => qPllLock(0),
            qPllLockDetClk => pllLockDetClk(0),
            qPllRefClkLost => qPllRefClkLost(0),
            qPllReset      => qPllReset(0));

   PLL1_GEN: if (TX_PLL_G /= RX_PLL_G) generate
      QPllCore_1 : entity work.Gtx7QuadPll
         generic map (
            QPLL_REFCLK_SEL_G  => "001",
            QPLL_FBDIV_G       => PLL1_CFG_G.QPLL_FBDIV_G,
            QPLL_FBDIV_RATIO_G => PLL1_CFG_G.QPLL_FBDIV_RATIO_G,
            QPLL_REFCLK_DIV_G  => PLL1_CFG_G.QPLL_REFCLK_DIV_G)
         port map (
            qPllRefClk     => qPllRefClk(1),
            qPllOutClk     => qPllOutClk(1),
            qPllOutRefClk  => qPllOutRefClk(1),
            qPllLock       => qPllLock(1),
            qPllLockDetClk => pllLockDetClk(1),
            qPllRefClkLost => qPllRefClkLost(1),
            qPllReset      => qPllReset(1));
   end generate PLL1_GEN;


   Pgp2bGtp7Fixedlat_Inst : entity work.Pgp2bGtp7FixedLat
      generic map (
         TPD_G                 => TPD_G,
         SIM_GTRESET_SPEEDUP_G => SIM_GTRESET_SPEEDUP_G,
         SIM_VERSION_G         => SIM_VERSION_G,
         SIMULATION_G          => SIMULATION_G,
         STABLE_CLOCK_PERIOD_G => 4.0E-9,  --set for longest timeout
         RXOUT_DIV_G           => RX_PLL_CFG_C.RXOUT_DIV_G,
         TXOUT_DIV_G           => TX_PLL_CFG_C.TXOUT_DIV_G,
         RX_CLK25_DIV_G        => RX_PLL_CFG_C.RX_CLK25_DIV_G,
         TX_CLK25_DIV_G        => TX_PLL_CFG_C.TX_CLK25_DIV_G,
         PMA_RSV_G             => PMA_RSV_G,
         RX_OS_CFG_G           => RX_OS_CFG_G,
         RXCDR_CFG_G           => RXCDR_CFG_G,
         RXDFEXYDEN_G          => RXDFEXYDEN_G,
         TX_BUF_EN_G           => false,
         TX_OUTCLK_SRC_G       => "PLLREFCLK",
         TX_PHASE_ALIGN_G      => "MANUAL",
         TX_PLL_G              => TX_PLL_G,
         RX_PLL_G              => RX_PLL_G,
         VC_INTERLEAVE_G       => VC_INTERLEAVE_G,
         PAYLOAD_CNT_TOP_G     => PAYLOAD_CNT_TOP_G,
         NUM_VC_EN_G           => NUM_VC_EN_G,
         AXI_ERROR_RESP_G      => AXI_ERROR_RESP_G,
         TX_ENABLE_G           => TX_ENABLE_G,
         RX_ENABLE_G           => RX_ENABLE_G)
      port map (
         -- GT Clocking
         stableClk        => stableClk,
         gtQPllOutRefClk  => qPllOutRefClk,
         gtQPllOutClk     => qPllOutClk,
         gtQPllLock       => qPllLock,
         gtQPllRefClkLost => qPllRefClkLost,
         gtQPllReset      => qPllReset,
         gtRxRefClkBufg   => '0',          -- Probably can remove this
         gtTxOutClk       => txOutClk,
         -- Gt Serial IO
         gtTxP            => gtTxP,
         gtTxN            => gtTxN,
         gtRxP            => gtRxP,
         gtRxN            => gtRxN,
         -- Tx Clocking
         pgpTxReset       => pgpTxReset,
         pgpTxClk         => pgpTxClk,
         -- Rx clocking
         pgpRxReset       => pgpRxReset,   --extRst,    
         pgpRxRecClk      => pgpRxRecClk,
         pgpRxRecClkRst   => pgpRxRecClkRst,
         pgpRxClk         => pgpRxClkLoc,  -- RecClk fed back, optionally though MMCM
         pgpRxMmcmReset   => pgpRxMmcmReset,
         pgpRxMmcmLocked  => pgpRxMmcmLocked,
         -- Non VC Rx Signals
         pgpRxIn          => pgpRxIn,
         pgpRxOut         => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn          => pgpTxIn,
         pgpTxOut         => pgpTxOut,
         -- Frame Transmit Interface - 1 Lane, Array of 4 VCs
         pgpTxMasters     => pgpTxMasters,
         pgpTxSlaves      => pgpTxSlaves,
         -- Frame Receive Interface - 1 Lane, Array of 4 VCs
         pgpRxMasters     => pgpRxMasters,
         pgpRxMasterMuxed => pgpRxMasterMuxed,
         pgpRxCtrl        => pgpRxCtrl,
         -- Debug Interface 
         txPreCursor      => txPreCursor,
         txPostCursor     => txPostCursor,
         txDiffCtrl       => txDiffCtrl,
         -- AXI-Lite Interface 
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMaster,
         axilReadSlave    => axilReadSlave,
         axilWriteMaster  => axilWriteMaster,
         axilWriteSlave   => axilWriteSlave);

   -------------------------------------------------------------------------------------------------
   -- Clock manager to clean up recovered clock
   -------------------------------------------------------------------------------------------------
   RxClkMmcmGen : if (RX_CM_EN_G) generate
      ClockManager7_1 : entity work.ClockManager7
         generic map (
            TPD_G              => TPD_G,
            TYPE_G             => RX_CM_TYPE_G,
            INPUT_BUFG_G       => false,
            FB_BUFG_G          => true,
            NUM_CLOCKS_G       => 1,
            BANDWIDTH_G        => "OPTIMIZED",
            CLKIN_PERIOD_G     => RX_CM_CLKIN_PERIOD_G,
            DIVCLK_DIVIDE_G    => RX_CM_DIVCLK_DIVIDE_G,
            CLKFBOUT_MULT_F_G  => RX_CM_CLKFBOUT_MULT_F_G,
            CLKOUT0_DIVIDE_F_G => RX_CM_CLKOUT_DIVIDE_F_G,
            CLKOUT0_RST_HOLD_G => 16)
         port map (
            clkIn     => pgpRxRecClk,
            rstIn     => pgpRxMmcmReset,
            clkOut(0) => pgpRxClkLoc,
            locked    => pgpRxMmcmLocked);

      -- I think this is right, sync reset to mmcm clk
      RstSync_1 : entity work.RstSync
         generic map (
            TPD_G => TPD_G)
         port map (
            clk      => pgpRxClkLoc,
            asyncRst => pgpRxRecClkRst,
            syncRst  => pgpRxRstOut);
   end generate RxClkMmcmGen;

   RxClkNoMmcmGen : if (not RX_CM_EN_G) generate
      pgpRxClkLoc     <= pgpRxRecClk;
      pgpRxRstOut     <= pgpRxRecClkRst;
      pgpRxMmcmLocked <= '1';
   end generate RxClkNoMmcmGen;

   pgpRxClkOut <= pgpRxClkLoc;

   stableClkOut <= stableClk;

end rtl;
