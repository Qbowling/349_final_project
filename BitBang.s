        AREA    BitBang, CODE, READONLY
        EXPORT  __main

RS      EQU 0x20      ; PA5
RW      EQU 0x40      ; PA6 (tied to GND in hardware)
EN      EQU 0x80      ; PA7

__main  PROC
        ; --- Safety delay at startup -------------------------------
        MOV R2, #1000
safe_start
        SUBS R2, R2, #1
        BNE safe_start

        ; --- Initialize LCD Display --------------------------------
        BL LCDInit

        ; --- Test Message: Show "Hi" -------------------------------
        MOV R3, #'H'
        BL LCDData
        MOV R3, #'i'
        BL LCDData

        ; --- Set up GPIOA & GPIOB ----------------------------------
        LDR R0, =0x40023830       ; RCC_AHB1ENR
        LDR R1, =0x03             ; Enable GPIOA and GPIOB
        STR R1, [R0]

        ; Configure PA4 as input (button), PA5–PA7 as output (LCD)
        LDR R0, =0x40020000       ; GPIOA base
        LDR R1, =0x28000100       ; PA4 input, PA5–PA7 output
        STR R1, [R0]

        ; Configure PB8 and PB9 as output (BitBang TX)
        LDR R0, =0x40020400       ; GPIOB base
        LDR R1, [R0]
        BIC R1, R1, #0x00030000 ; Clear MODER8
        BIC R1, R1, #0x000C0000 ; Clear MODER9
        ORR R1, R1, #0x00010000 ; Set PB8 as output
        ORR R1, R1, #0x00040000 ; Set PB9 as output
        STR R1, [R0]

        ; --- Set addresses -----------------------------------------
        LDR R3, =0x40020414       ; GPIOB_ODR
        LDR R9, =0x40020010       ; GPIOA_IDR (for PA4 button)

main_loop
        ; --- Wait for button press on PA4 --------------------------
wait_press
        LDR R1, [R9]
        TST R1, #0x10             ; Bit 4 = PA4
        BNE wait_press

        ; --- Debounce ----------------------------------------------
        MOV R0, #50
        BL systick_delay_ms

wait_release
        LDR R1, [R9]
        TST R1, #0x10
        BEQ wait_release

        MOV R0, #50
        BL systick_delay_ms

        ; --- Begin Transmission ------------------------------------
        MOV R5, #0x55             ; Data to send
        MOV R4, #8

        LDR R1, [R3]
        ORR R1, R1, #(1 << 8)     ; PB8 HIGH (Enable)
        STR R1, [R3]
        PUSH {R3, R4, R5}
        MOV R0, #500
        BL systick_delay_ms
        POP {R3, R4, R5}

bit_check
        TST R5, #1
        BEQ bit_zero

bit_one
        LDR R1, [R3]
        ORR R1, R1, #(1 << 9)     ; PB9 HIGH (Data)
        STR R1, [R3]
        B send_clock

bit_zero
        LDR R1, [R3]
        BIC R1, R1, #(1 << 9)     ; PB9 LOW (Data)
        STR R1, [R3]

send_clock
        PUSH {R3, R4, R5}
        MOV R0, #1000
        BL systick_delay_ms
        POP {R3, R4, R5}

        LSR R5, R5, #1
        SUBS R4, R4, #1
        BNE bit_check

        ; --- End transmission --------------------------------------
        LDR R1, [R3]
        BIC R1, R1, #(1 << 8)     ; PB8 LOW (End)
        STR R1, [R3]
        PUSH {R3, R4, R5}
        MOV R0, #1000
        BL systick_delay_ms
        POP {R3, R4, R5}

        B main_loop
        ENDP

; ======================================================
; LCD Initialization & Display Functions
; ======================================================

LCDInit FUNCTION
        LDR R0, =0x40023830          ; RCC AHB1ENR
        MOV R1, #0x05                ; Enable GPIOA and GPIOC
        STR R1, [R0]

        ; GPIOA: PA5–PA7 as output
        LDR R0, =0x40020000
        LDR R1, =0x28005400
        STR R1, [R0]

        ; GPIOC: PC0–PC7 as output
        LDR R1, =0x40020800
        LDR R2, =0x00015555
        STR R2, [R1]

        PUSH {LR}
        BL delay

        MOV R2, #0x38                ; Function set
        BL LCDCommand
        MOV R2, #0x0E                ; Display ON
        BL LCDCommand
        MOV R2, #0x01                ; Clear
        BL LCDCommand
        MOV R2, #0x06                ; Entry mode
        BL LCDCommand

        POP {LR}
        BX LR
        ENDP

LCDCommand FUNCTION
        STRB R2, [R1, #0x14]         ; Send to GPIOC_ODR
        MOV R2, #0x00
        ORR R2, R2, #EN
        STRB R2, [R0, #0x14]

        PUSH {LR}
        BL delay
        MOV R2, #0x00
        STRB R2, [R0, #0x14]
        POP {LR}
        BX LR
        ENDP

LCDData FUNCTION
        STRB R3, [R1, #0x14]         ; Data to GPIOC_ODR
        MOV R2, #RS
        ORR R2, R2, #EN
        STRB R2, [R0, #0x14]

        PUSH {LR}
        BL delay
        MOV R2, #RS
        STRB R2, [R0, #0x14]
        POP {LR}
        BX LR
        ENDP

delay FUNCTION
        MOV R5, #200
loop1   MOV R4, #0xFF
loop2   SUBS R4, #1
        BNE loop2
        SUBS R5, #1
        BNE loop1
        BX LR
        ENDP

; ======================================================
; SysTick Delay (1ms * R0)
; ======================================================
systick_delay_ms PROC
        LDR R6, =0xE000E010
        LDR R7, =0xE000E014
        LDR R8, =0xE000E018

delay_loop
        LDR R2, =16000-1
        STR R2, [R7]
        MOV R2, #0
        STR R2, [R8]
        MOV R2, #5
        STR R2, [R6]

wait_tick
        LDR R2, [R6]
        TST R2, #0x10000
        BEQ wait_tick

        MOV R2, #0
        STR R2, [R6]

        SUBS R0, R0, #1
        BNE delay_loop
        BX LR
        ENDP

        END
