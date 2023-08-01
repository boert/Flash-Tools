
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
DABR:	EQU	032h
PADR:	EQU	034h
WININ:	EQU	03Ch
WINAK:	EQU	03Dh
LINE:	EQU	03Eh
CSTBT:	EQU	042h
ZKOUT:  EQU     045h
HLDEZ:	EQU	04Ah

; Sonderzeichen
BCLR:	EQU	001h	; Backspace clear
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

        DB	2	    ; Argumente (3 = Autostart)
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


	;------------------------------
        ; Menüwort 3
        DW	07F7Fh
        DB	"ROMSEARCH"
        DB	01h

	LD	C, 0	; Startwert für Slot
	
NEXTSLOT:
	PUSH	BC
	CALL	CLRLINE 

	LD	A, C
	; Schacht ausgeben
	CALL	PV1
	DB	AHEX
	
	CALL	PV1
	DB	SPACE

	LD	L, C
	XOR	A
        
	CALL    PV1
        DB      MODU

	; auf 0xFF prüfen
	; 0xFF = kein Modul
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

	LD	H, (IY + PAR_MSGH)
	LD	L, (IY + PAR_MSGL)

	CALL	PV1
	DB	ZKOUT

	; kein ROM oder Autostart
	LD	A, (IY + PAR_STRUCT)
	CP	2
	JR	C, CHKNEXTCR


	; Segmentanzahl
	LD	H, (IY + PAR_SEGMENTSH)
	LD	L, (IY + PAR_SEGMENTSL)
	CALL	DispHL

	; mal
	LD	A, '*'
	CALL	PV1
	DB	CRT


	; Segmentgröße
	LD	A, (IY + PAR_SEGSIZE)
	LD	H, 0
	LD	L, A
	CALL	DispHL

	LD	A, 'k'
	CALL	PV1
	DB	CRT

	CALL	PV1
	DB	SPACE
    
	; Klammer auf
	LD	A, '('
	CALL	PV1
	DB	CRT
	
	; Speichergröße
	LD	D, (IY + PAR_SEGMENTSH)
	LD	E, (IY + PAR_SEGMENTSL)
	LD	A, (IY + PAR_SEGSIZE)

	CALL	mult_a_de
	CALL	DispHL

	LD	A, 'k'
	CALL	PV1
	DB	CRT

	; Klammer zu
	LD	A, ')'
	CALL	PV1
	DB	CRT

CHKNEXTCR:
	CALL	PV1
	DB	CRLF

CHKNEXT:
	POP	BC
	INC	C
	LD	A, C
	CP 	0xFF	; Endwert für Slot
	JP	NZ, NEXTSLOT

	CALL	CLRLINE 
	RET


	;------------------------------
        ; Menüwort 4
        DW	07F7Fh
        DB	"ROMCHECK"
        DB	01h
START:
        ; Parameter
        ;  A = ARGN A=Anzahl
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

	; Strukturbyte lesen
	LD	A, (SLOT)
	LD	L, A
	XOR	A
        
	CALL    PV1
        DB      MODU

	; auf 0xFF prüfen
	; 0xFF = kein Modul
	LD	A, H
	CP	0xFF
	JP	Z, NOMOD
	
	; Strukturbyte suchen/prüfen
	CALL	MOD_ID
	
	; Strukturbyte ausgeben
	LD	HL, MSGSTRUCT
	CALL	PV1
	DB	ZKOUT

	LD	A, (IY + PAR_STRUCT)
	CALL	PV1
	DB	AHEX

        ; Modultyp
        LD	HL, MSGTYP
        CALL	PV1
        DB	ZKOUT

        LD	H, (IY + PAR_MSGH)
        LD	L, (IY + PAR_MSGL)
        CALL	PV1
        DB	ZKOUT

	; kein ROM-Modul
	LD	A, (IY + PAR_STRUCT)
	CP	1
	JP	C, NOROMMOD

        ; Segmentgröße
        LD	HL, MSGSEGSIZE
        CALL	PV1
        DB	ZKOUT

        LD	A, (IY + PAR_SEGSIZE)
	; auf 0 prüfen
	OR	A
	JR	Z, INPUT_SEGSIZE

	; ausgeben
	LD	H, 0
        LD	L, A
        CALL	DispHL
	JR	INPUT_SEGSIZE2

	; eingeben
