;TOMER YEHEZKELY 310079553, OMRI NAOR 208306068

LIST 	P=PIC16F877
		include	P16f877.inc
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

;  LCD
;
		org		0x00
reset	goto	start

		org	0x10
start	bcf		STATUS, RP0
		bcf		STATUS, RP1		;Bank 0
		clrf	PORTD
		clrf	PORTE

		bsf		STATUS, RP0		;Bank 1
		movlw	0x02
		movwf	ADCON1

		clrf	TRISE		;porte output 
		clrf	TRISD		;portd output

		bcf		STATUS, RP0		;Bank 0

		movlw 0x89
		movwf ADCON0
		call d_20
		call	init


; Init timer 0

		bcf		STATUS, RP0
		bcf		STATUS, RP1		;Bank 0

		movlw 0x00 ; 0d
        movwf TMR0 ; TD = 200ns*(256)*256 = 0.0131072s
		clrf INTCON
		bsf STATUS, RP0 ;bank 1

; Choose prescaler

        movlw 0xc7 ; ps 1:256
		movwf OPTION_REG
		bcf STATUS,RP0 ; BANK 0
   		
  		
		
		clrf 0x56 ; 00X counter
		clrf 0x57 ; 0X0 counter
		clrf 0x58 ; X00 counter
		
		clrf 0x51 ; helper register (every 75)

		clrf 0x78 ; Register to set whether to count up (1) or down (0) or nothing (3). 

;---------- Main program area: ---------------------------------------------------------;

loop:	btfss	INTCON, T0IF		; Checking the flag (Timer0)
		goto	loop
		
    	incf	0x51 ; Inc the helper register
		movlw d'75'
        subwf 0x51 ,w
		btfss STATUS, Z   ; If 0x51 reached 75 skip next line and count 
		goto resetStatus 

lulaa:
		bsf ADCON0, GO ; Start conversion
waitc:	
		btfsc ADCON0, GO ; Wait end of conversion
		goto waitc		
		call d_4
		call checkWhichCount

		movlw d'3'
        subwf 0x78 ,w
		btfsc STATUS, Z   ; If 0x78 isn't 3, skip next line and count 
		goto resetStatusWithStop 


		clrf 0x51 ; Reset helper register to start its count again
		call printNumber ; Print number on the LCD

		; Check 0x78 status to know if count up or down
		incf 0x78
		decf 0x78
		btfss STATUS, Z
		goto DoCountUp	
		call countDown
		goto resetStatus

DoCountUp:	
		call countUp

resetStatus:
		bcf	INTCON, T0IF ; Reset timer flag
		bcf		STATUS, RP0
		bcf		STATUS, RP1		; Bank 0 (in case it changed)

		goto loop

resetStatusWithStop:

		call printStop
		goto resetStatus
;---------- Functions area: -----------------------------------------------------------;

checkWhichCount:
               
			   movf ADRESH, w ; result of conversion     
               movwf 0x44 ; result	
			   rlf 0x44, 1
          	   
			   clrf 0x78
 			   bsf STATUS, C ; set c to 1
               movlw d'150'
               subwf 0x44,w ; result - 150
               btfss STATUS,C ;
               goto check1 ; result - 150 < 0 ----> Count up or nothing
               goto check2 ; result -150 >= 0 ----> Count down or nothing

check2:
		       bsf STATUS, C ; set c to 1
               movlw d'230'
               subwf 0x44,w ; result - 230
               btfss STATUS,C ;
               goto check3 ; result - 230 < 0 ----> Count down or nothing
               movlw d'3' ; Stop counting
               movwf 0x78
               return

check3:
               bsf STATUS, C ;set c to 1
               movlw d'180'
               subwf 0x44,w ; result - 180
               btfsc STATUS,C ;
               goto startDown ; result - 180 > 0 ----> Count down
			   movlw d'3' ; Stop counting
               movwf 0x78
               return
			   
               
   check1: 
           bsf STATUS, C ;set c to 1
           movlw d'50'
           subwf 0x44,w ; result - 50
		   btfsc STATUS,C ;
           goto startUp ; result - 50 >= 0 ----> Count up
           movlw d'3' ;stop counting
           movwf 0x78
           return


startUp: 

           movlw d'1'
           movwf 0x78
           return

startDown:
           movlw d'0'
           movwf 0x78
           return



countUp:
		
; ---- Check if reached 250 ----
		movlw d'2'
        subwf 0x58, w
        btfss STATUS, Z
        goto continue_countup

        movlw d'5'
        subwf 0x57, w
        btfss STATUS, Z
		goto continue_countup

		; Set number to 000 and return
        clrf 0x57 
        clrf 0x58
        return	

; -----------------------------
continue_countup:

		call printUp ; Print "UP" on the LCD

		incf 0x56
		; Check if 0x56 reached 10
		movlw d'10'
        subwf 0x56 ,w
		btfss STATUS, Z
		return

		; 0x56 reached 10, reset it to 0 and inc asarot (0x57)
		clrf 0x56
		incf 0x57

		
		; Check if 0x57 reached 10
		movlw d'10'
        subwf 0x57 ,w
		btfss STATUS, Z
		return

		; 0x57 reached 10, reset it to 0 and inc meot (0x58)
		clrf 0x57
		incf 0x58
        
        return



countDown:	

		call printDown

		; Check if 0x56 reached 0
		movlw d'0'
        subwf 0x56 ,w
		btfss STATUS, Z
 		goto ahadotNotZero

		
		; Check if 0x57 reached 0
		movlw d'0'
        subwf 0x57 ,w
		btfss STATUS, Z
		goto asarotNotZero

		; Check if 0x58 reached 0
		movlw d'0'
        subwf 0x58 ,w
		btfss STATUS, Z
		goto meotNotZero

