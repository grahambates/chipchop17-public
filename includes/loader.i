;------------------------------------------------------
;
; MFM trackloader based on Photon/Scoopex old snippets.
;
; Changes by Michael "Axis" Hillebrandt:
;
;	- Added documentation
; 	- Added simple turn disk check (not heavily tested, so use with care)
;	- Dont turn off motor between files (speeds up loading of small files)
;	- Reuse trackbuffer of last file, if possible (speeds up loading of small files in sequential order)
;
;------------------------------------------------------

                include includes/macros.i

;------------------	
;defines
;------------------	

MFMBUFSIZE = 12980
MFMsync = $4489


;------------------	
;global functions
;------------------	

;initializes the loader, turns motor on and steps to track 0
;destroys: d7/a4-a6
LoaderInit:
                lea     ciab+ciaprb,a4
                move.w  #-1,fw_MFMlastcyl(a5)
                bsr.w   MotorOn
                bra.w   StepCyl0
	

;load sectors from disk
;a0 - buffer to load the data into
;d0 - id of startsector
;d1 - number of sectors to read (buffersize must be this*512)
LoaderLoad:
                movem.l d0-d7/a0-a6,-(sp)
                lea     ciab+ciaprb,a4
                ; bsr     MotorOn
.NoSt0:	
                and.l   #$ffff,d0
                divu    #22,d0          ;startcyl
                sub.w   fw_MFMcyl(a5),d0 ;delta-step
                beq.s   .StRdy
                bmi.s   .StOut
                bsr.s   StepIn
                subq.w  #2,d0
                bmi.s   .StRdy
.StIn:	
                bsr.w   StepInFast
                dbf     d0,.StIn
                bra.s   .StRdy
.StOut:	
                neg.w   d0              ;=neg+sub#1
                bsr.s   StepOut
                subq.w  #2,d0
                bmi.b   .StRdy
.StOutLoop:
                bsr.s   StepOutFast
                dbf     d0,.StOutLoop
.StRdy:	
                swap    d0              ;startsec within cyl
                cmp.w   #11,d0
                blt.s   .Head0
                sub.w   #11,d0
                bra.s   .Head1
.Head0:
                bsr.s   Upper
                bsr.w   LoadTrak        ;read track+decode
                beq.s   .End
.Head1:	
                bsr.s   Lower
                bsr.w   LoadTrak        ;read track+decode
                ble.s   .End
                bsr.s   StepIn          ;1 cyl forward
                bra.s   .Head0
.End:	
                ; bsr     MotorOff
                movem.l (sp)+,d0-d7/a0-a6
                rts

;------------------	
;internal functions
;------------------	
	
;switch to upper head and wait for timeout
Upper:
                bset    #CIAB_DSKSIDE,(a4)
                clr.w   fw_MFMhead(a5)
                moveq   #2,d6           ;0,1 ms=2 scan lines!
                bra.s   LdrWait
	
;switch to lower head and wait for timeout
Lower:
                bclr    #CIAB_DSKSIDE,(a4) ;Head 1
                move.w  #1,fw_MFMhead(a5)
                moveq   #2,d6           ;0,1 ms=2 scan lines!
                bra.s   LdrWait
	
;step head 1 track out and wait for timeout
StepOut:
                bset    #1,(a4)
                subq.w  #1,fw_MFMcyl(a5)
                bclr    #0,(a4)
                bset    #0,(a4)
                move.w  #282,d6         ;18 ms=282 scan lines!
                bra.s   LdrWait
	
;step head 1 track in and wait for timeout
StepIn:
                bclr    #1,(a4)
                addq.w  #1,fw_MFMcyl(a5)
                bclr    #0,(a4)
                bset    #0,(a4)
                move.w  #282,d6         ;18 ms=282 scan lines!
                bra.s   LdrWait
	
;step head 1 track out fast and wait for timeout (this can be used if the direction of the head didnt change)
StepOutFast:
                subq.w  #1,fw_MFMcyl(a5)
                bclr    #0,(a4)
                bset    #0,(a4)
                moveq   #47,d6          ;3 ms=47 scan lines!
                bra.s   LdrWait

;step head 1 track in fast and wait for timeout (this can be used if the direction of the head didnt change)
StepInFast:
                addq.w  #1,fw_MFMcyl(a5)
                bclr    #0,(a4)
                bset    #0,(a4)
                moveq   #47,d6          ;3 ms=47 scan lines!
                bra.s   LdrWait
	
;move the head to track 0 (step out until track 0 is reached)
StepCyl0:
                btst    #CIAB_DSKTRACK0,ciacrb+1(a4) ;Cyl 0 when low.
                beq.s   .AtCylPos0
                bsr.s   StepOut
.TowardsCyl0:
                btst    #CIAB_DSKTRACK0,ciacrb+1(a4) ;Cyl 0 when low.
                beq.s   .AtCylPos0
                bsr.s   StepOutFast
                bra.s   .TowardsCyl0
.AtCylPos0:
                clr.w   fw_MFMcyl(a5)
                rts
	
;wait the specified amount of rasterlines
;d7 - amount of scanlines
LdrWait:					
.loop1:		
                move.b  6(a6),d7
.loop2:
                cmp.b   6(a6),d7
                beq.s   .loop2
                dbf     d6,.loop1
                rts

