#-----------------------------------------------------------------------------
# Title      : PyRogue Timing pattern generator status
#-----------------------------------------------------------------------------
# Description:
# PyRogue Timing pattern generator status
#-----------------------------------------------------------------------------
# This file is part of the 'LCLS Timing Core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'LCLS Timing Core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class TPGStatus(pr.Device):
    def __init__(   self,
            name        = "TPGStatus",
            description = "Timing pattern generator status",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.addRemoteVariables(
            name         = "BsaStat",
            description  = "BSA status num averaged/written",
            offset       =  0x00,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            number       =  64,
            stride       =  4,
            pollInterval = 1,
        )

        self.add(pr.RemoteVariable(
            name         = "CountPLL",
            description  = "PLL Status changes",
            offset       =  0x100,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "Count186M",
            description  = "186MHz clock counts / 16",
            offset       =  0x104,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "CountSyncE",
            description  = "Sync error counts",
            offset       =  0x108,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "CountIntv",
            description  = "Interval timer",
            offset       =  0x10C,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "CountBRT",
            description  = "Base rate trigger count in interval",
            offset       =  0x110,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.addRemoteVariables(
            name         = "CountTrig",
            description  = "External trigger count in interval",
            offset       =  0x114,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            number       =  12,
            stride       =  4,
            pollInterval = 1,
        )

        self.addRemoteVariables(
            name         = "CountSeq",
            description  = "Sequence requests in interval",
            offset       =  0x144,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RO",
            number       =  64,
            stride       =  2,
            pollInterval = 1,
        )

        self.add(pr.RemoteVariable(
            name         = "CountRxClks",
            description  = "Recovered clock count / 16",
            offset       =  0x248,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "CountRxDV",
            description  = "Received data valid count",
            offset       =  0x24C,
            bitSize      =  32,
            bitOffset    =  0x00,
            mode         = "RW",
        ))
