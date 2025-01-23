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

SetupRED    bic.b   #BIT0,&P1OUT            ; Clear P6.6 output
            bis.b   #BIT0,&P1DIR            ; P6.6 output    

SetupP13    bic.b   #BIT6,&P1OUT            ; Set P1.6 as SCL
            bis.b   #BIT6,&P1DIR

SetupP12    bic.b   #BIT5,&P1OUT            ; Set P1.5 as SDA
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



DisableLPM  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable low-power mode

           

main:

            nop
            jmp main
            nop



;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------        
ISR_TB0_CCR0:
            xor.b   #BIT0, &P1OUT           ; Toggle P1.1
            xor.b   #BIT6, &P1OUT
            xor.b   #BIT5, &P1OUT
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