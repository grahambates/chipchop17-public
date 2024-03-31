		include	"hw.i"
		include	"exec/funcdef.i"
		include	"exec/exec_lib.i"
		include	"exec/memory.i"

		ifnd	MACROS_I
MACROS_I	set	1


********************************************************************************
; Profiling
********************************************************************************

		ifnd	PROFILE
PROFILE		set	0		; Enable profiling
		endc

********************************************************************************
; Set background for profiling
; \1 - color value
;-------------------------------------------------------------------------------
PROFILE_BG	macro
		ifne	PROFILE
		move.w	#\1,custom+color00
		endc
		endm

********************************************************************************
; Fixed point maths
********************************************************************************

********************************************************************************
; Fixed point to integer (15)
; \1 - Fixed point value (mutated)
;-------------------------------------------------------------------------------
FP2I		macro
		add.l	\1,\1
		swap	\1
		endm

********************************************************************************
FPMULS		macro
;-------------------------------------------------------------------------------
		muls.w	\1,\2
		FP2I	\2
		endm

********************************************************************************
FPMULU		macro
;-------------------------------------------------------------------------------
		mulu.w	\1,\2
		FP2I	\2
		endm


********************************************************************************
; Blitter
********************************************************************************

WAIT_BLIT:	macro
.l\@:		btst	#DMAB_BLITTER,dmaconr(a6)
		bne.b	.l\@
		endm

WAIT_BLIT_NASTY: macro
		HOG_BLIT
.l\@:		btst	#DMAB_BLITTER,dmaconr(a6)
		bne.b	.l\@
		RELEASE_BLIT
		endm

HOG_BLIT:	macro
		move.w	#DMAF_SETCLR!DMAF_BLITHOG,dmacon(a6)
		endm

RELEASE_BLIT:	macro
		move.w	#DMAF_BLITHOG,dmacon(a6)
		endm


********************************************************************************
; Copper
********************************************************************************

COP_MOVE:	macro
		dc.w	(\2)&$1fe,\1
		endm

COP_WAIT:	macro
		dc.w	(((\1)&$ff)<<8)+((\2)&$fe)+1,$fffe
		endm

COP_WAITV:	macro
		COP_WAIT \1&$ff,4
		endm

COP_WAITH:	macro
		dc.w	((\1&$80)<<8)+(\2&$fe)+1,$80fe
		endm

COP_WAITBLIT:	macro
		dc.l	$10000
		endm

COP_SKIP:	macro
		dc.w	(((\1)&$ff)<<8)+((\2)&$fe)+1,$ffff
		endm

COP_SKIPV:	macro
		COP_SKIP \1,4
		endm

COP_SKIPH:	macro
		dc.w	(((\1)&$80)<<8)+((\2)&$fe)+1,$80ff
		endm

COP_NOP:	macro
		COP_MOVE 0,$1fe
		endm

COP_END:	macro
		dc.l	$fffffffe
		endm

		endc
