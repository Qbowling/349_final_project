		AREA    MyProgram, CODE, READONLY
        EXPORT  __main

__main  PROC
        ; Enable GPIOA clock
        LDR R0, =0x40023830
        MOV R1, #1
        STR R1, [R0]

        ; Configure PA0, PA1, PA2 as outputs
        LDR R0, =0x40020000
        LDR R1, =0x00000015
        STR R1, [R0]

        ; Set address of GPIOA_ODR
        LDR R3, =0x40020014

send
        ; Load 8-bit data
        MOV R5, #0b10101010       ; Data to send
        MOV R4, #8                ; Loop counter (8 bits)

        ; Turn ON PA0 (start/latch)
        LDR R1, [R3]
        ORR R1, R1, #0x01
        STR R1, [R3]
        BL delay1

bit_check
        TST R5, #1                ; Test LSB of R5
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
        ; 1-second delay
        BL delay1

        ; Clock pulse end (PA1 LOW)
        LDR R1, [R3]
        BIC R1, R1, #0x02
        STR R1, [R3]
        BL delay1

        ; Shift data right by 1
        LSR R5, R5, #1

        ; Decrement counter
        SUBS R4, R4, #1
        BNE bit_check

        ; Done transmitting, turn off PA0
        LDR R1, [R3]
        BIC R1, R1, #0x01
        STR R1, [R3]

        ; Optional: repeat
        ;B send
        ;ENDP

;1 second delay
delay1  PROC
        MOV R2, #1000
outer
        MOV R1, #4000
inner
        SUBS R1, R1, #1
        BNE inner
        SUBS R2, R2, #1
        BNE outer
        BX LR
        ENDP

        END