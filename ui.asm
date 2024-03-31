; TODO:
; - toggle between default / custom texts
; - loading indicator?
; - autoplay
; - credits
; - combine disk load for bank/music

                incdir  "includes"
                include "macros.i"
                include "fw.i"


********************************************************************************
* Constants:
********************************************************************************

; Display window:
DIW_W = 320
DIW_H = 256
BPLS = 5

DMASET = DMAF_SETCLR!DMAF_MASTER!DMAF_RASTER!DMAF_COPPER!DMAF_BLITTER
INTSET = INTF_SETCLR!INTF_INTEN!INTF_VERTB!INTF_PORTS

COLORS = 1<<BPLS

DIW_BW = DIW_W/16*2
DIW_MOD = DIW_BW*(BPLS-1)
DIW_SIZE = DIW_BW*DIW_H*BPLS
DIW_XSTRT = ($242-DIW_W)/2
DIW_YSTRT = ($158-DIW_H)/2
DIW_XSTOP = DIW_XSTRT+DIW_W
DIW_YSTOP = DIW_YSTRT+DIW_H

CLOUDS_SRC_W = 256+DIW_W
CLOUDS_SRC_BW = CLOUDS_SRC_W/8

CLOUDS_H = 88
CLOUDS_W = DIW_W+16
CLOUDS_BW = CLOUDS_W/8
CLOUDS_SIZE = CLOUDS_BW*CLOUDS_H*BPLS
CLOUDS_MOD = CLOUDS_BW*BPLS-DIW_BW

FONT16_W = 48
FONT16_H = 16
FONT16_BW = FONT16_W/8

SCROLL_TOP = 30
SCROLL_H = 16
SCROLL_BPLS = 3
SCROLL_W = DIW_W+FONT16_W+16
SCROLL_BW = SCROLL_W/8
SCROLL_BUFFER_SIZE = SCROLL_H*SCROLL_BW*SCROLL_BPLS+1024*8

TRACK_COUNT = (TracksE-Tracks)/2

MENU_ROW_H = 12
MENU_PAD = 10
MENU_CONTENT_H = 16*TRACK_COUNT
MENU_H = 96
MENU_BUFFER_SIZE = DIW_BW*(MENU_ROW_H*TRACK_COUNT+MENU_PAD*2)
MENU_TEXT_Y = MENU_Y+MENU_PAD-2

; Wait positions
MENU_Y = DIW_YSTRT+CLOUDS_H
BOTTOM_UPPER_Y = MENU_Y+MENU_H
SCROLL_Y = BOTTOM_UPPER_Y+SCROLL_TOP
BOTTOM_LOWER_Y = SCROLL_Y+SCROLL_H

BANK_BUFFER_SIZE = 1024*30
MUSIC_BUFFER_SIZE = 1024*102

; Colours
COL_FRONT_BG = $112
COL_TEXT = $859
COL_TEXT_SHADOW = $000
COL_TEXT_SELECTED = $aae
COL_TEXT_CURRENT = $aae
COL_TEXT_CURRENT_FLASH = $ffe
COL_TEXT_LOADING = $ffe

SCROLL_SPEED = 2

KEYCODE_SPACE = $40
KEYCODE_RETURN = $44
KEYCODE_UP = $4c
KEYCODE_DOWN = $4d

KEY_INIT_DELAY = 20
KEY_REPT_DELAY = 5

********************************************************************************
* Vars:
********************************************************************************

                rsreset
                rs.b    fw_SIZEOF
PauseScroller:  rs.w    1
CloudsScrollPos: rs.w   1
BottomScrollPos: rs.w   1
MouseLast:      rs.w    1
MouseY:         rs.w    1
MenuTop:        rs.w    1
CurrentTrack:   rs.w    1
SelectedTrack:  rs.w    1
ScrollTextPtr:  rs.l    1
ScrollSteps:    rs.w    1
MenuY1:         rs.w    1
MenuY2:         rs.w    1
LogoY:          rs.w    1
PalPt:          rs.l    1

CloudBuffers:   rs.b    0
DrawClouds:     rs.l    1
ViewClouds:     rs.l    1

ScrollBuffer:   rs.l    1
MenuBuffer:     rs.l    1
MenuBg:         rs.l    1
MenuBgBlank:    rs.l    1

DrawCop:        rs.l    1
ViewCop:        rs.l    1

Sin:            rs.l    1

MusicPos:       rs.w    1
AutoPlay:       rs.w    1
Loading:        rs.w    1

KeyReptCounter  rs.w    1
KeyReptDelay    rs.w    1
Keys:           rs.b    $80


********************************************************************************
Main:
********************************************************************************
                lea     FW(pc),a0
                move.l  a5,(a0)

                move.w  #DMASET,dmacon(a6)

                ; Init vars:
                move.w  #1,PauseScroller(a5)
                clr.w   CloudsScrollPos(a5)
                clr.w   BottomScrollPos(a5)
                clr.w   MouseLast(a5)
                clr.w   MouseY(a5)
                move.w  #2,MenuTop(a5)
                clr.w   CurrentTrack(a5)
                clr.w   SelectedTrack(a5)
                clr.w   ScrollSteps(a5)
                move.w  #DIW_YSTRT-1,MenuY1(a5)
                move.w  #BOTTOM_UPPER_Y+71+5,MenuY2(a5)
                move.w  #-84,LogoY(a5)
                lea     FrontPalBlank(pc),a0
                move.l  a0,PalPt(a5)
                clr.w   MusicPos(a5)
                move.w  #0,AutoPlay(a5)
                clr.w   Loading(a5)


                move.w  #KEY_INIT_DELAY,KeyReptCounter(a5)
                clr.w   KeyReptDelay(a5)
                clr.b   Keys+KEYCODE_UP(a5)
                clr.b   Keys+KEYCODE_DOWN(a5)
                clr.b   Keys+KEYCODE_SPACE(a5)
                clr.b   Keys+KEYCODE_RETURN(a5)

                ; Init buffers:
                FW_ALLOC_CHIP CLOUDS_SIZE,DrawClouds(a5)
                FW_ALLOC_CHIP CLOUDS_SIZE,ViewClouds(a5)
                FW_ALLOC_CHIP DIW_BW*DIW_H,MenuBg(a5)
                FW_ALLOC_FAST 1024*2,Sin(a5)
                FW_ALLOC_CHIP SCROLL_BUFFER_SIZE,ScrollBuffer(a5)

                FW_ALLOC_CHIP MENU_BUFFER_SIZE,MenuBuffer(a5)
                WAIT_BLIT
                move.l  #$1000000,bltcon0(a6)
                clr.w   bltdmod(a6)
                move.l  a0,bltdpt(a6)
                move.w  #(MENU_ROW_H*TRACK_COUNT+MENU_PAD*2)*64+DIW_BW/2,bltsize(a6)

                FW_ALLOC_CHIP DIW_BW*DIW_H,MenuBgBlank(a5)
                WAIT_BLIT
                move.l  a0,bltdpt(a6)
                move.w  #DIW_H*64+DIW_BW/2,bltsize(a6)

                ; These modify the copper template so need to run before copy
                bsr     InitBpls
                bsr     InitSprites

                ; Copy copper template to buffers
                FW_ALLOC_CHIP CopE-Cop,DrawCop(a5)
                move.l  a0,a2
                FW_ALLOC_CHIP CopE-Cop,ViewCop(a5)
                lea     Cop(pc),a1
                move.w  #(CopE-Cop)/4-1,d7