INPUT_SEGSIZE:
	LD	A, 2		; zwei Stellen
	CALL	INPUT_DECIMAL

	; abspeichern
	LD	A, L
	LD	(IY + PAR_SEGSIZE), A

INPUT_SEGSIZE2:
        LD	A, 'k'
        CALL	PV1
        DB	CRT

        ; Zahl der Segemente
        LD	HL, MSGSEGMENTS
        CALL	PV1
        DB	ZKOUT

        LD	H, (IY + PAR_SEGMENTSH)
        LD	L, (IY + PAR_SEGMENTSL)
	
	; auf 0 prüfen
	LD	A, L
	ADD	H
	OR	A
	JR	Z, INPUT_SEGMENTS

	; ausgeben
        CALL	DispHL
	JR	INPUT_SEGMENTS2

	; eingeben
INPUT_SEGMENTS:
	LD	A, 4	; Anzahl Stellen (1024)
	CALL	INPUT_DECIMAL

	; abspeichern
        LD	(IY + PAR_SEGMENTSH), H
        LD	(IY + PAR_SEGMENTSL), L

INPUT_SEGMENTS2:

	CALL	PV1
	DB	CRLF
	CALL	CLRLINE


        LD	A, (IY + PAR_OFFSET)
	; auf 0 prüfen
	OR	A
	JR	NZ, OFFSET_SHIFT_OK

        LD	HL, MSGOFFSET
        CALL	PV1
        DB	ZKOUT

	LD	A, 2		; zwei Stellen
	CALL	INPUT_HEX

	; abspeichern
	LD	A, L
	LD	(IY + PAR_OFFSET), A

	; Shift noch eingeben
        LD	HL, MSGSHIFT
        CALL	PV1
        DB	ZKOUT

	LD	A, 1		; zwei Stellen
	CALL	INPUT_DECIMAL

	; abspeichern
	LD	A, L
	LD	(IY + PAR_SHIFT), A

OFFSET_SHIFT_OK:


	; mehr als 1 Segment?
	; (weniger als 2 Segmente)
	LD	A, (IY + PAR_SEGMENTSL)
	CP	2
	JR      C, NOSINGLE

        ; Ausgabe Header
	LD	HL, MSGHEADER
        CALL	PV1
        DB	ZKOUT

	; Prüfsummen über die einzelnen Segmente
	LD	B, (IY + PAR_SEGMENTSH)
	LD	C, (IY + PAR_SEGMENTSL)
	LD	DE, 0	; Index
	LD	(INDEX), DE
MLOOP:
        PUSH    BC
        
	; Zeile freimachen
	CALL	CLRLINE 
	
	; Index ausgeben
	LD	HL, (INDEX)
	CALL	PRINT_HL8_16
	
	; Index zu Steuerbyte (und aktivieren)
        call    SET_SEGMENT

	; Steuerbyte ausgeben
	CALL	PRINT_HL8_16

        CALL    PV1
        DB      SPACE
        
        LD      HL, 0C000h  ; Startadresse
	CALL	CALC_LENGTH ; Anzahl
	LD      DE, 00000h  ; Startwert
        CALL    CHSUM
        EX      DE, HL      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        
        LD      HL, 0C000h  ; Startadresse
	CALL	CALC_LENGTH ; Anzahl
	LD	DE, 0FFFFh  ; Startwert
        CALL    CRCSUM
        EX      DE, HL      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      CRLF

        POP     BC
	
	; Index erhöhen
	LD	HL, (INDEX)
	INC	HL
	LD	(INDEX), HL

        DEC	BC
	LD	A, B
	OR	C

        JR	NZ, MLOOP


