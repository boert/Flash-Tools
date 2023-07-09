
;---------------------------------------- 

PV1     EQU     0F003h 	; Sprungverteiler


; CAOS Funktionsnummern
; bzw. Unterprogramme
CRT     EQU     000h
KBD     EQU     004h
KBDS	EQU		00Ch
BYE     EQU     00Dh
KBDZ	EQU		00Eh
COLORUP	EQU		00Fh
LOOP	EQU		012h
ERRM	EQU		019h
HLHX	EQU		01Ah
AHEX	EQU		01Ch
OSTR    EQU     023h
MODU	EQU		026h
SPACE	EQU		02Bh
CRLF	EQU		02Ch
HOME	EQU		02Dh
PADR	EQU		034h
WININ	EQU		03Ch
WINAK	EQU		03Dh
LINE	EQU		03Eh
CSTBT	EQU		042h
ZKOUT   EQU     045h

; Sonderzeichen
BREAK	EQU	003h
CUL	EQU	008h
CUR	EQU	009h
CUD     EQU     00Ah
LF      EQU     00Ah
CUU     EQU     00Bh
CLS     EQU     00Ch
CR      EQU     00Dh
STOP	EQU	013h
ESC	EQU	01Bh
SPC	EQU	020h

; VRAM-Zellen
VRAM    EQU     08000h
ARGN    EQU     0B781h
ARG1	EQU	0B782h
ARG2	EQU	0B784h
ARG3	EQU	0B786h
ARG4	EQU	0B788h
CURSO   EQU     0B7A0h
STBT	EQU	0B7A2h
COLOR	EQU	0B7A3h
NCAOS	EQU	0B7B4h
FARB	EQU	0B7D6h

;---------------------------------------- 

PROGADR EQU 0200h

;KCC-Header
        ORG PROGADR - 080h
        DB	"FLCHECK"

        ORG PROGADR - 070h
        DB	2 	        ; Argumente (3 = Autostart)
        DW	KCCBEGIN    ; Loadadresse
        DW	KCCEND      ; Endadress(+1)
        DW	START       ; Startadresse

        DS	9
        DB	"fuer KC85/4/5; "
        DB	"B. Lange; "
        DB	"07/2023"

ALIGN1	EQU	128 - (($+128) MOD 128)
	DS	ALIGN1


KCCBEGIN:

        ; Menüwort
        DW	07F7Fh
        DB	"FLCHECK"
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
        LD  	HL, MSGSTART
        CALL 	PV1
        DB  	ZKOUT
        LD  	HL, BUILDSTR
        CALL 	PV1
        DB  	ZKOUT
        LD  	HL, MSGSLOT
        CALL 	PV1
        DB  	ZKOUT
        pop     AF
        pop     HL

        ; Anazahl Parameter (A) prüfen
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
	LD  	HL, MSGHEADER
        CALL 	PV1
        DB  	ZKOUT


        LD      b, 16       ; Zähler
        LD      c, 0        ; Segmentnummer
MLOOP:
        push    bc
        call    SET_SEGMENT
        
        LD      HL, 0C000h  ; Startadresse
        LD      DE, 02000h  ; Anzahl
        CALL    CHSUM
        EX      de, hl      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      SPACE
        
        LD      HL, 0C000h  ; Startadresse
        LD      DE, 02000h  ; Anzahl
        CALL    CRCSUM
        EX      de, hl      ; Ergenbis nach HL

        CALL    PV1         ; ausgeben
        DB      HLHX
        CALL    PV1
        DB      CRLF

        pop     bc
        inc     c
        djnz    MLOOP

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
        ; DE = Laenge
        ; Ergebnis -> DE
CHSUM:
        push    de
        pop     bc
        xor     a
        ld      d, a
        ld      e, a

CHSUM_LP:
        ld      a, e
        add     a, (hl)
        jr      nc, CHSUM_DEC
        inc     d
CHSUM_DEC:
        ld      e, a
        inc     hl         ; Addresse++
        dec     bc         ; Laenge--
        ld      a, b        
        or      c          ; pruefen auf BC = 0
        jr      nz, CHSUM_LP
        ret
        
                    

        ; Parameter
        ; HL = Startadresse
        ; DE = Laenge
        ; Ergebnis -> DE
CRCSUM:
        push de
        pop  bc         ; BC = Laenge
        ld   de, 0ffffh ; Startwert?
CRCSUM_LP:
        ld   a, (hl)    ; Byte laden
        xor  d          
        ld   d,a        ; D = D xor Byte
        rrca            ; rotate accumulator right with branch carry
        rrca            ; CY = Bit 0
        rrca            ; 76543210 becomes 32107654
        rrca
        and  0fh        ; mask bits ____7654
        xor  d
        ld   d,a        ; D = D xor high nibble( Byte)
        rrca
        rrca
        rrca
        push af
        and  1fh
        xor  e
        ld   e,a
        pop  af
        push af
        rrca
        and  0f0h
        xor  e
        ld   e,a
        pop  af
        and  0e0h
        xor  d
        ld   d,e        ; Ergebnis nach DE
        ld   e,a
        inc  hl         ; Addresse++
        dec  bc         ; Laenge--
        ld   a,b        
        or   c          ; pruefen auf BC = 0
        jr   nz, CRCSUM_LP
        ret

        ; Parameter:
        ;   C - Segmentnummer  
SET_SEGMENT:
        LD      B, 0
        LD 	    HL, MODCTRL
        ADD 	HL, BC
        LD	    A, (HL)

        push    af
        CALL    PV1
        DB      AHEX
        CALL    PV1
        DB      SPACE
        pop     af

        LD      HL, SLOT
        LD      D, A        ; Steuerbyte
        LD      L, (HL)     ; Steckplatz
        LD      A, 2
        CALL    PV1
        DB      MODU
        RET
        

MODBASE	EQU	0C0h		; Modul-Basisadresse
MODCTRL	DB	MODBASE + 001h, MODBASE + 005h
        DB	MODBASE + 009h, MODBASE + 00Dh
        DB	MODBASE + 011h, MODBASE + 015h
        DB	MODBASE + 019h, MODBASE + 01Dh
        DB	MODBASE + 021h, MODBASE + 025h
        DB	MODBASE + 029h, MODBASE + 02Dh
        DB	MODBASE + 031h, MODBASE + 035h
        DB	MODBASE + 039h, MODBASE + 03Dh

SLOT    DB  0

MSGSTART
        DB      "Flashcheck", CR, LF, 0
MSGSLOT  
        DB      CR, LF, "Slot: ", 0
MSGHEADER
        DB      CR, LF, "CB SUM   CRC"   
        DB      CR, LF, "-- ----  ----", CR, LF, 0

include "date.inc"

	; fill up with 0xff
ALIGN2	EQU	128 - (($+128) MOD 128)
	DS	ALIGN2, 0xff
KCCEND:

; vim: set tabstop=8 noexpandtab:
