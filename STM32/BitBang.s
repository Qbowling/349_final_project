        AREA    BitBang, CODE, READONLY
        EXPORT  __main

__main  PROC
        ; --- Safety delay at startup -------------------------------
        MOV R2, #1000
safe_start
        SUBS R2, R2, #1
        BNE safe_start

        ; --- Enable GPIOA clock -----------------------------------
        LDR R0, =0x40023830       ; RCC_AHB1ENR
        MOV R1, #1
        STR R1, [R0]

        ; --- Configure PA0–PA2 as output, PA4 as input -------------
        LDR R0, =0x40020000       ; GPIOA_MODER
        LDR R1, =0x00000115       ; PA0–PA2 output, PA4 = 00 (input)
        STR R1, [R0]

        ; --- Enable pull-down resistor on PA4 ----------------------
        LDR R0, =0x4002000C       ; GPIOA_PUPDR
        LDR R1, =0x00000200       ; PA4 = 10 (pull-down)
        STR R1, [R0]

        ; --- Set address of GPIOA_ODR and IDR ----------------------
        LDR R3, =0x40020014       ; ODR
        LDR R9, =0x40020010       ; IDR

main_loop
        ; --- Wait for button press on PA4 (bit 4 == 1) -------------
wait_press
        LDR R1, [R9]
        TST R1, #0x10             ; Test PA4
        BNE wait_press            ; Wait while PA4 is LOW (not pressed)

        ; --- Debounce delay (optional, ~50ms) ----------------------
        MOV R0, #50
        BL systick_delay_ms

        ; --- Wait for button release -------------------------------
wait_release
        LDR R1, [R9]
        TST R1, #0x10             ; Test PA4
        BEQ wait_release          ; Wait while PA4 is still HIGH (pressed)

        ; --- Debounce release delay -------------------------------
        MOV R0, #50
        BL systick_delay_ms

        ; --- Data transmission begins ------------------------------
        MOV R5, #0x55             ; Data to send
        MOV R4, #8                ; Bit count

        ; --- Start transmission: PA0 HIGH --------------------------
        LDR R1, [R3]
        ORR R1, R1, #0x01
        STR R1, [R3]
        PUSH {R3, R4, R5}
        MOV R0, #500
        BL systick_delay_ms
        POP {R3, R4, R5}

bit_check
        TST R5, #1
        BEQ bit_zero

bit_one
        ; Set PA1 HIGH
        LDR R1, [R3]
        ORR R1, R1, #0x02
        STR R1, [R3]
        B send_clock

bit_zero
        ; Set PA1 LOW
        LDR R1, [R3]
        BIC R1, R1, #0x02
        STR R1, [R3]

send_clock
        PUSH {R3, R4, R5}
        MOV R0, #1000
        BL systick_delay_ms
        POP {R3, R4, R5}

        LSR R5, R5, #1
        SUBS R4, R4, #1
        BNE bit_check

        ; --- End transmission: PA0 LOW -----------------------------
        LDR R1, [R3]
        BIC R1, R1, #0x01
        STR R1, [R3]
        PUSH {R3, R4, R5}
        MOV R0, #1000
        BL systick_delay_ms
        POP {R3, R4, R5}

        B main_loop              ; Wait for next button press
        ENDP

; --- SysTick delay ------------------------------------------------
systick_delay_ms PROC
        LDR R6, =0xE000E010       ; STK_CTRL
        LDR R7, =0xE000E014       ; STK_LOAD
        LDR R8, =0xE000E018       ; STK_VAL

delay_loop
        LDR R2, =16000-1          ; 1ms @ 16MHz
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