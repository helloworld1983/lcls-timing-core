-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : TPGMiniStream.vhd
-- Author     : Matt Weaver  <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-11-09
-- Last update: 2017-02-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-- Since the event codes are not 'predicted' we pick them
-- off the event pipeline;
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
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;
use work.TPGPkg.all;
use work.StdRtlPkg.all;
use work.TimingPkg.all;

entity TPGMiniStream is
  generic (
    AC_PERIOD : integer := 119000000/360
    );
  port (
    config     : in  TPGConfigType;

    txClk      : in  sl;
    txRst      : in  sl;
    txRdy      : in  sl;
    txData     : out slv(15 downto 0);
    txDataK    : out slv(1 downto 0)
    );
end TPGMiniStream;


-- Define architecture for top level module
architecture TPGMiniStream of TPGMiniStream is

  constant FixedRateDiv : IntegerArray(0 to 6) := ( 3, 6, 12, 36, 72, 360, 720 );

  subtype FixedRateEvents is slv(FixedRateDiv'range);

  type FixedRateEventsArray is array (natural range 0 to 6) of FixedRateEvents;

  type RegType is record
    pulseId      : slv(31 downto 0);
    timeSlot     : slv(2 downto 0);
    timeSlotBit  : slv(5 downto 0);
    ratePipeline : FixedRateEventsArray;
  end record;
  constant REG_INIT_C : RegType := (
    pulseId      => (others=>'0'),
    timeSlot     => "001",
    timeSlotBit  => "000001",
    ratePipeline => (others => (others=>'0')));

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  constant SbaseDivisor : slv(18 downto 0) := toSlv(AC_PERIOD,19);
--  constant SbaseDivisor : slv(18 downto 0) := toSlv(119000000/360,19);
--  constant SbaseDivisor : slv(18 downto 0) := toSlv(1190000/360,19); -- for simulation

  signal fixedRates_i   : FixedRateEvents;

  signal baseEnable     : sl; -- 360Hz
  signal baseEnabled    : slv(3 downto 0);
  signal dataBuff       : TimingDataBuffType := TIMING_DATA_BUFF_INIT_C;
  signal eventCodes     : slv(255 downto 0)  := (others=>'0');
  signal epicsTime      : slv(63 downto 0);
  
begin

  dataBuff.epicsTime <= epicsTime(31 downto 17) & (r.pulseId(16 downto 0)+toSlv(2,17)) & epicsTime(63 downto 32);

  dataBuff.dtype                            <= X"0001";
  dataBuff.version                          <= X"0001";

  dataBuff.dmod(15)                         <= fixedRates_i(6); -- MODULO720_MASK
  dataBuff.dmod(37 downto 32)               <= r.timeSlotBit;
  dataBuff.dmod( 3*32+29+2 downto 3*32+29 ) <= r.timeSlot;
  dataBuff.dmod(                  5*32+ 0 ) <= '1'; -- fake MPS_VALID in MOD6
  
  BaseEnableDivider : entity work.Divider
    generic map (
      Width => SbaseDivisor'length)
    port map (
      sysClk   => txClk,
      sysReset => '0',
      enable   => '1',
      clear    => '0',
      divisor  => SbaseDivisor,
      trigO    => baseEnable);

  eventCodes(1) <= '1';
  eventCodes(9) <= '1';
  
  FixedDivider_loop : for i in 0 to FixedRateDiv'length-1 generate
    U_FixedDivider_1 : entity work.Divider
      generic map (
        Width => log2(FixedRateDiv(i)))
      port map (
        sysClk   => txClk,
        sysReset => txRst,
        enable   => baseEnable,
        clear    => '0',
        divisor  => toSlv(FixedRateDiv(i),log2(FixedRateDiv(i))),
        trigO    => fixedRates_i(i) );

      -- base rate events are generated by the dividers and
      -- emit event codes 10,11,12,13..16
      -- NOTE: we let the fixed rate dividers run 2 timeslots
      --       ahead (so that we can announce MOD720 in the pattern)
      -- Since the event codes are not 'predicted' we pick them
      -- off the event pipeline;
      FixedRates_loop: for j in 1 to 6 generate
      	eventCodes(j*10+i) <= r.ratePipeline(j)(i);
      end generate FixedRates_loop;
  end generate FixedDivider_loop;

  U_TSerializer : entity work.TimingStreamTx
    port map ( clk       => txClk,
               rst       => txRst,
               fiducial  => baseEnable,
               dataBuff  => dataBuff,
               pulseId   => r.pulseId,
               eventCodes=> eventCodes,
               data      => txData,
               dataK     => txDataK );

  comb: process (r,baseEnable,eventCodes,fixedRates_i) is
    variable v : RegType;
  begin
    v := r;

    if baseEnable='1' then
      if r.pulseId=x"0001FFDF" then
        v.pulseId := (others=>'0');
      else
        v.pulseId := r.pulseId+1;
      end if;
      -- timeSlot announced in the pattern is 2 timeslots ahead.
      -- Thus, if the current timeslot is 4 then the next timeslot
      -- would be 5 and we must announce 1. Same as when the count
      -- rools over.
      if eventCodes(41)='1' or r.timeSlot="110" then
        v.timeSlot    := "001";
        v.timeSlotBit := "000001";
      else
        v.timeSlot    := r.timeSlot + "001";
        v.timeSlotBit := r.timeSlotBit(4 downto 0) & '0';
      end if;

      -- pipeline of base-rate events; these produce these events
      -- on all other timeslots
      v.ratePipeline(0) := fixedRates_i;

      EventCodeTimeslot_loop : for i in 1 to 6 loop
        v.ratePipeline(i) := r.ratePipeline(i-1);
      end loop EventCodeTimeslot_loop;

    end if;

    rin <= v;
  end process;
         
  seq: process (txClk) is
  begin
    if rising_edge(txClk) then
      r <= rin;
    end if;
  end process;

  U_ClockTime : entity work.ClockTime
    port map (
      step      => toSlv(8,5),
      remainder => toSlv(2,5),
      divisor   => toSlv(5,5),
      rst    => txRst,
      clkA   => txClk,
      wrEnA  => config.timeStampWrEn,
      wrData => config.timeStamp,
      rdData => open,
      clkB   => txClk,
      wrEnB  => baseEnable,
      dataO  => epicsTime);

end TPGMiniStream;