.l:             move.l  (a1)+,d0
                move.l  d0,(a0)+
                move.l  d0,(a2)+
                dbf     d7,.l

                bsr     ResetScroller

; Install interrupts:
                move.w  #0,fw_Frame(a5)
                lea     IntLvl3(pc),a0
                move.l  a0,$6c
                lea     IntLvl2(pc),a0
                move.l  a0,$68

                move.w  #INTSET,intena(a6)

                bsr     InitSin
                bsr     InitDither

                move.b  joy0dat(a6),MouseLast(a5)

;-------------------------------------------------------------------------------
; Input handling and tracking loading in the main loop,
; effect code goes in the VBI for super-simple multitasking 
; i.e. animation doesn't freeze when loading!
;-------------------------------------------------------------------------------
.mainLoop:
                move.l  FW(pc),a5
                bsr     CheckAutoPlay
                bsr     CheckInput
                jsr     fw_WaitFrame(a5)
                bra     .mainLoop


********************************************************************************
IntLvl3:
********************************************************************************
                movem.l d0-a6,-(sp)
                lea     custom,a6
                btst    #5,intreqr+1(a6)
                beq.s   .notvb

                ; Inc frame
                move.l  FW(pc),a5
                addq.w  #1,fw_Frame(a5)

                ; Swap copper buffers
                movem.l DrawCop(a5),a0/a1
                exg     a0,a1
                movem.l a0/a1,DrawCop(a5)
                move.l  a0,cop1lc(a6)

                bsr     UpdateLayout
                bsr     UpdateMenu
                bsr     UpdateClouds
                bsr     UpdateScroller
                bsr     UpdateCheckbox
                bsr     SetPal
                bsr     DrawMenu
                bsr     Script
                bsr     LerpWordsStep   
                bsr     LerpPalStep

                moveq   #INTF_VERTB,d0
                move.w  d0,intreq(a6)
                move.w  d0,intreq(a6)
.notvb:         movem.l (sp)+,d0-a6
                rte


********************************************************************************
IntLvl2:
                movem.l d0-d1/a0-a1/a5-a6,-(a7)

                lea     custom,a6
                moveq   #INTF_PORTS,d0

;check if is it level 2 interrupt
                move.w  intreqr(a6),d1
                and.w   d0,d1
                beq.b   .end

;check if SP cause interrupt, hopefully CIAICRF_SP = 8
                lea     ciaa,a0 
                move.b  ciaicr(a0),d1
                and.b   d0,d1
                beq.b   .end

                move.b  ciasdr(a0),d1   ;get keycode
                or.b    #CIACRAF_SPMODE,ciacra(a0) ;start SP handshaking

                move.l  FW(pc),a5
                lea     Keys(a5),a1
                not.b   d1
                lsr.b   #1,d1
                scc     (a1,d1.w)

;handshake
                moveq   #3-1,d1
.wait1:         move.b  vhposr(a6),d0
.wait2:         cmp.b   vhposr(a6),d0
                beq.b   .wait2
                dbf     d1,.wait1

;set input mode
                and.b   #~(CIACRAF_SPMODE),ciacra(a0)

.end:           
                moveq   #INTF_PORTS,d0
                move.w  d0,intreq(a6)
                move.w  d0,intreq(a6)
                movem.l (a7)+,d0-d1/a0-a1/a5-a6
                rte


********************************************************************************
* Routines
********************************************************************************

                include "transitons.i"


********************************************************************************
Script:
                move.w  fw_Frame(a5),d0
                ; Fade pal
                cmp.w   #20,d0
                bne     .s1
                moveq   #2,d0
                moveq   #4,d1
                lea     FrontPalBlank(pc),a0
                lea     MainPal(pc),a1
                lea     PalPt(a5),a2
                bra     StartPalLerp
.s1:
                ; menu Y1
                cmp.w   #80,d0
                bne     .s2
                move.w  #MENU_Y-1,d0
                moveq   #4,d1
                lea     MenuY1(a5),a1
                bra     LerpWord
.s2:
                ; menu Y2
                cmp.w   #100,d0
                bne     .s3
                move.w  #BOTTOM_UPPER_Y,d0
                moveq   #4,d1
                lea     MenuY2(a5),a1
                bra     LerpWord
.s3:
                ; unpause scroller
                cmp.w   #140,d0
                bne     .s4
                clr.w   PauseScroller(a5)
.s4:
                rts



********************************************************************************
InitDither:
                move.l  MenuBg(a5),a0
                move.w  #DIW_H/2-1,d7
.l:
                move.l  #$aaaaaaaa,d0
                move.w  #DIW_BW/4-1,d6
.l0:            move.l  d0,(a0)+
                dbf     d6,.l0
                not.l   d0

                move.w  #DIW_BW/4-1,d6
