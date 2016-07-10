-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : TimingFrameRx.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-01
-- Last update: 2016-07-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
--   Need to fix:  some eventcodes start before x70,x71,x7d sequence
--                 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;


entity TimingStreamRx is

   generic (
      TPD_G             : time            := 1 ns;
      AXIL_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_OK_C);

   port (
      rxClk               : in  sl;
      rxRst               : in  sl;
      rxData              : in  TimingRxType;
      
      timingMessage       : out TimingStreamType;
      timingMessageStrobe : out sl;
      timingMessageValid  : out sl;

      staData             : out slv(3 downto 0)
      );

end entity TimingStreamRx;

architecture rtl of TimingStreamRx is

   -------------------------------------------------------------------------------------------------
   -- rxClk Domain
   -------------------------------------------------------------------------------------------------
   type StateType is (IDLE_S, FRAME_S);

   type RegType is record
      dstate              : StateType;
      estate              : StateType;
      sofStrobe           : sl;
      eofStrobe           : sl;
      ecount              : slv(19 downto 0);
      dataBuffEn          : sl;
      dataBuffShift       : slv(TIMING_DATABUFF_BITS_C-1 downto 0);
      pulseIdShift        : slv(31 downto 0);
      eventCodes          : slv(255 downto 0);
      timingStream        : TimingStreamType;
      dataBuffCache       : TimingDataBuffArray(2 downto 0);
      timingMessageStrobe : sl;
   end record;

   constant REG_INIT_C : RegType := (
      dstate              => IDLE_S,
      estate              => IDLE_S,
      sofStrobe           => '0',
      eofStrobe           => '0',
      ecount              => (others => '0'),
      dataBuffEn          => '0',
      dataBuffShift       => (others => '0'),
      pulseIdShift        => (others => '0'),
      eventCodes          => (others => '0'),
      timingStream        => TIMING_STREAM_INIT_C,
      dataBuffCache       => (others=>TIMING_DATA_BUFF_INIT_C),
      timingMessageStrobe => '0');

   constant FRAME_LEN : slv(19 downto 0) := x"036b0";  -- end of EVG stream
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rxDbuf             : slv(7 downto 0);
   signal rxEcod             : slv(7 downto 0);
   signal timingStreamOut    : TimingStreamType;

begin

  rxDbuf <= rxData.data(15 downto 8);
  rxEcod <= rxData.data( 7 downto 0);

  comb : process (r, rxRst, rxDbuf, rxEcod, rxData) is
    variable v : RegType;
  begin
    v := r;

    -- Strobed registers
    v.sofStrobe           := '0';
    v.eofStrobe           := '0';
    v.timingMessageStrobe := '0';

    case (r.dstate) is
      when IDLE_S =>
        if (rxData.dataK(1)='1' and rxDbuf=K_280_C) then
          v.dstate     := FRAME_S;
          v.dataBuffEn := '0';
          v.sofStrobe  := '1';
        end if;
      when FRAME_S =>
        if (rxData.dataK(1)='1' and (rxDbuf=K_COM_C or rxDbuf=K_281_C)) then
          v.dstate        := IDLE_S;
          v.eofStrobe     := '1';
          -- shift data buffer into storage
          v.dataBuffCache := r.dataBuffCache(1 downto 0) & toTimingDataBuffType(r.dataBuffShift);
        elsif (rxData.dataK(1)='0' and r.dataBuffEn='1') then
          v.dataBuffShift := rxDbuf & r.dataBuffShift(r.dataBuffShift'left downto 8);
        end if;
        v.dataBuffEn    := not r.dataBuffEn;
      when others => null;
    end case;

    case (r.estate) is
      when IDLE_S =>
        if (rxData.dataK(0)='0') then
          if (rxEcod=x"7D") then
            v.ecount := (others=>'0');
            v.estate := FRAME_S;
          elsif rxEcod=x"70" then
            v.pulseIdShift := r.pulseIdShift(30 downto 0) & '0';
          elsif rxEcod=x"71" then
            v.pulseIdShift := r.pulseIdShift(30 downto 0) & '1';
          else
            v.eventCodes(conv_integer(rxEcod)) := '1';
          end if;
        end if;
      when FRAME_S =>
        if r.ecount = FRAME_LEN then
          v.estate := IDLE_S;
          v.eventCodes := (others=>'0');
          v.timingStream.pulseId := r.pulseIdShift;
          v.timingStream.eventCodes  := r.eventCodes;
          v.timingStream.dbuff   := r.dataBuffCache(2);
          v.timingMessageStrobe  := '1';
        else
          v.ecount := r.ecount+1;
          if rxData.dataK(0)='0' then
            v.eventCodes(conv_integer(rxEcod)) := '1';
          end if;
        end if;
      when others =>  null;
    end case;

    
    if (rxData.decErr /= "00" or rxData.dspErr /= X"00") then
      v.dstate := IDLE_S;
    end if;

    if (rxRst='1') then
      v := REG_INIT_C;
    end if;

    rin              <= v;
  end process comb;
  
  timingMessage       <= r.timingStream;
  timingMessageStrobe <= r.timingMessageStrobe;
  staData             <= '0' & r.timingMessageStrobe & r.eofStrobe & r.sofStrobe;

   seq : process (rxClk) is
   begin
      if (rising_edge(rxClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