; ---- Check if reached 000 ----
		movlw d'0'
        subwf 0x58, w
        btfss STATUS, Z
        return

        movlw d'0'
        subwf 0x57, w
        btfss STATUS, Z
		return

		movlw d'0'
        subwf 0x56, w
        btfss STATUS, Z
		return

; Number reached 000, set to 250 and return

		movlw d'5'
		movwf 0x57

		movlw d'2'
		movwf 0x58

        return	

; -----------------------------

ahadotNotZero:
        decf 0x56       
		return

asarotNotZero: ; Set number to XX9 because ahadot reached zero
		decf 0x57
        movlw d'9'
		movwf 0x56
		return

meotNotZero: ; Set number to X99 because ahadot AND asarot reached zero
		decf 0x58
  		movlw d'9'
		movwf 0x56
		movlw d'9'
		movwf 0x57
		return



printUp:
          
		; print on lcd location 0xc0
		movlw 0xc0
		movwf 0x20
		call lcdc 
		
		; print "U"
		movlw 0x55
		movwf 0x20
		call lcdd

		; print "P"
		movlw 0x50
		movwf 0x20
		call lcdd

		; Clear rest
		movlw 0x20
		movwf 0x20
		call lcdd
		call lcdd

		return

printStop:
          
		; print on lcd location 0xc0
		movlw 0xc0
		movwf 0x20
		call lcdc 
		
		; print "S"
		movlw 0x53
		movwf 0x20
		call lcdd

		; print "T"
		movlw 0x54
		movwf 0x20
		call lcdd

		; print "O"
		movlw 0x4f
		movwf 0x20
		call lcdd

		; print "P"
		movlw 0x50
		movwf 0x20
		call lcdd
		

		return  

printNumber:
		
		; print on lcd location 0x80
		movlw 0x80
		movwf 0x20
		call lcdc 

		movlw d'48'
        addwf 0x58,0 ; 0x61 is the argument
		movwf 0x20
		call lcdd

		movlw d'48'
        addwf 0x57,0 ; 0x61 is the argument
		movwf 0x20
		call lcdd

		movlw d'48'
        addwf 0x56,0 ; 0x61 is the argument
		movwf 0x20
		call lcdd

		return


printDown:
          
		; print on lcd location 0xc0
		movlw 0xc0
		movwf 0x20
		call lcdc 
		
		; print "D"
		movlw 0x44
		movwf 0x20
		call lcdd

		; print "O"
		movlw 0x4f
		movwf 0x20
		call lcdd

		; print "W"
		movlw 0x57
		movwf 0x20
		call lcdd

		; print "N"
		movlw 0x4e
		movwf 0x20
		call lcdd
		

		return  
		
;
;subroutine to initialize LCD
;
init	movlw	0x30
		movwf	0x20
		call 	lcdc
		call	del_41

		movlw	0x30
		movwf	0x20
		call 	lcdc
		call	del_01

		movlw	0x30
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x01		; display clear
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x06		; ID=1,S=0 increment,no  shift 000001 ID S
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x0c		; D=1,C=B=0 set display ,no cursor, no blinking
		movwf	0x20
		call 	lcdc
		call	mdel

		movlw	0x38		; dl=1 ( 8 bits interface,n=12 lines,f=05x8 dots)
		movwf	0x20
		call 	lcdc
		call	mdel
		return

;
;subroutine to write command to LCD
;

lcdc	movlw	0x00		; E=0,RS=0 
		movwf	PORTE
		movf	0x20,w
		movwf	PORTD
		movlw	0x01		; E=1,RS=0
		movwf	PORTE
        call	sdel
		movlw	0x00		; E=0,RS=0
		movwf	PORTE
		return

;
;subroutine to write data to LCD
;

lcdd	movlw		0x02		; E=0, RS=1
		movwf		PORTE
		movf		0x20,w
		movwf		PORTD
        movlw		0x03		; E=1, rs=1  
		movwf		PORTE
		call		sdel
		movlw		0x02		; E=0, rs=1  
		movwf		PORTE
		return

;----------------------------------------------------------

del_41	movlw		0xcd
		movwf		0x23
lulaa6	movlw		0x20
		movwf		0x22
lulaa7	decfsz		0x22,1
		goto		lulaa7
		decfsz		0x23,1
		goto 		lulaa6 
		return


del_01	movlw		0x20
		movwf		0x22
lulaa8	decfsz		0x22,1
		goto		lulaa8
		return


sdel	movlw		0x19		; movlw = 1 cycle
		movwf		0x23		; movwf	= 1 cycle
lulaa2	movlw		0xfa
		movwf		0x22
lulaa1	decfsz		0x22,1		; decfsz= 12 cycle
		goto		lulaa1		; goto	= 2 cycles
		decfsz		0x23,1
		goto 		lulaa2 
		return


mdel	movlw		0x0a
		movwf		0x24
lulaa5	movlw		0x19
		movwf		0x23
lulaa4	movlw		0xfa
		movwf		0x22
lulaa3	decfsz		0x22,1
		goto		lulaa3
		decfsz		0x23,1
		goto 		lulaa4 
		decfsz		0x24,1
		goto		lulaa5
		return


d_20:
	movlw 0x20
	movwf 0x22
lulaa10: 
	decfsz 0x22, 1
	goto lulaa10
	return

d_4:	
	movlw 0x06
	movwf 0x22
lulaa11:
	decfsz 0x22, 1
	goto lulaa11
	return
;---------- Interrupt program: ---------------------------------------------------------;


;---------------------------------------------------------------------------------------

		end