.l1:            move.l  d0,(a0)+
                dbf     d6,.l1

                dbf     d7,.l
                rts


********************************************************************************
InitSprites:
                lea     CopSprPt+2(pc),a0

; Unattached sprites for spiral shadow
                lea     SpriteB+2(pc),a1
                move.w  a1,4(a0)
                move.l  a1,d0
                swap    d0
                move.w  d0,(a0)
                lea     8(a0),a0

                lea     SpriteD+2(pc),a1
                move.w  a1,4(a0)
                move.l  a1,d0
                swap    d0
                move.w  d0,(a0)
                lea     8(a0),a0

; Attached sprites for main spiral
                lea     SpriteA(pc),a1
                move.l  a1,a2
                moveq   #2-1,d7
.sprSlice0:
                move.w  (a1)+,d0
                lea     (a2,d0.w),a3
                move.w  a3,4(a0)
                move.l  a3,d1
                swap    d1
                move.w  d1,(a0)
                lea     8(a0),a0
                dbf     d7,.sprSlice0

                lea     SpriteC,a1
                move.l  a1,a2
                moveq   #2-1,d7
.sprSlice1:
                move.w  (a1)+,d0
                lea     (a2,d0.w),a3
                move.w  a3,4(a0)
                move.l  a3,d1
                swap    d1
                move.w  d1,(a0)
                lea     8(a0),a0
                dbf     d7,.sprSlice1

; Unattached sprites for DSR logo on menu
                lea     LogoSprite+2(pc),a1
                move.w  a1,4(a0)
                move.l  a1,d0
                swap    d0
                move.w  d0,(a0)

                rts


********************************************************************************
InitBpls:
                lea     Cop(pc),a0
                lea     Data(pc),a4
                ; Bottom bg before scroller
                lea     BottomUpper-Data(a4),a1
                lea     CopBplPtBg+2-Cop(a0),a2
                moveq   #BPLS-1,d7
.bpl1:          move.l  a1,d0
                swap    d0
                move.w  d0,(a2)         ; hi
                move.w  a1,4(a2)        ; lo
                lea     8(a2),a2
                lea     DIW_BW(a1),a1
                dbf     d7,.bpl1

                ; Bottom bg after scroller
                ; -2 because DDF start is still fetching extra word
                lea     BottomLower-2-Data(a4),a1
                lea     CopBplPtBg2+2-Cop(a0),a2
                moveq   #BPLS-1,d7
.bpl2:          move.l  a1,d0
                swap    d0
                move.w  d0,(a2)         ; hi
                move.w  a1,4(a2)        ; lo
                lea     8(a2),a2
                lea     DIW_BW(a1),a1
                dbf     d7,.bpl2

                lea     CopBplPtScrollBg+2-Cop(a0),a2
                lea     ScrollBg-Data(a4),a1
                moveq   #3-1,d7
.bpl3:          move.l  a1,d0
                swap    d0
                move.w  d0,(a2)         ; hi
                move.w  a1,4(a2)        ; lo
                lea     8(a2),a2
                lea     DIW_BW(a1),a1
                dbf     d7,.bpl3

                rts


********************************************************************************
; Populate sin table
;-------------------------------------------------------------------------------
; FP 2/14
; +-16384 ($c000-$4000) over 1024 ($400) steps
; https://eab.abime.net/showpost.php?p=1471651&postcount=24
; maxError = 26.86567%
; averageError = 8.483626%
;-------------------------------------------------------------------------------
InitSin:
                lea     Sin,a0
                moveq   #0,d0           ; amp=16384, len=1024
                move.w  #511+2,a1
.l:
                subq.l  #2,a1
                move.l  d0,d1

                ; ifne    EXTRA_ACC
                move.w  d1,d2
                neg.w   d2
                mulu.w  d1,d2
                divu.w  #74504/2,d2     ; 74504=amp/scale
                lsr.w   #2+1,d2
                sub.w   d2,d1
                ; endc

                asr.l   #2,d1
                move.w  d1,(a0)+
                neg.w   d1
                move.w  d1,(1024-2,a0)
                add.l   a1,d0
                bne.b   .l

                rts


********************************************************************************
SetPal:
                move.l  PalPt(a5),a0
                move.l  DrawCop(a5),a1
                move.w  (a0)+,CopPal+2-Cop(a1)
                move.w  (a0)+,CopPal+6-Cop(a1)
                rts

********************************************************************************
CheckAutoPlay:
                jsr     fw_GetPos(a5)
                move.w  MusicPos(a5),d1
                move.w  d0,MusicPos(a5)
                cmp.w   d0,d1           ; Has position has loop back to a lower value?
                ble     .done
                tst.w   AutoPlay(a5)    ; autoplay enabled?
                beq     .done
                ; Move to next track
                move.w  CurrentTrack(a5),d0
                add.w   #1,d0
                cmp.w   #TRACK_COUNT,d0 ; Wrap if last track
                blt     .noWrap
                clr.w   d0
.noWrap:
                move.w  d0,CurrentTrack(a5)
                ; Select current track to keep in view
                lsl.w   #4,d0
                move.w  d0,MouseY(a5)
                bsr     StartTrack
.done:
                rts


********************************************************************************
CheckInput:
                ; Read mouse pos:
                ; http://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node0038.html

                ; Get delta
                move.b  joy0dat(a6),d0
                sub.b   MouseLast(a5),d0
                ext.w   d0
                move.b  joy0dat(a6),MouseLast(a5)

                ; Adjust and clamp position
                move.w  MouseY(a5),d1
                add.w   d0,d1
                bge     .notNeg
                moveq   #0,d1
.notNeg:
                cmp.w   #MENU_CONTENT_H-1,d1
                ble     .noClamp
                move.w  #MENU_CONTENT_H-1,d1
.noClamp:
                move.w  d1,MouseY(a5)

                ; Get selected track index from mouse pos
                lsr.w   #4,d1
                move.w  d1,SelectedTrack(a5)

;-------------------------------------------------------------------------------
; Check mouse:
                ; Check LMB
                btst    #CIAB_GAMEPORT0,ciaa
                bne     .noClick
                ; Play selected track
                move.w  d1,CurrentTrack(a5)
                bsr     StartTrack
