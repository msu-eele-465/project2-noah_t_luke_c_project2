;-------------------------------------------------------------------------------
; Include files
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------

            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer

STOPWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

SetupRED    bic.b   #BIT0,&P1OUT            ; Clear P1.1 output
            bis.b   #BIT0,&P1DIR            ; P1.1 output    

SetupP16    bic.b   #BIT6,&P1OUT            ; Set P1.6 as SCL
            bis.b   #BIT6,&P1DIR

SetupP15    bic.b   #BIT5,&P1OUT            ; Set P1.5 as SDA
            bis.b   #BIT5,&P1DIR

SetupTimer  bis.w   #TBCLR, &TB0CCTL0       ; Clear timer and dividers
            bis.w   #TBSSEL__ACLK, &TB0CTL  ; ACLK as timer source
            bis.w   #MC__UP, &TB0CTL        ; Up counting mode for timer
            mov.w   #32800, TB0CCR0
            bis.w   #CCIE, &TB0CCTL0
            bis.w   #CCIFG, &TB0CCTL0       ; Clear interrupt flag
           
            NOP
            bis.w   #GIE, SR                ; Enable maskable interrupts
            NOP
            clrc                            ; Clear carry



DisableLPM  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable low-power mode

           

main:
            call    #i2c_start
            call    #i2c_tx_byte
            call    #i2c_stop
            jmp main
            nop

;------------------------------------------------------------------------------
;           Subroutines
;------------------------------------------------------------------------------
i2c_write:
            call    #i2c_start
            call    #i2c_tx_byte
            call    #i2c_sda_delay
            bic.b   #BIT5, &P1OUT           ; Clear SDA for WRITE
            bis.b   #BIT6, &P1OUT           ; Pulse SCL
            call    #i2c_sda_delay
            bic.b   #BIT6, &P1OUT           
            ret



i2c_start:                                  ; Start signal, high to low on SDA, high on SCL
            bis.b   #BIT6, &P1OUT           ; Set SCL high   
            call    #i2c_sda_delay          ; Delay
            bic.b   #BIT5, &P1OUT           ; Set SDA low
            ret

i2c_stop:                                   ; Stop signal, low to high on SDA, high on SCL, assume SCL high SDA low
            bis.b   #BIT6, &P1OUT           ; Set SCL high   
            call    #i2c_sda_delay          ; Delay
            bis.b   #BIT5, &P1OUT           ; Set SDA high
            ret

i2c_tx_byte:                                ; Use to send a byte
            mov.w  #8, R5                   ; Loop Counter

tx_msb_tester:                              ; Test the MSB of tx_byte
            bit.b  #BIT7, &tx_byte          ; Test bit 7
            jz     clear_sda                ; If 0 clear SDA
            bis.b  #BIT5, &P1OUT            ; If 1 set SDA
            jmp    set_scl

clear_sda:
            bic.b  #BIT5, &P1OUT            ; Clear SDA

set_scl:    
            ; SDA Setup
            bis.b  #BIT6, &P1OUT            ; SCL high
            call   #i2c_sda_delay
            bic.b  #BIT6, &P1OUT            ; SCL low
            rlc.b  tx_byte                  ; Shift MSB
            dec    R5                       ; Dec loop Counter
            jnz    tx_msb_tester            ; loop
            rlc.b  tx_byte                  ; Shift MSB
            ret

i2c_rx_ack:                                 ; Acknowledge data recieved
            bic.b  #BIT5, &P1DIR            ; Input for SDA
            nop

            bis.b  #BIT6, &P1OUT            ; Set SCL high
            nop
            bit.b  #BIT5, &P1DIR            ; Check SDA with Z flag
            bic.b  #BIT6, &P1OUT            ; SCL low
           
            bic.b  #BIT5, &P1DIR            ; Reset SDA to output
            ret

i2c_sda_delay:
            nop
            nop
            ret


i2c_scl_delay:




;------------------------------------------------------------------------------
;           Variables
;------------------------------------------------------------------------------

            .DATA
tx_byte:    .byte  0x088;



;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------        
ISR_TB0_CCR0:
            xor.b   #BIT0, &P1OUT           ; Toggle P1.1
            bic.w   #CCIFG, &TB0CCTL0       ; Clear flag
            reti


;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect ".int43"
            .short ISR_TB0_CCR0

            .end                ;