NOSINGLE:

	; Prüfsumme SUM über alle Segmente
	LD	HL, MSGSUM
        CALL	PV1
        DB	ZKOUT

	LD	B, (IY + PAR_SEGMENTSH)
	LD	C, (IY + PAR_SEGMENTSL)
	LD	DE, 0	    ; Index
	LD	(INDEX), DE
	LD      DE, 00000h  ; Startwert
MLOOP2:
        PUSH    BC

	call	FIX_CURSO
	LD	HL, (INDEX)
        call    SET_SEGMENT
        
	; Steuerbyte ausgeben
	CALL    PV1
        DB      HLHX
        
        LD      HL, 0C000h  ; Startadresse
	CALL	CALC_LENGTH ; Anzahl
        CALL    CHSUM

        POP     BC
	
	; Index erhöhen
	LD	HL, (INDEX)
	INC	HL
	LD	(INDEX), HL
        
	; Schleifenzähler
	DEC	BC
	LD	A, B
	OR	C
        JR	NZ, MLOOP2

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

	LD	B, (IY + PAR_SEGMENTSH)
	LD	C, (IY + PAR_SEGMENTSL)
	LD	DE, 0	    ; Index
	LD	(INDEX), DE
	LD      DE, 0FFFFh  ; Startwert
MLOOP3:
        PUSH    BC

	call    FIX_CURSO
	LD	HL, (INDEX)
        call    SET_SEGMENT
        
	; Steuerbyte ausgeben
	CALL    PV1
        DB      HLHX
        
        LD      HL, 0C000h  ; Startadresse
	CALL	CALC_LENGTH ; Anzahl
        CALL    CRCSUM

        POP     BC
	
	; Index erhöhen
	LD	HL, (INDEX)
	INC	HL
	LD	(INDEX), HL

	; Schleifenzähler
        DEC	BC
	LD	A, B
	OR	C
        JR	NZ, MLOOP3

        EX      DE, HL      ; Ergenbis nach HL

	CALL	FIX_CURSO
        CALL    PV1         ; ausgeben
        DB      HLHX

	; CRC suchen und Zeichenkette ausgeben
	CALL	SEARCH_CRC
        CALL    PV1
        DB      ZKOUT

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

	; alternatives Ende
NOMOD:
	LD	HL, MSGNOMODUL
        CALL	PV1
        DB	ZKOUT
	
	; 2. alternatives Ende
NOROMMOD:
	CALL	PV1
	DB	CRLF
	CALL	CLRLINE
	
	RET

	; Anzahl/Länge aus Segmentgröße
	; berechnen
	; Parameter
	; IY = Zeiger auf genutzte Struktur
	; Rückgabe
	; BC = Anzahl der Bytes
CALC_LENGTH:
	PUSH	HL
	PUSH	DE
        LD	B, (IY + PAR_SEGSIZE)
	LD	HL, 0
	LD	DE, 1024

CALC_NEXT:
	ADD	HL, DE
	DJNZ	CALC_NEXT

	LD	B, H
	LD	C, L

	POP	DE
	POP	HL
	RET

	; Abschalten vom CAOS-ROM
CAOS_OFF:
	DI
	; PIO A, 88H, Bit 0 löschen
	IN	A,(88H)
	AND	7EH
	OUT	(88H), A
	RET

	; Anschalten vom CAOS-ROM
CAOS_ON:
	; PIO A, 88H, Bit 0 setzen
	IN	A,(88H)
	OR 	01H
	OUT	(88H), A
	EI
	RET

	; Eingabe einer Zahl
	; Parameter
	; A = max. Anzahl Stellen
	; Rückgabe
	; HL -> Dezimalzahl
	; CY = 1 -> Abbruch
	
	; ESC		Abbruch
	; STOP		Abbruch
	; Ctrl-C	Abbruch
	; Enter		Umwandlung
	; Ziffern	Eingabe
	; CUL		= Backspace
	; Backspace	= Backspace