.noClick:
                ; Check RMB
                btst    #10,potinp(a6)  ; exit on RMB
                bne     .noClickR
                not.w   AutoPlay(a5)
.l:             btst    #10,potinp(a6)  ; wait for release
                beq     .l
.noClickR:

;-------------------------------------------------------------------------------
; Check keys:
                tst.b   Keys+KEYCODE_UP(a5)
                beq     .k0
                sub.w   #1,KeyReptCounter(a5)
                bgt     .done
                move.w  KeyReptDelay(a5),KeyReptCounter(a5)
                move.w  #KEY_REPT_DELAY,KeyReptDelay(a5)
                bra     SelectPrevTrack
.k0:
                tst.b   Keys+KEYCODE_DOWN(a5)
                beq     .k1
                sub.w   #1,KeyReptCounter(a5)
                bgt     .done
                move.w  KeyReptDelay(a5),KeyReptCounter(a5)
                move.w  #KEY_REPT_DELAY,KeyReptDelay(a5)
                bra     SelectNextTrack
.k1:
                tst.b   Keys+KEYCODE_SPACE(a5)
                beq     .k3
                bsr     StartSelected
                clr.b   Keys+KEYCODE_SPACE(a5)
                rts
.k3:
                tst.b   Keys+KEYCODE_RETURN(a5)
                beq     .k4
                bsr     StartSelected
                clr.b   Keys+KEYCODE_RETURN(a5)
                rts
.k4:
; No keys pressed - reset delay
                clr.w   KeyReptCounter(a5)
                move.w  #KEY_INIT_DELAY,KeyReptDelay(a5)
.done:          rts


********************************************************************************
SelectNextTrack:
                ; Move to next track
                move.w  SelectedTrack(a5),d0
                addq    #1,d0
                cmp.w   #TRACK_COUNT,d0 ; Wrap if last track
                blt     .noWrap
                clr.w   d0
.noWrap:
                move.w  d0,SelectedTrack(a5)
                ; Select current track to keep in view
                lsl.w   #4,d0
                move.w  d0,MouseY(a5)
                rts


********************************************************************************
SelectPrevTrack:
                ; Move to next track
                move.w  SelectedTrack(a5),d0
                subq    #1,d0
                bge     .noWrap
                move.w  #TRACK_COUNT,d0 ; Wrap if first track
.noWrap:
                move.w  d0,SelectedTrack(a5)
                ; Select current track to keep in view
                lsl.w   #4,d0
                move.w  d0,MouseY(a5)
                rts


********************************************************************************
StartSelected:
                move.w  SelectedTrack(a5),d0
                move.w  d0,CurrentTrack(a5)
********************************************************************************
StartTrack:
                ; Get ptr to current track struct
                bsr     ResetScroller
                move.w  #1,PauseScroller(a5)
                move.w  #1,Loading(a5)

                jsr     fw_LoadTrack(a5)

                clr.w   PauseScroller(a5)
                clr.w   MusicPos(a5)
                clr.w   Loading(a5)
                rts


********************************************************************************
; Get ptr to track struct by idx
;-------------------------------------------------------------------------------
; d0.w - index
; returns:
; a0 - track
;-------------------------------------------------------------------------------
GetTrack:
                moveq   #0,d1
                move.w  d0,d1
                add.w   d1,d1
                lea     Data(pc),a0
                add.l   #Tracks-Data,a0
                move.w  (a0,d1.w),d1    ; d1 = track data offset
                add.l   #TrackData-Tracks,d1
                lea     (a0,d1.l),a0    ; a0 = track struct
                rts


********************************************************************************
ResetScroller:
                move.w  CurrentTrack(a5),d0
                bsr     GetTrack
                lea     Track_Text(a0),a0
                move.l  a0,ScrollTextPtr(a5)

                clr.w   ScrollSteps(a5)
                clr.w   BottomScrollPos(a5)

                move.l  ScrollBuffer(a5),a1
                WAIT_BLIT
                move.l  #$1000000,bltcon0(a6)
                clr.w   bltdmod(a6)
                move.l  a1,bltdpth(a6)
                move.w  #SCROLL_H*SCROLL_BPLS*64+SCROLL_BW/2,bltsize(a6)
                rts


********************************************************************************
DrawMenu:
                move.w  fw_Frame(a5),d0
                sub.w   #10,d0
                blt     .done
                lsr.w   #2,d0
                cmp.w   #TRACK_COUNT-1,d0
                ble     DrawMenuItem
.done:          rts


********************************************************************************
; d0 - item idx
DrawMenuItem:
                move.l  MenuBuffer(a5),a2
                lea     3+DIW_BW*MENU_PAD(a2),a2
                move.w  d0,d1
                mulu    #DIW_BW*MENU_ROW_H,d1
                lea     (a2,d1.l),a2    ; a2 = menu draw ptr

                lea     Font8,a1        ; a1 = font data

                bsr     GetTrack
                ; lea     Track_Title(a0),a0 ; a0 = title text

                moveq   #TITLE_LEN-1,d7
.char:
                move.b  (a0)+,d0        ; next char
                move.l  a2,a3

                and.w   #$ff,d0
                sub.w   #$20,d0
                lsl.w   #3,d0
                lea     (a1,d0.w),a4

                rept    8
                move.b  (a4)+,(a3)
                lea     DIW_BW(a3),a3
                endr

                lea     1(a2),a2
                dbf     d7,.char

                rts

********************************************************************************
UpdateScroller:
                tst.w   PauseScroller(a5)
                bne     .pause

                ; Clear last word
                move.w  BottomScrollPos(a5),d0
                lsr.w   #3,d0
                move.l  ScrollBuffer(a5),a1
                lea     SCROLL_BW-4(a1,d0.w),a1
                WAIT_BLIT
                move.l  #$1000000,bltcon0(a6)
                move.w  #SCROLL_BW-2,bltdmod(a6)
                move.l  a1,bltdpth(a6)

                move.w  #SCROLL_H*SCROLL_BPLS*64+1,bltsize(a6)

                ; Step *speed
                rept    SCROLL_SPEED
                bsr     StepScroller
                endr
.pause:
                ; Set position:

                move.w  BottomScrollPos(a5),d0
                move.l  DrawCop(a5),a0
                ; bplcon1 scroll
                move.w  d0,d1
                not.w   d1
                and.w   #$f,d1
                lsl.w   #4,d1
                move.w  d1,CopScroll-Cop(a0)

                ; bpl offset
                lea     CopBplPtScrollFg+2-Cop(a0),a0
                move.l  ScrollBuffer(a5),a1
                move.w  d0,d1
                lsr.w   #4,d1
                add.w   d1,d1
                lea     (a1,d1.w),a1
                moveq   #3-1,d7
.bpl1:          move.l  a1,d0
                swap    d0
                move.w  d0,(a0)         ; hi
                move.w  a1,4(a0)        ; lo
                lea     8(a0),a0
                lea     SCROLL_BW(a1),a1
                dbf     d7,.bpl1
                rts




********************************************************************************
StepScroller:

;-------------------------------------------------------------------------------
; Blit char?
                move.w  BottomScrollPos(a5),d0
                cmp.w   ScrollSteps(a5),d0
                bne     .noLetter

                ; Get next character:
                move.l  ScrollTextPtr(a5),a2
                move.b  (a2)+,d1
                beq     ResetScroller
.noWrap:
                move.l  a2,ScrollTextPtr(a5) ; update ptr
                and.w   #$ff,d1
                sub.w   #$20,d1
                ; Look up character width
                lea     Font16Widths,a0
                move.b  (a0,d1.w),d3
                and.w   #$ff,d3
                add.w   d0,d3
                move.w  d3,ScrollSteps(a5) ; set remianing steps to char width
                ; Get character in font data
                lea     Font16(pc),a0
                mulu    #FONT16_BW*SCROLL_BPLS*FONT16_H,d1
                lea     (a0,d1.w),a0

                ; Blit character to buffer
                ; bltcon0 offset
                moveq   #$f,d1
                and.w   d0,d1
                lsl.w   #2,d1
                ; Buffer offset
                ; x = BottomScrollPos + DIW_W
                lsr.w   #3,d0
                move.l  ScrollBuffer(a5),a1
                lea     DIW_BW(a1,d0.w),a1
                WAIT_BLIT
                move.l  .bltcon(pc,d1.w),bltcon0(a6)
                move.l  #SCROLL_BW-FONT16_BW,bltamod(a6)
                move.w  #SCROLL_BW-FONT16_BW,bltcmod(a6)
                movem.l a0-a1,bltapth(a6)
                move.l  a1,bltcpt(a6)
                move.l  #-1,bltafwm(a6)
                move.w  #SCROLL_H*SCROLL_BPLS*64+FONT16_BW/2,bltsize(a6)
.noLetter:

                addq.w  #1,BottomScrollPos(a5)

                rts

.bltcon:        dc.l    $0bfa0000,$1bfa0000,$2bfa0000,$3bfa0000
                dc.l    $4bfa0000,$5bfa0000,$6bfa0000,$7bfa0000
                dc.l    $8bfa0000,$9bfa0000,$abfa0000,$bbfa0000
                dc.l    $cbfa0000,$dbfa0000,$ebfa0000,$fbfa0000



********************************************************************************
UpdateClouds:
                move.w  fw_Frame(a5),d0
                lsr.w   #1,d0
                and.w   #$ff,d0
                move.w  d0,d1
                not.w   d1
                and.w   #$f,d1
                lsl.w   #2,d1

                lsr.w   #4,d0
                add.w   d0,d0

                lea     Data(pc),a2
                lea     Logo-Data(a2),a0 ; src C - Mask
                add.l   #CloudsSrc-Data,a2 ; src A
                lea     (a2,d0.w),a2    ; scroll byte offset
                move.l  DrawClouds(a5),a3 ; dest

                ; Odd/even frames:
                move.w  fw_Frame(a5),d2
                btst    #0,d2
                beq     .odd
                ; even - Swap buffers
                movem.l CloudBuffers(a5),d2-d3
                exg     d2,d3
                movem.l d2-d3,CloudBuffers(a5)
                bra     .done
.odd:
                ; odd Blit bottom half
                lea     CLOUDS_BW*CLOUDS_H*BPLS(a0),a0
                lea     CLOUDS_SRC_BW*CLOUDS_H*BPLS/2(a2),a2
                lea     CLOUDS_BW*CLOUDS_H*BPLS/2(a3),a3
.done:
                lea     CLOUDS_BW(a0),a1 ; src B - Logo

                WAIT_BLIT
                move.l  .bltcon(pc,d1),bltcon0(a6)
                move.l  #-1,bltafwm(a6)
                move.l  #(CLOUDS_SRC_BW-CLOUDS_BW)<<16,bltamod(a6)
                move.l  #CLOUDS_BW<<16+CLOUDS_BW,bltcmod(a6)
                movem.l a0-a3,bltcpth(a6)
                move.w  #CLOUDS_H/2*BPLS*64+CLOUDS_BW/2,bltsize(a6)

                move.l  ViewClouds(a5),a1
                lea     2(a1),a1
                move.l  DrawCop(a5),a0
                lea     CopBplPtClouds+2-Cop(a0),a0
                moveq   #BPLS-1,d7
.bpl0:          move.l  a1,d0
                swap    d0
                move.w  d0,(a0)         ; hi
                move.w  a1,4(a0)        ; lo
                lea     8(a0),a0
                lea     CLOUDS_BW(a1),a1
                dbf     d7,.bpl0

                rts

; Table for combined minterm and shifts for bltcon0/bltcon1
.bltcon:        dc.l    $0fb80000,$1fb80000,$2fb80000,$3fb80000
                dc.l    $4fb80000,$5fb80000,$6fb80000,$7fb80000
                dc.l    $8fb80000,$9fb80000,$afb80000,$bfb80000
                dc.l    $cfb80000,$dfb80000,$efb80000,$ffb80000


