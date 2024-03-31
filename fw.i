                ifnd    _FW_I
_FW_I           set     1

; Vars

                rsreset
fw_Frame:       rs.w    1

fw_MemFast:     rs.l    1
fw_MemFastE:    rs.l    1
fw_MemChip:     rs.l    1
fw_MemChipE:    rs.l    1

fw_MusicBuffer: rs.l    1
fw_BankBuffer:  rs.l    1

fw_Directory:   rs.l    1
fw_LoadBuffer:  rs.l    1

fw_TrackBuffer: rs.l    1
fw_MFMcyl:      rs.w    1
fw_MFMhead:     rs.w    1
fw_MFMdrv:      rs.w    1
fw_MFMlastcyl:  rs.w    1
fw_MFMchk:      rs.l    1  
fw_TrackNo:     rs.w    1

fw_VarsSIZEOF   rs.b    0

; LVOs

fw_AllocChip:   rs.l    1
fw_AllocFast:   rs.l    1
fw_LoadFile:    rs.l    1
fw_LoadTrack:   rs.l    1
fw_WaitFrame:   rs.l    1
fw_ZX0Decompress rs.l   1
fw_GetPos       rs.l    1

fw_SIZEOF       rs.b    0

                endc


FW_ALLOC_CHIP   macro
                move.l  #\1,d0
                jsr     fw_AllocChip(a5)
                ifnc    "\2",""
                move.l  a0,\2
                endc
                endm

FW_ALLOC_FAST   macro
                move.l  #\1,d0
                jsr     fw_AllocFast(a5)
                ifnc    "\2",""
                move.l  a0,\2
                endc
                endm
