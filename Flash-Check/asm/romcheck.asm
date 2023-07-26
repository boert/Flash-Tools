
;---------------------------------------- 

PV1:    EQU     0F003h	; Sprungverteiler


; CAOS Funktionsnummern
; bzw. Unterprogramme
CRT:    EQU     000h
KBD:    EQU     004h
KBDS:	EQU	00Ch
BYE:    EQU     00Dh
KBDZ:	EQU	00Eh
COLORUP:EQU	00Fh
LOOP:	EQU	012h
ERRM:	EQU	019h
HLHX:	EQU	01Ah
AHEX:	EQU	01Ch
OSTR:   EQU     023h
MODU:	EQU	026h
SPACE:	EQU	02Bh
CRLF:	EQU	02Ch
HOME:	EQU	02Dh
PADR:	EQU	034h
WININ:	EQU	03Ch
WINAK:	EQU	03Dh
LINE:	EQU	03Eh
CSTBT:	EQU	042h
ZKOUT:  EQU     045h

; Sonderzeichen
CLL:	EQU	002h	; clear line
BREAK:	EQU	003h
CUL:	EQU	008h	; cursor left
CUR:	EQU	009h
CUD:    EQU     00Ah
LF:     EQU     00Ah
CUU:    EQU     00Bh
CLS:    EQU     00Ch
CR:     EQU     00Dh
STOP:	EQU	013h
ESC:	EQU	01Bh
SPC:	EQU	020h

; VRAM-Zellen
VRAM:   EQU     08000h
ARGN:   EQU     0B781h
ARG1:	EQU	0B782h
ARG2:	EQU	0B784h
ARG3:	EQU	0B786h
ARG4:	EQU	0B788h
CURSO:  EQU     0B7A0h
STBT:	EQU	0B7A2h
COLOR:	EQU	0B7A3h
NCAOS:	EQU	0B7B4h
FARB:	EQU	0B7D6h

;---------------------------------------- 

PROGADR: EQU 0200h

;KCC-Header
        ORG PROGADR - 080h
        DB	"ROMCHECK"

	ds      PROGADR - 070h - $
	ORG	PROGADR - 070h

        DB	3	    ; Argumente (3 = Autostart)
        DW	KCCBEGIN    ; Loadadresse
        DW	KCCEND      ; Endadress(+1)
        DW	START       ; Startadresse

        DS	9
        DB	"fuer KC85/4/5; "
        DB	"B. Lange; "
        DB	"07/2023"


;ALIGN1	EQU	128 - (($+128) MOD 128) ; pasmo
	ds      PROGADR - $
	ORG PROGADR	
KCCBEGIN:

	; -------------------- 
        ; Menüwort 1
        DW	07F7Fh
        DB	"SUM"
        DB	01h
	
	; A = ARGN (0..3)
	; HL = ARG1
	; DE = ARG2
	; BC = ARG3

	; Abfrage: kleiner 2 (=0 oder =1)
	CP	2
	JR	C, SUMHELP

	; Abfrage: ungleich 2 (=3)
	JR	NZ, SUMRUN
	LD      BC, 00000h  ; Startwert (wird nach DE getauscht)
SUMRUN:
	; Austausch BC, DE
	LD	A, B
	LD	B, D
	LD	D, A

	LD	A, C
	LD	C, E
	LD	E, A

        CALL    CHSUM
        EX      DE, HL      ; Ergenbis nach HL

        CALL    PV1
        DB      HLHX
        CALL    PV1
        DB      CRLF

	RET

SUMHELP:
        LD	HL, MSGSUMHELP
	CALL	PV1
	DB	ZKOUT

	RET


	; -------------------- 
        ; Menüwort 2
        DW	07F7Fh
        DB	"CRC"
        DB	01h

	; Abfrage: kleiner 2 (=0 oder =1)
	CP	2
	JR	C, CRCHELP

	; Abfrage: ungleich 2 (=3)
	JR	NZ, CRCRUN
	LD      BC, 0FFFFh ; Startwert (wird nach DE getauscht)
CRCRUN:
	; Austausch BC, DE
	LD	A, B
	LD	B, D
	LD	D, A

	LD	A, C
	LD	C, E
	LD	E, A

	CALL	CRCSUM
        EX      DE, HL      ; Ergenbis nach HL

        CALL    PV1
        DB      HLHX
        CALL    PV1
        DB      CRLF

	RET

