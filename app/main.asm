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


init:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL

            bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
            bis.b   #BIT0,&P1DIR            ; P1.0 output

            bis.w   #TBCLR, &TB0CTL         ; Clear timers and dividers
            bis.w   #TBSSEL__ACLK, &TB0CTL  ; ACLK as Timer source
            bis.w   #MC__UP, &TB0CTL        ; Up counting mode 
            mov.w   #32800, &TB0CCR0        ; initialize CCR0
            bis.w   #CCIE, &TB0CCTL0         ; Enable capture/compare Interrupt
            bis.w   #CCIFG, &TB0CCTL0        ; Clear interrupt flag
            

            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0
            NOP
            bis.w   #GIE, SR                ; Enable maskable interrupts
            NOP

main:

            nop 
            jmp main
            nop


;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------
ISR_TB0_CCR0:
            xor.b   #BIT0,&P1OUT              ; Toggle P6.6
            bic.w   #CCIFG, &TB0CCTL0         ; Clear interrupt flag
            reti

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   ".int43"
            .short  ISR_TB0_CCR0
            .end