INPUT_DECIMAL:
	
	LD	C, A	; noch Stellen
	LD	B, 0	; Position

        ; auf Taste warten
IN_DEC_KEYIN:
	CALL 	PV1
        DB 	KBD

	CP	ESC
	JR	Z, IN_DEC_END

	CP	BREAK
	JR	Z, IN_DEC_END

	CP	STOP
	JR	Z, IN_DEC_END

	CP	CR
	JR	Z, IN_DEC_DECODE


	CP	CUL
	JR	Z, IN_DEC_CLRBS

	CP	BCLR
	JR	Z, IN_DEC_CLRBS


	CP	'0'
	JR	C, IN_DEC_KEYIN

	CP	'9'+1
	JR	NC, IN_DEC_KEYIN

	; Anzahl prüfen
	LD	D, A
	LD	A, C
	OR	A
	LD	A, D
	JR	Z, IN_DEC_KEYIN

	INC	B
	DEC	C

	; endlich Zeichen ausgeben
	CALL	PV1
	DB	CRT

	JR	IN_DEC_KEYIN

IN_DEC_CLRBS:
	; Position prüfen
	LD	A, B
	OR	A
	JR	Z, IN_DEC_KEYIN

	INC	C
	DEC	B

	LD	A, BCLR
	CALL	PV1
	DB	CRT

	JR	IN_DEC_KEYIN

IN_DEC_DECODE:  
	; Cursor auf Anfang der Eingabe stellen
	PUSH	BC
	
	LD	A, CUL
IN_DEC_FIXC:	
	CALL	PV1
	DB	CRT

	DJNZ	IN_DEC_FIXC
	
	POP	BC

	; vorbereiten
	LD	HL, 0	; Ergebnis
	LD	D, 0	; Hi-Teil für Addition

IN_DEC_NEXT_DIGIT:
	CALL	MUL_HL_10

	CALL	READ_CHAR

	LD	E, A
	ADD	HL, DE

	; nach rechts rücken
	LD	A, CUR
	CALL	PV1
	DB	CRT

	DJNZ	IN_DEC_NEXT_DIGIT

	SCF
	CCF
	RET

IN_DEC_END:
	SCF
	RET



	; Eingabe einer Zahl
	; Parameter
	; A = max. Anzahl Stellen
	; Rückgabe
	; HL -> Hexadezimalzahl
	; CY = 1 -> Abbruch
	
	; ESC		Abbruch
	; STOP		Abbruch
	; Ctrl-C	Abbruch
	; Enter		Umwandlung
	; Ziffern	Eingabe
	; A-F    	Eingabe
	; a-f    	Eingabe
	; CUL		= Backspace
	; Backspace	= Backspace
INPUT_HEX:
	
	LD	C, A	; noch Stellen
	LD	B, 0	; Position

        ; auf Taste warten
IN_HEX_KEYIN:
	CALL 	PV1
        DB 	KBD

	CP	ESC
	JR	Z, IN_HEX_END

	CP	BREAK
	JR	Z, IN_HEX_END

	CP	STOP
	JR	Z, IN_HEX_END

	CP	CR
	JR	Z, IN_HEX_DECODE


	CP	CUL
	JR	Z, IN_HEX_CLRBS

	CP	BCLR
	JR	Z, IN_HEX_CLRBS


	CP	'0'
	JR	C, IN_HEX_KEYIN

	CP	'F'+1
	JR	NC, IN_HEX_KEYIN

	; Anzahl prüfen
	LD	D, A
	LD	A, C
	OR	A
	LD	A, D
	JR	Z, IN_HEX_KEYIN

	INC	B
	DEC	C

	; endlich Zeichen ausgeben
	CALL	PV1
	DB	CRT

	JR	IN_HEX_KEYIN

