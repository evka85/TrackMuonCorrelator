#!/bin/sh

MODULE=$1
if [ -z "$MODULE" ]; then
    echo "Usage: this_script.sh <module_name>"
    echo "Available modules:"
    echo "TTC"    echo "MUONLINK"    exit
fi

if [ "$MODULE" = "TTC" ]; then
    printf 'GEM_AMC.TTC.CTRL.L1A_ENABLE                   = 0x%x\n' $(( (`mpeek 0x64c00010` & 0x00000001) >> 0 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_BC0                    = 0x%x\n' $(( (`mpeek 0x64c00014` & 0x000000ff) >> 0 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_EC0                    = 0x%x\n' $(( (`mpeek 0x64c00014` & 0x0000ff00) >> 8 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_RESYNC                 = 0x%x\n' $(( (`mpeek 0x64c00014` & 0x00ff0000) >> 16 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_OC0                    = 0x%x\n' $(( (`mpeek 0x64c00014` & 0xff000000) >> 24 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_HARD_RESET             = 0x%x\n' $(( (`mpeek 0x64c00018` & 0x000000ff) >> 0 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_CALPULSE               = 0x%x\n' $(( (`mpeek 0x64c00018` & 0x0000ff00) >> 8 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_START                  = 0x%x\n' $(( (`mpeek 0x64c00018` & 0x00ff0000) >> 16 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_STOP                   = 0x%x\n' $(( (`mpeek 0x64c00018` & 0xff000000) >> 24 ))
    printf 'GEM_AMC.TTC.CONFIG.CMD_TEST_SYNC              = 0x%x\n' $(( (`mpeek 0x64c0001c` & 0x000000ff) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.MMCM_LOCKED                = 0x%x\n' $(( (`mpeek 0x64c00020` & 0x00000001) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.MMCM_UNLOCK_CNT            = 0x%x\n' $(( (`mpeek 0x64c00020` & 0xffff0000) >> 16 ))
    printf 'GEM_AMC.TTC.STATUS.TTC_SINGLE_ERROR_CNT       = 0x%x\n' $(( (`mpeek 0x64c00024` & 0x0000ffff) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.TTC_DOUBLE_ERROR_CNT       = 0x%x\n' $(( (`mpeek 0x64c00024` & 0xffff0000) >> 16 ))
    printf 'GEM_AMC.TTC.STATUS.BC0.LOCKED                 = 0x%x\n' $(( (`mpeek 0x64c00028` & 0x00000001) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.BC0.UNLOCK_CNT             = 0x%x\n' $(( (`mpeek 0x64c0002c` & 0x0000ffff) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.BC0.OVERFLOW_CNT           = 0x%x\n' $(( (`mpeek 0x64c00030` & 0x0000ffff) >> 0 ))
    printf 'GEM_AMC.TTC.STATUS.BC0.UNDERFLOW_CNT          = 0x%x\n' $(( (`mpeek 0x64c00030` & 0xffff0000) >> 16 ))
    printf 'GEM_AMC.TTC.CMD_COUNTERS.L1A                  = 0x%x\n' `mpeek 0x64c00034` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.BC0                  = 0x%x\n' `mpeek 0x64c00038` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.EC0                  = 0x%x\n' `mpeek 0x64c0003c` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.RESYNC               = 0x%x\n' `mpeek 0x64c00040` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.OC0                  = 0x%x\n' `mpeek 0x64c00044` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.HARD_RESET           = 0x%x\n' `mpeek 0x64c00048` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.CALPULSE             = 0x%x\n' `mpeek 0x64c0004c` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.START                = 0x%x\n' `mpeek 0x64c00050` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.STOP                 = 0x%x\n' `mpeek 0x64c00054` 
    printf 'GEM_AMC.TTC.CMD_COUNTERS.TEST_SYNC            = 0x%x\n' `mpeek 0x64c00058` 
    printf 'GEM_AMC.TTC.L1A_ID                            = 0x%x\n' $(( (`mpeek 0x64c0005c` & 0x00ffffff) >> 0 ))
    printf 'GEM_AMC.TTC.L1A_RATE                          = 0x%x\n' `mpeek 0x64c00060` 
    printf 'GEM_AMC.TTC.TTC_SPY_BUFFER                    = 0x%x\n' `mpeek 0x64c00064` 
fi

if [ "$MODULE" = "MUONLINK" ]; then
    printf 'GEM_AMC.MUONLINK.STATUS.MUON_COUNTER          = 0x%x\n' `mpeek 0x65000000` 
    printf 'GEM_AMC.MUONLINK.STATUS.MUON_RATE_COUNTER     = 0x%x\n' `mpeek 0x65000004` 
    printf 'GEM_AMC.MUONLINK.STATUS.BX_SYNC_ERR_COUNTER   = 0x%x\n' `mpeek 0x65000008` 
    printf 'GEM_AMC.MUONLINK.STATUS.COUNT_SYNC_ERRS       = 0x%x\n' `mpeek 0x6500000c` 
fi

