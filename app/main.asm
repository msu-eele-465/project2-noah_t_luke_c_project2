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

SetupRED    bic.b   #BIT0, &P1OUT           ; Clear P1.1 output
            bis.b   #BIT0, &P1DIR           ; P1.1 output    

SetupP1_6   bic.b   #BIT6, &P1OUT           ; Set P1.6 as SCL
            bis.b   #BIT6, &P1DIR           ; Pink wire from AD2
            bis.b   #BIT6, &P1REN           ; Enable pullup/down resistor
            bis.b   #BIT6, &P1OUT           ; Select up

SetupP1_5   bic.b   #BIT5, &P1OUT           ; Set P1.5 as SDA
            bis.b   #BIT5, &P1DIR           ; Green wire from AD2
            bis.b   #BIT5, &P1REN           ; Enable pullup/down resistor
            bis.b   #BIT5, &P1OUT           ; Select up


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
            ; For the send dummy data task
            ;call    #i2c_start
            ;call    #i2c_tx_byte
            ;call    #i2c_stop
            ;inc.b   &COUNTER
            ;cmp.b   #0x0A, &COUNTER
            ;jeq     reset_counter               

            ; For the recieve data from AD2 task
            ;call    #i2c_start
            ;mov.b   #10101011b, &tx_byte
            ;call    #i2c_tx_byte
            ;call    #i2c_rx_byte
            ;call    #i2c_stop         
            
            mov.b   ADDRESS, &tx_byte
            call    #i2c_write
            jmp main
            nop

;------------------------------------------------------------------------------
;           Subroutines
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Start / Stop / Delay
;------------------------------------------------------------------------------
i2c_start:                                  ; Start signal, high to low on SDA, high on SCL
            bis.b   #BIT5, &P1OUT           ; Set SDA high 
            bis.b   #BIT6, &P1OUT           ; Set SCL high   
            call    #i2c_delay              ; Delay
            bic.b   #BIT5, &P1OUT           ; clear SDA low
            call    #i2c_delay              ; Delay
            bic.b   #BIT6, &P1OUT           ; Clear SCL
            ret

i2c_stop:                                   ; Stop signal, low to high on SDA, high on SCL, assume SCL high SDA low
            bic.b   #BIT5, &P1OUT           ; Clear SDA
            call    #i2c_delay              ; Delay
            bis.b   #BIT6, &P1OUT           ; Set SCL high   
            call    #i2c_delay              ; Delay
            bis.b   #BIT5, &P1OUT           ; Set SDA high
            ret

i2c_delay:
            nop
            nop
            ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Write        
;------------------------------------------------------------------------------
i2c_write:
            call    #i2c_start
            call    #i2c_send_multiple
;            call    #i2c_recieve_ack_nack
;            tst.b   R8
;            jnz i2c_nack

            ;mov.b   #0xAD, &tx_byte
            ;call    #i2c_tx_byte
            ;call    #i2c_recieve_ack_nack
            ;tst.b   R8
            ;jnz i2c_nack     

            call    #i2c_stop

            ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Send a byte / Send multiple
;------------------------------------------------------------------------------
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
            bis.b  #BIT6, &P1OUT            ; SCL high
            call   #i2c_delay               ; Delay
            bic.b  #BIT6, &P1OUT            ; SCL low
            rlc.b  tx_byte                  ; Shift MSB
            dec    R5                       ; Dec loop Counter
            jnz    tx_msb_tester            ; loop
            call    #i2c_recieve_ack_nack
            tst.b   R8
            jnz i2c_nack
            ret

i2c_send_multiple:
            mov.b   DATA_COUNT,R10          ; Move the size of data packet into R10
            mov.w   #DATA_LIST,R9           ; Move the data packet into R9
            
i2c_send_next:
            mov.b   @R9+, &tx_byte          ; First byte from R10 into tx_byte
            call    #i2c_tx_byte            ; Send byte
            dec     R10                     ; Decrease R10, number left to send
            jnz     i2c_send_next
            ret

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Receive a byte
;------------------------------------------------------------------------------
i2c_rx_byte:
            bis.b   #BIT5, &P1DIR           ; SDA input
            mov.b   #8, R6                  ; Move 8 into reg for loop
            clr.b   R7                      ; Make sure empty to recive new data

i2c_rx_loop:
            bis.b   #BIT6, &P1OUT           ; SCL high
            call    #i2c_delay              ; Delay
            bit.b   #BIT5, &P1OUT           ; Check
            jnz      rx_low                 ; Jump if SDA low
            bis.b   #BIT0, R7               ; SDA high so set the bit

rx_low: 
            rlc.b   R7                      ; Rotate the registor
            bic.b   #BIT6, &P1OUT           ; SCL low
            call    #i2c_delay              ; Delay
            dec     R6                      ; Dec R6
            jnz     i2c_rx_loop             ; Loop?

            bic.b   #BIT5, &P1OUT           ; SDA low for ack
            bis.b   #BIT5, &P1DIR           ; SDA output
            bis.b   #BIT6, &P1OUT           ; SCL high
            call    #i2c_delay              ; Delay
            bic.b   #BIT6, &P1OUT           ; SCL low
            call    #i2c_delay

            mov.b   R7, &rx_byte
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Ack / Nack
;------------------------------------------------------------------------------
i2c_recieve_ack_nack:
     
            bic.b   #BIT5, &P1DIR           ; SDA input
            call    #i2c_delay              ; Delay
           
            bis.b   #BIT6, &P1OUT           ; SCL high
            ;call    #i2c_delay              ; Delay
            
            bit.b   #BIT5, &P1IN            ; Test ack nack
            jnz     i2c_nack_recieved       ; If SDA high nack recieved
            
            bic.b   #BIT6, P1OUT            ; SCL low
            bis.b   #BIT5, &P1DIR           ; SDA output  
            clr.b   R8                      ; Clear R8

            ret

i2c_nack_recieved:  
            bis.b   #BIT5, &P1DIR           ; SDA output  
            call    #i2c_delay              ; Delay
            bic.b   #BIT6, &P1OUT           ; SCL low
            mov.b   #0x01, R8               ; Put 1 in R8 to signify NACK
            ret

i2c_nack: 
            call   #i2c_stop
            ret

;i2c_send_ack:
;            bic.b   #BIT5, &P1OUT           ; Clear SDA
;            call    #i2c_delay              ; Delay
;            bis.b   #BIT6, &P1OUT           ; Pulse SCL
;            call    #i2c_delay              ; Delay
;            bic.b   #BIT6, &P1OUT           ; SCL low
;            ret

;------------------------------------------------------------------------------

endless:
            jmp     endless
            ret

;------------------------------------------------------------------------------
;           Variables
;------------------------------------------------------------------------------

            .DATA
tx_byte:    .byte   10101010b                    ; Hold the byte to transmit before being sent
rx_byte:    .byte   0x00                    ; Data recieved from AD2, used in recieve from AD2 task
DATA_LIST:  .byte   0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09  ; Data to send for the send multiple task
DATA_COUNT: .byte   0x0A                    ; Amount of items in DATA_LIST, for the send multiple task
ADDRESS:    .byte   10101010b               ; Where send the byte to


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

            .end