********************************************************************************
UpdateLayout:
;-------------------------------------------------------------------------------
; Adjust Copper waits:
;-------------------------------------------------------------------------------
                move.w  MenuY1(a5),d0
                move.l  DrawCop(a5),a4
                move.b  d0,CopMenuY-Cop(a4)
                move.w  MenuY2(a5),d0

                ; PAL fix or NOP
                move.w  #$1fe,d1        ; NOP
                move.w  #$ffdf,d2       ; Pal fix
                cmp.w   #BOTTOM_UPPER_Y+27,d0
                ble     .ok
                exg     d1,d2
.ok:
                move.w  d1,CopPalFixA-Cop(a4)
                move.w  d2,CopPalFixB-Cop(a4)

                move.b  d0,CopBottomUpperY-Cop(a4)
                add.w   #SCROLL_TOP-1,d0
                move.b  d0,CopScrollYPrev-Cop(a4)
                addq    #1,d0
                move.b  d0,CopScrollY-Cop(a4)
                add.w   #SCROLL_H,d0
                move.b  d0,CopBottomLowerY-Cop(a4)

;-------------------------------------------------------------------------------
; Repositon sprites:
;-------------------------------------------------------------------------------
                ; Logo:
                lea     LogoSprite+2,a0
                move.w  MenuY2(a5),d0
                subq    #4,d0           ; start y
                move.w  d0,d1
                move.b  d0,(a0)
                addq    #4,d0           ; end y
                move.b  d0,2(a0)
                ; combined ctrl bits
                clr.b   d1
                add.w   d1,d1
                or.w    d0,d1
                lsr.w   #8,d1
                add.w   d1,d1
                move.b  d1,3(a0)

                ; Spiral overlay
                lea     SpriteB+2,a0
                lea     SpriteD+2,a1
                lea     SpriteA+4,a2
                lea     SpriteC+4,a3
                move.w  MenuY2(a5),d0
                add.w   #SCROLL_TOP,d0  ; start y
                move.b  d0,(a0)
                move.b  d0,(a1)
                move.b  d0,(a2)
                move.b  d0,(a3)
                move.b  d0,$48(a2)
                move.b  d0,$48(a3)
                add.w   #SCROLL_H,d0    ; end y
                move.b  d0,2(a0)
                move.b  d0,2(a1)
                move.b  d0,2(a2)
                move.b  d0,2(a3)
                move.b  d0,$4a(a2)
                move.b  d0,$4a(a3)

                ; Menu background
                lea     CopBplPtMenuBg+2-Cop(a4),a0
                move.l  MenuBg(a5),d0
                ; Prevent flicker on dither pattern scroll
                btst.b  #0,MenuY1+1
                beq     .even
                add.l   #DIW_BW,d0
.even:

                move.w  d0,4(a0)        ; hi
                swap    d0
                move.w  d0,(a0)         ; lo
                lea     8(a0),a0
                move.l  MenuBgBlank(a5),d0
                move.w  d0,4(a0)        ; hi
                swap    d0
                move.w  d0,(a0)         ; lo

                rts

********************************************************************************
UpdateCheckbox:
                lea     Data(pc),a0
                lea     Checkbox-Data(a0),a1
                tst.w   AutoPlay(a5)
                bne     .on
                lea     6*BPLS*2(a1),a1
.on:
                lea     BottomLower+DIW_BW*BPLS*19-Data(a0),a0
                WAIT_BLIT
                move.l  #$9f00000,bltcon0(a6)
                move.l  #DIW_BW-2,bltamod(a6)
                move.l  #-1,bltafwm(a6)
                move.l  a1,bltapt(a6)
                move.l  a0,bltdpt(a6)
                move.w  #6*BPLS*64+1,bltsize(a6)
                rts

********************************************************************************
UpdateMenu:
;-------------------------------------------------------------------------------
; Colours
;-------------------------------------------------------------------------------
                move.l  DrawCop(a5),a4
                move.w  fw_Frame(a5),d0
                lsl.w   #5,d0
                and.w   #$7fe,d0
                lea     Sin,a0
                move.w  (a0,d0.w),d0
                add.w   #$4000,d0
                move.w  #COL_TEXT_CURRENT,d3
                move.w  #COL_TEXT_CURRENT_FLASH,d4
                bsr     LerpCol

                tst.w   Loading(a5)
                beq     .notLoading
                move.w  #COL_TEXT_LOADING,d7
.notLoading:

                move.w  d7,CopCurrentACol1-Cop(a4)
                move.w  d7,CopCurrentACol2-Cop(a4)
                move.w  d7,CopCurrentBCol1-Cop(a4)
                move.w  d7,CopCurrentBCol2-Cop(a4)
                ; Is selected item also current? Keep flashing colour.
                move.w  CurrentTrack(a5),d1
                cmp.w   SelectedTrack(a5),d1
                beq     .keepFlash
                move.w  #COL_TEXT_SELECTED,d7
.keepFlash:
                move.w  d7,CopSelectedCol1-Cop(a4)
                move.w  d7,CopSelectedCol2-Cop(a4)

                move.w  MenuY1(a5),d4   ; d4 = MenuY

;-------------------------------------------------------------------------------
; Selected item:
;-------------------------------------------------------------------------------
                move.w  SelectedTrack(a5),d0
                sub.w   MenuTop(a5),d0

                ; Adjust menu top to include selected
                bge     .notNeg
                add.w   d0,MenuTop(a5)
                moveq   #0,d0
.notNeg:
                cmp.w   #6,d0
                ble     .noScroll
                move.w  d0,d1
                move.w  #6,d0
                sub.w   d0,d1
                add.w   d1,MenuTop(a5)
.noScroll:
                ; Set copper waits
                mulu    #MENU_ROW_H,d0
                add.w   d4,d0
                add.w   #MENU_PAD-2,d0
                move.b  d0,CopSelectedY1-Cop(a4)
                add.w   #MENU_ROW_H,d0
                move.b  d0,CopSelectedY2-Cop(a4)

;-------------------------------------------------------------------------------
; Current item above selected:
;-------------------------------------------------------------------------------
                move.w  d4,d0
                move.w  d4,d1
