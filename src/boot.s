.setcpu "6502"
.segment "CODE"

;; CPU setup

reset:
    ; Disable CPU interrupts
    ; (This disables IRQs but not NMIs.)
    sei

    ; Disable BCD (decimal) arithmetic
    cld

    ; FRAMECTR: Disable APU frame IRQs
    ldx #$80
    stx $4017

    ; Initialize CPU stack pointer to 0x01ff
    ldx #$ff
    txs

    ; Set X to zero (by overflow)
    inx

    ; PPUCTRL: Disable vblank NMI (and normalize other data)
    stx $2000

    ; PPUMASK: Disable tiles and sprites, and color emphasis
    ; The PPU must be disabled before modifying the memory.
    stx $2001

    ; Disable the sound DMC (delta modulation channel) interrupt and DMA.
    ;
    ; The DMC is the only audio channel that uses interrupts and DMA reads.
    ; (DMA is direct memory access, an automated transfer launched by the CPU.)
    stx $4010   ; DMC off


;; PPU boot

; The CPU starts before the PPU, whose registers may not yet be reliable.
; Wait two vblank cycles for the PPU to restart.

; First vblank
vblank1:
    ; Read bit 7 of PPUSTATUS into N flag
    ;   NOTE: `bit` sets multiple status flags
    bit $2002

    ; Jump if N is clear
    bpl vblank1

; Reading PPUSTATUS also unsets bit7.
; It will not be set again until the next vblank.

; Second vblank
vblank2:
    bit $2002
    bpl vblank2


;; Set background color

    ; The active PPU RAM address is set by writing a two-byte value to PPUADDR.
    ; The CPU streams the upper byte to PPUADDR, followed by the lower byte.
    ;
    ; The "write toggle latch", `w`, is an internal PPU bit register which
    ; determines whether the next byte to PPUADDR is the upper byte of a new
    ; address, or the lower byte of an address in progress.  This register
    ; cannot be read by the CPU, so `w` is in general not known.
    ;
    ; However, reading PPUSTATUS will reset the write toggle latch, ensuring
    ; that the next write to PPUADDR is an upper byte.  This process is
    ; referred to as "resetting the latch".

    ; Read PPUSTATUS
    lda $2002

    ; Write the upper, then lower, address to PPUADDR.
    ; $3f00 is the address of the first color of the first palette
    lda #$3f
    sta $2006
    lda #$00
    sta $2006

    ; Write some color to PPUDATA, which writes to $3f00.
    lda #$25
    sta $2007

    ; Set PPUMASK to enable background rendering
    ;        0 : Color
    ;      00  : Hide leftmost 8 pixels
    ;    01    : Enable background, disable sprites
    ; 000      : Disable color highlights
    lda #%00001000  ; background on left 8px off
    sta $2001


;; Main loop

main:
    jmp main


; Interrupts (return to program)

nmi:
    rti

irq:
    rti


; Vector interrupt table
.segment "VECTORS"
    .word nmi
    .word reset
    .word irq