CRCHELP:
        LD	HL, MSGCRCHELP
	CALL	PV1
	DB	ZKOUT

	RET


	; -------------------- 
        ; Menüwort 3
        DW	07F7Fh
        DB	"MODSEARCH"
        DB	01h

	LD	L, 0	; Startwert für Slot
	
NEXTSLOT:
	CALL	CLRLINE 

	LD	A, L
	; Schacht ausgeben
	CALL	PV1
	DB	AHEX
	
	CALL	PV1
	DB	SPACE

	XOR	A
        
	CALL    PV1
        DB      MODU

	; auf 0xFF prüfen
	LD	A, H
	SUB	0xFF
	JR	Z, CHKNEXT

	; Strukturbyte ausgeben
	LD	A, H
	CALL	PV1
	DB	AHEX
	
	CALL	PV1
	DB	SPACE
	
	LD	A, H
	CALL	MOD_ID

	CALL	PV1
	DB	CRLF
	

CHKNEXT:

	INC	L
	LD	A, L
	SUB	0xFF	; Endwert für Slot
	JR	NZ, NEXTSLOT

	CALL	CLRLINE 
	RET

        ; Menüwort 4
        DW	07F7Fh
        DB	"ROMCHECK"
        DB	01h
START:
        ; Parameter
        ;  A = ARGN
        ; HL = ARG1 L=Modulschacht
        ; DE = ARG2
        ; BC = ARG3
        
        push    HL
        push    AF
        ; Ausgabe Titel
        LD	HL, MSGSTART
        CALL	PV1
        DB	ZKOUT
        LD	HL, BUILDSTR
        CALL	PV1
        DB	ZKOUT
        LD	HL, MSGSLOT
        CALL	PV1
        DB	ZKOUT
        pop     AF
        pop     HL

        ; Anzahl Parameter (A) prüfen
        OR      A
        JR      Z, SLOT8
        LD      A, L
        JR      SLOTRDY

SLOT8:
        LD      A, 8
SLOTRDY:
        ; Modulschacht
        LD      (SLOT), A
        CALL    PV1
        DB      AHEX
        
        ; Ausgabe Header
	LD	HL, MSGHEADER
        CALL	PV1
        DB	ZKOUT

	; Prüfsummen über die einzelnen Segmente
        LD      b, 16       ; Zähler
        LD      c, 0        ; Segmentnummer
MLOOP:
        push    bc
        call    SET_SEGMENT
        
	; Zeile freimachen
	CALL	CLRLINE 
	; Steuerbyte ausgeben
	CALL    PV1
        DB      AHEX
        CALL    PV1
        DB      SPACE
        
        LD      HL, 0C000h  ; Startadresse
        LD      BC, 02000h  ; Anzahl
	LD      DE, 00000h  ; Startwert
        CALL    CHSUM
        EX      de, hl      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      SPACE
        
        LD      HL, 0C000h  ; Startadresse
        LD      BC, 02000h  ; Anzahl
	LD	DE, 0FFFFh  ; Startwert
        CALL    CRCSUM
        EX      de, hl      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      CRLF

        pop     bc
        inc     c
        djnz    MLOOP


	; Prüfsumme SUM über alle Segmente
	LD	HL, MSGSUM
        CALL	PV1
        DB	ZKOUT

        LD      b, 16       ; Zähler
        LD      c, 0        ; Segmentnummer
	LD      DE, 00000h  ; Startwert
MLOOP2:
        PUSH    BC

	call	FIX_CURSO
        call    SET_SEGMENT
        
	; Steuerbyte ausgeben
	CALL    PV1
        DB      AHEX
        
        LD      HL, 0C000h  ; Startadresse
        LD      BC, 02000h  ; Anzahl
        CALL    CHSUM

        POP     BC
        INC     C
        djnz    MLOOP2

        EX      DE, HL      ; Ergenbis nach HL

	call	FIX_CURSO
        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      CRLF
        
	; Prüfsumme CRC über alle Segmente
	LD	HL, MSGCRC
        CALL	PV1
        DB	ZKOUT

        LD      b, 16       ; Zähler
        LD      c, 0        ; Segmentnummer
	LD      DE, 0FFFFh  ; Startwert