;turn the floppy motor on and wait until the motor is running
MotorOn:
                lea     ciab+ciaprb,a4
                move.w  fw_MFMdrv(a5),d7
                addq.w  #3,d7
                or.b    #$78,(a4)
                bset    d7,(a4)
                bclr    #7,(a4)         ;turns motor on
                bclr    d7,(a4)
.DiskR:	
                btst    #CIAB_DSKRDY,ciacrb+1(a4) ;wait until motor running
                bne.s   .DiskR
                rts

;turn the floppy motor off
MotorOff:
                lea     ciab+ciaprb,a4
                move.w  fw_MFMdrv(a5),d7
                addq.w  #3,d7
                bset    d7,(a4)
                bset    #7,(a4)
                bclr    d7,(a4)
                rts

;load & mfm decode 1 track
;a0 - buffer to load the track into
;d0 - sector offset inside the track
;d1 - amount of sectors to read
LoadTrak:		
                move.l  fw_TrackBuffer(a5),a1
                move.w  fw_MFMcyl(a5),d5
                add.w   d5,d5
                add.w   fw_MFMhead(a5),d5
                cmp.w   fw_MFMlastcyl(a5),d5
                beq.s   .skipload
	
.reload:
                move.l  fw_TrackBuffer(a5),a1
	
;wait settle time
                move.w  #235,d6         ;15 ms=235 scan lines!
                bsr.s   LdrWait

                move.w  #MFMsync,MFMBUFSIZE-2(a1) ; make sure we get another sync match at the end of buffer
                clr.w   (a1)+
	
                move.w  #INTB_SOFTINT,intreq(a6) ;Clr Req
                move.l  a1,dskpt(a6)
                move.w  #DMAF_SETCLR|DMAF_MASTER|DMAF_DISK,dmacon(a6)
                move.w  #MFMsync,dsksync(a6)
                move.w  #ADKF_SETCLR|ADKF_MFMPREC|ADKF_WORDSYNC|ADKF_FAST,adkcon(a6)
                move.w  #$4000,dsklen(a6)
                move.w  #$8000+(MFMBUFSIZE/2)-2,dsklen(a6) ; DskLen(12800)+DmaEn
                move.w  #$8000+(MFMBUFSIZE/2)-2,dsklen(a6) ; start reading MFMdata
.Wrdy:	
                btst    #INTB_DSKBLK,intreqr+1(a6) ;wait until data read
                beq.s   .Wrdy
	
                move.w  d5,fw_MFMlastcyl(a5)

.skipload:	
                move.w  d0,-(sp)
                move.w  d1,-(sp)
	
.decode:
                move.w  d0,d2
                add.w   d1,d2           ;highest sec# (d0=lowest)
                cmp.w   #11,d2
                ble.s   .NoOvr
                moveq   #11,d2
.NoOvr:	
                sub.w   d0,d2           ;nrsecs
                move.l  #$55555555,d3   ;and-const
                move.w  d2,d1
                subq.w  #1,d1           ;loopctr
.FindS:	
                cmp.w   #MFMsync,(a1)+  ;search for a sync word
                bne.s   .FindS
                cmp.b   (a1),d3         ;search for 0-nibble
                bne.s   .FindS
                move.l  (a1)+,d4        ;decode fmtbyte/trk#,sec#,eow#
                move.l  (a1)+,d5
                and.w   d3,d4
                and.w   d3,d5
                add.w   d4,d4
                or.w    d5,d4
                lsr.w   #8,d4           ;sec#
                sub.w   d0,d4           ;do we want this sec?
                bmi.s   .Skip
                cmp.w   d2,d4
                blt.s   .DeCode
.Skip:	
                lea     48+1024(a1),a1  ;nope
                bra.s   .FindS
.DeCode:
                lea     40(a1),a1       ;found a sec,skip unnecessary data
                clr.l   fw_MFMchk(a5)
                move.l  (a1)+,d6        ;decode data chksum.L
                move.l  (a1)+,d5
                and.l   d3,d6
                and.l   d3,d5
                add.l   d6,d6
                or.l    d5,d6           ;chksum
                lea     512(a1),a2
                add.w   d4,d4           ;x512
                lsl.w   #8,d4
                lea     (a0,d4.w),a3    ;dest addr for this sec
                moveq   #127,d7
.DClup:	
                move.l  (a1)+,d4
                move.l  (a2)+,d5
                and.l   d3,d4
                and.l   d3,d5
                eor.l   d4,d6           ;EOR with checksum
                eor.l   d5,d6           ;EOR with checksum
                add.l   d4,d4
                or.l    d5,d4
                move.l  d4,(a3)+
                dbf     d7,.DClup       ;chksum should now be 0 if correct
                or.l    d6,fw_MFMchk(a5) ;or with track total chksum
                move.l  a2,a1
                dbf     d1,.FindS       ;decode next sec
                move.w  (sp)+,d1
                move.w  (sp)+,d0
                tst.l   fw_MFMchk(a5)   ;track total chksum OK?
                bne.w   .reload         ;no,retry
                moveq   #0,d0           ;set to start of track
                move.w  d2,d3
                add.w   d3,d3
                lsl.w   #8,d3
                add.w   d3,a0
                sub.w   d2,d1           ;sub #secs loaded
                rts
	