; Set value?
                move.w  CurrentTrack(a5),d2
                cmp.w   SelectedTrack(a5),d2
                bge     .setA
                ; calc offsets
                sub.w   MenuTop(a5),d2
                mulu    #MENU_ROW_H,d2
                add.w   d4,d2
                add.w   #MENU_PAD-2,d2
                move.w  d2,d0
                move.w  d2,d1
                addq    #8,d1
                ; clamp
                cmp.w   d4,d0
                bge     .noClampAStart
                move.w  d4,d0
.noClampAStart:
                cmp.w   d4,d1
                bge     .noClampAEnd
                move.w  d4,d1
.noClampAEnd:
.setA:
                move.b  d0,CopCurrentAY1-Cop(a4)
                move.b  d1,CopCurrentAY2-Cop(a4)

;-------------------------------------------------------------------------------
; Current item below selected:
;-------------------------------------------------------------------------------
                move.w  #BOTTOM_UPPER_Y-1,d0
                move.w  #BOTTOM_UPPER_Y-1,d1
; Set value?
                move.w  CurrentTrack(a5),d2
                cmp.w   SelectedTrack(a5),d2
                ble     .setB
                ; calc offsets
                sub.w   MenuTop(a5),d2
                mulu    #MENU_ROW_H,d2
                add.w   d4,d2
                add.w   #MENU_PAD-2-1,d2
                move.w  d2,d0
                move.w  d2,d1
                addq    #8,d1
                ; clamp
                cmp.w   #BOTTOM_UPPER_Y-1,d0
                ble     .noClampBStart
                move.w  #BOTTOM_UPPER_Y-1,d0
.noClampBStart:
                cmp.w   #BOTTOM_UPPER_Y-1,d1
                ble     .noClampBEnd
                move.w  #BOTTOM_UPPER_Y-1,d1
.noClampBEnd:
.setB:
                move.b  d0,CopCurrentBY1-Cop(a4)
                move.b  d1,CopCurrentBY2-Cop(a4)

;-------------------------------------------------------------------------------
; Set bpl ptrs to apply top offset
                move.l  MenuBuffer(a5),a1
                move.w  MenuTop(a5),d0
                mulu    #DIW_BW*MENU_ROW_H,d0
                lea     (a1,d0.w),a1

                move.l  DrawCop(a5),a0
                lea     CopBplPtMenuFg+2-Cop(a0),a0
                move.l  a1,d0
                swap    d0
                move.w  d0,(a0)         ; hi
                move.w  a1,4(a0)        ; lo
                lea     8(a0),a0

                lea     DIW_BW*2(a1),a1 ; shadow offset
                move.l  a1,d0
                swap    d0
                move.w  d0,(a0)         ; hi
                move.w  a1,4(a0)        ; lo

                rts

********************************************************************************
; Vars:
********************************************************************************

FW:             dc.l    0

********************************************************************************
* Data
********************************************************************************

MainPal:        dc.w    0,$412
NullSprite:     ds.b    4
FrontPalBlank:  dcb.w   COLORS,COL_FRONT_BG


;-------------------------------------------------------------------------------
; Fonts
;-------------------------------------------------------------------------------

Font16Widths:
                dc.b    11              ; <space>
                dc.b    10              ; !
                dc.b    10              ; "
                dc.b    15
                dc.b    15
                dc.b    15
                dc.b    16              ; &
                dc.b    6               ; '
                dc.b    15              ; (
                dc.b    15              ; )
                dc.b    15
                dc.b    11              ; +
                dc.b    6               ; ,
                dc.b    10              ; -
                dc.b    6               ; .
                dc.b    12              ; /
                dc.b    15              ; 0
                dc.b    12              ; 1
                dc.b    15              ; 2
                dc.b    15              ; 3
                dc.b    16              ; 4
                dc.b    15              ; 5
                dc.b    15              ; 6
                dc.b    14              ; 7
                dc.b    15              ; 8
                dc.b    15              ; 9
                dc.b    6               ; :
                dc.b    6               ; ;
                dc.b    10              ; <
                dc.b    10              ; =
                dc.b    10              ; >
                dc.b    15              ; ?
                dc.b    19              ; @
                dc.b    16              ; A
                dc.b    16              ; B
                dc.b    17              ; C
                dc.b    15              ; D
                dc.b    15              ; E
                dc.b    15              ; F
                dc.b    15              ; G
                dc.b    16              ; H
                dc.b    8               ; I
                dc.b    15              ; J
                dc.b    16              ; K
                dc.b    16              ; L
                dc.b    20              ; M
                dc.b    15              ; N
                dc.b    15              ; O
                dc.b    15              ; P
                dc.b    16              ; Q
                dc.b    17              ; R
                dc.b    16              ; S
                dc.b    17              ; T
                dc.b    15              ; U
                dc.b    15              ; V
                dc.b    19              ; W
                dc.b    17              ; X
                dc.b    18              ; Y
                dc.b    17              ; Z
                dc.b    14              ; [
                dc.b    13              ; \
                dc.b    14              ; ]
                even

Font8:          incbin  data/font-8.bin


*******************************************************************************
                ; data_c
*******************************************************************************


;-------------------------------------------------------------------------------
; Copper:
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
Cop:
                dc.w    diwstrt,DIW_YSTRT<<8!DIW_XSTRT
                dc.w    diwstop,(DIW_YSTOP-256)<<8!(DIW_XSTOP-256)
                dc.w    ddfstrt,(DIW_XSTRT-17)>>1&$fc
                dc.w    ddfstop,(DIW_XSTRT-17+(DIW_W>>4-1)<<4)>>1&$fc
                dc.w    bplcon0,BPLS<<12!$200
                dc.w    bplcon1,0
                dc.w    bplcon2,%1100100 ; playfield 2 priority

; Sprites:
                dc.w    dmacon,DMAF_SETCLR!DMAF_SPRITE
CopSprPt:
                rept    8*2
                dc.w    sprpt+REPTN*2,0
                endr

;-------------------------------------------------------------------------------
; Logo / cloud animation:
CopPal:
                incbin  data/logo.COP   ; main palette
CopBplPtClouds: rept    BPLS*2
                dc.w    bpl0pt+REPTN*2,0
                endr
                dc.w    bpl1mod,CLOUDS_MOD
                dc.w    bpl2mod,CLOUDS_MOD

