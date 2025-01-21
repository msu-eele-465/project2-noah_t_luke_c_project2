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

SetupP2     bic.b   #BIT6,&P6OUT            ; Clear P6.6 output
            bis.b   #BIT6,&P6DIR            ; P6.6 output      

SetupTimer  bis.w   #TBCLR, &TB0CCTL0       ; Clear timer and dividers
            bis.w   #TBSSEL__ACLK, &TB0CTL  ; ACLK as timer source
            bis.w   #MC__UP, &TB0CTL        ; Up counting mode for timer
            
            mov.w   #32800, TB0CCR0
            bis.w   #CCIE, &TB0CCTL0
            bis.w   #CCIFG, &TB0CCTL0       ; Clear interrupt flag
            
            NOP
            bis.w   #GIE, SR                ; Enable maskable interrupts
            NOP

            bis.w #UCB0CTLW0, &UCSWRST      ; UCSWRST = 1 for eUSCI_B0 in SW reset
            

            bic.w   #LOCKLPM5,&PM5CTL0      ; Disable low-power mode

            

main:

            nop 
            jmp main
            nop



;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------        
ISR_TB0_CCR0:
            xor.b   #BIT6, &P6OUT           ; Toggle P6.6
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
