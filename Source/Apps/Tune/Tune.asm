;===============================================================================
; TUNE - Play PT2/PT3/MYM sound files
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;
;	This application is basically just a RomWBW wrapper for the
;       Universal PT2 and PT3 player by S.V.Bulba and the MYM player
;       by Marq/Lieves!Tuore.  See comments below.
;_______________________________________________________________________________
;
; Usage:
;   TUNE <filename>
;
;   <filename> of sound file to load and play
;   Filename extension determines file type (.PT2, .PT3, or .MYM)
;
; Notes:
;   - Supports AY-3-8910, YM2149, etc.
;   - Plays PT2, PT3, or MYM format files.  File extension (.PT2, .PT3, or .MYM)
;     determines file type.
;   - Max Z80 CPU clock is about 8MHz or sound chip will not handle speed.
;   - Higher CPU clock speeds are possible on Z180 because extra I/O
;     wait states are added during I/O to sound chip.
;   - Uses hardware timer support on Z180 processors.  Otherwise, a delay
;     loop calibrated to CPU speed is used.
;   - Delay loop is calibrated to CPU speed, but it does not compensate for
;     time variations in each quark loop resulting from data decompression.
;     An average quark processing time is assumed in each loop.
;_______________________________________________________________________________
;
; Change Log:
;   2018-01-26 [WBW] Initial release
;   2018-01-28 [WBW] Added support for MYM sound files
;_______________________________________________________________________________
;
; ToDo:
;   1) Add an option to play file in a continuous loop?
;_______________________________________________________________________________
;
;===============================================================================
; Main program
;===============================================================================
;
RESTART		.EQU	$0000		; CP/M restart vector
BDOS		.EQU	$0005		; BDOS invocation vector
;	
IDENT		.EQU	$FFFE		; loc of RomWBW HBIOS ident ptr
;	
RMJ		.EQU	2		; intended CBIOS version - major
RMN		.EQU	9		; intended CBIOS version - minor
;
BF_SYSVER	.EQU	$F1		; BIOS: VER function
BF_SYSGET	.EQU	$F8		; HBIOS: SYSGET function
;
DCNTL		.EQU	$72		; Z180 DCNTL PORT
;
FCB		.EQU	$5C		; Location of default FCB
;
HEAPEND		.EQU	$C000		; End of heap storage
;
TYPPT2		.EQU	1		; FILTYP value for PT2 sound file
TYPPT3		.EQU	2		; FILTYP value for PT3 sound file
TYPMYM		.EQU	3		; FILTYP value for MYM sound file
;
;
;
	.ORG	$0100
;
	CALL	CRLF
	LD	DE,MSGBAN		; Point to banner message
	CALL	PRTSTR			; Print message
;		
	; Check BIOS and version	
	CALL	IDBIO			; Identify hardware BIOS
	CP	1			; RomWBW HBIOS?
	JP	NZ,ERRBIO		; If not, handle BIOS error
	LD	A,RMJ << 4 | RMN	; Expected HBIOS ver
	CP	D			; Compare with result above
	JP	NZ,ERRBIO		; Handle BIOS error
;	
	; Use platform id to derive port addresses
	LD	A,L			; Platform ID is still in L from above
	LD	C,L			; Save platform id in C for now
	LD	HL,$D0D8		; For RC2014 Z80, RSEL=D8, RDAT=D0
	LD	DE,MSGRCZ80		; Message for RC2014 Z80 platform
	CP	7			; RC2014 Z80?
	JR	Z,_SETP			; If so, set ports
	LD	DE,MSGEZ		; Message for Easy Z80 platform
	CP	9			; Easy Z80?
	LD	HL,$6068		; For RC2014 Z180, RSEL=D8, RDAT=D0
	LD	DE,MSGRCZ180		; Message for RC2014 Z180 platform
	CP	8			; RC2014 Z80?
	JR	Z,_SETP			; If so, set ports
	LD	DE,MSGSC126		; Message for SC126 Z180 platform
	CP	10			; SC126?
	JR	Z,_SETP			; If so, same ports as RC2014
	LD	HL,$9D9C		; For N8, RSEL=9C, RDAT=9D
	LD	DE,MSGN8		; Message for N8 platform
	CP	4			; N8?
	JR	Z,_SETP			; If so, set ports
	LD	HL,$9B9A		; Otherwise SCG, RSEL=9A, RDAT=9B
	LD	DE,MSGSCG		; Message for SCG platform
	LD	A,$FF			; Write $FF to the
	OUT	($9C),A			; ... SCG ACR register to activate card
_SETP	LD	(PORTS),HL		; Save port values
	CALL	CRLF			; Formatting
	CALL	PRTSTR			; Display platform string
;	
	; Choose quark wait mode based on platform
	LD	A,C			; Recover platform id
	LD	B,1			; Assume timer mode
	LD	DE,MSGTIM		; Corresponding display string
	CP	4			; N8?
	JR	Z,_SETM			; If so, commit timer mode
	CP	5			; MK4?
	JR	Z,_SETM			; If so, commit timer mode
	LD	B,0			; Otherwise, delay mode
	LD	DE,MSGDLY		; Corresponding display string
_SETM	LD	A,B			; Mode flag value to A
	LD	(WMOD),A		; Save wait mode
	CALL	PRTSTR			; Print it
;	
	; Get CPU speed & type from RomWBW HBIOS and compute quark delay factor
	LD	B,$F8			; HBIOS SYSGET function 0xF8
	LD	C,$F0			; CPUINFO subfunction 0xF0
	RST	08			; Do it, DE := CPU speed in KHz
	SRL	D			; Divide by 2
	RR	E			; ... for delay factor
	EX	DE,HL			; Move result to HL
	LD	(QDLY),HL		; Save result as quark delay factor
;	
	; Test for hardware (sound chip detection)
	LD	DE,(PORTS)		; D := RDAT, E := RSEL
	LD	C,E			; Port = RSEL
	LD	A,2			; Register 2
	OUT	(C),A			; Select register 2
	LD	C,D			; Port = RDAT
	LD	A,$AA			; Value = $AA
	OUT	(C),A			; Write $AA to register 2
	LD	C,E			; Port = RSEL
	IN	A,(C)			; Read back value in register 2
	;CALL	PRTHEX			; *debug*
	CP	$AA			; Value as written?
	JP	NZ,ERRHW		; If not, handle hardware error
;
	; Clear heap storage
	LD	HL,HEAP			; Point to heap start
	XOR	A			; A := zero
	LD	(HEAP),A		; Clear first byte of heap
	LD	DE,HEAP+1		; Set dest to next byte
	LD	BC,HEAPEND-HEAP-1	; Size of heap except first byte
	LDIR				; Propagate zero to rest of heap
;	
	; Check sound filename (must be *.PT2, *.PT3, or *.MYM)
	LD	A,(FCB+1)		; Get first char of filename
	CP	' '			; Compare to blank
	JP	Z,ERRCMD		; If so, missing filename
	LD	A,(FCB+9)		; Extension char 1
	CP	'P'			; Check for 'P'
	JP	NZ,CHKMYM		; If not, check for MYM extension
	LD	A,(FCB+10)		; Extension char 2
	CP	'T'			; Check for 'T'
	JP	NZ,ERRNAM		; If not, bad file extension
	LD	A,(FCB+11)		; Extension char 3
	LD	C,TYPPT2		; Assume PT2 file type
	CP	'2'			; Check for '2'
	JR	Z,_SET			; If so, commit file type value
	LD	C,TYPPT3		; Assume PT3 file type
	CP	'3'			; Check for '3'
	JR	Z,_SET			; If so, commit file type value
	JP	ERRNAM			; Anything else is a bad file extension
CHKMYM	LD	A,(FCB+9)		; Extension char 1
	CP	'M'			; Check for 'M'
	JP	NZ,ERRNAM		; If not, bad file extension
	LD	A,(FCB+10)		; Extension char 2
	CP	'Y'			; Check for 'Y'
	JP	NZ,ERRNAM		; If not, bad file extension
	LD	A,(FCB+11)		; Extension char 3
	LD	C,TYPMYM		; Assume MYM file type
	CP	'M'			; Check for 'M'
	JR	Z,_SET			; If so, commit file type value
	JP	ERRNAM			; Anything else is a bad file extension
_SET	LD	A,C			; Get file type value
	LD	(FILTYP),A		; Save file type value
;
	; Load sound file
_LD0	LD	C,15			; CPM Open File function
	LD	DE,FCB			; FCB
	CALL	BDOS			; Do it
	INC	A			; Test for error $FF
	JP	Z,ERRFIL		; Handle file error
;	
	LD	A,(FILTYP)		; Get file type
	LD	HL,MDLADDR		; Assume load address
	LD	(DMA),HL		; ... for PTx files
	CP	TYPMYM			; MYM file?
	JR	NZ,_LD			; If not, all set
	LD	HL,rows			; Otherwise, load address
	LD	(DMA),HL		; ... for MYM files
;
_LD	LD	HL,(DMA)		; Get load address
	PUSH	HL			; Save it
	LD	DE,128			; Bump by size of
	ADD	HL,DE			; ... one record
	LD	(DMA),HL		; Save for next loop
	LD	A,HEAPEND >> 8		; A := page limit for load
	CP	H			; Check to see if limit hit
	JP	Z,ERRSIZ		; Handle size error
	POP	DE			; Restore current DMA to DE
	LD	C,26			; CPM Set DMA function
	CALL	BDOS			; Read next 128 bytes