;-------------------------------------------------------------------------------
; Menu:
CopMenuY:       
                COP_WAIT MENU_Y-1,$d6
                dc.w    bpl1mod,0
                dc.w    bpl2mod,0
CopBplPtMenuBg:
                dc.w    bpl0pt,0
                dc.w    bpl0ptl,0
                dc.w    bpl2pt,0
                dc.w    bpl2ptl,0
CopBplPtMenuFg:
                dc.w    bpl1pt,0
                dc.w    bpl1ptl,0
                dc.w    bpl3pt,0
                dc.w    bpl3ptl,0
                dc.w    bplcon0,4<<12!1<<10!$200 ; 4 bpls dual playfield

                dc.w    color09,COL_TEXT_SHADOW
                dc.w    color10,COL_TEXT
                dc.w    color11,COL_TEXT

                ;---------------------------------------------------------------
                ; Current text above selected
CopCurrentAY1:  COP_WAITV MENU_Y
                dc.w    color10
CopCurrentACol1: dc.w   COL_TEXT_SELECTED
                dc.w    color11
CopCurrentACol2: dc.w   COL_TEXT_SELECTED
CopCurrentAY2:  COP_WAITV MENU_Y

                ; Back to default text col
                dc.w    color10,COL_TEXT
                dc.w    color11,COL_TEXT

                ;---------------------------------------------------------------
                ; Active text col
CopSelectedY1:  COP_WAITV MENU_Y+MENU_PAD-2
                dc.w    color10
CopSelectedCol1: dc.w   COL_TEXT_CURRENT
                dc.w    color11
CopSelectedCol2: dc.w   COL_TEXT_CURRENT
CopSelectedY2:  COP_WAITV MENU_Y+MENU_PAD+8-2

                ; DSR logo cols
                dc.w    color29,$716
                dc.w    color30,$a4a
                dc.w    color31,$b8d

                ; Back to default text col
                dc.w    color10,COL_TEXT
                dc.w    color11,COL_TEXT

                ;---------------------------------------------------------------
                ; Current text below selected
CopCurrentBY1:  COP_WAIT BOTTOM_UPPER_Y-1,$d0
                dc.w    color10
CopCurrentBCol1: dc.w   COL_TEXT_SELECTED
                dc.w    color11
CopCurrentBCol2: dc.w   COL_TEXT_SELECTED
CopCurrentBY2:  COP_WAIT BOTTOM_UPPER_Y-1,$df

                ; Back to default text col
                dc.w    color10,COL_TEXT
                dc.w    color11,COL_TEXT

CopPalFixA:     dc.l    $01fefffe       ; pal fix / nop

;-------------------------------------------------------------------------------
; Bottom upper:
CopBottomUpperY:
                COP_WAITV BOTTOM_UPPER_Y
                dc.w    bplcon0,BPLS<<12!$200
CopBplPtBg:     rept    BPLS*2
                dc.w    bpl0pt+REPTN*2,0
                endr
                dc.w    bpl1mod,DIW_MOD
                dc.w    bpl2mod,DIW_MOD

                incbin  data/logo.COP,8*4 ; restore main palette

CopPalFixB:     dc.l    $ffdffffe       ; pal fix / nop

; Sprites palette - need to get this in on previous line
CopScrollYPrev: 
                COP_WAIT SCROLL_Y-1,$a0
                incbin  data/scroll.COP,17*4,11*4 ; sprite colors

;-------------------------------------------------------------------------------
; Scroller:
CopScrollY:     
                COP_WAIT SCROLL_Y,0
CopBplPtScrollFg:
                dc.w    bpl1pt,0
                dc.w    bpl1ptl,0
                dc.w    bpl3pt,0
                dc.w    bpl3ptl,0
                dc.w    bpl5pt,0
                dc.w    bpl5ptl,0
CopBplPtScrollBg:
                dc.w    bpl0pt,0
                dc.w    bpl0ptl,0
                dc.w    bpl2pt,0
                dc.w    bpl2ptl,0
                dc.w    bpl4pt,0
                dc.w    bpl4ptl,0

                dc.w    bplcon0,6<<12!1<<10!$200 ; 6 bpl dual playfield
                dc.w    bpl1mod,DIW_BW*SCROLL_BPLS-DIW_BW-2
                dc.w    bpl2mod,SCROLL_BW*SCROLL_BPLS-DIW_BW-2
                dc.w    bplcon1
CopScroll:      dc.w    0<<4

                incbin  data/scroll.COP,8*4,8*4 ; pf2 colors
                dc.w    ddfstrt,(DIW_XSTRT-17)>>1&$fc-8 ; start fetching extra word for scroll

;-------------------------------------------------------------------------------
; Bottom lower:
; End of scroller - back to background graphic
CopBottomLowerY:
                COP_WAITV BOTTOM_LOWER_Y
                dc.w    bplcon1,0
                dc.w    bplcon0,BPLS<<12!$200
CopBplPtBg2:    rept    BPLS*2
                dc.w    bpl0pt+REPTN*2,0
                endr
                incbin  data/logo.COP,32
                dc.w    bpl1mod,DIW_MOD-2
                dc.w    bpl2mod,DIW_MOD-2

                dc.l    -2
CopE:


;-------------------------------------------------------------------------------
; Images:
;-------------------------------------------------------------------------------

Data:


SpriteA:        incbin  data/scroll-overlay-a.ASP
SpriteB:        incbin  data/scroll-overlay-b.SPR
SpriteC:        incbin  data/scroll-overlay-c.ASP
SpriteD:        incbin  data/scroll-overlay-d.SPR
LogoSprite:     incbin  data/menu-logo.SPR
Font16:         incbin  data/font-16.BPL
Checkbox:       incbin  data/checkbox.BPL

ScrollBg:       incbin  data/scroll-bg.BPL
BottomUpper:    incbin  data/bg-bottom-a.BPL
BottomLower:    incbin  data/bg-bottom-b.BPL
Logo:           incbin  data/logo.BPL
CloudsSrc:      incbin  data/clouds-rept.BPL

                include tracks.i