IN_HEX_CLRBS:
	; Position prüfen
	LD	A, B
	OR	A
	JR	Z, IN_HEX_KEYIN

	INC	C
	DEC	B

	LD	A, BCLR
	CALL	PV1
	DB	CRT

	JR	IN_HEX_KEYIN

IN_HEX_DECODE:  
	; Cursor auf Anfang der Eingabe stellen
	PUSH	BC
	
	LD	A, CUL
IN_HEX_FIXC:	
	CALL	PV1
	DB	CRT

	DJNZ	IN_HEX_FIXC
	
	POP	BC

	; vorbereiten
	LD	HL, 0	; Ergebnis
	LD	D, 0	; Hi-Teil für Addition

IN_HEX_NEXT_DIGIT:
	CALL	MUL_HL_16

	CALL	READ_CHAR

	LD	E, A
	ADD	HL, DE

	; Cursor nach rechts rücken
	LD	A, CUR
	CALL	PV1
	DB	CRT

	DJNZ	IN_HEX_NEXT_DIGIT

	SCF
	CCF
	RET

IN_HEX_END:
	SCF
	RET


	; liest ASCII Zeichen von
	; Cursorposition
	; Umwandlung in dez. bzw. hex-Wert
READ_CHAR:
	PUSH	HL
	PUSH	DE

	LD	HL, CURSO
	LD	E, (HL)
	INC	HL
	LD	D, (HL)

	CALL	PV1	; D = Zeile, E = Spalte
	DB	DABR	; HL = ASCII-Addr

	LD	A, (HL)

	CP	'A'
	JR	C, RC_DIGIT

	; Buchstaben
	RES	5, A	; Klein -> Großbuchstaben
	SUB	7	; hinter 9 schieben

RC_DIGIT:	
	SUB	'0'

	POP	DE
	POP	HL
	RET

	; multipliziert HL
	; mit 10
MUL_HL_10:
	PUSH	DE

	LD	D, H
	LD	E, L

	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, DE
	ADD	HL, DE

	POP	DE
	RET

MUL_HL_16:
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	RET

	;------------------------------
        ; Parameter
        ; HL = Startadresse
        ; BC = Laenge
	; DE = Startwert
        ; Ergebnis -> DE
CHSUM:
	CALL	CAOS_OFF

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
	CALL	CAOS_ON
        ret
        
                    

	;------------------------------
        ; Parameter
        ; HL = Startadresse
        ; BC = Laenge
	; DE = Startwert
        ; Ergebnis -> DE
CRCSUM:
	CALL	CAOS_OFF
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
	dec   c
        jr   nz, CRCSUM_LP
	CALL	CAOS_ON
        ret

	;------------------------------
        ; Parameter:
        ;   HL - Segmentnummer  
	; Rückgabe:
	;   HL - Steuerbyte
SET_SEGMENT:
	PUSH	AF
	PUSH    BC
	PUSH	DE

	LD	B, (IY + PAR_SHIFT)

	; shiften
SHIFT_NEXT:
	LD	A, B
	OR	A
	JR	Z, SHIFT_READY
	DEC	B
	LD	A, C 	; Segmentnummer
	SLA	L
	RL      H
	JR	SHIFT_NEXT
SHIFT_READY:
	; und Offset addieren
	LD	B, 0
	LD	C, (IY + PAR_OFFSET)
	ADD	HL, BC
	; jetzt Steuerbyte in HL

	; und Modul schalten
	PUSH	HL

        LD      D, L        ; Steuerbyte
        LD      HL, SLOT
        LD      L, (HL)     ; Steckplatz
        LD      A, 2
        CALL    PV1
        DB      MODU


	POP	HL
	POP	DE

	; zusätzliches Steuerbyte
        LD      A, (SLOT)     ; Steckplatz
	LD	B, A
	LD	C, 081h

	LD	A, L
	OUT	(C), A

	POP	BC
	POP	AF
	RET


	;------------------------------
	; Cursorposition korrigieren
FIX_CURSO:
	PUSH    HL
	LD	HL, CURSO
	LD	A, (HL)
	SUB	A, 5
	LD	(HL), A
	POP	HL
	RET

	;------------------------------
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
	; Parameter
	; A - Strukturbyte
	; Ergebnis
	; IY - Zeiger auf Modulstruktur
MOD_ID:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	DE, PAR_SIZE
	LD	IY, PAR_LIST

NEXT_ID:
	CP	(IY + 0)
	JR	Z, ID_FOUND
	
	; letzter Eintrag?
	LD	B, A
	LD	A, (IY + 0)
	OR	A
	CP	0
	LD	A, B
	JR	Z, ID_FOUND

	ADD	IY, DE
	JR	NEXT_ID

ID_FOUND:
	; alles nach PARSET umkopieren
	PUSH	IY
	POP	HL
	LD	DE, PARSET
	LD	BC, PAR_SIZE
	LDIR
	LD	HL, PARSET
	PUSH	HL
	POP	IY

	POP	BC
	POP	DE
	POP	HL
	RET


;------------------------------
; Multiplikation 8 Bit * 16 Bit
; https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Multiplication#16.2A8_multiplication
mult_a_de:
        ld	c, 0
        ld	h, c
        ld	l, h
     
        add	a, a		; optimised 1st iteration
        jr	nc, $+4
        ld	h,d
        ld	l,e
     
        ld b, 7
m_loop:
        add	hl, hl
        rla
        jr	nc, $+4
        add	hl, de
        adc	a, c            ; yes this is actually adc a, 0 but since c is free we set it to zero and so we can save 1 byte and up to 3 T-states per iteration
        
        djnz	m_loop
        
        ret
	
	;------------------------------
	; Ausgabe HL als 8 oder 16-Bit-Zahl
	; Parameter
	; HL = Hexwert
PRINT_HL8_16:
	PUSH	AF

	LD	A, H
	OR	A
	JR	NZ, HL16


	CALL	PV1
	DB	SPACE

	CALL	PV1
	DB	SPACE
	
	LD	A, L

	CALL	PV1
	DB	AHEX

	CALL	PV1
	DB	SPACE
HL_END:
	POP	AF
	RET
HL16:
	CALL	PV1
	DB	HLHX
	JR	HL_END

	;------------------------------
	; Ausgabe HL als Dezimalzahl
	; Erweitert: Vornullen werden unterdrückt und Register gesichert
	;https://wikiti.brandonw.net/index.php?title=Z80_Routines:Other:DispHL
	;Number in hl to decimal ASCII
	;Thanks to z80 Bits
	;inputs:	hl = number to ASCII
	;example: hl=300 outputs '00300'
	;destroys: af, bc, hl, de used
DispHL:
	PUSH	AF
	PUSH	HL
	PUSH	BC
	PUSH	DE
	CALL	disprun
	; wenn B = 0 (= nix ausgegeben)
	ld	a, b
	or	a
	jr	nz, Disp_rdy
	; dann eine 0 ausgeben
	ld	a, '0'
	CALL	PV1
	DB	CRT
Disp_rdy:
	POP	DE
	POP	BC
	POP	HL
	POP	AF
	RET

disprun:
	ld	b, 0
	ld	de,-10000
	call	Num1
	ld	de,-1000
	call	Num1
	ld	de,-100
	call	Num1
	ld	e,-10
	call	Num1
	ld	e,-1
Num1:	ld	a,'0'-1
Num2:	inc	a
	add	hl,de
	jr	c,Num2
	sbc	hl,de
	
	cp	'0'
	ret	z
	inc	b

	CALL	PV1
	DB	CRT
	ret 

	
	;------------------------------
	; Suche nach passendem CRC in Liste
	; Parameter
	; HL = zu suchender CRC
	; Rückgabe
	; HL = Zeiger auf Zeichenkette
SEARCH_CRC:
	PUSH	BC
	PUSH	DE
	EX 	DE, HL
	LD	HL, CRC_LIST

	LD	C, (HL)
	INC	HL
	LD	B, (HL)
	INC	HL

