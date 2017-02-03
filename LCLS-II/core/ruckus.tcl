# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -path "$::DIR_PATH/rtl/TimingPkg.vhd"
loadSource -path "$::DIR_PATH/rtl/TPGPkg.vhd"
loadSource -path "$::DIR_PATH/rtl/TPGMiniReg.vhd"
loadSource -path "$::DIR_PATH/rtl/Divider.vhd"
loadSource -path "$::DIR_PATH/rtl/BsaControlv2.vhd"
loadSource -path "$::DIR_PATH/rtl/CtrControl.vhd"
loadSource -path "$::DIR_PATH/rtl/ClockTime.vhd"
loadSource -path "$::DIR_PATH/rtl/EventSelect.vhd"
loadSource -path "$::DIR_PATH/rtl/TPSerializer.vhd"
loadSource -path "$::DIR_PATH/rtl/TPGMini.vhd"
loadSource -path "$::DIR_PATH/rtl/TPGMiniCore.vhd"
loadSource -path "$::DIR_PATH/rtl/TPGMiniStream.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingSerializer.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingDeserializer.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingSerialDelay.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingRx.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingFrameRx.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingStreamRx.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingStreamTx.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingGthCoreWrapper.vhd"
loadSource -path "$::DIR_PATH/rtl/GthRxAlignCheck.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingMsgAxiRingBuffer.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingMsgDelay.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingMsgToAxiStream.vhd"
loadSource -path "$::DIR_PATH/rtl/TimingCore.vhd"