;		
	LD	C,20			; CPM Read Sequential function
	LD	DE,FCB			; FCB
	CALL	BDOS			; Read next 128 bytes
	OR	A			; Set flags to check EOF
	JR	NZ,_LDX			; Non-zero is EOF
	JR	Z,_LD			; Load loop
;		
_LDX	LD	C,16			; CPM Close File function
	LD	DE,FCB			; FCB
	CALL	BDOS			; Do it
;		
	; Play loop	
	CALL	CRLF2			; Formatting
	LD	DE,MSGPLY		; Playing message
	CALL	PRTSTR			; Print message
	;CALL	CRLF2			; Formatting
	
	LD	A,(FILTYP)		; Get file type
	CP	TYPPT2			; PT2?
	JR	Z,GOPT2			; If so, do it
	CP	TYPPT3			; PT3?
	JR	Z,GOPT3			; If so, do it
	CP	TYPMYM			; MYM?
	JR	Z,gomym			; If so, do it
	JP	ERRNAM			; This should never happen

GOPT2	LD	A,2			; SETUP value to PT2 sound files
	LD	(START+10),A		; Save it
	; Avg TS / quark for PT2 files has *not* been measured!!!
	LD	DE,185			; Avg TS / quark = 7400, so 185 delay loops
	JR	GOPTX			; Play PTx file

GOPT3	LD	A,0			; SETUP value to PT3 sound files
	LD	(START+10),A		; Save it
	LD	DE,185			; Avg TS / quark = 7400, so 185 delay loops
	JR	GOPTX			; Play PTx file

GOPTX	LD	HL,(QDLY)		; Get basic quark delay
	OR	A			; Clear carry
	SBC	HL,DE			; Adjust for file type
	LD	(QDLY),HL		; Save updated quark delay factor
	CALL	START			; Do initialization
PTXLP	CALL	START+5			; Play one quark
	LD	A,(START+10)		; Get setup byte
	BIT	7,A			; Check bit 7 (loop point passed)
	JR	NZ,EXIT			; Bail out when done playing
	CALL	GETKEY			; Check for keypress
	JR	NZ,EXIT			; Abort on keypress
	;LD	A,13			; Back to
	;CALL	PRTCHR			; ... start of line
	;LD	A,(CurPos)		; Get current position
	;CALL	PRTHEX			; ... and display it
	CALL	WAITQ			; Wait one quark period
	JR	PTXLP			; Loop for next quark
;
gomym	ld	hl,(QDLY)		; Get basic quark delay
	or	a			; Clear carry
	ld	de,125			; Avg TS / quark = ~5000, so 125 delay loops
	sbc	hl,de			; Adjust for file type
	ld	(QDLY),hl		; Save updated quark delay factor
	;ld	bc,(rows)
	;call	PRTHEXWORD
	call	mymini			; Initialize player
        call    extract         	; Unpack the first fragment
mymlp	call	extract
	jr	nc,EXIT			; CF clear at end of tune
waitvb	call	WAITQ
	call	upsg			; Update PSG registers
	call	GETKEY			; Check for keypess
	jr	nz,EXIT			; Bail out if so
	ld      a,(played)      	; Wait until VBI has played a fragment
        or      a
        jr      nz,waitvb
        ld      (psource),iy
        ld      a,FRAG
        ld      (played),a
	;call	PRTDOT
	jr	mymlp
;	
EXIT	CALL	START+8			; Mute audio
	;CALL	CRLF2			; Formatting
	LD	DE,MSGEND		; Completion message
	CALL	PRTSTR			; Print message
	CALL	CRLF			; Formatting
	JP	0			; Exit the easy way
;
; Wait for quark play time.  Can use hardware timer if
; supported by hardware or simple delay loop otherwise.
; Delay loop requires QDLY to be pre-set to to achieve 
; optimal 20ms wait time.
;
WAITQ	LD	A,(WMOD)		; Get delay mode
	OR	A			; Set flags
	JR	Z,DLY			; Delay mode
;		
	; Timer loop	
	CALL	TIM2			; Read timer LSB into A
	LD	C,A			; Init prev value
TIM1	PUSH	BC			; Save prev value
	CALL	TIM2			; Read timer LSB into A
	POP	BC			; Recover prev value
	CP	C			; Compare to prev
	RET	NZ			; Done if changed
	JR	TIM1			; Else, loop
;	
TIM2	LD	B,$F8			; BIOS SYSGET function
	LD	C,$D0			; TIMER sub-function
	RST	08			; Call BIOS
	LD	A,L			; MSB to A
	RET				; Return to loop
;	
	; Delay spin loop (40 tstates per loop)
DLY	LD	BC,(QDLY)		; Load quark delay factor
DLY1	DEC	BC              	; [6]
	NOP				; [4]
	NOP				; [4]
	NOP				; [4]
	NOP				; [4]
	LD	A,B             	; [4]
	OR	C               	; [4]
	JP	NZ,DLY1			; [10]
	RET
;
; Get a keystroke from CPM
;
GETKEY	LD	C,6		; BDOS direct I/O
	LD	E,$FF		; Get character if available
	CALL	BDOS		; Call BDOS
	OR	A		; Set flags, Z set if no key
	RET			; Done
;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
IDBIO:
;
	; Check for UNA (UBIOS)
	LD	A,($FFFD)	; fixed location of UNA API vector
	CP	$C3		; jp instruction?
	JR	NZ,IDBIO1	; if not, not UNA
	LD	HL,($FFFE)	; get jp address
	LD	A,(HL)		; get byte at target address
	CP	$FD		; first byte of UNA push ix instruction
	JR	NZ,IDBIO1	; if not, not UNA
	INC	HL		; point to next byte
	LD	A,(HL)		; get next byte
	CP	$E5		; second byte of UNA push ix instruction
	JR	NZ,IDBIO1	; if not, not UNA, check others
;
	LD	BC,$04FA	; UNA: get BIOS date and version
	RST	08		; DE := ver, HL := date
;
	LD	A,2		; UNA BIOS id = 2
	RET			; and done
;
IDBIO1:
	; Check for RomWBW (HBIOS)
	LD	HL,($FFFE)	; HL := HBIOS ident location
	LD	A,'W'		; First byte of ident
	CP	(HL)		; Compare
	JR	NZ,IDBIO2	; Not HBIOS
	INC	HL		; Next byte of ident
	LD	A,~'W'		; Second byte of ident
	CP	(HL)		; Compare
	JR	NZ,IDBIO2	; Not HBIOS
;
	LD	B,BF_SYSVER	; HBIOS: VER function
	LD	C,0		; required reserved value
	RST	08		; DE := version, L := platform id
;	
	LD	A,1		; HBIOS BIOS id = 1
	RET			; and done
;
IDBIO2:
	; No idea what this is
	XOR	A		; Setup return value of 0
	RET			; and done
;
; Print character in A without destroying any registers
;
PRTCHR:
	PUSH	BC		; save registers
	PUSH	DE
	PUSH	HL
	LD	E,A		; character to print in E
	LD	C,$02		; BDOS function to output a character
	CALL	BDOS		; do it
	POP	HL		; restore registers
	POP	DE
	POP	BC
	RET
;
PRTDOT:
;
	; shortcut to print a dot preserving all regs
	PUSH	AF		; save af
	LD	A,'.'		; load dot char
	CALL	PRTCHR		; print it
	POP	AF		; restore af
	RET			; done
;
PRTCR:
;
	; shortcut to print a dot preserving all regs
	PUSH	AF		; save af
	LD	A,13		; load CR value
	CALL	PRTCHR		; print it
	POP	AF		; restore af
	RET			; done
;
; Print a zero terminated string at (DE) without destroying any registers
;
PRTSTR:
	PUSH	DE
;
PRTSTR1:
	LD	A,(DE)		; get next char
	OR	A
	JR	Z,PRTSTR2
	CALL	PRTCHR
	INC	DE
	JR	PRTSTR1
;
PRTSTR2:
	POP	DE		; restore registers
	RET	
;
; Print the value in A in hex without destroying any registers
;
PRTHEX:
	PUSH	AF		; save AF
	PUSH	DE		; save DE
	CALL	HEXASCII	; convert value in A to hex chars in DE
	LD	A,D		; get the high order hex char
	CALL	PRTCHR		; print it
	LD	A,E		; get the low order hex char
	CALL	PRTCHR		; print it
	POP	DE		; restore DE
	POP	AF		; restore AF
	RET			; done
;
; print the hex word value in bc
;
PRTHEXWORD:
	PUSH	AF
	LD	A,B
	CALL	PRTHEX
	LD	A,C
	CALL	PRTHEX 
	POP	AF
	RET
;
; print the hex dword value in de:hl
;
PRTHEX32:
	PUSH	BC
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	RET
;
; Convert binary value in A to ascii hex characters in DE
;
HEXASCII:
	LD	D,A		; save A in D
	CALL	HEXCONV		; convert low nibble of A to hex
	LD	E,A		; save it in E
	LD	A,D		; get original value back
	RLCA			; rotate high order nibble to low bits
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV		; convert nibble
	LD	D,A		; save it in D
	RET			; done