SEARCH_CMP:
	; clear carry
	OR	A
	EX 	DE, HL
	SBC	HL, BC
	JR	Z, SEARCH_FND
	ADD	HL, BC
	EX 	DE, HL

	; Ende der ZK suchen
	XOR	A
SEARCH_NXT:
	CP	(HL)
	INC	HL
	JR	NZ, SEARCH_NXT

	; zeigt auf nächsten CRC
	LD	C, (HL)
	INC	HL
	LD	B, (HL)
	INC	HL
	
	; schon Ende?
	LD	A, B
	OR	C

	JR	NZ, SEARCH_CMP
	EX 	DE, HL

SEARCH_FND:
	EX 	DE, HL
	; HL zeigt auf Zeichenkette

	POP	DE
	POP	BC
	RET

	


;------------------------------
; data segment
; ab hier nur Datenstrukturen

MSGUNKOWN:	DB	"kein ROM", 0
MSG_01:		DB	"Autostart", 0
MSG_ROM1:	DB	"segmented ROM ", 0
MSG_ROM2:	DB	"USER ROM ", 0
MSG_ROM3:	DB	"PROM ", 0
MSG_ROM4:	DB	"M052 ", 0
MSG_ROM5:	DB	"Flash ", 0

PAR_SIZE:	EQU 8	; Länge eines Eintrags
; Definition der jeweilgen Offsets
PAR_STRUCT:	EQU 0
PAR_SEGSIZE:	EQU 1
PAR_SEGMENTSL:	EQU 2
PAR_SEGMENTSH:	EQU 3
PAR_OFFSET:	EQU 4
PAR_SHIFT:	EQU 5
PAR_MSGL:	EQU 6
PAR_MSGH:	EQU 7
; hier gehts los
PAR_LIST:
	; Autostart
	DB	0x01	; Strukturbyte	+0
	DB	0	; kByte		+1
	DW	0	; Segmente	+2
	DB	0	; Offset	+4
	DB	0	; Shift		+5
	DW	MSG_01  ;		+6

	;  32k ROM
	DB	0x70	; Strukturbyte
	DB	8	; kByte
	DW	4	; Segmente
	DB	0xC1	; Offset
	DB	4	; Shift
	DW	MSG_ROM1

	;  64k ROM (Brücken umsetzen!)
	DB	0x71	; Strukturbyte
	DB	8	; kByte
	DW	8	; Segmente
	DB	0xC1	; Offset
	DB	3	; Shift
	DW	MSG_ROM1

	; 128k ROM
	DB	0x72	; Strukturbyte
	DB	8	; kByte
	DW	16	; Segmente
	DB	0xC1	; Offset
	DB	2	; Shift
	DW	MSG_ROM1

	; 256k ROM
	DB	0x73	; Strukturbyte
	DB	16	; kByte
	DW	16	; Segmente
	DB	0xC0	; Offset
	DB	2	; Shift
	DW	MSG_ROM1

	; 512k ROM
	DB	0x74	; Strukturbyte
	DB	16	; kByte
	DW	32	; Segmente
	DB	0   	; Offset
	DB	1	; Shift
	DW	MSG_ROM1

	; 1024k ROM, M050
	DB	0x75	; Strukturbyte
	DB	8	; kByte
	DW	128	; Segmente
	DB	1	; Offset
	DB	0	; Shift
	DW	MSG_ROM1

	; flash ROM, M044
	DB	0x76	; Strukturbyte
	DB	8	; kByte
	DW	0  	; Segmente
	DB	0	; Offset
	DB	0	; Shift
	DW	MSG_ROM5

	; M025/M040
	DB	0xF7	; Strukturbyte
	DB	8	; kByte
	DW	1	; Segmente
	DB	0xC1	; Offset
	DB	0	; Shift
	DW	MSG_ROM2

	; M028/M040
	DB	0xF8	; Strukturbyte
	DB	16	; kByte
	DW	1	; Segmente
	DB	0xC1	; Offset
	DB	0	; Shift
	DW	MSG_ROM2

	; M012/M026/M027
	DB	0xFB	; Strukturbyte
	DB	8	; kByte
	DW	1	; Segmente
	DB	0xC1	; Offset
	DB	0	; Shift
	DW	MSG_ROM3

	; M006/M028
	DB	0xFC	; Strukturbyte
	DB	16	; kByte
	DW	1	; Segmente
	DB	0xC1	; Offset
	DB	0	; Shift
	DW	MSG_ROM3

	; M052
	DB	0xFD	; Strukturbyte
	DB	8	; kByte
	DW	4	; Segmente
	DB	0xC1	; Offset
	DB	3	; Shift
	DW	MSG_ROM4
	
	; unknown
	; = letzter Eintrag in Liste, Strukturbyte = 0x00
	DB	0x00	; Strukturbyte	
	DB	0	; kByte
	DW	0	; Segmente
	DB	0	; Offset
	DB	0	; Shift
	DW	MSGUNKOWN


