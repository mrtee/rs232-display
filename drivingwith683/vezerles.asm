	list	p=12f683

		
include "p12f683.inc"

    __config (_FCMEN_OFF & _IESO_OFF & _BOD_NSLEEP & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO)

;baud=10417, 4mhz-nél 96 utasitasciklus kell legyen a bitek között
;GP0
;GP1 TX
;GP2
;GP3 gomb
;GP4
;GP5


cblock	0x20
W_TEMP
STATUS_TEMP
tmp1
tmp2
rolbyte
endc	


	org	0

main
    goto	kezd

	org 	4

megszak
    MOVWF  W_TEMP        ;Copy W to TEMP register
    SWAPF  STATUS,W      ;Swap status to be saved into W (swap does not affect status)
    CLRF   STATUS        ;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    MOVWF  STATUS_TEMP   ;Save status to bank zero STATUS_TEMP register






    SWAPF  STATUS_TEMP,W ;Swap STATUS_TEMP register into W
                         ;(sets bank to original state)
    MOVWF  STATUS        ;Move W into Status register
    SWAPF  W_TEMP,F      ;Swap W_TEMP
    SWAPF  W_TEMP,W      ;Swap W_TEMP into W
    retfie


kezd
    bsf		GPIO,1
    bsf		STATUS,RP0
    bcf		TRISIO,1
    clrf	ANSEL
    bcf		STATUS,RP0
    
cikl
    btfsc	GPIO,3
    goto	cikl

    movlw	0x08
    call	byteki

    movlw	0x00
    call	byteki
    



kapcski

    btfss	GPIO,3
    goto	kapcski
    goto 	cikl



byteki
    movwf	rolbyte
    movlw	0x0a		;10 bit
    movwf	tmp2
    
    bcf		STATUS,C	;start bit
    goto	cbitki
bitki
    bsf		STATUS,C	;1 stop bit a 9.
    rrf		rolbyte,f	;1
cbitki
    movf	GPIO,w		;1
    andlw	b'11111101'    	;1

    btfsc	STATUS,C	;1
    iorlw	b'00000010'	;1
    movwf	GPIO		;1
ido
    movlw	d'27'		;1
    movwf	tmp1		;1
ido88
    decfsz	tmp1,f		;cikl 3
    goto	ido88		;1
    goto 	$+1		;2
    decfsz	tmp2,f		;1
    goto	bitki		;2
    return			;ö=3*x+15




end


