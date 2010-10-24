	list	p=16f690

		
include "p16f690.inc"

    __config (_FCMEN_OFF & _IESO_OFF & _BOR_ON & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO)

;RA5	Z7		;RB6	CP1
;RA4	Z6		;RB5	ADAT
;RA3	ADAT		;RB4	D3
;RC5	Z3		;RC2	CP2
;RC4	Z1		;RC1	D2
;RC3	Z2		;RC0	CP3
;RC6	Z4		;RA2	D4
;RC7	Z5		;RA1	CP4
;RB7	D1		;RA0	D5

;    ZZ DCD	  DC D           ZZZZZCDC
;A 0076x445     B 11x3xxxx     C 54312223


cblock	0x74
;megszakitas
W_TEMP
STATUS_TEMP
fogadas
;sorolo
sor
;kiszamolo
tmp1 ; var ciklusban pl. mindenhol van
tmp2 ; var ciklusban pl. mindenhol van
tablatmp
matrix
nullajelzo
mibol_hi
mibol_lo

endc	


	org	0

main
    goto	kezd

	org 	4

megszak
    MOVWF  W_TEMP
    SWAPF  STATUS,W
    CLRF   STATUS
    MOVWF  STATUS_TEMP

    bcf		STATUS,RP0
    bcf		STATUS,RP1
    movf	fogadas,w
    btfss	STATUS,Z
    goto	jonamasodik
    movf	RCREG,w		;az elso byte erkezett meg
    movwf	mibol_hi	;ez a hi-byte
    incf	fogadas,f	;varjuk a masodik byte-ot
    btfss	PIR1,RCIF	;meg mindig jon?
    goto	nemjontobb
jonamasodik
    movf	RCREG,w		;a masodik byte erkezett meg
    movwf	mibol_lo	;ez a lo-byte
    incf	fogadas,f	;jelez hogy megjott az egesz

nemjontobb
    swapf	STATUS_TEMP,W	;megszakitas vege rutin
    movwf	STATUS
    swapf	W_TEMP,F
    swapf	W_TEMP,W
    retfie

clockokki
    bcf		PORTC,0
    bcf		PORTA,1
    bcf		PORTB,6
    bcf		PORTC,2
    return

egyszamkiir
    addwf	sor,w
    movwf	FSR
    movf	INDF,w
    call 	clockokki
    movwf	PORTA
    movlw	0x07
    addwf	FSR,f
    movf	INDF,w
    movwf	PORTB
    bsf		STATUS,RP0	;az RB7-et a soros port vezerli
    bsf		BAUDCTL,SCKP	;D5 = 0
    andlw	0x80
    btfss	STATUS,Z
    bcf		BAUDCTL,SCKP	;D5 = 1
    bcf		STATUS,RP0
    movlw	0x07
    addwf	FSR,f
    movf	INDF,w
    movwf	PORTC
    return
    
zbe
    movwf	tmp1
    movlw	high z_adatok     ; get high order part of the beginning of the table
    movwf	PCLATH
    movlw	low z_adatok      ; load starting address of table
    addwf	tmp1,w              ; add offset
    btfsc	STATUS,C            ; did it overflow?
    incf	PCLATH,f            ; yes: increment PCLATH
    movwf	PCL                 ; modify PCL
z_adatok
    retlw	b'00000000'	;PORTA
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00010000'
    retlw	b'00100000'
    
    retlw	b'00010000'	;PORTC
    retlw	b'00001000'
    retlw	b'00100000'
    retlw	b'01000000'
    retlw	b'10000000'
    retlw	b'00000000'
    retlw	b'00000000'



kezd

    clrf	PORTA
    clrf	PORTB
    clrf	PORTC
    bsf		STATUS,RP1
;---bank 2
    clrf	ANSEL
    clrf	ANSELH
    bsf		WPUB,WPUB5	;pull-up resistor (RB5-RX)
    bcf		STATUS,RP1
;---bank 0
    bsf		RCSTA,SPEN	;serial bekapcs
    bsf		STATUS,RP0
;---bank 1
    bsf		BAUDCTL,SCKP	;alapból 0 a C1 kimeneten
    movlw	0x05
    movwf	SPBRG		;10417 baud
    movlw	b'00001000'
    movwf	TRISA
    movlw	b'00101111'	;RB5-bemenet!
    movwf	TRISB
    clrf	TRISC
    clrf	sor		;nulladik sor
    clrf	fogadas		;meg nem jott semmi
    bsf		PIE1,RCIE	;megszakitas
    bcf		OPTION_REG,NOT_RABPU ;pull-up resistor
    bcf		STATUS,RP0
;---bank 0



;    movlw	0x0e		;alap értékek, kezdőszám
;    movwf	mibol_hi
;    movlw	0x00
;    movwf	mibol_lo
;    call	kitesz

    movlw	0x0b		;teszt képernyő
    call	szam
    movlw	0x4b
    call	szam
    movlw	0x8b
    call	szam
    movlw	0xce
    call	szam

				;inicializálás befejezés
    bsf		RCSTA,CREN	;soros port be
    movlw	b'11000000'	;raadja a megszakitast
    movwf	INTCON


kiirociklus

    movlw	0x20
    call	egyszamkiir
    bsf		PORTB,6		;clock 1 be
    movlw	0x35
    call	egyszamkiir
    bsf		PORTC,2		;clock 2 be
    movlw	0x4a
    call	egyszamkiir
    bsf		PORTC,0		;clock 3 be
    movlw	0x5f
    call	egyszamkiir
    bsf		PORTA,1		;clock 4 be

    movf	sor,w		;bekapcsolja a Z-ket, 
    call	zbe		;mindig a sornak megfeleloen
    iorwf	PORTA,f
    movlw	0x07
    addwf	sor,w
    call	zbe
    iorwf	PORTC,f

    incf	sor,f		;noveli a sor-t
    movlw	0x07
    xorwf	sor,w
    btfsc	STATUS,Z
    clrf	sor
    call	clockokki	;clockokat kikapcsolja

    call	varr

    movf	sor,w
    btfss	STATUS,Z	;utolso sor megvolt-e?
    goto	kiirociklus	;nem


    bcf		INTCON,GIE	;megszakítás letiltása
    btfss	fogadas,1	;megjott az uj adat?
    goto	megfogad	;nem
    call	kitesz		;kiszamolja az uj szamot
    clrf	fogadas

megfogad
    bsf		INTCON,GIE
    goto	kiirociklus


var
;    call	varr
;    call	varr
;    call	varr
    call	varr
varr
    clrf	tmp1
    clrf	tmp2
    movlw	0x01		;villogas sebesseg (1=leggyorsabb)
    movwf	tmp2
ido1
    decfsz      tmp1,f
    goto        ido1
    decfsz	tmp2,f
    goto	ido1
    return


kitesz				;kiteszi a 16 bites szamot a kijelzore
    clrf	nullajelzo
    incfsz	mibol_hi,w	;ffff specialis sotet kod
    goto	nemzero1
    incfsz	mibol_lo,w
    goto	nemzero1
    movlw	0x0b		;kiteszi a sotetet
    call	szam
    movlw	0x4b
    call	szam
    movlw	0x8b
    call	szam
    movlw	0xcb
    call	szam
    return
nemzero1			;nem ffff, ki kell szamolni az eredmenyt
    movlw	0x03		;ezresek
    movwf	tmp1
    movlw	0xe8
    call	kivon
    sublw	0x09
    btfss	STATUS,C
    goto	overflow
    movf	matrix,w
    iorwf	nullajelzo,f
    btfsc	STATUS,Z
    movlw	0x0b
    call	szam
    clrf	tmp1		;szazasok
    movlw	0x64
    call	kivon
    iorwf	nullajelzo,f
    btfsc	STATUS,Z
    movlw	0x0b
    iorlw	0x40
    call	szam
    clrf	tmp1
    movlw	0x0a		;tizesek
    call	kivon
    iorwf	nullajelzo,f
    btfsc	STATUS,Z
    movlw	0x0b
    iorlw	0x80
    call	szam
    clrf	tmp1
    movf	mibol_lo,w	;egyesek
    iorlw	0xc0
    call	szam
    return			;vege a kis rutinnak
overflow
    movlw	0x0a		;overflow nyilak
    call	szam
    movlw	0x4a
    call	szam
    movlw	0x8a
    call	szam
    movlw	0xca
    call	szam
    return
kivon
    movwf	tmp2
    clrf	matrix
    decf	matrix,f
kivoncikl
    movf	tmp2,w
    incf	matrix,f
    subwf       mibol_lo,f
    movf        tmp1,W
    btfss       STATUS,C
    incfsz      tmp1,W
    subwf       mibol_hi,f
    btfsc	STATUS,C
    goto	kivoncikl
    movf	tmp2,w		;vissza hozzáad
    addwf	mibol_lo,f
    btfsc	STATUS,C
    incf	mibol_hi,f
    movf	tmp1,w
    addwf	mibol_hi,f
    movf	matrix,w
    return