CRC_LIST:
	DW	0x1C01
	DB	"BM600", 0

	DW	0xD34A
	DB	"BM601", 0

	DW	0x6CD1
	DB	"M006 BASIC", 0

	DW	0xD30E
	DB	"M033 TYPESTAR", 0

	DW	0x1DD1
	DB	"M012 TEXOR", 0

	DW	0x08FE
	DB	"M026 FORTH", 0

	DW	0xD76F
	DB	"M027 DEVELOPMENT", 0

	DW	0xC20C
	DB	"M052 USB 2.2", 0

	DW	0x3FA4
	DB	"M052 USB 3.0", 0

	DW	0
	DB	"---", 0


MSGSTART:
        DB      CLL
	DB	"ROM-checker, ", 0
MSGSLOT:  
	DB      CR, LF, CLL
	DB      CR, LF, CLL
	DB      "Slot: ", 0
MSGSTRUCT:  
	DB      CR, LF, CLL
	DB      "Strukturbyte: ", 0
MSGTYP:  
	DB      CR, LF, CLL
	DB      "Modultyp: ", 0
MSGSEGSIZE:  
	DB      CR, LF, CLL
	DB      "Segmentgr", 0x7c, 0x7e 
	DB	"e: ", 0
MSGSEGMENTS: 
	DB      CR, LF, CLL
	DB      "Segmente: ", 0

MSGOFFSET: 
	DB      "Offset (hex): ", 0

MSGSHIFT: 
	DB      CR, LF, CLL
	DB      "Shift: ", 0

MSGNOMODUL:
	DB      CR, LF, CLL
	DB	"Kein Modul gefunden!"
	DB	0

MSGHEADER:
        DB      CR, LF, CLL
	DB	"idx  ctrl  SUM  CRC"   
        DB      CR, LF, CLL
	DB      "---- ----  ---- ----"
	DB      CR, LF, CLL, 0
MSGSUM:   
        DB      CLL
	DB	"SUM 0000 " , 0
MSGCRC:   
        DB      CLL
	DB	"CRC 0000 " , 0

MSGSUMHELP:
        DB      CLL
	DB	"SUM SADDR LENGTH (START_VALUE)"
	DB      CR, LF, CLL, 0

MSGCRCHELP:
        DB      CLL
	DB	"CRC SADDR LENGTH (START_VALUE)"
	DB      CR, LF, CLL, 0

include "date.inc"


;------------------------------
; data segment
SLOT:   DB  	0
INDEX:	DW	0
PARSET:	DS  	PAR_SIZE


	; fill up with 0xff
;ALIGN2:	EQU	128 - (($+128) % 128)
	;DS	ALIGN2, 0xff
	; jeweils 128 (0x80) hinzufügen, bei asm-Fehler
	;ds	(14 * 0x80) - $
	ds	0xA00 - $
KCCEND:

; vim: set tabstop=8 noexpandtab:
