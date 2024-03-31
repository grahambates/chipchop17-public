                incdir  "includes"
                include "macros.i"
                include fw.i

ERROR_OOM_CHIP = $ff0                   ; one of the memory stacks ran out of memory
ERROR_OOM_FAST = $0ff                   ; one of the memory stacks ran out of memory

UI_CODE_SIZE = 1024*144
LOAD_BUFFER_SIZE = 1024*48              ; largest compressed mod
BANK_BUFFER_SIZE = 1024*112             ; largest unpacked mod

; Index of first music file in directory table
MUSIC_FILES_OFFSET = 2

********************************************************************************
Init:
                lea     FW(pc),a5
                lea     custom,a6
                move.w  #$7fff,intena(a6) ; interrupts off

                ; Store memory pointers
                move.l  (a0)+,a1        ; pointer to chipmem structure
                move.l  4(a1),a2
                move.l  a2,fw_MemChip(a5)
                add.l   (a1),a2
                move.l  a2,fw_MemChipE(a5)
                move.l  (a0)+,a1        ; pointer to fastmem structure
                move.l  4(a1),a2
                move.l  a2,fw_MemFast(a5)
                add.l   (a1),a2
                move.l  a2,fw_MemFastE(a5)

                ; Initialize disk loader
                move.w  #255,d0         ; Retries, 0-255
                bsr     LoaderInit

; Overlap load buffer and unpacked data:
; Trail and error for what works with largest tracks
; Last minute fix to avoid OOM with boot screen!
OVERLAP_SPACE = 32*1024
                FW_ALLOC_CHIP BANK_BUFFER_SIZE+OVERLAP_SPACE,fw_BankBuffer(a5)
                ; FW_ALLOC_CHIP LOAD_BUFFER_SIZE,fw_LoadBuffer(a5)
                add.l   #BANK_BUFFER_SIZE-LOAD_BUFFER_SIZE+OVERLAP_SPACE,a0
                move.l  a0,fw_LoadBuffer(a5)

                FW_ALLOC_CHIP MFMBUFSIZE,fw_TrackBuffer(a5)
                FW_ALLOC_FAST 1024,fw_Directory(a5)

                ; Load directory table
                moveq   #2,d0
                moveq   #2,d1
                bsr     LoaderLoad

                ; Init music player
                suba.l  a0,a0
                moveq   #1,d0           ; 1=PAL
                jsr     _mt_install_cia

                ; Start first track
                clr.w   d0
                bsr     LoadTrack

                ; Enable interrupt
                lea     Interrupt(pc),a0
                move.l  a0,$6c
                move.w  #INTF_SETCLR!INTF_INTEN!INTF_VERTB,intena(a6)

                bra     Front


********************************************************************************
Interrupt:
                movem.l d0-a6,-(sp)
                btst    #5,intreqr+1(a6)
                beq.s   .notvb

                lea     FW(pc),a5
                addq.w  #1,fw_Frame(a5)

                moveq   #INTF_VERTB,d0
                move.w  d0,intreq+custom
                move.w  d0,intreq+custom
.notvb:         movem.l (sp)+,d0-a6
                rte


********************************************************************************
WaitFrame:
                WAIT_BLIT_NASTY
                move.w  fw_Frame(a5),d0
.l:             cmp.w   fw_Frame(a5),d0
                beq     .l
                rts


********************************************************************************
; d0.w - track index
;-------------------------------------------------------------------------------
LoadTrack:
                move.w  d0,d1
                jsr     _mt_end
                bsr     MotorOn

                ; Load and decrunch sample bank
                move.w  d1,d0
                addq    #MUSIC_FILES_OFFSET,d0 ; initial offset
                move.l  fw_LoadBuffer(a5),a0
                bsr     LoadFile
                move.l  fw_BankBuffer(a5),a1
                bsr     zx0_decompress


                ; Start playing
                moveq   #0,d0           ;Pattern 0 start
                move.l  fw_BankBuffer(a5),a0
                sub.l   a1,a1
                jsr     _mt_init

                lea     _mt_music(pc),a0
                move.b  #1,_mt_Enable-_mt_music(a0)

                lea     FW(pc),a5
                bsr     MotorOff
                rts


********************************************************************************
; d0.w - file index
; returns:
; a1
;-------------------------------------------------------------------------------
LoadFile:
                move.l  fw_Directory(a5),a1
                lsl.w   #3,d0
                lea     (a1,d0.w),a1
                move.l  (a1)+,d0        ; start offset
                move.w  d0,d2
                and.w   #$1fc,d2        ; offset into first loaded sector for later correction of pointer
                lea     (a0,d2.w),a2
                move.l  a2,-(sp)        ; Stash start pointer
                lsr.l   #8,d0           ; / 512
                lsr.l   #1,d0           ; = start sector
                move.l  (a1)+,d1        ; num sectors
                bsr     LoaderLoad
                move.l  (sp)+,a0        ; Return start pointer
                rts


********************************************************************************
; Endlessly loops and sets the background color
; d0.w - errorcode
;-------------------------------------------------------------------------------
DisplayError:
.l:
                move.w  d0,color00+custom
                bra.b   .l


********************************************************************************
; d0.l - bytes
; returns:
; a0 - allocated ptr
;-------------------------------------------------------------------------------
AllocChip:
                move.l  fw_MemChip(a5),a0
                lea     (a0,d0.l),a1
                cmp.l   fw_MemChipE(a5),a1
                ble     .ok
                move.w  #ERROR_OOM_CHIP,d0
                bra     DisplayError
.ok:            move.l  a1,fw_MemChip(a5)
                rts

********************************************************************************
; d0.l - bytes
; returns:
; a0 - allocated ptr
;-------------------------------------------------------------------------------
AllocFast:
                move.l  fw_MemFast(a5),a0
                lea     (a0,d0.l),a1
                cmp.l   fw_MemFastE(a5),a1
                ble     .ok
                move.w  #ERROR_OOM_FAST,d0
                bra     DisplayError
.ok:            move.l  a1,fw_MemFast(a5)
                rts

                include "includes/loader.i"
                include "includes/unzx0.i"


********************************************************************************
FW:             
;-------------------------------------------------------------------------------
; vars:
                ds.b    fw_VarsSIZEOF
;-------------------------------------------------------------------------------
; jump table:
                bra     AllocChip
                bra     AllocFast
                bra     LoadFile
                bra     LoadTrack
                bra     WaitFrame
                bra     zx0_decompress
                bra     GetPos
;-------------------------------------------------------------------------------
; effect vars
                ds.b    $100 


********************************************************************************
; Front screen:
*******************************************************************************

BPLS = 5
COLORS = 1<<BPLS
DIW_BW = 40
DIW_H = 256
FRONT_MOD = DIW_BW*(BPLS-1)
COL_FRONT_BG = $112

FRONT_END_FRAME = 400

*******************************************************************************

                rsreset
                rs.b    fw_SIZEOF
front_UiCode:   rs.l    1
front_UiLoaded: rs.w    1
front_Cop:      rs.l    1
front_Image:    rs.l    1


*******************************************************************************
Front:
                bsr     LoadPal

                ; Move copper to chip RAM
                FW_ALLOC_CHIP FrontCopE-FrontCop,front_Cop(a5)
                lea     FrontCop(pc),a1
                move.l  #(FrontCopE-FrontCop)/4-1,d7
.copLoop:       move.l  (a1)+,(a0)+
                dbf     d7,.copLoop

                ; Decrunch image to chip RAM
                FW_ALLOC_CHIP DIW_BW*BPLS*DIW_H,front_Image(a5)
                move.l  a0,a1
                lea     FrontImageZX0(pc),a0
                jsr     fw_ZX0Decompress(a5)

                ; Set bitplane ptrs in copper
                move.l  front_Cop(a5),a0
                lea     FrontCopBpls-FrontCop+2(a0),a0
                move.l  front_Image(a5),a1
                moveq   #BPLS-1,d7
.bpl:           move.l  a1,d0
                swap    d0
                move.w  d0,(a0)         ; hi
                move.w  a1,4(a0)        ; lo
                lea     8(a0),a0
                lea     DIW_BW(a1),a1
                dbf     d7,.bpl

                move.w  #DMAF_SETCLR!DMAF_MASTER!DMAF_RASTER!DMAF_COPPER!DMAF_BLITTER,dmacon(a6)
                move.l  front_Cop(a5),cop1lc(a6)

                ; Prepare to load UI code
                clr.w   front_UiLoaded(a5)
                FW_ALLOC_CHIP UI_CODE_SIZE,front_UiCode(a5)

.frontLoop:
                lea     FrontPalBlank(pc),a0
                lea     FrontPal(pc),a1
                lea     Pal(pc),a2
                move.w  #COLORS-1,d1
                move.w  fw_Frame(a5),d0

                ; Fade in?
                cmp.w   #64,d0
                bgt     .fadeInDone
                lsl.w   #8,d0
                add.w   d0,d0
                bsr     LerpPal
                bra     .wait
.fadeInDone:

                ; Fade out?
                cmp.w   #FRONT_END_FRAME-32,d0
                blt     .noFadeOut
                neg.w   d0
                add.w   #FRONT_END_FRAME,d0
                lsl.w   #8,d0
                add.w   d0,d0
                add.w   d0,d0
                bsr     LerpPal
                bra     .wait
.noFadeOut:

                ; Load UI code?
                tst.w   front_UiLoaded(a5)
                bne     .wait
                bsr     MotorOn
                move.w  #1,d0
                move.l  fw_LoadBuffer(a5),a0
                bsr     LoadFile
                bsr     MotorOff
                move.l  front_UiCode(a5),a1
                jsr     fw_ZX0Decompress(a5)
                move.w  #1,front_UiLoaded(a5)

.wait:
                bsr     LoadPal
                jsr     fw_WaitFrame(a5)
                cmp.w   #FRONT_END_FRAME,fw_Frame(a5)
                blt     .frontLoop

                move.l  front_UiCode(a5),a0
                jmp     (a0)


                include "transitons.i"


********************************************************************************
LoadPal:
                lea     Pal(pc),a0
                lea     color00(a6),a1
                moveq   #COLORS/2-1,d7
.col:           move.l  (a0)+,(a1)+
                dbf     d7,.col
                rts


;-------------------------------------------------------------------------------
FrontCop:
                dc.w    fmode,0
                dc.w    diwstrt,$2c81
                dc.w    diwstop,$2cc1
                dc.w    ddfstrt,$38
                dc.w    ddfstop,$d0
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    bplcon1,0
                dc.w    bpl1mod,FRONT_MOD
                dc.w    bpl2mod,FRONT_MOD
FrontCopBpls:   rept    BPLS*2
                dc.w    bpl0pt+REPTN*2,0
                endr
                dc.l    -2
FrontCopE:

;-------------------------------------------------------------------------------
Pal:            dcb.w   COLORS,COL_FRONT_BG
FrontPal:       incbin  data/front.PAL
FrontImageZX0:  incbin  data/front.BPL.zx0
                even
FrontPalBlank:  dcb.w   COLORS,COL_FRONT_BG


GetPos:
                lea     mt_data(pc),a4
                move.b  mt_SongPos(a4),d0
                and.w   #$ff,d0
                rts

                include "includes/ptplayer.i"