;
; Convert low nibble of A to ascii hex
;
HEXCONV:
	AND	$0F	     	; low nibble only
	ADD	A,$90
	DAA	
	ADC	A,$40
	DAA	
	RET
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
PRTDECB:
	PUSH	HL
	LD	H,0
	LD	L,A
	CALL	PRTDECW		; print it
	POP	HL
	RET
;
PRTDECW:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	PRTDEC0
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
PRTDEC0:
	LD	E,'0'
	LD	BC,-10000
	CALL	PRTDEC1
	LD	BC,-1000
	CALL	PRTDEC1
	LD	BC,-100
	CALL	PRTDEC1
	LD	C,-10
	CALL	PRTDEC1
	LD	E,0
	LD	C,-1
PRTDEC1:
	LD	A,'0' - 1
PRTDEC2:
	INC	A
	ADD	HL,BC
	JR	C,PRTDEC2
	SBC	HL,BC
	CP	E
	RET	Z
	LD	E,0
	CALL	PRTCHR
	RET
;
; Start a new line
;
CRLF2:
	CALL	CRLF		; two of them
CRLF:
	PUSH	AF		; preserve AF
	LD	A,13		; <CR>
	CALL	PRTCHR		; print it
	LD	A,10		; <LF>
	CALL	PRTCHR		; print it
	POP	AF		; restore AF
	RET
;
ERRBIO:	; Invalid BIOS or version
	LD	DE,MSGBIO
	JR	ERR
;
ERRHW:	; Hardware error, sound chip not detected
	LD	DE,MSGHW
	JR	ERR
;
ERRCMD:	; Command error, display usage info
	LD	DE,MSGUSE
	JR	ERR
;
ERRNAM:	; Missing or invalid filename parameter
	LD	DE,MSGNAM
	JR	ERR
;
ERRFIL:	; Error opening sound file
	LD	DE,MSGFIL
	JR	ERR
;
ERRSIZ:	; Sound file is too large for memory
	LD	DE,MSGSIZ
	JR	ERR
;
ERR:	; print error string and return error signal
	CALL	CRLF2		; print newline
;
ERR1:	; without the leading crlf
	CALL	PRTSTR		; print error string
;
ERR2:	; without the string
	CALL	CRLF		; print newline
	JP	0		; fast exit

QDLY		.DW	0	; quark delay factor
WMOD		.DB	0	; delay mode, non-zero to use timer
DCSAV		.DB	0	; for saving Z180 DCNTL value
DMA		.DW	0	; Working DMA
FILTYP		.DB	0	; Sound file type (TYPPT2, TYPPT3, TYPMYM)
				
TMP		.DB	0	; work around use of undocumented Z80
				
PORTS:	                        
RSEL		.DB	0	; Register selection port
RDAT		.DB	0	; Register data port
		
MSGBAN		.DB	"Tune Player for RomWBW v2.1, 11-Aug-2019",0
MSGUSE		.DB	"Copyright (C) 2019, Wayne Warthen, GNU GPL v3",13,10
		.DB	"PTxPlayer Copyright (C) 2004-2007 S.V.Bulba",13,10
		.DB	"MYMPlay by Marq/Lieves!Tuore",13,10,13,10
		.DB	"Usage: TUNE <filename>.[PT2|PT3|MYM]",0
MSGBIO		.DB	"Incompatible BIOS or version, "
		.DB	"HBIOS v", '0' + RMJ, ".", '0' + RMN, " required",0
MSGHW		.DB	"Hardware error, sound chip not detected!",0
MSGNAM		.DB	"Sound filename invalid (must be .PT2, .PT3, or .MYM)",0
MSGFIL		.DB	"Sound file not found!",0
MSGSIZ		.DB	"Sound file too large to load!",0
MSGRCZ80	.DB	"RC2014 Z80 w/ Ed Brindley Sound Module",0
MSGRCZ180	.DB	"RC2014 Z180 w/ Ed Brindley Sound Module",0
MSGSC126	.DB	"SC126 Z180 w/ Ed Brindley Sound Module",0
MSGEZ		.DB	"Easy Z80 w/ Ed Brindley Sound Module",0
MSGN8		.DB	"RetroBrew N8 Onboard Sound System",0
MSGSCG		.DB	"RetroBrew SCG ECB Adapter Sound System",0
MSGTIM		.DB	", timer mode",0
MSGDLY		.DB	", delay mode",0
MSGPLY		.DB	"Playing...",0
MSGEND		.DB	" Done",0
;
;===============================================================================
; PTx Player Routines
;===============================================================================
;
;Universal PT2 and PT3 player for ZX Spectrum and MSX
;(c)2004-2007 S.V.Bulba <vorobey@mail.khstu.ru>
;http://bulba.untergrund.net (http://bulba.at.kz)

;Release number
;Release 	.EQU "1"
#DEFINE Release "1"

;Conditional assembly
;1) Version of ROUT (ZX or MSX standards)
ZX		.EQU	0
MSX		.EQU	0
WBW		.EQU	1
;2) Current position counter at (START+11)
CurPosCounter	.EQU	0
;3) Allow channels allocation bits at (START+10)
ACBBAC		.EQU	0
;4) Allow loop checking and disabling
LoopChecker	.EQU	1
;5) Insert official identificator
Id		.EQU	1

;Features
;--------
;-Can be compiled at any address (i.e. no need rounding ORG
; address).
;-Variables (VARS) can be located at any address (not only after
;code block).
;-INIT subprogram checks PT3-module version and rightly
; generates both note and volume tables outside of code block
; (in VARS).
;-Two portamento (spc. command 3xxx) algorithms (depending of
; PT3 module version).
;-New 1.XX and 2.XX special command behaviour (only for PT v3.7
; and higher).
;-Any Tempo value are accepted (including Tempo=1 and Tempo=2).
;-Fully compatible with Ay_Emul PT3 and PT2 players codes.
;-See also notes at the end of this source code.

;Limitations
;-----------
;-Can run in RAM only (self-modified code is used).
;-PT2 position list must be end by $FF marker only.

;Warning!!! PLAY subprogram can crash if no module are loaded
;into RAM or INIT subprogram was not called before.

;Call MUTE or INIT one more time to mute sound after stopping
;playing 

	;ORG $C000
;Test codes (commented)
;	LD A,2 ;PT2,ABC,Looped
;	LD (START+10),A
;	CALL START
;	EI
;_LP	HALT
;	CALL START+5
;	XOR A
;	IN A,($FE)
;	CPL
;	AND 15
;	JR Z,_LP
;	JR START+8

TonA	.EQU 0
TonB	.EQU 2
TonC	.EQU 4
Noise	.EQU 6
Mixer	.EQU 7
AmplA	.EQU 8
AmplB	.EQU 9
AmplC	.EQU 10
Env	.EQU 11
EnvTp	.EQU 13

;ChannelsVars
;	STRUCT	CHP
;reset group
PsInOr	.EQU 0
PsInSm	.EQU 1
CrAmSl	.EQU 2
CrNsSl	.EQU 3
CrEnSl	.EQU 4
TSlCnt	.EQU 5
CrTnSl	.EQU 6
TnAcc	.EQU 8
COnOff	.EQU 10
;reset group

OnOffD	.EQU 11

;IX for PTDECOD here (+12)
OffOnD	.EQU 12
OrnPtr	.EQU 13
SamPtr	.EQU 15
NNtSkp	.EQU 17
Note	.EQU 18
SlToNt	.EQU 19
Env_En	.EQU 20
Flags	.EQU 21
 ;Enabled - 0,SimpleGliss - 2
TnSlDl	.EQU 22
TSlStp	.EQU 23
TnDelt	.EQU 25
NtSkCn	.EQU 27
Volume	.EQU 28
;	ENDS
CHP	.EQU 29

;Entry and other points
;START initialize playing of module at MDLADDR
;START+3 initialization with module address in HL
;START+5 play one quark
;START+8 mute
;START+10 setup and status flags
;START+11 current position value (byte) (optional)

START
	LD HL,MDLADDR
	JR INIT
	JP PLAY
	JR MUTE
SETUP	.DB 0 ;set bit0, if you want to play without looping
	     ;(optional);
	     ;set bit1 for PT2 and reset for PT3 before
	     ;calling INIT;
	     ;bits2-3: %00-ABC, %01 ACB, %10 BAC (optional);
	     ;bits4-6 are not used
	     ;bit7 is set each time, when loop point is passed
	     ;(optional)
#IF CurPosCounter
CurPos	.DB 0 ;for visualization only (i.e. no need for playing)
#ENDIF

;Identifier
	.IF Id
	.DB "=Uni PT2 and PT3 Player r.",Release,"="
	.ENDIF

	.IF LoopChecker
CHECKLP	LD HL,SETUP
	SET 7,(HL)
	BIT 0,(HL)
	RET Z
	POP HL
	LD HL,DelyCnt
	INC (HL)
	LD HL,ChanA+NtSkCn
	INC (HL)
	.ENDIF

MUTE	XOR A
	LD H,A
	LD L,A
	LD (AYREGS+AmplA),A
	LD (AYREGS+AmplB),HL
	JP ROUT

INIT
;HL - AddressOfModule
	LD A,(START+10)
	AND 2
	JR NZ,INITPT2

	CALL SETMDAD
	PUSH HL
	LD DE,100
	ADD HL,DE
	LD A,(HL)
	LD (Delay),A
	PUSH HL
	POP IX
	ADD HL,DE
	LD (CrPsPtr),HL
	LD E,(IX+102-100)
	INC HL

#IF CurPosCounter
	LD A,L
	LD (PosSub+1),A
#ENDIF

	ADD HL,DE
	LD (LPosPtr),HL
	POP DE
	LD L,(IX+103-100)
	LD H,(IX+104-100)
	ADD HL,DE
	LD (PatsPtr),HL
	LD HL,169
	ADD HL,DE
	LD (OrnPtrs),HL
	LD HL,105
	ADD HL,DE
	LD (SamPtrs),HL
	LD A,(IX+13-100) ;EXTRACT VERSION NUMBER
	SUB $30
	JR C,L20
	CP 10
	JR C,L21
L20	LD A,6
L21	LD (Version),A
	PUSH AF ;VolTable version
	CP 4
	LD A,(IX+99-100) ;TONE TABLE NUMBER
	RLA
	AND 7
	PUSH AF ;NoteTable number
	LD HL,(e_-SamCnv-2)*256+$18
	LD (SamCnv),HL
	LD A,$BA
	LD (OrnCP),A
	LD (SamCP),A
	LD A,$7B
	LD (OrnLD),A
	LD (SamLD),A
	LD A,$87
	LD (SamClc2),A
	LD BC,PT3PD
	LD HL,0
	LD DE,PT3EMPTYORN
	JR INITCOMMON

INITPT2	LD A,(HL)
	LD (Delay),A
	PUSH HL
	PUSH HL
	PUSH HL
	INC HL
	INC HL
	LD A,(HL)
	INC HL
	LD (SamPtrs),HL
	LD E,(HL)
	INC HL
	LD D,(HL)
	POP HL
	AND A
	SBC HL,DE
	CALL SETMDAD
	POP HL
	LD DE,67
	ADD HL,DE
	LD (OrnPtrs),HL
	LD E,32
	ADD HL,DE
	LD C,(HL)
	INC HL
	LD B,(HL)
	LD E,30
	ADD HL,DE
	LD (CrPsPtr),HL
	LD E,A
	INC HL

#IF CurPosCounter
	LD A,L
	LD (PosSub+1),A
#ENDIF

	ADD HL,DE
	LD (LPosPtr),HL
	POP HL
	ADD HL,BC
	LD (PatsPtr),HL
	LD A,5
	LD (Version),A
	PUSH AF
	LD A,2
	PUSH AF
	LD HL,$51CB
	LD (SamCnv),HL
	LD A,$BB
	LD (OrnCP),A
	LD (SamCP),A
	LD A,$7A
	LD (OrnLD),A
	LD (SamLD),A
	LD A,$80
	LD (SamClc2),A
	LD BC,PT2PD
	LD HL,$8687
	LD DE,PT2EMPTYORN

INITCOMMON

	LD (PTDECOD+1),BC
	LD (PsCalc),HL
	PUSH DE

;note table data depacker
;(c) Ivan Roshin
	LD DE,T_PACK
	LD BC,T1_+(2*49)-1
TP_0	LD A,(DE)
	INC DE
	CP 15*2
	JR NC,TP_1
	LD H,A
	LD A,(DE)
	LD L,A
	INC DE
	JR TP_2
TP_1	PUSH DE
	LD D,0
	LD E,A
	ADD HL,DE
	ADD HL,DE
	POP DE
TP_2	LD A,H
	LD (BC),A
	DEC BC
	LD A,L
	LD (BC),A
	DEC BC
	SUB ($F8*2) & $FF
	JR NZ,TP_0

#IF LoopChecker
	LD HL,SETUP
	RES 7,(HL)

  #IF CurPosCounter
	INC HL
	LD (HL),A
  #ENDIF

#ELSE

  #IF CurPosCounter
	LD (CurPos),A
  #ENDIF
	
#ENDIF

	LD HL,VARS
	LD (HL),A
	LD DE,VARS+1
	LD BC,VAR0END-VARS-1
	LDIR
	LD (AdInPtA),HL ;ptr to zero
	INC A
	LD (DelyCnt),A
	LD HL,$F001 ;H - Volume, L - NtSkCn
	LD (ChanA+NtSkCn),HL
	LD (ChanB+NtSkCn),HL
	LD (ChanC+NtSkCn),HL
	POP HL
	LD (ChanA+OrnPtr),HL
	LD (ChanB+OrnPtr),HL
	LD (ChanC+OrnPtr),HL

	POP AF

;NoteTableCreator (c) Ivan Roshin
;A - NoteTableNumber*2+VersionForNoteTable
;(xx1b - 3.xx..3.4r, xx0b - 3.4x..3.6x..VTII1.0)

	LD HL,NT_DATA
	PUSH DE
	LD D,B
	ADD A,A
	LD E,A
	ADD HL,DE
	LD E,(HL)
	INC HL
	SRL E
	SBC A,A
	AND $A7 ;$00 (NOP) or $A7 (AND A)
	LD (L3),A
	EX DE,HL
	POP BC ;BC=T1_
	ADD HL,BC

	LD A,(DE)
	ADD A,T_ & $FF
	LD C,A
	ADC A,T_/256
	SUB C
	LD B,A
	PUSH BC
	LD DE,NT_
	PUSH DE

	LD B,12
	LD IX,TMP		; +WW
L1	PUSH BC
	LD C,(HL)
	INC HL
	PUSH HL
	LD B,(HL)

	PUSH DE
	EX DE,HL
	LD DE,23
	;LD IXH,8		; -WW
	LD (IX),8		; +WW

L2	SRL B
	RR C
L3	.DB $19	;AND A or NOP
	LD A,C
	ADC A,D	;=ADC 0
	LD (HL),A
	INC HL
	LD A,B
	ADC A,D
	LD (HL),A
	ADD HL,DE
	;DEC IXH		; -WW
	DEC (IX)		; +WW
	JR NZ,L2

	POP DE
	INC DE
	INC DE
	POP HL
	INC HL
	POP BC
	DJNZ L1

	POP HL
	POP DE

	LD A,E
	CP TCOLD_1 & $FF
	JR NZ,CORR_1
	LD A,$FD
	LD (NT_+$2E),A

CORR_1	LD A,(DE)
	AND A
	JR Z,TC_EXIT
	RRA
	PUSH AF
	ADD A,A
	LD C,A
	ADD HL,BC
	POP AF
	JR NC,CORR_2
	DEC (HL)
	DEC (HL)
CORR_2	INC (HL)
	AND A
	SBC HL,BC
	INC DE
	JR CORR_1

TC_EXIT

	POP AF

;VolTableCreator (c) Ivan Roshin
;A - VersionForVolumeTable (0..4 - 3.xx..3.4x;
			   ;5.. - 2.x,3.5x..3.6x..VTII1.0)

	CP 5
	LD HL,$11
	LD D,H
	LD E,H
	LD A,$17
	JR NC,M1
	DEC L
	LD E,L
	XOR A
M1      LD (M2),A

	LD IX,VT_+16

	LD C,$F
INITV2  PUSH HL

	ADD HL,DE
	EX DE,HL
	SBC HL,HL

	LD B,$10
INITV1  LD A,L
M2      .DB $7D
	LD A,H
	ADC A,0
	LD (IX),A
	INC IX
	ADD HL,DE
	DJNZ INITV1

	POP HL
	LD A,E
	CP $77
	JR NZ,M3
	INC E
M3      DEC C
	JR NZ,INITV2

	JP ROUT

SETMDAD	LD (MODADDR),HL
	LD (MDADDR1),HL
	LD (MDADDR2),HL
	RET

PTDECOD JP $C3C3

;PT2 pattern decoder
PD2_SAM	CALL SETSAM
	JR PD2_LOOP

PD2_EOff LD (IX-12+Env_En),A
	JR PD2_LOOP

PD2_ENV	LD (IX-12+Env_En),16
	LD (AYREGS+EnvTp),A
	LD A,(BC)
	INC BC
	LD L,A
	LD A,(BC)
	INC BC
	LD H,A
	LD (EnvBase),HL
	JR PD2_LOOP

PD2_ORN	CALL SETORN
	JR PD2_LOOP

PD2_SKIP INC A
	LD (IX-12+NNtSkp),A
	JR PD2_LOOP

PD2_VOL	RRCA
	RRCA
	RRCA
	RRCA
	LD (IX-12+Volume),A
	JR PD2_LOOP

PD2_DEL	CALL C_DELAY
	JR PD2_LOOP

PD2_GLIS SET 2,(IX-12+Flags)
	INC A
	LD (IX-12+TnSlDl),A
	LD (IX-12+TSlCnt),A
	LD A,(BC)
	INC BC
        LD (IX-12+TSlStp),A
	ADD A,A
	SBC A,A
        LD (IX-12+TSlStp+1),A
	SCF
	JR PD2_LP2

PT2PD	AND A

PD2_LP2	EX AF,AF'

PD2_LOOP LD A,(BC)
	INC BC
	ADD A,$20
	JR Z,PD2_REL
	JR C,PD2_SAM
	ADD A,96
	JR C,PD2_NOTE
	INC A
	JR Z,PD2_EOff
	ADD A,15
	JP Z,PD_FIN
	JR C,PD2_ENV
	ADD A,$10
	JR C,PD2_ORN
	ADD A,$40
	JR C,PD2_SKIP
	ADD A,$10
	JR C,PD2_VOL
	INC A
	JR Z,PD2_DEL
	INC A
	JR Z,PD2_GLIS
	INC A
	JR Z,PD2_PORT
	INC A
	JR Z,PD2_STOP
	LD A,(BC)
	INC BC
	LD (IX-12+CrNsSl),A
	JR PD2_LOOP

PD2_PORT RES 2,(IX-12+Flags)
	LD A,(BC)
	INC BC
	INC BC ;ignoring precalc delta to right sound
	INC BC
	SCF
	JR PD2_LP2

PD2_STOP LD (IX-12+TSlCnt),A
	JR PD2_LOOP

PD2_REL	LD (IX-12+Flags),A
	JR PD2_EXIT

PD2_NOTE LD L,A
	LD A,(IX-12+Note)
	LD (PrNote+1),A
	LD (IX-12+Note),L
	XOR A
	LD (IX-12+TSlCnt),A
	SET 0,(IX-12+Flags)
	EX AF,AF'
	JR NC,NOGLIS2
	BIT 2,(IX-12+Flags)
	JR NZ,NOPORT2
	LD (LoStep),A
	ADD A,A
	SBC A,A
	EX AF,AF'
	LD H,A
	LD L,A
	INC A
	CALL SETPORT
NOPORT2	LD (IX-12+TSlCnt),1
NOGLIS2	XOR A


PD2_EXIT LD (IX-12+PsInSm),A
	LD (IX-12+PsInOr),A
	LD (IX-12+CrTnSl),A
	LD (IX-12+CrTnSl+1),A
	JP PD_FIN

;PT3 pattern decoder
PD_OrSm	LD (IX-12+Env_En),0
	CALL SETORN
PD_SAM_	LD A,(BC)
	INC BC
	RRCA

PD_SAM	CALL SETSAM
	JR PD_LOOP

PD_VOL	RRCA
	RRCA
	RRCA
	RRCA
	LD (IX-12+Volume),A
	JR PD_LP2
	
PD_EOff	LD (IX-12+Env_En),A
	LD (IX-12+PsInOr),A
	JR PD_LP2

PD_SorE	DEC A
	JR NZ,PD_ENV
	LD A,(BC)
	INC BC
	LD (IX-12+NNtSkp),A
	JR PD_LP2

PD_ENV	CALL SETENV
	JR PD_LP2

PD_ORN	CALL SETORN
	JR PD_LOOP

PD_ESAM	LD (IX-12+Env_En),A
	LD (IX-12+PsInOr),A
	CALL NZ,SETENV
	JR PD_SAM_

PT3PD	LD A,(IX-12+Note)
	LD (PrNote+1),A
	LD L,(IX-12+CrTnSl)
	LD H,(IX-12+CrTnSl+1)
	LD (PrSlide+1),HL

PD_LOOP	LD DE,$2010
PD_LP2	LD A,(BC)
	INC BC
	ADD A,E
	JR C,PD_OrSm
	ADD A,D
	JR Z,PD_FIN
	JR C,PD_SAM
	ADD A,E
	JR Z,PD_REL
	JR C,PD_VOL
	ADD A,E
	JR Z,PD_EOff
	JR C,PD_SorE
	ADD A,96
	JR C,PD_NOTE
	ADD A,E
	JR C,PD_ORN
	ADD A,D
	JR C,PD_NOIS
	ADD A,E
	JR C,PD_ESAM
	ADD A,A
	LD E,A
	LD HL,SPCCOMS+$FF20-$2000
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	PUSH DE
	JR PD_LOOP

PD_NOIS	LD (Ns_Base),A
	JR PD_LP2

PD_REL	RES 0,(IX-12+Flags)
	JR PD_RES

PD_NOTE	LD (IX-12+Note),A
	SET 0,(IX-12+Flags)
	XOR A

PD_RES	LD (PDSP_+1),SP
	LD SP,IX
	LD H,A
	LD L,A
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
PDSP_	LD SP,$3131

PD_FIN	LD A,(IX-12+NNtSkp)
	LD (IX-12+NtSkCn),A
	RET

C_PORTM LD A,(BC)
	INC BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
	INC BC
	INC BC
	EX AF,AF'
	LD A,(BC) ;SIGNED TONE STEP
	INC BC
	LD (LoStep),A
	LD A,(BC)
	INC BC
	AND A
	EX AF,AF'
	LD L,(IX-12+CrTnSl)
	LD H,(IX-12+CrTnSl+1)

;Set portamento variables
;A - Delay; A' - Hi(Step); ZF' - (A'=0); HL - CrTnSl

SETPORT	RES 2,(IX-12+Flags)
	LD (IX-12+TnSlDl),A
	LD (IX-12+TSlCnt),A
	PUSH HL
	LD DE,NT_
	LD A,(IX-12+Note)
	LD (IX-12+SlToNt),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	PUSH HL
PrNote	LD A,$3E
	LD (IX-12+Note),A
	ADD A,A
	LD L,A
	LD H,0
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	POP HL
	SBC HL,DE
	LD (IX-12+TnDelt),L
	LD (IX-12+TnDelt+1),H
	POP DE
Version .EQU $+1
	LD A,$3E
	CP 6
	JR C,OLDPRTM ;Old 3xxx for PT v3.5-
PrSlide	LD DE,$1111
	LD (IX-12+CrTnSl),E
	LD (IX-12+CrTnSl+1),D
LoStep	.EQU $+1
OLDPRTM	LD A,$3E
	EX AF,AF'
	JR Z,NOSIG
	EX DE,HL
NOSIG	SBC HL,DE
	JP P,SET_STP
	CPL
	EX AF,AF'
	NEG
	EX AF,AF'
SET_STP	LD (IX-12+TSlStp+1),A
	EX AF,AF'
	LD (IX-12+TSlStp),A
	LD (IX-12+COnOff),0
	RET

C_GLISS	SET 2,(IX-12+Flags)
	LD A,(BC)
	INC BC
	LD (IX-12+TnSlDl),A
	AND A
	JR NZ,GL36
	LD A,(Version) ;AlCo PT3.7+
	CP 7
	SBC A,A
	INC A
GL36	LD (IX-12+TSlCnt),A
	LD A,(BC)
	INC BC
	EX AF,AF'
	LD A,(BC)
	INC BC
	JR SET_STP

C_SMPOS	LD A,(BC)
	INC BC
	LD (IX-12+PsInSm),A
	RET

C_ORPOS	LD A,(BC)
	INC BC
	LD (IX-12+PsInOr),A
	RET

C_VIBRT	LD A,(BC)
	INC BC
	LD (IX-12+OnOffD),A
	LD (IX-12+COnOff),A
	LD A,(BC)
	INC BC
	LD (IX-12+OffOnD),A
	XOR A
	LD (IX-12+TSlCnt),A
	LD (IX-12+CrTnSl),A
	LD (IX-12+CrTnSl+1),A
	RET

C_ENGLS	LD A,(BC)
	INC BC
	LD (Env_Del),A
	LD (CurEDel),A
	LD A,(BC)
	INC BC
	LD L,A
	LD A,(BC)
	INC BC
	LD H,A
	LD (ESldAdd),HL
	RET

C_DELAY	LD A,(BC)
	INC BC
	LD (Delay),A
	RET
	
SETENV	LD (IX-12+Env_En),E
	LD (AYREGS+EnvTp),A
	LD A,(BC)
	INC BC
	LD H,A
	LD A,(BC)
	INC BC
	LD L,A
	LD (EnvBase),HL
	XOR A
	LD (IX-12+PsInOr),A
	LD (CurEDel),A
	LD H,A
	LD L,A
	LD (CurESld),HL
C_NOP	RET

SETORN	ADD A,A
	LD E,A
	LD D,0
	LD (IX-12+PsInOr),D
OrnPtrs .EQU $+1
	LD HL,$2121
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
MDADDR2 .EQU $+1
	LD HL,$2121
	ADD HL,DE
	LD (IX-12+OrnPtr),L
	LD (IX-12+OrnPtr+1),H
	RET

SETSAM	ADD A,A
	LD E,A
	LD D,0
SamPtrs .EQU $+1
	LD HL,$2121
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
MDADDR1	.EQU $+1
	LD HL,$2121
	ADD HL,DE
	LD (IX-12+SamPtr),L
	LD (IX-12+SamPtr+1),H
	RET

;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES
SPCCOMS .DW C_NOP
	.DW C_GLISS
	.DW C_PORTM
	.DW C_SMPOS
	.DW C_ORPOS
	.DW C_VIBRT
	.DW C_NOP
	.DW C_NOP
	.DW C_ENGLS
	.DW C_DELAY
	.DW C_NOP
	.DW C_NOP
	.DW C_NOP
	.DW C_NOP
	.DW C_NOP
	.DW C_NOP

CHREGS	XOR A
	LD (Ampl),A
	BIT 0,(IX+Flags)
	PUSH HL
	JP Z,CH_EXIT
	LD (CSP_+1),SP
	LD L,(IX+OrnPtr)
	LD H,(IX+OrnPtr+1)
	LD SP,HL
	POP DE
	LD H,A
	LD A,(IX+PsInOr)
	LD L,A
	ADD HL,SP
	INC A
		;PT2	PT3
OrnCP	INC A	;CP E	CP D
	JR C,CH_ORPS
OrnLD	.DB 1	;LD A,D	LD A,E
CH_ORPS	LD (IX+PsInOr),A
	LD A,(IX+Note)
	ADD A,(HL)
	JP P,CH_NTP
	XOR A
CH_NTP	CP 96
	JR C,CH_NOK
	LD A,95
CH_NOK	ADD A,A
	EX AF,AF'
	LD L,(IX+SamPtr)
	LD H,(IX+SamPtr+1)
	LD SP,HL
	POP DE
	LD H,0
	LD A,(IX+PsInSm)
	LD B,A
	ADD A,A
SamClc2	ADD A,A ;or ADD A,B for PT2
	LD L,A
	ADD HL,SP
	LD SP,HL
	LD A,B
	INC A
		;PT2	PT3
SamCP	INC A	;CP E	CP D
	JR C,CH_SMPS
SamLD	.DB 1	;LD A,D	LD A,E
CH_SMPS	LD (IX+PsInSm),A
	POP BC
	POP HL

;Convert PT2 sample to PT3
		;PT2		PT3
SamCnv	POP HL  ;BIT 2,C	JR e_
	POP HL	
	LD H,B
	JR NZ,$+8
	EX DE,HL
	AND A
	SBC HL,HL
	SBC HL,DE
	LD D,C
	RR C
	SBC A,A
	CPL
	AND $3E
	RR C
	RR B
	AND C
	LD C,A
	LD A,B
	RRA
	RRA
	RR D
	RRA
	AND $9F
	LD B,A

e_	LD E,(IX+TnAcc)
	LD D,(IX+TnAcc+1)
	ADD HL,DE
	BIT 6,B
	JR Z,CH_NOAC
	LD (IX+TnAcc),L
	LD (IX+TnAcc+1),H
CH_NOAC EX DE,HL
	EX AF,AF'
	ADD A,NT_ & $FF
	LD L,A
	ADC A,NT_/256
	SUB L
	LD H,A
	LD SP,HL
	POP HL
	ADD HL,DE
	LD E,(IX+CrTnSl)
	LD D,(IX+CrTnSl+1)
	ADD HL,DE
CSP_	LD SP,$3131
	EX (SP),HL
	XOR A
	OR (IX+TSlCnt)
	JR Z,CH_AMP
	DEC (IX+TSlCnt)
	JR NZ,CH_AMP
	LD A,(IX+TnSlDl)
	LD (IX+TSlCnt),A
	LD L,(IX+TSlStp)
	LD H,(IX+TSlStp+1)
	LD A,H
	ADD HL,DE
	LD (IX+CrTnSl),L
	LD (IX+CrTnSl+1),H
	BIT 2,(IX+Flags)
	JR NZ,CH_AMP
	LD E,(IX+TnDelt)
	LD D,(IX+TnDelt+1)
	AND A
	JR Z,CH_STPP
	EX DE,HL
CH_STPP SBC HL,DE
	JP M,CH_AMP
	LD A,(IX+SlToNt)
	LD (IX+Note),A
	XOR A
	LD (IX+TSlCnt),A
	LD (IX+CrTnSl),A
	LD (IX+CrTnSl+1),A
CH_AMP	LD A,(IX+CrAmSl)
	BIT 7,C
	JR Z,CH_NOAM
	BIT 6,C
	JR Z,CH_AMIN
	CP 15
	JR Z,CH_NOAM
	INC A
	JR CH_SVAM
CH_AMIN	CP -15
	JR Z,CH_NOAM
	DEC A
CH_SVAM	LD (IX+CrAmSl),A
CH_NOAM	LD L,A
	LD A,B
	AND 15
	ADD A,L
	JP P,CH_APOS
	XOR A
CH_APOS	CP 16
	JR C,CH_VOL
	LD A,15
CH_VOL	OR (IX+Volume)
	ADD A,VT_ & $FF
	LD L,A
	ADC A,VT_/256
	SUB L
	LD H,A
	LD A,(HL)
CH_ENV	BIT 0,C
	JR NZ,CH_NOEN
	OR (IX+Env_En)
CH_NOEN	LD (Ampl),A
	BIT 7,B
	LD A,C
	JR Z,NO_ENSL
	RLA
	RLA
	SRA A
	SRA A
	SRA A
	ADD A,(IX+CrEnSl) ;SEE COMMENT BELOW
	BIT 5,B
	JR Z,NO_ENAC
	LD (IX+CrEnSl),A
NO_ENAC	LD HL,AddToEn
	ADD A,(HL) ;BUG IN PT3 - NEED WORD HERE
	LD (HL),A
	JR CH_MIX
NO_ENSL RRA
	ADD A,(IX+CrNsSl)
	LD (AddToNs),A
	BIT 5,B
	JR Z,CH_MIX
	LD (IX+CrNsSl),A
CH_MIX	LD A,B
	RRA
	AND $48
CH_EXIT	LD HL,AYREGS+Mixer
	OR (HL)
	RRCA
	LD (HL),A
	POP HL
	XOR A
	OR (IX+COnOff)
	RET Z
	DEC (IX+COnOff)
	RET NZ
	XOR (IX+Flags)
	LD (IX+Flags),A
	RRA
	LD A,(IX+OnOffD)
	JR C,CH_ONDL
	LD A,(IX+OffOnD)
CH_ONDL	LD (IX+COnOff),A
	RET

PLAY    XOR A
	LD (AddToEn),A
	LD (AYREGS+Mixer),A
	DEC A
	LD (AYREGS+EnvTp),A
	LD HL,DelyCnt
	DEC (HL)
	JP NZ,PL2
	LD HL,ChanA+NtSkCn
	DEC (HL)
	JR NZ,PL1B
AdInPtA .EQU $+1
	LD BC,$0101
	LD A,(BC)
	AND A
	JR NZ,PL1A
	LD D,A
	LD (Ns_Base),A
CrPsPtr .EQU $+1
	LD HL,$2121
	INC HL
	LD A,(HL)
	INC A
	JR NZ,PLNLP

#IF LoopChecker
	CALL CHECKLP
#ENDIF

LPosPtr .EQU $+1
	LD HL,$2121
	LD A,(HL)
	INC A
PLNLP	LD (CrPsPtr),HL
	DEC A
		;PT2		PT3
PsCalc	DEC A	;ADD A,A	NOP
	DEC A	;ADD A,(HL)	NOP
	ADD A,A
	LD E,A
	RL D

#IF CurPosCounter
	LD A,L
PosSub	SUB $D6
	LD (CurPos),A
#ENDIF

PatsPtr .EQU $+1
	LD HL,$2121
	ADD HL,DE
MODADDR	.EQU $+1
	LD DE,$1111
	LD (PSP_+1),SP
	LD SP,HL
	POP HL
	ADD HL,DE
	LD B,H
	LD C,L
	POP HL
	ADD HL,DE
	LD (AdInPtB),HL
	POP HL
	ADD HL,DE
	LD (AdInPtC),HL
PSP_	LD SP,$3131
PL1A	LD IX,ChanA+12
	CALL PTDECOD
	LD (AdInPtA),BC

PL1B	LD HL,ChanB+NtSkCn
	DEC (HL)
	JR NZ,PL1C
	LD IX,ChanB+12
AdInPtB	.EQU $+1
	LD BC,$0101
	CALL PTDECOD
	LD (AdInPtB),BC

PL1C	LD HL,ChanC+NtSkCn
	DEC (HL)
	JR NZ,PL1D
	LD IX,ChanC+12
AdInPtC	.EQU $+1
	LD BC,$0101
	CALL PTDECOD
	LD (AdInPtC),BC

Delay	.EQU $+1
PL1D	LD A,$3E
	LD (DelyCnt),A

PL2	LD IX,ChanA
	LD HL,(AYREGS+TonA)
	CALL CHREGS
	LD (AYREGS+TonA),HL
	LD A,(Ampl)
	LD (AYREGS+AmplA),A
	LD IX,ChanB
	LD HL,(AYREGS+TonB)
	CALL CHREGS
	LD (AYREGS+TonB),HL
	LD A,(Ampl)
	LD (AYREGS+AmplB),A
	LD IX,ChanC
	LD HL,(AYREGS+TonC)
	CALL CHREGS
	LD (AYREGS+TonC),HL

	LD HL,(Ns_Base_AddToNs)
	LD A,H
	ADD A,L
	LD (AYREGS+Noise),A

AddToEn .EQU $+1
	LD A,$3E
	LD E,A
	ADD A,A
	SBC A,A
	LD D,A
	LD HL,(EnvBase)
	ADD HL,DE
	LD DE,(CurESld)
	ADD HL,DE
	LD (AYREGS+Env),HL

	XOR A
	LD HL,CurEDel
	OR (HL)
	JR Z,ROUT
	DEC (HL)
	JR NZ,ROUT
Env_Del	.EQU $+1
	LD A,$3E
	LD (HL),A
ESldAdd	.EQU $+1
	LD HL,$2121
	ADD HL,DE
	LD (CurESld),HL

ROUT
#IF ACBBAC
	LD A,(SETUP)
	AND 12
	JR Z,ABC
	ADD A,CHTABLE
	LD E,A
	ADC A,CHTABLE/256
	SUB E
	LD D,A
	LD B,0
	LD IX,AYREGS
	LD HL,AYREGS
	LD A,(DE)
	INC DE
	LD C,A
	ADD HL,BC
	LD A,(IX+TonB)
	LD C,(HL)
	LD (IX+TonB),C
	LD (HL),A
	INC HL
	LD A,(IX+TonB+1)
	LD C,(HL)
	LD (IX+TonB+1),C
	LD (HL),A
	LD A,(DE)
	INC DE
	LD C,A
	ADD HL,BC
	LD A,(IX+AmplB)
	LD C,(HL)
	LD (IX+AmplB),C
	LD (HL),A
	LD A,(DE)
	INC DE
	LD (RxCA1),A
	XOR 8
	LD (RxCA2),A
	LD HL,AYREGS+Mixer
	LD A,(DE)
	AND (HL)
	LD E,A
	LD A,(HL)
RxCA1	LD A,(HL)
	AND %010010
	OR E
	LD E,A
	LD A,(HL)
	AND %010010
RxCA2	OR E
	OR E
	LD (HL),A
ABC
#ENDIF

#IF ZX
	XOR A
	LD DE,$FFBF
	LD BC,$FFFD
	LD HL,AYREGS
LOUT	OUT (C),A
	LD B,E
	OUTI 
	LD B,D
	INC A
	CP 13
	JR NZ,LOUT
	OUT (C),A
	LD A,(HL)
	AND A
	RET M
	LD B,E
	OUT (C),A
	RET
#ENDIF

#IF MSX
;MSX version of ROUT (c)Dioniso
	XOR A
	LD C,$A0
	LD HL,AYREGS
LOUT	OUT (C),A
	INC C
	OUTI 
	DEC C
	INC A
	CP 13
	JR NZ,LOUT
	OUT (C),A
	LD A,(HL)
	AND A
	RET M
	INC C
	OUT (C),A
	RET
#ENDIF

#IF WBW
	LD A,(WMOD)	; If WMOD = 1, CPU is Z180
	OR A		; Set flags
	JR Z,LOUT0	; Skip Z180 stuff
	DI
	IN0 A,(DCNTL)	; Get wait states
	LD (DCSAV),A	; Save value
	OR %00110000	; Force slow operation (I/O W/S=3)
	OUT0 (DCNTL),A	; And update DCNTL
LOUT0	LD DE,(PORTS)	; D := RDAT, E := RSEL
	XOR A		; start with reg 0
	LD C,E		; point to address port
	LD HL,AYREGS	; start of value list
LOUT	OUT (C),A	; select register
	LD C,D		; point to data port
	OUTI		; write (HL) to data port, bump HL
	LD C,E		; point to address port
	INC A		; next register
	CP 13		; reg 13?
	JR NZ,LOUT	; if not, loop
	OUT (C),A	; select register 13
	LD A,(HL)	; get value for register 13
	AND A		; set flags
	JP M,LOUT2	; if bit 7 set, return w/o writing value
	LD C,D		; select data port
	OUT (C),A	; write value to register 13
LOUT2	LD A,(WMOD)	; If WMOD = 1, CPU is Z180
	OR A		; Set flags
	RET Z		; Skip Z180 stuff
	LD A,(DCSAV)	; Get saved DCNTL value
	OUT0 (DCNTL),A	; And restore it
	EI
	RET		; And done
#ENDIF
	
#IF ACBBAC
CHTABLE	.EQU $-4
	.DB 4,5,15,%001001,0,7,7,%100100
#ENDIF

NT_DATA	.DB (T_NEW_0-T1_)*2
	.DB TCNEW_0-T_
	.DB (T_OLD_0-T1_)*2+1
	.DB TCOLD_0-T_
	.DB (T_NEW_1-T1_)*2+1
	.DB TCNEW_1-T_
	.DB (T_OLD_1-T1_)*2+1
	.DB TCOLD_1-T_
	.DB (T_NEW_2-T1_)*2
	.DB TCNEW_2-T_
	.DB (T_OLD_2-T1_)*2
	.DB TCOLD_2-T_
	.DB (T_NEW_3-T1_)*2
	.DB TCNEW_3-T_
	.DB (T_OLD_3-T1_)*2
	.DB TCOLD_3-T_

T_

TCOLD_0	.DB $00+1,$04+1,$08+1,$0A+1,$0C+1,$0E+1,$12+1,$14+1
	.DB $18+1,$24+1,$3C+1,0
TCOLD_1	.DB $5C+1,0
TCOLD_2	.DB $30+1,$36+1,$4C+1,$52+1,$5E+1,$70+1,$82,$8C,$9C
	.DB $9E,$A0,$A6,$A8,$AA,$AC,$AE,$AE,0
TCNEW_3	.DB $56+1
TCOLD_3	.DB $1E+1,$22+1,$24+1,$28+1,$2C+1,$2E+1,$32+1,$BE+1,0
TCNEW_0	.DB $1C+1,$20+1,$22+1,$26+1,$2A+1,$2C+1,$30+1,$54+1
	.DB $BC+1,$BE+1,0
TCNEW_1 .EQU TCOLD_1
TCNEW_2	.DB $1A+1,$20+1,$24+1,$28+1,$2A+1,$3A+1,$4C+1,$5E+1
	.DB $BA+1,$BC+1,$BE+1,0

PT3EMPTYORN .EQU $-1
	.DB 1,0

;first 12 values of tone tables (packed)

T_PACK	.DB $06EC*2/256,$06EC*2
	.DB $0755-$06EC
	.DB $07C5-$0755
	.DB $083B-$07C5
	.DB $08B8-$083B
	.DB $093D-$08B8
	.DB $09CA-$093D
	.DB $0A5F-$09CA
	.DB $0AFC-$0A5F
	.DB $0BA4-$0AFC
	.DB $0C55-$0BA4
	.DB $0D10-$0C55
	.DB $066D*2/256,$066D*2
	.DB $06CF-$066D
	.DB $0737-$06CF
	.DB $07A4-$0737
	.DB $0819-$07A4
	.DB $0894-$0819
	.DB $0917-$0894
	.DB $09A1-$0917
	.DB $0A33-$09A1
	.DB $0ACF-$0A33
	.DB $0B73-$0ACF
	.DB $0C22-$0B73
	.DB $0CDA-$0C22
	.DB $0704*2/256,$0704*2
	.DB $076E-$0704
	.DB $07E0-$076E
	.DB $0858-$07E0
	.DB $08D6-$0858
	.DB $095C-$08D6
	.DB $09EC-$095C
	.DB $0A82-$09EC
	.DB $0B22-$0A82
	.DB $0BCC-$0B22
	.DB $0C80-$0BCC
	.DB $0D3E-$0C80
	.DB $07E0*2/256,$07E0*2
	.DB $0858-$07E0
	.DB $08E0-$0858
	.DB $0960-$08E0
	.DB $09F0-$0960
	.DB $0A88-$09F0
	.DB $0B28-$0A88
	.DB $0BD8-$0B28
	.DB $0C80-$0BD8
	.DB $0D60-$0C80
	.DB $0E10-$0D60
	.DB $0EF8-$0E10
;
;Release 0 steps:
;02/27/2005
;Merging PT2 and PT3 players; debug
;02/28/2005
;debug; optimization
;03/01/2005
;Migration to SjASM; conditional assembly (ZX, MSX and
;visualization)
;03/03/2005
;SETPORT subprogram (35 bytes shorter)
;03/05/2005
;fixed CurPosCounter error
;03/06/2005
;Added ACB and BAC channels swapper (for Spectre); more cond.
;assembly keys; optimization
;Release 1 steps:
;04/15/2005
;Removed loop bit resetting for no loop build (5 bytes shorter)
;04/30/2007
;New 1.xx and 2.xx interpretation for PT 3.7+.

;Tests in IMMATION TESTER V1.0 by Andy Man/POS
;(for minimal build)
;Module name/author	Min tacts	Max tacts
;PT3 (a little slower than standalone player)
;Spleen/Nik-O		1720		9368
;Chuta/Miguel		1720		9656
;Zhara/Macros		4536		8792
;PT2 (more slower than standalone player)
;Epilogue/Nik-O		3928		10232
;NY tHEMEs/zHenYa	3848		9208
;GUEST 4/Alex Job	2824		9352
;KickDB/Fatal Snipe	1720		9880

;Size (minimal build for ZX Spectrum):
;Code block $7B9 bytes
;Variables $21D bytes (can be stripped)
;Size in RAM $7B9+$21D=$9D6 (2518) bytes

;Notes:
;Pro Tracker 3.4r can not be detected by header, so PT3.4r tone
;tables realy used only for modules of 3.3 and older versions.
;
;===============================================================================
; MYM Player Routines
;===============================================================================
;
; MYMPLAY - Player for MYM-tunes
; MSX-version by Marq/Lieves!Tuore & Fit 30.1.2000
:
; 1.2.2000  - Added the disk loader. Thanks to Yzi & Plaque for examples.
; 7.2.2000  - Removed one unpack window -> freed 1.7kB memory
;
; Source suitable for Table-driven assembler (TASM), sorry all
; Devpac freaks :v/

FRAG    .equ    128     ; Fragment size
REGS    .equ    14      ; Number of PSG registers
FBITS   .equ    7       ; Bits needed to store fragment offset
;
mymini  exx                     ; Starting values for procedure readbits
        ld      e,1
        ld      d,0
        ld      hl,data
        exx

        ld      hl,uncomp+FRAG  ; Starting values for the playing variables
        ld      (dest1),hl
        ld      (dest2),hl
        ld      (psource),hl
        ld      a,FRAG
        ld      (played),a
        ld      hl,0
        ld      (prows),hl
;
; *** Unpack a fragment. Returns IY=new playing position for VBI
extract:
        ld      a,0
regloop:
        push    af
        ld      c,a
        ld      b,0
        ld      hl,regbits      ; D=Bits in this PSG register
        add     hl,bc
        ld      d,(hl)
        ld      hl,current      ; E=Current value of a PSG register
        add     hl,bc
        ld      e,(hl)

        ld      bc,FRAG*3
        ld      hl,(dest1)      ; IX=Destination 1
        ld      ix,(dest1)
        add     hl,bc
        ld      (dest1),hl
        ld      hl,(dest2)      ; HL=Destination 2
        push    hl
        add     hl,bc
        ld      (dest2),hl
        pop     hl

        ex      af,af'
        ld      a,FRAG          ; AF'=fragment end counter
        ex      af,af'
        ld      a,1             ; Get fragment bit
        call    readbits
        or      a
        jr      nz,compfrag     ; 1=Compressed fragment, 0=Unchanged

        ld      b,FRAG          ; Unchanged fragment: just set all to E
sweep:  ld      (hl),e
        inc     hl
        ld      (ix),e
        inc     ix
        djnz    sweep
        jp      nextreg

compfrag:                       ; Compressed fragment
        ld      a,1
        call    readbits
        or      a
        jr      nz,notprev      ; 0=Previous register value, 1=raw/compressed

        ld      (hl),e          ; Unchanged register
        inc     hl
        ld      (ix),e
        inc     ix
        ex      af,af'
        dec     a
        ex      af,af'
        jp      nextbit

notprev:
        ld      a,1
        call    readbits
        or      a
        jr      z,packed        ; 0=compressed data, 1=raw data

        ld      a,d             ; Raw data, read regbits[i] bits
        call    readbits
        ld      e,a
        ld      (hl),a
        inc     hl
        ld      (ix),a
        inc     ix
        ex      af,af'
        dec     a
        ex      af,af'
        jp      nextbit

packed: ld      a,FBITS         ; Reference to previous data:
        call    readbits        ; Read the offset
        ld      c,a
        ld      a,FBITS         ; Read the number of bytes
        call    readbits
        ld      b,a

        push    hl
        push    bc
        ld      bc,-FRAG
        add     hl,bc
        pop     bc
        ld      a,b
        ld      b,0
        add     hl,bc
        ld      b,a
        push    hl
        pop     iy              ; IY=source address
        pop     hl

        inc     b
copy:   ld      a,(iy)          ; Copy from previous data
        inc     iy
        ld      e,a             ; Set current value
        ld      (hl),a
        inc     hl
        ld      (ix),a
        inc     ix
        ex      af,af'
        dec     a
        ex      af,af'
        djnz    copy

nextbit:
        ex      af,af'          ; If AF'=0 then fragment is done
        ld      c,a
        ex      af,af'
        ld      a,c
        or      a
        jp      nz,compfrag

nextreg:
        pop     af
        ld      b,0             ; Save the current value of PSG reg
        ld      c,a
        push    hl
        ld      hl,current
        add     hl,bc
        ld      (hl),e
        pop     hl

        inc     a               ; Check if all registers are done
        cp      REGS
        jp      nz,regloop

        or      a               ; Check if dest2 must be wrapped
        ld      bc,rows
        sbc     hl,bc
        jr      nz,nowrap

        ld      ix,FRAG+uncomp
        ld      hl,FRAG+uncomp
        ld      iy,(2*FRAG)+uncomp
        jr      endext

nowrap: ld      ix,uncomp
        ld      hl,(2*FRAG)+uncomp
        ld      iy,(FRAG)+uncomp

endext: ld      (dest1),ix
        ld      (dest2),hl

        ld      bc,FRAG         ; Check end-of-file. Clumsy :v/
        ld      hl,(prows)
        add     hl,bc
        ld      (prows),hl
        ld      bc,(rows)
        or      a
        sbc     hl,bc
	
;        jr      c,noend         ; If rows>played rows then exit
;        exx                     ; Otherwise restart
;        ld      e,1
;        ld      d,0
;        ld      hl,data
;        exx
;        ld      hl,0
;        ld      (prows),hl

noend:  ret

; *** Reads A bits from data, returns bits in A
readbits:
        exx
        ld      b,a
        ld      c,0

onebit: sla     c               ; Get one bit at a time
        rrc     e
        jr      nc,nonew        ; Wrap the AND value
        ld      d,(hl)
        inc     hl

nonew:  ld      a,e
        and     d
        jr      z,zero
        inc     c
zero:   djnz    onebit

        ld      a,c
        exx
        ret

; *** Update PSG registers
upsg:	ld	a,(WMOD)	; if WMOD = 1, CPU is z180
	or	a		; set flags
	jr	z,upsg1		; skip z180 stuff
	di
	in0	a,(DCNTL)	; get wait states
	ld	(DCSAV),a	; save value
	or	%00110000	; force slow operation (i/o w/s=3)
	out0	(DCNTL),a	; and update DCNTL

upsg1:	ld	hl,(psource)
	ld	de,(PORTS)	; E := RSEL, D := RDAT
        xor     a

psglp:	ld	c,e		; C := RSEL
	out	(c),a		; Select register
	ld	c,d		; C := RDAT
	outi			; Set register value
        inc     a		; Next register
        ld      bc,(3*FRAG)-1   ; Bytes to skip before next reg-1
        add     hl,bc		; Update HL
        cp      REGS-1		; Check for next to last register?
        jr      nz,psglp	; If not, loop

        ld      a,$FF		; Prepare to check for $FF value
        cp      (hl)            ; If last reg (13) is $FF
        jr      z,notrig	; ... then don't output
        ld      a,13		; Register 13
	ld	c,e		; C := RSEL
	out	(c),a		; Select register
	ld	c,d		; C := RDAT
        outi			; Set register value

notrig: ld      hl,(psource)
        inc     hl
        ld      (psource),hl

        ld      a,(played)
        or      a
        jr      z,endint
        dec     a
        ld      (played),a

endint:	ld a,(WMOD)		; If WMOD = 1, CPU is Z180
	or a			; Set flags
	ret z			; Skip Z180 stuff
	ld a,(DCSAV)		; Get saved DCNTL value
	out0 (DCNTL),a		; And restore it
	ei	
	ret			; And done
;
; *** Program data
played	.db	0       	; VBI counter
dest1	.dw	0       	; Uncompress destination 1
dest2	.dw	0       	; - " -                  2
psource	.dw	0       	; Playing offset for the VB-player
prows	.dw	0       	; Rows played so far

; Bits per PSG register
regbits	.db	8,4,8,4,8,4,5,8,5,5,5,8,8,8
; Current values of PSG registers
current	.db	0,0,0,0,0,0,0,0,0,0,0,0,0,0
;
;===============================================================================
;===============================================================================
; PTx/MYM Shared Heap Storage
;===============================================================================
;===============================================================================
;
; Note that two different storage layouts are defined below.  One for PTx and
; one for MYM.  They share the same storage area starting at the HEAP marker,
; but only one defintion will be active depending on the type of file
; being played.
;
HEAP	.EQU	$
;
;===============================================================================
; PTx Player Storage
;===============================================================================
;
	.ORG	HEAP
;
;vars from here can be stripped
;you can move VARS to any other address

VARS

ChanA	.DS CHP
ChanB	.DS CHP
ChanC	.DS CHP

;GlobalVars
DelyCnt	.DS 1
CurESld	.DS 2
CurEDel	.DS 1
Ns_Base_AddToNs
Ns_Base	.DS 1
AddToNs	.DS 1

AYREGS

VT_	.DS 256		;CreatedVolumeTableAddress

EnvBase	.EQU VT_+14

T1_	.EQU VT_+16	;Tone tables data depacked here

T_OLD_1	.EQU T1_
T_OLD_2	.EQU T_OLD_1+24
T_OLD_3	.EQU T_OLD_2+24
T_OLD_0	.EQU T_OLD_3+2
T_NEW_0	.EQU T_OLD_0
T_NEW_1	.EQU T_OLD_1
T_NEW_2	.EQU T_NEW_0+24
T_NEW_3	.EQU T_OLD_3

PT2EMPTYORN .EQU VT_+31	;1,0,0 sequence

NT_	.FILL 192	;CreatedNoteTableAddress

;local var
Ampl	.EQU AYREGS+AmplC

VAR0END	.EQU VT_+16 ;INIT zeroes from VARS to VAR0END-1

VARSEND .EQU $

MDLADDR .EQU $
;
;===============================================================================
; MYM Player Storage
;===============================================================================
;
	.ORG	HEAP
; Reserve room for uncompressed data
uncomp:
.org $+(3*FRAG*REGS)

; The tune is stored here
rows:   .dw     0
data:
;
;===============================================================================
	.END