szam				;ez a rutin kitesz egy szamot(W0-5) a megfelelo helyre (W6-7)
    movwf	tmp2		;ez tarolja hogy melyik betu es hova
    clrf	tmp1		;ez szamolja a sorokat
    incf	tmp2,w		;jobb igy megszamolni
    andlw	b'00111111'
    movwf	tablatmp	;ennyiedik karakter a matrix-ban
    movlw	0xf9
kovetkezo_matrix
    addlw	0x07    
    decfsz	tablatmp,f
    goto	kovetkezo_matrix
    movwf	matrix		;ezen a pozicion kezdodik az adtott karakter matrixa
egykarakter
    movf	tmp1,w
    addwf	matrix,w
    bcf		INTCON,GIE	;nagyon fontos, mert a megszakítás bezavar!
    call	karakteradatok
    bsf		INTCON,GIE
    movwf	tablatmp
    movlw	0x20		;itt talalja ki, hogy a ramban hol van az adott hely
    btfsc	tmp2,7		;7.bit=3.-4. kijelzo
    addlw	0x2a
    btfsc	tmp2,6		;6.bit=1.-2. kijelzo
    addlw	0x15
    addwf	tmp1,w		;plusz a sor
    movwf	FSR
    clrf	INDF
    btfsc	tablatmp,2	;bitek szetszorasa a portokra
    bsf		INDF,2
    btfsc	tablatmp,1
    bsf		INDF,0
    movlw	0x07
    addwf	FSR,f
    clrf	INDF
    btfsc	tablatmp,3
    bsf		INDF,4
    btfsc	tablatmp,5
    bsf		INDF,7
    movlw	0x07
    addwf	FSR,f
    clrf	INDF
    btfsc	tablatmp,4
    bsf		INDF,1
    incf	tmp1,f
    movlw	0x07
    xorwf	tmp1,w
    btfss	STATUS,Z
    goto	egykarakter	;minden sort külön
    return

karakteradatok
    movwf	tablatmp
    movlw	high kar_adatok     ; get high order part of the beginning of the table
    movwf	PCLATH
    movlw	low kar_adatok      ; load starting address of table
    addwf	tablatmp,w              ; add offset
    btfsc	STATUS,C            ; did it overflow?
    incf	PCLATH,f            ; yes: increment PCLATH
    movwf	PCL                 ; modify PCL

;    ZZ DCD	  DC D           ZZZZZCDC
;A 0076x445     B 11x3xxxx     C 54312223

kar_adatok
    retlw	b'00111110'	; 0
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'

    retlw	b'00001000'	; 1
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'

    retlw	b'00111110'	; 2
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00111110'
    retlw	b'00100000'
    retlw	b'00100000'
    retlw	b'00111110'

    retlw	b'00111110'	; 3
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00111110'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00111110'

    retlw	b'00100010'	; 4
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00000010'

    retlw	b'00111110'	; 5
    retlw	b'00100000'
    retlw	b'00100000'
    retlw	b'00111110'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00111110'

    retlw	b'00111110'	; 6
    retlw	b'00100000'
    retlw	b'00100000'
    retlw	b'00111110'
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'

    retlw	b'00111110'	; 7
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00000010'

    retlw	b'00111110'	; 8
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'

    retlw	b'00111110'	; 9
    retlw	b'00100010'
    retlw	b'00100010'
    retlw	b'00111110'
    retlw	b'00000010'
    retlw	b'00000010'
    retlw	b'00111110'

    retlw	b'00001000'	; nyil
    retlw	b'00011100'
    retlw	b'00101010'
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'
    retlw	b'00001000'

    retlw	b'00000000'	; semmi
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'

    retlw	b'00000000'	; 0
    retlw	b'00000000'
    retlw	b'00111110'
    retlw	b'00101010'
    retlw	b'00111110'
    retlw	b'00000000'
    retlw	b'00000000'

    retlw	b'00000000'	; 0
    retlw	b'00010100'
    retlw	b'00111110'
    retlw	b'00111110'
    retlw	b'00011100'
    retlw	b'00001000'
    retlw	b'00000000'

    retlw	b'00000010'	; pont
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'

    retlw	b'00000000'	; 0
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'
    retlw	b'00000000'

end