MLOOP3:
        PUSH    BC

	call    FIX_CURSO
        call    SET_SEGMENT
        
	; Steuerbyte ausgeben
	CALL    PV1
        DB      AHEX
        
        LD      HL, 0C000h  ; Startadresse
        LD      BC, 02000h  ; Anzahl
        CALL    CRCSUM

        POP     BC
        INC     C
        djnz    MLOOP3

        EX      DE, HL      ; Ergenbis nach HL

	call	FIX_CURSO
        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      CRLF
	CALL	CLRLINE 

        ; Modul abschalten
        LD      HL, SLOT
        LD      D, 0        ; Steuerbyte
        LD      L, (HL)     ; Steckplatz
        LD      A, 2
        CALL    PV1
        DB      MODU

        RET     ; zum CAOS

        ; Parameter
        ; HL = Startadresse
        ; BC = Laenge
	; DE = Startwert
        ; Ergebnis -> DE
CHSUM:

	; Vorbereitung Schleifenzähler
	; für schnelle Zählroutine
	ld   a, c
	dec  bc
	inc  b
	ld   c, b
	ld   b, a

CHSUM_LP:
        ld      a, e
        add     a, (hl)
        jr      nc, CHSUM_DEC
        inc     d
CHSUM_DEC:
        ld      e, a
        inc     hl         ; Addresse++
        djnz    CHSUM_LP
	dec     c
        jr      nz, CHSUM_LP
        ret
        
                    

        ; Parameter
        ; HL = Startadresse
        ; BC = Laenge
	; DE = Startwert
        ; Ergebnis -> DE
CRCSUM:
        ; Vorbereitung Schleifenzähler, Alternative ohne Modifikation DE
				; A  F  B  C   D  E   H  L
				;       Lh Ll         Sh Sl	; Start
	ld   a, c		; Ll    Lh Ll
	dec  bc			;       Mh Ml
	inc  b                  ;       Nh Ml
	ld   c, b               ;          Nh
	ld   b, a               ;       Ll


        ;ld   de, 0ffffh ; Startwert
CRCSUM_LP:
        ld   a, (hl)    ; Byte laden
        xor  d          
        ld   d, a       ; D = D xor Byte
        rrca            ; rotate accumulator right with branch carry
        rrca            ; CY = Bit 0
        rrca            ; 76543210 becomes 32107654
        rrca
        and  0fh        ; mask bits ____7654
        xor  d
        ld   d, a       ; D = D xor high nibble( Byte)
        rrca
        rrca
        rrca
        push af
        and  1fh
        xor  e
        ld   e, a
        pop  af
        push af
        rrca
        and  0f0h
        xor  e
        ld   e, a
        pop  af
        and  0e0h
        xor  d
        ld   d, e       ; Ergebnis nach DE
        ld   e, a
        inc  hl         ; Addresse++
	djnz CRCSUM_LP
        ;dec  bc         ; Laenge--
        ;or   c          ; pruefen auf BC = 0
	dec   c
        jr   nz, CRCSUM_LP
        ret

        ; Parameter:
        ;   C - Segmentnummer  
	; Rückgabe:
	;   A - Steuerbyte
SET_SEGMENT:
        LD      B, 0
        LD	HL, MODCTRL
        ADD	HL, BC
        LD	A, (HL)	    ; Steuerbyte

	push	af
	push	de
        LD      HL, SLOT
        LD      D, A        ; Steuerbyte
        LD      L, (HL)     ; Steckplatz
        LD      A, 2
        CALL    PV1
        DB      MODU
	pop	de
	pop	af
        RET

FIX_CURSO:
	; Cursorposition korrigieren
	PUSH    HL
	LD	HL, CURSO
	LD	A, (HL)
	DEC	A
	DEC	A
	LD	(HL), A
	POP	HL
	RET


	; Zeile freimachen
CLRLINE:
	PUSH	AF
	LD	A, CLL	    ; clear line
	CALL	PV1
	DB	CRT
	POP	AF
	RET

	; Modulkennung im Klartext
	; ausgeben
MOD_ID:
	PUSH	HL
        LD	HL, MSGUNKOWN

	CP	0x72
	JR	NZ, MOD_ID_1
        LD	HL, MSG_72
	JR	MOD_OUT

MOD_ID_1:
	CP	0xF7
	JR	NZ, MOD_ID_2
        LD	HL, MSG_F7
	JR	MOD_OUT

MOD_ID_2:
	CP	0xF8
	JR	NZ, MOD_ID_3
        LD	HL, MSG_F8
	JR	MOD_OUT

MOD_ID_3:
	CP	0xFB
	JR	NZ, MOD_ID_4
        LD	HL, MSG_FB
	JR	MOD_OUT

MOD_ID_4:
	CP	0xFC
	JR	NZ, MOD_ID_5
        LD	HL, MSG_FC
	JR	MOD_OUT

MOD_ID_5:
	CP	0xFD
	JR	NZ, MOD_ID_6
        LD	HL, MSG_FD
	JR	MOD_OUT

MOD_ID_6:
	CP	0x01
	JR	NZ, MOD_ID_7
        LD	HL, MSG_01
	JR	MOD_OUT

MOD_ID_7:
MOD_OUT:
	CALL	PV1
	DB	ZKOUT
	POP	HL
	RET

MSGUNKOWN:
	DB	"--", 0
MSG_01:	DB	"Autostart", 0
MSG_72:	DB	"ROM  8k*16", 0
MSG_F7:	DB	"ROM  8k* 1", 0
MSG_F8:	DB	"ROM 16k* 1", 0
MSG_FB:	DB	"ROM  8k* 1", 0
MSG_FC:	DB	"ROM 16k* 1", 0
MSG_FD:	DB	"ROM  8k* 4", 0

PAR_8_1:
	DB	8	; kByte
	DW	1	; Anzahl
	DB	0	; Shift

PAR_8_2:
	DB	8	; kByte
	DW	2	; Anzahl
	DB	4	; Shift

PAR_8_4_3:
	DB	8	; kByte
	DW	4	; Anzahl
	DB	3	; Shift

PAR_8_4_4:
	DB	8	; kByte
	DW	4	; Anzahl
	DB	4	; Shift

PAR_8_8:
	DB	8	; kByte
	DW	8	; Anzahl
	DB	3	; Shift

PAR_8_16:
	DB	8	; kByte
	DW	16	; Anzahl
	DB	2	; Shift

PAR_16_1:
	DB	16	; kByte
	DW	1	; Anzahl
	DB	0	; Shift

PAR_16_16:
	DB	16	; kByte
	DW	16	; Anzahl
	DB	2	; Shift
        

MODBASE:EQU	0C0h		; Modul-Basisadresse
MODCTRL:	
	DB	MODBASE + 001h, MODBASE + 005h
	DB	MODBASE + 009h, MODBASE + 00Dh
        DB	MODBASE + 011h, MODBASE + 015h
        DB	MODBASE + 019h, MODBASE + 01Dh
        DB	MODBASE + 021h, MODBASE + 025h
        DB	MODBASE + 029h, MODBASE + 02Dh
        DB	MODBASE + 031h, MODBASE + 035h
        DB	MODBASE + 039h, MODBASE + 03Dh

SLOT:   DB  0

MSGSTART:
        DB      CLL
	DB	"ROM-checker", CR, LF, CLL, 0
MSGSLOT:  
	DB      CR, LF, CLL
	DB      "Slot: ", 0

MSGHEADER:
        DB      CR, LF, CLL
	DB	"CB SUM   CRC"   
        DB      CR, LF, CLL
	DB      "-- ----  ----"
	DB      CR, LF, CLL, 0
MSGSUM:   
        DB      CLL
	DB	"SUM 00" , 0
MSGCRC:   
        DB      CLL
	DB	"CRC 00" , 0

MSGSUMHELP:
        DB      CLL
	DB	"SUM SADDR LENGTH (START_VALUE)"
	DB      CR, LF, CLL, 0

MSGCRCHELP:
        DB      CLL
	DB	"CRC SADDR LENGTH (START_VALUE)"
	DB      CR, LF, CLL, 0

include "date.inc"

	; fill up with 0xff
;ALIGN2:	EQU	128 - (($+128) % 128)
	;DS	ALIGN2, 0xff
	; jeweils 128 (0x80) hinzufügen, bei asm-Fehler
	ds	0x580 - $
KCCEND:

; vim: set tabstop=8 noexpandtab:
