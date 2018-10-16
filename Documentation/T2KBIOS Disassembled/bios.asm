
; Ralf Brown's Interrupt List has some information on the T2K here:
;    http://www.ctyme.com/intr/cat-044.htm
;
; It documents calls that are not in this disassmbled BIOS.  I can
; only assume the DOS bootstrap contains supplemental BIOS support.
; Otherwise, there are an aweful lot of interrupt handlers in this
; code that do effectively nothing but iret.  It seems a waste of
; perfectly good hardware.
;
; The fact disk routines here have no write support means a BIOS
; supplement must be coming from the DOS boot-strap.  Also the
; video BIOS only implements set/get character set and teletype


LF        equ   10
FF        equ   12
CR        equ   13
SPACE     equ   32

NORMAL_CHAR_ATTR   equ   00ah    ; No blink, reg intensity, normal


LBDA_SEG                         equ   00000h
EBDA_OS_OFFSET                   equ    0064h   ; [W] OS jump offset
LBDA_HDDA_SEGMENT                equ    040eh   ; [W] Pointer to disk context
LBDA_PCB_REVISION                equ    0420h   ; [B]
LBDA_GRAPHICS_CONFIG             equ    0422h   ; [W] Graphics config bits
LBDA_RAMEND_UPPER                equ    0424h   ; [W] Upper 16 bits
LBDA_RAMEND_LOWER                equ    0426h   ; [W] Lower 4 bits
LBDA_RAMEND_TOP                  equ    0428h   ; [W] Appears to be same as upper
LBDA_TEXT_FB_OFF                 equ    042ah   ; [W]Text frame buffer offset
LBDA_TEXT_FB_SEG                 equ    042ch   ; [W]Text frame buffer seg
LBDA_SYS_FAULT                   equ    0432h   ; [W]
LBDA_UNK_07                      equ    0442h   ; [B] MBR from 0 FDC, 2 HDC
LBDA_OS_OFFSET                   equ    0444h   ; [W] OS jump offset
LBDA_OS_SEGMENT                  equ    0446h   ; [W] OS jump segment
LBDA_DMA_MUX_CTRL                equ    044ah   ; [B]
LBDA_VIDEO_FB_OFF                equ    0472h   ; [W] Text frame buffer offset
LBDA_VIDEO_FB_SEG                equ    0474h   ; [W] Text frame buffer seg
LBDA_VIDEO_CSET_BASE             equ    0476h   ; [D]
LBDA_VIDEO_CSET_8X8_LOWER_PTR    equ    0476h   ; [D]
LBDA_VIDEO_CSET_8X8_UPPER_PTR    equ    047ah   ; [D]
LBDA_VIDEO_CSET_8X16_LOWER_PTR   equ    047eh   ; [D]
LBDA_VIDEO_CSET_8X16_UPPER_PTR   equ    0482h   ; [D]
LBDA_CFG_VIDEO_FB                equ    0486h   ; [B] port 101h reg value (FB)
LBDA_CFG_PORT0                   equ    0487h   ; [B] port 0 reg value
LBDA_FDC_BOOT_RETRIES            equ    048ah   ; [B]
LBDA_HDC_BOOT_RETRIES            equ    048bh   ; [B]


EBDA_SEG                         equ   01800h
EBDA_MEMSIZE                     equ    0000h   ; in 64KB pages
EBDA_UNK_02                      equ    0002h   ;
EBDA_ROM_CHECKSUM                equ    0004h   ; [W] ROM checksum
EBDA_RAMTEST_OFFSET              equ    0006h   ; [W] segment offset of end
EBDA_RAMTEST_ENDSEG              equ    0008h   ; [W] segment where ended
EBDA_RAMTEST_PATTERN             equ    000ah   ; [W] Last pattern written
EBDA_RAMTEST_ENDADDR             equ    000ch   ; [W] Upper 16 bits of end
EBDA_ISR_COUNTS                  equ    0020h   ; No longer used
EBDA_ISR_COUNT_PARITY            equ    0020h   ; No longer used
EBDA_ISR_COUNT_BUS_TIMEOUT       equ    0022h   ; No longer used
EBDA_ISR_COUNT_UART              equ    0024h   ; No longer used
EBDA_ISR_COUNT_SDLC              equ    0026h   ; No longer used
EBDA_ISR_COUNT_FDC               equ    0028h   ; No longer used
EBDA_ISR_COUNT_NETWORK           equ    002ah   ; No longer used
EBDA_ISR_COUNT_HDC_PRI           equ    002ch   ; No longer used
EBDA_ISR_COUNT_HDC_SEC           equ    002eh   ; No longer used
EBDA_ISR_COUNT_KEYBOARD          equ    0030h   ; No longer used
EBDA_ISR_COUNT_CRT               equ    0032h   ; No longer used
EBDA_VIDEO_CURSOR_POS            equ    0040h   ; [W] MSB row, LSB col
EBDA_VIDEO_BG_TEXT_ATTR          equ    0042h   ; [B] Current teletype attribute
EBDA_VIDEO_FG_TEXT_ATTR          equ    0043h   ; [B] Current teletype attribute

EBDA_OS_SEGMENT                  equ    0066h   ; [W] OS jump segment

CRT_CHARSET_SEG                  equ   0f800h
MBR_LOAD_SEG                     equ   01b00h

CONFIG_REV          equ    00h     ; PCB rev resistor strappings
CONFIG_MAXRAM       equ    01h     ; in 64KB blocks
CONFIG_UMCS         equ    02h     ; defines ROM starting address
CONFIG_128K_VIDEO   equ    04h     ; Base for mem-sized value for 101h
CONFIG_128K_PORT0   equ    05h     ; Base for mem-sized value for   0h



_TEXT segment word public use16 'CODE'

	public _entry
	public _init_entry

	assume cs:_TEXT, ds:nothing, es:nothing


	org    00000h

_init_entry:
	cli
	cld
	jmp    _init
	nop

_str_copyright:   ; Unreferenced by code - placed here as a signature
	db     'BOOT ROM version 02.00.00', CR, LF
	db     'Copyright 1983,84 Tandy Corp.', CR, LF
	db     'All rights reserved.', CR, LF, 0ffh

_init:

	; Setup a working stack
	mov    ax, 0050h
	mov    ss, ax
	mov    sp, 0100h

	; Make sure there is an iret at NMI location
	mov    ax, 0
	mov    ds, ax
	mov    word ptr ds:[008h], offset _isr_nmi
	mov    word ptr ds:[00ah], cs

	; Rev.3 turns on bit 5 - not sure of the meaning atm
	mov    al, cs:[bp + CONFIG_128K_PORT0]
	mov    dx, 0
	out    dx, al

	; PIT control: Timer 2 (DRAM refresh) -> LE, Mode 2 (rate gen)
	mov    al, 0b4h
	mov    dx, 0046h
	out    dx, al
	nop
	nop

	; Load Timer 2 count (LE) = 001fh -> 2 MHz / 31 = 15.5us rate
	mov    al, 1fh
	mov    dx, 0044h
	out    dx, al
	nop
	nop

	mov    al, 0
	mov    dx, 0044h
	out    dx, al
	nop
	nop


	; Perform a RAM sizing loop

	cld

	mov    bh, 0eh      ; count to 896K (64K * 14)
	mov    bl, 0        ; current count

	mov    ax, 0        ; Start at 0000:0000
	mov    ds, ax
	mov    si, 0

_ramsize_loop:
	mov    ax, 5a5ah
	mov    ds:[si], ax

	; delay - why? RAM settling time?
	mov    cx, 1000
_init_delay1:
	loop   _init_delay1

	cmp    ax, ds:[si]
	jne    _ramsize_done
	not    ax
	mov    ds:[si], ax

	mov    cx, 1000
_init_delay2:
	loop   _init_delay2

	cmp    ax, ds:[si]
	jne    _ramsize_done

	mov    ax, ds
	add    ax, 1000h    ; +64KB
	mov    ds, ax

	inc    bl
	cmp    bl, bh
	jb     _ramsize_loop

_ramsize_done:

	; This forces ram size to a minimum of 128K but it does it
	; regardless if things passed or not.  Not sure why it doesn't
	; fail here if the first 128KB failed to hold content in the
	; first word.  But it doesn't hurt to let the test pass fail.

	cmp    bl, 2
	jae    _ramtest_setup
	mov    bl, 2

_ramtest_setup:
	; Set the test size (64K page count) to what was sized
	mov    bh, bl
	mov    bl, 0

	; Reset the starting pointer past NMI vector for first page
	mov    ax, 0
	mov    ds, ax
	mov    si, 000ch
	mov    cx, 7ffah
	jmp    _ramtest_start

_ramtest_next:
	; Subsequent pages start at begining
	mov    si, 0
	mov    cx, 08000h

_ramtest_start:
	mov    dx, 5a5ah

_ramtest_loop:
	mov    ds:[si], dx
	nop
	lodsw
	cmp    ax, dx
	jne    _ramtest_failed
	inc    dl
	dec    dh
	nop
	nop
	loop   _ramtest_loop

	; next 64KB page
	mov    ax, ds
	add    ax, 1000h
	mov    ds, ax
	inc    bl
	cmp    bl, bh
	jc     _ramtest_next
	jmp    _ramtest_clip

_ramtest_failed:

	; Again, this forces ram size to a minimum of 128K even on
	; failure.  Not sure why.  The config table for RAM sizing
	; does require a start of di=2, so that may be why - for
	; alignment purposes

	cmp    bl, 2
	jae    _ramtest_failed_adj
	mov    bl, 2

_ramtest_failed_adj:

	; Adjust pointer back to the place that failed
	dec     si
	mov     cl, dh
	mov     ch, ah
	cmp     al, dl
	jz      _ramtest_clip
	dec     si
	mov     cl, dl
	mov     ch, al

_ramtest_clip:
	mov     al, cs:[bp + CONFIG_MAXRAM]
	cmp     bl, al
	jbe     _ramtest_done
	mov     bl, al

_ramtest_done:

	; This rounds down the size to 128KB border and indexes
	; the config table for a value to write to port 101h which
	; is the frame buffer start address and then port 0 which
	; controls speaker, resets, and clock gating

	and    bl, 0feh
	mov    bh, 0
	mov    di, bx

	mov    ax, cs:[bp + di + CONFIG_128K_VIDEO - 2]
	mov    dx, 0101h
	out    dx, al

	mov    al, ah
	mov    dx, 0
	out    dx, al

	; ds points to first segment after end of RAM -> dx

	mov    dx, ds

	mov    ax, EBDA_SEG
	mov    ds, ax

	mov    ax, LBDA_SEG
	mov    es, ax

	mov    al, cs:[bp + CONFIG_REV]
	mov    es:[LBDA_PCB_REVISION], al

	mov    bh, 0
	mov    ds:[EBDA_MEMSIZE], bx
	mov    di, bx

	mov    ax, cs:[bp + di + CONFIG_128K_VIDEO - 2]

	mov    es:[LBDA_CFG_VIDEO_FB], al
	mov    es:[LBDA_CFG_PORT0], ah

	mov    word ptr es:[LBDA_SYS_FAULT], 0

	mov    ds:[EBDA_RAMTEST_OFFSET], si
	mov    ds:[EBDA_RAMTEST_ENDSEG], dx
	mov    ds:[EBDA_RAMTEST_PATTERN + 0], cl
	mov    ds:[EBDA_RAMTEST_PATTERN + 1], ch

	mov    ax, si
	shr    ax, 04h
	add    ax, dx

	mov    ds:[EBDA_RAMTEST_ENDADDR], ax
	cmp    ax, 2000h
	jae    _ramtest_seg_ok

	mov    ax, 2000h
	jmp    _ramtest_sysfault

_ramtest_seg_ok:
	test    ax, 1fffh
	jz      _ramtest_off_ok

	and     ax, 0e000h
	jmp     _ramtest_sysfault

_ramtest_off_ok:
	cmp     si, 0
	jz      _ramtest_good

_ramtest_sysfault:
;	or     word ptr es:[LBDA_SYS_FAULT], 20h
	db     026h, 081h, 00eh, 032h, 004h, 020h, 000h   ; fixup


_ramtest_good:

	; ax = top 16 bits of end of ram
	mov     es:[LBDA_RAMEND_UPPER], ax
	mov     word ptr es:[LBDA_RAMEND_LOWER], 0

	mov     es:[LBDA_RAMEND_TOP], ax
	sub     ax, 0140h        ; 5 KB

	mov     word ptr es:[LBDA_VIDEO_FB_OFF], 0
	mov     es:[LBDA_VIDEO_FB_SEG], ax

	mov     word ptr es:[LBDA_TEXT_FB_OFF], 0
	mov     es:[LBDA_TEXT_FB_SEG], ax

	; Verify ROM checksum

	mov     si, 0
	mov     cx, 1000h   ; 4K words
	xor     ax, ax

_rom_checksum:
	add     al, cs:[si]
	inc     si
	add     ah, cs:[si]
	inc     si
	loop    _rom_checksum

	mov     ds:[EBDA_ROM_CHECKSUM], ax

	or      ax, ax
	jz      _rom_checksum_ok
;	or     word ptr es:[LBDA_SYS_FAULT], 10h
	db     26h, 081h, 0eh, 32h, 04h, 10h, 00h


_rom_checksum_ok:

	mov    ax, LBDA_SEG
	mov    ds, ax

	mov    dx, 0180h         ; Hi-res graphics option status reg
	in     al, dx

	mov    cl, 28h
	mov    ch, 21h

	cmp    al, 0ffh
	je     _graphics_done    ; Not installed

	test   al, 1
	jz     _crt_set_colors

	or     cl, 1
	or     ch, 4
	jmp    _graphics_done


_crt_set_colors:

	push   ax

	mov    dx, 0198h        ; Background high intensity color = 0
	mov    al, 0
	out    dx, al

	mov    dx, 019ah        ; Character high intensity color = 15
	mov    al, 15
	out    dx, al

	mov    dx, 019ch        ; Background low intensity color = 0
	mov    al, 0
	out    dx, al

	mov    dx, 019eh        ; Character low intensity color = 7
	mov    al, 7
	out    dx, al

	pop    ax

	test   al, 20h
	jnz    _graphics_rev2

	test   al, 2
	jnz    _graphics_3planes
	or     cl, 2
	jmp    _graphics_ext

_graphics_3planes:
	or     cl, 4
	jmp    _graphics_ext

_graphics_rev2:
	or     cl, 6

_graphics_ext:
	or     ch, 2

_graphics_done:
	mov    ds:[LBDA_GRAPHICS_CONFIG], cx


	; This places _TEXT:_isr_default from vector 3 to 255

	mov    ax, cs
	mov    ds, ax

	mov    ax, 0
	mov    es, ax

	cld
	mov    di, 000ch
	mov    cx, 00fdh

_setup_default_vectors:
	mov    ax, _isr_default
	stosw
	mov    ax, _TEXT
	stosw
	loop   _setup_default_vectors

	mov    si, _initial_vectors
	nop

_setup_specific_vectors:
	lodsw
;	cmp    ax, 0ffffh
	db     03dh, 0ffh, 0ffh   ; fixup
	jz     _setup_io
	mov    di, ax
	movsw
	jmp    _setup_specific_vectors


_setup_io:

	mov    ax, cs
	mov    ds, ax

	mov    si, _portlist_pici
	nop
	call   _program_io_list

	mov    si, _portlist_pic1
	nop
	call   _program_io_list

	mov    si, _portlist_pic2
	nop
	call   _program_io_list


	mov    ax, cs
	mov    es, ax

	; Set lower 128 chars 8x8
	mov    bx, _char_table_8x8
	nop
	mov    al, 1
	mov    ah, 10h
	int    52h

	; Set upper 128 chars 8x8
	mov    bx, _char_table_8x8
	nop
	mov    al, 3
	mov    ah, 10h
	int    52h

	; Set lower 128 chars 8x16
	mov    bx, _char_table_8x16
	nop
	mov    al, 5
	mov    ah, 10h
	int    52h

	; Set upper 128 chars 8x16
	mov    bx, _char_table_8x16
	nop
	mov    al, 7
	mov    ah, 10h
	int    52h


	; Initialize CRT controller
	mov    ax, EBDA_SEG
	mov    ds, ax

	mov    bl, NORMAL_CHAR_ATTR
	call   _clear_screen

	mov    ax, cs
	mov    ds, ax
	mov    si, _portlist_crt
	nop
	call   _program_io_list

	cld

	mov    ax, cs
	mov    ds, ax

	mov    ax, EBDA_SEG
	mov    es, ax

	mov    ax, 0
	mov    di, EBDA_ISR_COUNTS
	mov    cx, 10
	rep    stosw

	sti
	call   _print_memsize
	call   _delay_big

	mov    ax, EBDA_SEG
	mov    ds, ax

	mov    ax, LBDA_SEG
	mov    es, ax

	mov    word ptr ds:[EBDA_UNK_02], 0
	mov    byte ptr es:[LBDA_FDC_BOOT_RETRIES], 10
	mov    byte ptr es:[LBDA_HDC_BOOT_RETRIES], 10

	push   ds
	push   es
	call   _boot_fdc
	pop    es
	pop    ds
	jc     _try_hdc

	mov    al, 0
	call   _chain_to_dos

_try_hdc:

	push   ds
	push   es
	call   _boot_hdc
	pop    es
	pop    ds
	jc     _halt_and_catch_fire

	mov    al, 2
	call   _chain_to_dos

_halt_and_catch_fire:
	jmp    _halt_and_catch_fire



	org    00314h

_chain_to_dos proc near public

	push   ds
	push   es

	mov    es:[LBDA_UNK_07], al

	mov    ax, ds:[19h * 4 + 0]
	mov    es:[LBDA_OS_OFFSET], ax

	mov    ax, ds:[19h * 4 + 2]
	mov    es:[LBDA_OS_SEGMENT], ax

	; Jump to DOS bootstrap - does not return unless controlled failure
	mov    es, ax
	callf  dword ptr ds:[19h * 4]      ; jmp to int 19h

	pop    es
	pop    ds

	ret

_chain_to_dos endp



_boot_failed_1:
	jmp    $+2

_boot_failed_2:
	stc
	jmp    _boot_done

_boot_ok:
	clc

_boot_done:
	ret



	org    00338h

_boot_defaults proc near public

	mov     word ptr ds:[14h * 4 + 0], cx
	mov     word ptr ds:[14h * 4 + 2], cx
	mov     word ptr ds:[19h * 4 + 0], 0
	mov     word ptr ds:[19h * 4 + 2], MBR_LOAD_SEG
	mov     word ptr ds:[18h * 4 + 0], 0
	mov     word ptr ds:[18h * 4 + 2], MBR_LOAD_SEG

	ret

_boot_defaults endp



	org    00359h

_boot_fdc proc near public

	mov    cx, 1000
	call   _boot_defaults
	call   _fdc_install

_boot_fdc_try:

	mov    dl, 0        ; Floppy A:
	mov    ah, 0        ; Reset drive
	int    56h

	or     ah, ah
	jnz    _boot_fdc_check_sts_2

	mov    dh, 0        ; Head 0
	mov    dl, 0        ; Floppy A:
	mov    ch, 0        ; Track 0
	mov    cl, 1        ; Sector 1
	mov    al, 1        ; 1 Sector
	les    bx, ds:[18h * 4]  ; int 18h pointer
	mov    ah, 2        ; read sectors
	int    56h

	or     ah, ah
	jz     _boot_fdc_check_sts_1

	dec    byte ptr es:[LBDA_FDC_BOOT_RETRIES]
	jnz    _boot_fdc_try

	jmp    _boot_fdc_failed
	nop

_boot_fdc_check_sts_1:
	cmp    al, 1
	jnz    _boot_fdc_failed
	jmp    _boot_ok

_boot_fdc_check_sts_2:
	test   ah, 7fh
	jnz    _boot_fdc_failed
	jmp    _boot_failed_2

_boot_fdc_failed:
	jmp    _boot_failed_1

_boot_fdc endp



	org    0039bh

_boot_hdc proc near public

	mov    cx, 1000
	call   _boot_defaults
	call   _hdc_install

_boot_hdc_try:

	mov    dl, 080h     ; Hard drive C:
	mov    ah, 0        ; Reset drive
	int    56h

	or     ah, ah
	jnz    _boot_hdc_failed

	mov    dh, 0        ; Head 0
	mov    dl, 080h     ; Hard drive C:
	mov    ch, 0        ; Cylinder 0
	mov    cl, 1        ; Sector 1
	mov    al, 1        ; 1 Sector
	les    bx, ds:[18h * 4]  ; int 18h pointer
	mov    ah, 2        ; read sectors
	int    56h

	or     ah, ah
	jz     _boot_hdc_check_sts

	dec    byte ptr es:[LBDA_HDC_BOOT_RETRIES]
	jnz    _boot_hdc_try

	jmp    _boot_hdc_failed
	nop

_boot_hdc_check_sts:
	cmp    al, 1
	jnz    _boot_hdc_failed
	jmp    _boot_ok

_deadlabel_1:
	jmp    _boot_failed_2

_boot_hdc_failed:
	jmp    _boot_failed_1

_boot_hdc endp



	org    003dbh

	public _isr_nmi
	public _isr_default
	public _isr_cpu_fault
	public _isr_spurious     ; this is actually bad is it does not EOI
	public _isr_fault_unk_1
	public _isr_fault_unk_2
	public _isr_fault_unk_3

_isr_nmi:
	iret

_isr_default:
	push   ax
	mov    ax, 1
	jmp    _isr_sysfault

_isr_cpu_fault:
	push   ax
	mov    ax, 2
	jmp    _isr_sysfault

_isr_spurious:
	push   ax
	mov    ax, 4
	jmp    _isr_sysfault

_isr_fault_unk_1:
	push   ax
	mov    ax, 8
	jmp    _isr_sysfault

_isr_fault_unk_2:
	push   ax
	mov    ax, 0040h
	jmp    _isr_sysfault

_isr_fault_unk_3:
	push   ax
	mov    ax, 0080h

_isr_sysfault:

	push   ds
	push   bx

	mov    bx, LBDA_SEG
	mov    ds, bx

	or     ds:[LBDA_SYS_FAULT], ax

	pop    bx
	pop    ds
	pop    ax

	iret



	org    0040dh

_isr_default_pic0 proc near public

	sti

	push   ds
	pusha

	call   _pic0_eoi

	popa
	pop    ds

	iret

_isr_default_pic0 endp




	org    00416h

_isr_default_pic1 proc near public

	sti

	push   ds
	pusha

	call   _pic1_eoi

	popa
	pop    ds

	iret

_isr_default_pic1 endp




	org    0041fh

_isr_parity_error proc near public

	sti

	push   ds
	pusha

	mov    si, EBDA_ISR_COUNT_PARITY
	call   _isr_update_count

	jz     $+2
	call   _pici_eoi

	popa
	pop    ds

	iret

_isr_parity_error endp




	org    00430h

_isr_fdc_old proc near public

	sti

	push   ds
	pusha

	mov    si, EBDA_ISR_COUNT_FDC
	call   _isr_update_count

	jz     $+2
	call   _pic0_eoi

	popa
	pop    ds

	iret

_isr_fdc_old endp




	org    00441h

_isr_hdc proc near public

	sti

	push   ds
	pusha

	mov    si, EBDA_ISR_COUNT_HDC_PRI
	call   _isr_update_count

	jz     $+2
	call   _pic0_eoi

	popa
	pop    ds

	iret

_isr_hdc endp




	org    00452h

_isr_keyboard proc near public

	sti

	push   ds
	pusha

	mov    si, EBDA_ISR_COUNT_KEYBOARD
	call   _isr_update_count

	jz     $+2
	call   _pic1_eoi

	popa
	pop    ds

	iret

_isr_keyboard endp




	org    00463h

_isr_crt proc near public

	sti

	push   ds
	pusha

	mov    si, EBDA_ISR_COUNT_CRT
	call   _isr_update_count

	jz     $+2
	call   _pic1_eoi

	popa
	pop    ds

	iret

_isr_crt endp



; This appears to have increamented WORD counters in the EBDA to
; record ISR counts.  But the code is gone or was commented out.

	org    00474h

_isr_update_count proc near public

	mov    ax, EBDA_SEG
	mov    ds, ax

	mov    ax, 0ffffh

	jmp    _isr_update_count_done

_isr_update_count_unreachable:
	mov    ax, 0

_isr_update_count_done:

	nop
	nop
	nop

	or      ax, ax

	ret

_isr_update_count endp




; Issues EOI in either external PIC or internal one

	org    00487h

	public _pic0_eoi
	public _pic1_eoi
	public _pici_eoi

_pic0_eoi:

	mov    dx, 0060h
	mov    al, 20h
	jmp    _pic_eoi_ext

_pic1_eoi:

	mov    dx, 0070h
	mov    al, 20h

_pic_eoi_ext:

	cli
	out    dx, al
	mov    al, 0bh
	out    dx, al
	nop
	nop
	in     al, dx
	or     al, al
	jnz    pic_eoi_done

_pici_eoi:

	cli
	mov    dx, 0ff22h
	mov    ax, 08000h
	out    dx, ax

pic_eoi_done:
	sti

	ret



	org    004a9h

_delay_big proc near public

	mov    bx, 1000

_delay_big_loop:
	call   _delay_min
	dec    bx
	jnz    _delay_big_loop

	ret

_delay_big endp




_unreachable_frag:
	out    dx, al



	org    004b4h

_delay_min proc near public

	mov    cx, 500
_delay_min_loop:
	loop   _delay_min_loop

	ret

_delay_min endp




	org    004bah

_program_io_list proc near public

	lodsb
	or     al, al            ; zero terminates list
	jz     _program_io_list_done

	dec    al
	jnz    _program_io_list_byte

_program_io_list_word:
	lodsw
	mov    dx, ax
	lodsb
	out    dx, al
	jmp    _program_io_list  ; itterate

_program_io_list_byte:
	lodsw
	mov    dx, ax
	lodsw
	out    dx, ax
	jmp    _program_io_list  ; itterate

_program_io_list_done:

	ret

_program_io_list endp



	org    004d2h

	; 0 terminate list, 2 is dw port, dw value, 1 is dw port, db value

	public _portlist_pici
	public _portlist_pic1
	public _portlist_pic2
	public _portlist_crt


_portlist_pici:
	; Interrupt Mask: DMA interrupts off, all others unmasked
	db     2, 028h, 0ffh, 0c0h, 000h   ; ff28: 00c0
	; Priority Mask: All interrupt priorities unmasked
	db     2, 02ah, 0ffh, 007h, 000h   ; ff2a: 0007
	; INT0: prio 0, edge trig, unmasked, cascade, special fully nested
	db     2, 038h, 0ffh, 060h, 000h   ; ff38: 0060
	; INT1: prio 5, edge trig, unmasked, cascade, special fully nested
	db     2, 03ah, 0ffh, 065h, 000h   ; ff3a: 0065
	; DMA0 control: unmasked, prio 2
	db     2, 034h, 0ffh, 002h, 000h   ; ff34: 0002
	; DMA1 control: unmasked, prio 3
	db     2, 036h, 0ffh, 003h, 000h   ; ff36: 0003
	; Timer control: unmasked, prio 7
	db     2, 032h, 0ffh, 007h, 000h   ; ff32: 0007
	; End of list
	db     0


_portlist_pic1:
	db     1, 060h, 000h, 013h         ; ICW1: edge trig, single, base 10h
	db     1, 062h, 000h, 070h         ; ICW2: base 70h
	db     1, 062h, 000h, 00dh         ; ICW3: Slave ID 5?
	db     1, 062h, 000h, 0ebh         ; ICW4: buffered slave, Auto EOI, x86
	db     0                           ; End of List


_portlist_pic2:
	db     1, 070h, 000h, 013h         ; ICW1: edge trig, single, base 10h
	db     1, 072h, 000h, 078h         ; ICW2: base 78h
	db     1, 072h, 000h, 00dh         ; ICW3: S3, S1, S0 have slaves (wtf?)
	db     1, 072h, 000h, 0fch         ; ICW4: SPFN, buffered master, Normal EOI, 
	db     0                           ; End of List


_portlist_crt:
	db     1, 02ch, 001h, 000h         ; R16h: Reset command
	db     1, 02ch, 001h, 000h         ; R16h: Reset command
	db     1, 02ch, 001h, 000h         ; R16h: Reset command
	db     1, 02ch, 001h, 000h         ; R16h: Reset command
	db     1, 000h, 001h, 06ah         ; R00h: Chars per horizontal period
	db     1, 002h, 001h, 04fh         ; R01h: Chars per data row
	db     1, 004h, 001h, 010h         ; R02h: Horizontal delay
	db     1, 006h, 001h, 008h         ; R03h: HSync width
	db     1, 008h, 001h, 008h         ; R04h: VSync width
	db     1, 00ah, 001h, 021h         ; R05h: Vertical delay
	db     1, 00ch, 001h, 052h         ; R06h: Pin config / Cursor/Blank Skew
	db     1, 00eh, 001h, 018h         ; R07h: Visible rows per frame
	db     1, 010h, 001h, 02fh         ; R08h: Scan lines per frame/row
	db     1, 012h, 001h, 0b8h         ; R09h: Scan lines per frame
	db     1, 014h, 001h, 06ah         ; R0ah: DMA burst delay/count
	db     1, 016h, 001h, 002h         ; R0bh: Operational mode
	db     1, 018h, 001h, 000h         ; R0ch: Table start (LSB)
	db     1, 01ah, 001h, 036h         ; R0dh: Table start (MSB)
	db     1, 01ch, 001h, 000h         ; R0eh: Aux addr reg 1 (LSB)
	db     1, 01eh, 001h, 000h         ; R0fh: Aux addr reg 1 (MSB)
	db     1, 020h, 001h, 0feh         ; R10h: Sequential break reg 1
	db     1, 022h, 001h, 0feh         ; R11h: Data row start
	db     1, 024h, 001h, 0feh         ; R12h: Data row end / Seq break reg 2
	db     1, 026h, 001h, 000h         ; R13h: Aux addr reg 2 (LSB)
	db     1, 028h, 001h, 000h         ; R14h: Aud addr reg 2 (MSB)
	db     1, 02eh, 001h, 000h         ; R17h: Cursor offset
	db     1, 030h, 001h, 000h         ; R18h: Vert cursor position
	db     1, 032h, 001h, 000h         ; R19h: Horz cursor position
	db     1, 034h, 001h, 000h         ; R1ah: Interrupt enable
	db     1, 02ah, 001h, 000h         ; R15h: Start command
	db     1, 02ah, 001h, 000h         ; R15h: Start command
	db     1, 02ah, 001h, 000h         ; R15h: Start command
	db     1, 02ah, 001h, 000h         ; R15h: Start command
	db     0                           ; End of List



	org    0059dh

_print_memsize proc near public

	push   ds
	push   es

	mov    ax, EBDA_SEG
	mov    ds, ax

	mov    ax, LBDA_SEG
	mov    es, ax

	mov    ax, es:[LBDA_SYS_FAULT]
	or     ax, ax
	jnz    _print_sysfault

	mov    bl, NORMAL_CHAR_ATTR
	call   _set_color
	mov    si, _str_memsize
	nop
	call   _puts

	mov    si, ds:[EBDA_MEMSIZE]
	sub    si, 2
	add    si, si
	add    si, _str_mem128k
	call   _puts

	mov    si, _str_memk
	nop
	call   _puts

	call   _print_newline
	jmp    _print_memsize_done

_print_sysfault:
	mov    bl, NORMAL_CHAR_ATTR
	call   _set_color
	mov    si, _str_sysfail
	nop
	call   _puts
	call   _print_newline

_sysfail_halt:
	jmp    _sysfail_halt

_print_memsize_done:
	pop    es
	pop    ds

	ret

_print_memsize endp



	org    005edh

	public _print_newline
	public _print_bell
	public _print_dblspace

_print_newline:

	mov    bl, NORMAL_CHAR_ATTR
	call   _set_color

	mov    si, _str_newline
	nop
	jmp    _puts

_print_bell:

	mov    si, _str_bell
	nop
	jmp    _puts

_deadlabel_5:
	mov    si, _str_dblspace
	nop

_puts proc near public

	push   ax
	push   bx
	mov    bl, 15       ; High intensity white

_puts_loop:
	mov    al, cs:[si]
	inc    si
	cmp    al, 0ffh
	jz     _puts_done
	call   _putc
	jmp    _puts_loop

_puts_done:
	pop    bx
	pop    ax

	ret

_puts endp



	org    00616h

_set_color proc near public

	push   ax
	mov    al, 0
	call   _putc
	pop    ax

	ret

_set_color endp



	org    0061eh

_clear_screen proc near public

	mov    al, FF

	; fall-through

_clear_screen endp




	org    00620h

_putc proc near public

	push   ax
	mov    ah, 0eh      ; BIOS teletype
	int    52h
	pop    ax

	ret

_putc endp



	org    00627h

_print_hex_byte proc near public

	mov    al, bh
	call   _print_hex_upper
	mov    al, bl

_print_hex_upper:

	push   ax
	shr    al, 04h
	call   _print_hex_lower
	pop    ax

_print_hex_lower:

	and    al, 0fh
	cmp    al, 10
	jb     _print_hex_num
	add    al, 7

_print_hex_num:
	add    al, '0'
	push   bx
	mov    bl, 15       ; High intensity white
	call   _putc
	pop    bx

	ret

_print_hex_byte endp



_str_newline:
	db     CR, LF, 0ffh

_str_bell:
	db     007h, 0ffh

_str_dblspace:
	db     '  ', 0ffh

_str_memsize:
	db     'Memory Size = ', 0ffh

_str_mem128k:
	db     '128', 0ffh

_str_mem256k:
	db     '256', 0ffh

_str_mem384k:
	db     '384', 0ffh

_str_mem512k:
	db     '512', 0ffh

_str_mem640k:
	db     '640', 0ffh

_str_mem768k:
	db     '768', 0ffh

_str_memk:
	db     'K', 0ffh

_str_sysfail:
	db     'System Fails Diagnostic Test', 0ffh



	org    00696h

; int 10h and int 52h handler
; only implements set/get character set and teletype

_isr_video proc near public

	push   ds
	push   es
	pusha
	mov    bp, sp

	cmp    ah, 0eh
	jne    _isr_video_next

	call   _video_teletype
	jmp    _isr_video_done

_isr_video_next:

	cmp    ah, 10h
	jne    _isr_video_done

	call   _isr_video_cset

_isr_video_done:

	popa
	pop    es
	pop    ds
	iret

_isr_video endp




	org    006b1h

_video_teletype proc near public

	mov    cx, LBDA_SEG
	mov    ds, cx

	mov    es, ds:[LBDA_VIDEO_FB_SEG]

	mov    cx, EBDA_SEG
	mov    ds, cx

	mov    ah, bl
	and    ah, 0fh
	cmp    ah, NORMAL_CHAR_ATTR
	jne    _video_teletype_go

	mov    ds:[EBDA_VIDEO_BG_TEXT_ATTR], bl
	cmp    al, 0ch      ; blanking bit set
	jnz    _video_teletype_go
	mov    ds:[EBDA_VIDEO_FG_TEXT_ATTR], bl

_video_teletype_go:

	mov    ah, ds:[EBDA_VIDEO_BG_TEXT_ATTR]
	mov    bx, ds:[EBDA_VIDEO_CURSOR_POS]

	cmp    al, SPACE    ; SPACE
	jae    _video_teletype_alphanum
	cmp    al, 7        ; BEL
	jz     _video_teletype_bell
	cmp    al, 8        ; BACKSPACE
	jz     _video_teletype_backspace
	cmp    al, 9        ; TAB
	jz     _video_teletype_tab
	cmp    al, LF       ; LINE FEED
	jz     _video_teletype_linefeed
	cmp    al, FF       ; FORM FEED
	jz     _video_teletype_formfeed
	cmp    al, CR       ; CARRIAGE RETURN
	jz     _video_teletype_cr

_video_teletype_ok:
	jmp    _video_teletype_done
	nop

_video_teletype_alphanum:
	call   _cursor_offset
	stosw
	inc    bl
	jmp    _crt_update_cursor

_video_teletype_bell:
	call   _video_bell
	jmp    _video_teletype_ok

_video_teletype_backspace:
	cmp    bl, 0
	jz     _video_teletype_ok
	dec    bl
	jmp    _crt_update_cursor

_video_teletype_tab:
	add    bl, 8
	and    bl, 0f8h
	jmp    _crt_update_cursor

_video_teletype_linefeed:
	inc    bh
	jmp    _crt_update_cursor

_video_teletype_formfeed:
	mov    bx, 0
	call   _cursor_offset
	mov    cx, 80 * 25
	mov    al, SPACE
	mov    ah, ds:[EBDA_VIDEO_FG_TEXT_ATTR]
	rep    stosw
	jmp    _crt_update_cursor

_video_teletype_cr:
	mov    bl, 0

_crt_update_cursor:

	call   _video_mod_cursor
	mov    ds:[EBDA_VIDEO_CURSOR_POS], bx

	mov    al, bh
	mov    dx, 0130h    ; R18h: Vert cursor position
	out    dx, al

	mov    al, bl
	mov    dx, 0132h    ; R19h: Horz cursor position
	out    dx, al

_video_teletype_done:

	ret

_video_teletype endp



	org    00747h

; Takes cursor row (BH) and column (BL) and compute an offset -> DI

_cursor_offset proc near public

	push   ax
	push   bx

	mov    di, 0
	mov    al, 80
	mul    bh

	mov    bh, 0
	add    ax, bx
	add    ax, ax
	add    di, ax

	pop    bx
	pop    ax

	ret

_cursor_offset endp



	org    0075bh

; Account for row/col rollover on cursor position

_video_mod_cursor proc near public

	cmp    bl, 80
	jb     _video_mod_cursor_row

	mov    bl, 0
	inc    bh

_video_mod_cursor_row:
	cmp    bh, 25
	jb     _video_mod_cursor_done

	mov    bh, 24
	call   _video_scroll

_video_mod_cursor_done:

	ret

_video_mod_cursor endp



	org    0076fh

; Scroll the video teletype window up one row

_video_scroll proc near public

	push   ds
	push   bx

	push   es
	pop    ds

	mov    bl, 0   ; col
	mov    bh, 1   ; row
	call   _cursor_offset
	mov    si, di

	mov    bh, 0   ; row
	call   _cursor_offset

	; Scroll bottom 24 rows up one
	mov    cx, 80 * 24
	rep    movsw

	; Clear bottom row
	mov    cx, 80
	mov    al, SPACE
	mov    ah, ds:[EBDA_VIDEO_FG_TEXT_ATTR]
	rep    stosw

	pop    bx
	pop    ds

	ret

_video_scroll endp



	org    00794h

_video_bell proc near public

	ret            ; not supported

_video_bell endp



	org    00795h

; Get/Set character font (AL=10h)
;    AL bit 0 = 1 set, 0 = get
;    AL bit 1 = 1 high 128 chars, 0 low 128 chars
;    AL bit 2 = 1 8x16, 0 8x8
;    ES:BX -> pointer to character set

_isr_video_cset proc near public

	mov    cx, 0
	mov    ds, cx

	; Dereference table index far pointer
	mov    si, LBDA_VIDEO_CSET_BASE
	push   ax
;	and    ax, 6
	db     025h, 006h, 000h   ; fixup
	add    ax, ax
	add    si, ax
	pop    ax

	test   al, 1
	jnz    _isr_video_cset_set

	; get
	mov    bx, ds:[si]
	mov    es, ds:[si + 2]

	; update ES:BX on the stack
	mov    [bp +  8], bx 
	mov    [bp + 16], es
	jmp    _isr_video_cset_done
	nop

_isr_video_cset_set:
	mov    ds:[si + 0], bx
	mov    ds:[si + 2], es

	test   al, 4        ; bit 2
	jnz    _isr_video_cset_set_hirez

	jmp    _isr_video_cset_done
	nop

_isr_video_cset_set_hirez:

	mov    ah, ds:[LBDA_PCB_REVISION]

	; Set source ds:si = user supplied pointer in es:bx
	mov    si, bx
	mov    bx, es
	mov    ds, bx

	; Set destination es:di = character set RAM @ f800:0
	mov    bx, CRT_CHARSET_SEG
	mov    es, bx
	mov    di, 0

	mov    cx, 2048     ; 128 chars * 16 bytes per char

	; Apparently Rev.1 PCBs did something very different
	cmp    ah, 1
	ja     _isr_video_cset_set_hirez_go
	jz     _isr_video_cset_rev1

_isr_video_cset_set_hirez_go:

	; Update address to upper bank if requested
	test   al, 2
	jz     _isr_video_cset_set_hirez_loop
	add    di, 1000h

_isr_video_cset_set_hirez_loop:
	movsb
	inc    di
	loop   _isr_video_cset_set_hirez_loop
	jmp    _isr_video_cset_done
	nop

_isr_video_cset_rev1:

	; Update address to upper bank if requested
	test   al, 2
	jz     _isr_video_cset_rev1_loop
	add    di, 2000h

_isr_video_cset_rev1_loop:
	push   cx
	lodsb
	xor    dl, dl
	mov    cx, 8

_loc_159:
	shr    al, 1
	adc    dl, dl
	loop   _loc_159

	mov    ax, di
;	and    ax, 3ch
	db     025h, 03ch, 000h   ; fixup
	shr    ax, 02h
	xor    bx, bx
	mov    cx, 4

_loc_160:
	shr    ax, 1
	adc    bx, bx
	loop   _loc_160

	shl    bx, 02h
	mov    ax, di
;	and    ax, 0ffc3h
	db     025h, 0c3h, 0ffh   ; fixup
	or     bx, ax
	mov    es:[bx], dl
	pop    cx
	add    di, 4
	loop   _isr_video_cset_rev1_loop

_isr_video_cset_done:

	ret

_isr_video_cset endp



	org    0082bh

_isr_unreachable proc near public

	iret           ; Not referenced anywhere

_isr_unreachable endp



	org    0082ch

	public  _initial_vectors

_initial_vectors:

	dw      000h * 4, _isr_cpu_fault    ; 00h Divide error
	dw      001h * 4, _isr_cpu_fault    ; 01h Single step
	dw      002h * 4, _isr_nmi          ; 02h NMI
	dw      003h * 4, _isr_cpu_fault    ; 03h Breakpoint
	dw      004h * 4, _isr_cpu_fault    ; 04h INT0 overflow
	dw      005h * 4, _isr_cpu_fault    ; 05h Array bounds
	dw      006h * 4, _isr_cpu_fault    ; 06h Unused opcode
	dw      007h * 4, _isr_cpu_fault    ; 07h ESC opcode
	dw      00ah * 4, _isr_dma0         ; 0ah DMA 0
	dw      00bh * 4, _isr_dma1         ; 0bh DMA 1
	dw      008h * 4, _isr_spurious     ; 08h Timer 0
	dw      012h * 4, _isr_spurious     ; 12h Timer 1
	dw      013h * 4, _isr_spurious     ; 13h Timer 2
	dw      072h * 4, _isr_spurious     ; 72h UART TX/RX
	dw      073h * 4, _isr_spurious     ; 73h Quad SDLC
	dw      074h * 4, _isr_fdc          ; 74h FDC
	dw      075h * 4, _isr_fdc          ; 75h Network Interface
	dw      076h * 4, _isr_hdc          ; 76h Primary HDC
	dw      077h * 4, _isr_spurious     ; 77h Secondary HDC
	dw      078h * 4, _isr_keyboard     ; 78h Keyboard
	dw      079h * 4, _isr_crt          ; 79h CRT 9007
	dw      07ah * 4, _isr_spurious     ; 7ah Mouse
	dw      07bh * 4, _isr_spurious     ; 7bh Line Printer
	dw      052h * 4, _isr_video        ; 52h Video Services
	dw      010h * 4, _isr_video        ; 10h Video Services
	dw      056h * 4, _fdc_services     ; 56h Disk Services
	dw      013h * 4, _fdc_services     ; 13h Disk Services
	dw      0ffffh                      ; End of List




; ********************************************
; ***** FLOPPY DRIVE CONTROLLER ROUTINES *****
; ********************************************

FDDA_SEG                         equ   01900h
FDDA_ISR_FLAGS                   equ    0000h     ; [B] atomic relays
FDDA_LAST_STATUS                 equ    0002h     ; [B] Prev operation sts
FDDA_DISK_PARM_TABLE             equ    002ch     ; [W] Offset to disk table


FDDA_DMA_TARGET0                 equ    003eh     ; [D] DMA0 target fptr
FDDA_DMA_TARGET1                 equ    0042h     ; [D] DMA1 target fptr
FDDA_DMA_MUX_CTRL                equ    0046h     ; [B] DMA mux value
FDDA_DMA_ERROR_FLAG              equ    0047h     ; [B] DMA error condition






	org    0089ah

_fdc_install proc near public

	pusha
	push   ds

	mov    ax, FDDA_SEG
	mov    es, ax

	mov    ax, _TEXT
	mov    ds, ax

	; Initialize the floppy drive data area

	mov    si, _fdda_init
	nop

	mov    di, 0
	mov    cx, 0048h
	nop

	cld
	rep    movsb

	mov    ax, 0
	mov    ds, ax

	mov    word ptr ds:[1eh * 4 + 0], FDDA_DISK_PARM_TABLE
	mov    word ptr ds:[1eh * 4 + 2], FDDA_SEG

	mov    al, 0        ; DMA mux control
	out    02h, al

	mov    ds:[LBDA_DMA_MUX_CTRL], al
	mov    es:[FDDA_DMA_MUX_CTRL], al

	pop    ds
	popa

	ret

_fdc_install endp




	org    008d3h

_fdda_init:
	db     000h                   ; 00 -> 
	db     000h                   ; 01 -> 
	db     000h                   ; 02 -> Last status
	db     000h                   ; 03 -> 
	db     000h                   ; 04 -> 
	db     000h                   ; 05 -> 
	db     000h                   ; 06 -> 
	db     000h                   ; 07 -> 
	db     000h                   ; 08 -> 
	db     001h                   ; 09 -> 
	db     004h                   ; 0a -> 
	db     000h                   ; 0b -> 
	db     000h                   ; 0c -> 
	db     000h                   ; 0d -> 
	db     080h                   ; 0e -> 
	db     000h                   ; 0f -> 
	db     000h                   ; 10 -> 
	db     000h                   ; 11 -> 
	db     000h                   ; 12 -> 
	db     000h                   ; 13 -> 
	db     000h                   ; 14 -> 
	db     000h                   ; 15 -> 
	db     000h                   ; 16 -> 
	db     000h                   ; 17 -> 
	db     066h                   ; 18 -> 
	db     0a2h                   ; 19 -> 
	db     000h                   ; 1a -> 
	db     000h                   ; 1b -> 
	db     004h                   ; 1c -> 
	db     000h                   ; 1d -> 
	db     000h                   ; 1e -> 
	db     000h                   ; 1f -> 
	db     000h                   ; 20 -> 
	db     000h                   ; 21 -> 
	db     000h                   ; 22 -> 
	db     000h                   ; 23 -> 
	db     080h                   ; 24 -> 
	db     000h                   ; 25 -> 
	db     000h                   ; 26 -> 
	db     000h                   ; 27 -> 
	db     000h                   ; 28 -> 
	db     000h                   ; 29 -> 
	db     086h                   ; 2a -> 
	db     016h                   ; 2b -> 

	; 2c + 00 -> Int 1eh start (Disk parameters table)
	db     0e0h                   ; 2c + 00 -> STR + HUT : first spec byte
	db     08ch                   ; 2c + 01 -> HLT + ND  : second spec byte
	db     000h                   ; 2c + 02 -> motor off wait time
	db     002h                   ; 2c + 03 -> N   : 512 bytes / sector
	db     009h                   ; 2c + 04 -> EOT : max sector number
	db     02ah                   ; 2c + 05 -> GPL : gap length
	db     0ffh                   ; 2c + 06 -> DTL : data len
	db     050h                   ; 2c + 07 -> gap len for format
	db     0f6h                   ; 2c + 08 -> fill byte for format
	db     019h                   ; 2c + 09 -> head settle time (ms)
	db     004h                   ; 2c + 0a -> motor start time (1/8 sec)

	db     000h                   ; e90a -37
	db     000h                                 ; e90b -38
	db     000h                                 ; e90c -39
	db     000h                                 ; e90d -3a
	db     000h                                 ; e90e -3b
	db     000h                                 ; e90f -3c
	db     000h                                 ; e910 -3d
	dd     000h                   ; 3e -> DMA 0 far pointer to completion reg
	dd     000h                   ; 42 -> DMA 1 far pointer to completion reg
	db     000h                   ; 46 -> DMA mux control value
	db     000h                   ; 47 -> DMA error condition




	org    0091bh

_fdc_services proc near public

	sti
	push   ds
	push   es
	push   bx
	push   cx
	push   ds
	push   si
	push   di
	push   bp
	push   dx
	mov    bp, sp

	mov    si, FDDA_SEG
	mov    ds, si

	call   _fdc_io
	mov    ah, ds:[FDDA_LAST_STATUS]
	cmp    ah, 1
	cmc

	pop    dx
	pop    bp
	pop    di
	pop    si
	pop    ds
	pop    cx
	pop    bx
	pop    es
	pop    ds

	retf   2

_fdc_services endp



	org    00943h

_fdc_io proc near public

	mov    dh, al
	or     ah, ah
	jz     _fdc_io_reset

	cmp    ah, 1                                ; e949 - 80 fc 01
	jz     _loc_064                             ; e94c - 74 18 -> e966
	mov    byte ptr ds:[FDDA_LAST_STATUS], 0
	cmp    dl, 2                                ; e953 - 80 fa 02
	jae    _loc_065                             ; e956 - 73 08 -> e960
	cmp    ah, 2                                ; e958 - 80 fc 02
	jnz    _loc_065                             ; e95b - 75 03 -> e960
	jmp    _loc_066                             ; e95d - e9 f3 00 -> ea53

_loc_065:                                         ; e960
	mov    byte ptr ds:[002h], 1                ; e960 - c6 06 02 00 01

	ret                                          ; e965 - c3

_loc_064:                                         ; e966
	mov    al, ds:[02h]                         ; e966 - a0 02 00

	ret                                          ; e969 - c3




_fdc_io_reset:

	push   ds
	mov    ax, LBDA_SEG
	mov    ds, ax
	mov    al, ds:[LBDA_CFG_PORT0]
	pop    ds

	and    al, 0dfh     ; clear FDC reset bit (act low)
	out    0, al

	mov    cx, 0014h
_fdc_io_reset_pulse:
	loop   _fdc_io_reset_pulse

	or     al, 20h     ; Release FDC reset
	out    00h, al

	; Wait a long time for drive to recover and come on-line

	mov    al, 5

_fdc_io_reset_delay_big:
	mov    cx, 0

_fdc_io_reset_delay_min:
	loop   _fdc_io_reset_delay_min
	dec    al
	jnz    _fdc_io_reset_delay_big

	; Reset delay complete

	mov    byte ptr ds:[FDDA_LAST_STATUS], 0
	mov    cx, 003ch                            ; e991 - b9 3c 00

_loc_107:                                         ; e994
	call   _sub_019                             ; e994 - e8 41 02 -> ebd8
	mov    byte ptr ds:[000h], 0                ; e997 - c6 06 00 00 00
	jnb    _loc_090                             ; e99c - 73 06 -> e9a4

_loc_139:                                         ; e99e
	or     byte ptr ds:[FDDA_LAST_STATUS], 20h

	ret



_loc_090:                                         ; e9a4
	mov    al, ds:[37h]                         ; e9a4 - a0 37 00
	cmp    al, 080h                             ; e9a7 - 3c 80
	jz     _loc_106                             ; e9a9 - 74 18 -> e9c3
	test   al, 2                                ; e9ab - a8 02
	jnz    _loc_107                             ; e9ad - 75 e5 -> e994
	test   al, 1                                ; e9af - a8 01
	jnz    _loc_108                             ; e9b1 - 75 07 -> e9ba
	xor    byte ptr ds:[003h], 0ffh             ; e9b3 - 80 36 03 00 ff
	jmp    _loc_109                             ; e9b8 - eb 05 -> e9bf

_loc_108:                                         ; e9ba
	xor    byte ptr ds:[005h], 0ffh             ; e9ba - 80 36 05 00 ff

_loc_109:                                        ; e9bf
	loop   _loc_107                             ; e9bf - e2 d3 -> e994
	jmp    _loc_139                             ; e9c1 - eb db -> e99e

_loc_106:                                         ; e9c3

	mov    ah, 3        ; Specify command
	call   _fdc_cmd

	mov    bx, 0h * 2 + 1
	call   _fdc_dpt_arg ; Send first spec byte

	mov    bx, 1h * 2 + 1
	call   _fdc_dpt_arg ; Send second spec byte

	and    byte ptr ds:[000h], 0fch             ; e9d4 - 80 26 00 00 fc
	mov    dl, 0                                ; e9d9 - b2 00
	mov    ch, 0ah                              ; e9db - b5 0a
	call   _sub_026                             ; e9dd - e8 6a 01 -> eb4a
	jb     _loc_140                             ; e9e0 - 72 3e -> ea20
	and    byte ptr ds:[000h], 0fch             ; e9e2 - 80 26 00 00 fc
	mov    ch, 0                                ; e9e7 - b5 00
	call   _sub_026                             ; e9e9 - e8 5e 01 -> eb4a
	jb     _loc_140                             ; e9ec - 72 32 -> ea20
	mov    ah, 4        ; Sense drive status command
	call   _fdc_cmd                             ; e9f0 - e8 15 01 -> eb08
	mov    ah, 1        ;                       ; e9f3 - b4 01
	call   _fdc_cmd                             ; e9f5 - e8 10 01 -> eb08
	call   _sub_025                             ; e9f8 - e8 2e 02 -> ec29
	jb     _loc_140                             ; e9fb - 72 23 -> ea20
	mov    ah, ds:[037h]               ; e9fd - 8a 26 37 00
	and    ah, 20h                              ; ea01 - 80 e4 20
	jz     _loc_141                             ; ea04 - 74 11 -> ea17
	mov    dl, 1                                ; ea06 - b2 01
	mov    ch, 0ah                              ; ea08 - b5 0a
	call   _sub_026                             ; ea0a - e8 3d 01 -> eb4a
	and    byte ptr ds:[000h], 0fch             ; ea0d - 80 26 00 00 fc
	mov    ch, 0                                ; ea12 - b5 00
	call   _sub_026                             ; ea14 - e8 33 01 -> eb4a

_loc_141:                                         ; ea17
	mov    dl, 0                                ; ea17 - b2 00
	mov    ch, 2                                ; ea19 - b5 02
	call   _sub_026                             ; ea1b - e8 2c 01 -> eb4a
	jnb    _loc_142                             ; ea1e - 73 06 -> ea26

_loc_140:                                         ; ea20
	or     byte ptr ds:[002h], 40h              ; ea20 - 80 0e 02 00 40

	ret                                          ; ea25 - c3






_loc_142:                                         ; ea26
	mov    ah, 4ah      ; Read ID command
	call   _fdc_cmd                             ; ea28 - e8 dd 00 -> eb08
	mov    ah, 0                                ; ea2b - b4 00
	call   _fdc_cmd                             ; ea2d - e8 d8 00 -> eb08
	call   _fdc_wait
	jnb    _loc_161                             ; ea33 - 73 03 -> ea38
	jmp    _loc_139                             ; ea35 - e9 66 ff -> e99e

_loc_161:                                         ; ea38
	call   _sub_025                             ; ea38 - e8 ee 01 -> ec29
	jnb    _loc_185                             ; ea3b - 73 03 -> ea40
	jmp    _loc_139                             ; ea3d - e9 5e ff -> e99e

_loc_185:                                         ; ea40
	cmp    byte ptr ds:[03ah], 2                ; ea40 - 80 3e 3a 00 02
	jz     _loc_200                             ; ea45 - 74 06 -> ea4d
	mov    byte ptr ds:[004h], 0ffh             ; ea47 - c6 06 04 00 ff

	ret                                          ; ea4c - c3

_loc_200:                                         ; ea4d
	mov    byte ptr ds:[004h], 0                ; ea4d - c6 06 04 00 00

	ret                                          ; ea52 - c3

_loc_066:                                         ; ea53
	call   _sub_018                             ; ea53 - e8 55 01 -> ebab
	jnb    _loc_086                             ; ea56 - 73 08 -> ea60
	mov    byte ptr ds:[002h], 9                ; ea58 - c6 06 02 00 09
	mov    al, 0                                ; ea5d - b0 00

	ret                                          ; ea5f - c3

_loc_086:                                         ; ea60
	call   _sub_026                             ; ea60 - e8 e7 00 -> eb4a
	mov    dh, 0                                ; ea63 - b6 00
	jb     _loc_112                             ; ea65 - 72 52 -> eab9
	push   0ab9h                                ; ea67 - 68 b9 0a
	nop                                         ; ea6a - 90

	mov    ah, 66h      ; Read data command
	call   _fdc_cmd                             ; ea6d - e8 98 00 -> eb08

	mov    ah, ss:[bp + 1]                ; ea70 - 8a 66 01
	shl    ah, 02h                              ; ea73 - c0 e4 02
	and    ah, 4                                ; ea76 - 80 e4 04
	or     ah, dl                               ; ea79 - 0a e2
	call   _fdc_cmd     ; Send drive select

	mov    ah, ch
	call   _fdc_cmd     ; Send C track

	mov    ah, ss:[bp + 1]
	call   _fdc_cmd     ; Send H head

	mov    ah, cl
	call   _fdc_cmd     ; Send R sector number

	mov    bx, 3h * 2 + 1
	call   _fdc_dpt_arg ; Send N sector length

	mov    bx, 4h * 2 + 1
	call   _fdc_dpt_arg ; Send EOT max sector number

	mov    bx, 5h * 2 + 1
	call   _fdc_dpt_arg ; Send GPL gap length

	mov    bx, 6h * 2 + 1
	call   _fdc_dpt_arg ; Send DTL data lengh

	mov    bx, si                               ; eaa6 - 8b de
	pop    si                                   ; eaa8 - 5e
	call   _sub_028                             ; eaa9 - e8 33 02 -> ecdf
	jnb    _loc_113                             ; eaac - 73 08 -> eab6
	or     byte ptr ds:[002h], 8                ; eaae - 80 0e 02 00 08
	jmp    _loc_114                             ; eab3 - eb 49 -> eafe
	nop                                          ; eab5 - 90

_loc_113:                                         ; eab6
	call   _fdc_wait

_loc_112:                                         ; eab9
	jb     _loc_114                             ; eab9 - 72 43 -> eafe
	call   _sub_025                             ; eabb - e8 6b 01 -> ec29
	jb     _loc_121                             ; eabe - 72 3d -> eafd
	cld                                          ; eac0 - fc
	mov    si, 0037h                            ; eac1 - be 37 00
	lodsb                                        ; eac4 - ac
	and    al, 0c0h                             ; eac5 - 24 c0
	jz     _loc_122                             ; eac7 - 74 39 -> eb02
	cmp    al, 40h                              ; eac9 - 3c 40
	jnz    _loc_123                             ; eacb - 75 27 -> eaf4
	lodsb                                        ; eacd - ac
	shl    al, 1                                ; eace - d0 e0
	mov    ah, 4                                ; ead0 - b4 04
	jb     _loc_124                             ; ead2 - 72 22 -> eaf6
	shl    al, 02h                              ; ead4 - c0 e0 02
	mov    ah, 10h                              ; ead7 - b4 10
	jb     _loc_124                             ; ead9 - 72 1b -> eaf6
	shl    al, 1                                ; eadb - d0 e0
	mov    ah, 8                                ; eadd - b4 08
	jb     _loc_124                             ; eadf - 72 15 -> eaf6
	shl    al, 02h                              ; eae1 - c0 e0 02
	mov    ah, 4                                ; eae4 - b4 04
	jb     _loc_124                             ; eae6 - 72 0e -> eaf6
	shl    al, 1                                ; eae8 - d0 e0
	mov    ah, 3                                ; eaea - b4 03
	jb     _loc_124                             ; eaec - 72 08 -> eaf6
	shl    al, 1                                ; eaee - d0 e0
	mov    ah, 2                                ; eaf0 - b4 02
	jb     _loc_124                             ; eaf2 - 72 02 -> eaf6

_loc_123:                                        ; eaf4
	mov    ah, 20h                              ; eaf4 - b4 20

_loc_124:                                         ; eaf6
	or     ds:[002h], ah               ; eaf6 - 08 26 02 00
	call   _sub_034                             ; eafa - e8 6a 01 -> ec67

_loc_121:                                         ; eafd

	ret                                          ; eafd - c3

_loc_114:                                         ; eafe
	call   _sub_025                             ; eafe - e8 28 01 -> ec29

	ret                                          ; eb01 - c3

_loc_122:                                         ; eb02
	call   _sub_034                             ; eb02 - e8 62 01 -> ec67
	xor    ah, ah                               ; eb05 - 32 e4

	ret                                          ; eb07 - c3

_fdc_io endp













	org    00b08h

_fdc_cmd proc near public

	push   cx

	mov    cl, 20h
_loc_136:                                         ; eb0b
	dec    cl                                   ; eb0b - fe c9
	jnz    _loc_136                             ; eb0d - 75 fc -> eb0b

	mov    cx, 0                                ; eb0f - b9 00 00

_loc_138:                                         ; eb12
	in     al, 30h      ; Main status reg
	and    al, 40h                              ; eb14 - 24 40
	jz     _loc_137                             ; eb16 - 74 0b -> eb23
	loop   _loc_138                             ; eb18 - e2 f8 -> eb12

_loc_164:                                         ; eb1a
	or     byte ptr ds:[FDDA_LAST_STATUS], 080h
	stc                                          ; eb1f - f9
	pop    cx                                   ; eb20 - 59
	pop    ax                                   ; eb21 - 58

	ret                                          ; eb22 - c3

_loc_137:                                         ; eb23
	mov    cx, 0                                ; eb23 - b9 00 00

_loc_163:                                         ; eb26
	in     al, 30h                              ; eb26 - e4 30 FDC
	and    al, 080h                             ; eb28 - 24 80
	jnz    _fdc_cmd_go
	loop   _loc_163                             ; eb2c - e2 f8 -> eb26
	jmp    _loc_164                             ; eb2e - eb ea -> eb1a




_fdc_cmd_go:
	mov    al, ah
	out    32h, al

	pop    cx

	ret

_fdc_cmd endp




	org    00b36h

_fdc_dpt_arg proc near public

	push   ds

	mov    ax, 0
	mov    ds, ax

	; Load index from drive param table (stored in bx / 2)
	;     bx bit 0 determines if we send arg or not (or just store in ah)

	push   si
	lds    si, ds:[1eh * 4]
	shr    bx, 1

	mov    ah, ds:[bx + si]
	pop    si

	pop    ds

	jc     _fdc_cmd

	ret

_fdc_dpt_arg endp







	org    00b4ah

_sub_026 proc near public                         ; eb4a

	mov    al, 1                                ; eb4a - b0 01
	push   cx                                   ; eb4c - 51
	mov    cl, dl                               ; eb4d - 8a ca
	shl    al, cl                               ; eb4f - d2 e0
	pop    cx                                   ; eb51 - 59
	test   ds:[000h], al               ; eb52 - 84 06 00 00
	jnz    _loc_128                             ; eb56 - 75 20 -> eb78
	or     ds:[000h], al               ; eb58 - 08 06 00 00

	mov    ah, 7
	call   _fdc_cmd     ; Send recalibrate command

	mov    ah, dl
	call   _fdc_cmd     ; Send drive select

	call   _sub_037

	mov    ah, 7
	call   _fdc_cmd     ; Send recalibrate command

	mov    ah, dl
	call   _fdc_cmd     ; Send drive select

	call   _sub_037                             ; eb73 - e8 5d 00 -> ebd3

	jc     _loc_129                             ; eb76 - 72 32 -> ebaa

_loc_128:                                         ; eb78
	mov    ah, 0fh                              ; eb78 - b4 0f
	call   _fdc_cmd                             ; eb7a - e8 8b ff -> eb08
	mov    ah, dl                               ; eb7d - 8a e2
	call   _fdc_cmd                             ; eb7f - e8 86 ff -> eb08
	mov    ah, ch                               ; eb82 - 8a e5
	or     byte ptr ds:[004h], 0                ; eb84 - 80 0e 04 00 00
	jz     _loc_130                             ; eb89 - 74 02 -> eb8d
	shl    ah, 1                                ; eb8b - d0 e4

_loc_130:                                         ; eb8d
	call   _fdc_cmd                             ; eb8d - e8 78 ff -> eb08
	call   _sub_037                             ; eb90 - e8 40 00 -> ebd3
	pushf                                       ; eb93 - 9c

	mov    bx, 9h * 2 + 0
	call   _fdc_dpt_arg ; lookup head settle time -> ah

	push   cx

_loc_133:                                         ; eb9b
	mov    cx, 0226h                            ; eb9b - b9 26 02
	or     ah, ah                               ; eb9e - 0a e4
	jz     _loc_131                             ; eba0 - 74 06 -> eba8

_loc_132:                                         ; eba2
	loop   _loc_132                             ; eba2 - e2 fe -> eba2
	dec    ah                                   ; eba4 - fe cc
	jmp    _loc_133                             ; eba6 - eb f3 -> eb9b

_loc_131:                                         ; eba8
	pop    cx                                   ; eba8 - 59
	popf                                         ; eba9 - 9d

_loc_129:                                         ; ebaa

	ret                                          ; ebaa - c3

_sub_026 endp



	org    00babh

_sub_018 proc near public

	mov    si, 8                                ; ebab - be 08 00
	mov    ds:[si + 00ch], es          ; ebae - 8c 44 0c
	mov    ds:[si + 00ah], bx          ; ebb1 - 89 5c 0a
	mov    ah, dh
	xor    al, al
	shr    ax, 1

	push   ax
	mov    bx, 3h * 2 + 0
	call   _fdc_dpt_arg ; Lookup N sector size -> ah
	mov    bl, ah
	pop    ax

_loc_115:
	shl    ax, 1
	dec    bl
	jnz    _loc_115
	mov    bx, si
	mov    ds:[bx + 00eh], ax          ; ebcc - 89 47 0e
	call   _sub_029

	ret

_sub_018 endp



	org    00bd3h

_sub_037 proc near public

	call   _fdc_wait
	jc     _loc_110

_sub_037 endp




	org    00bd8h

_sub_019 proc near public                         ; ebd8

	mov    ah, 8        ; Sense interrupt status command
	call   _fdc_cmd

	call   _sub_025                             ; ebdd - e8 49 00 -> ec29
	jc    _loc_110                             ; ebe0 - 72 0a -> ebec
	mov    al, ds:[37h]                         ; ebe2 - a0 37 00
	and    al, 60h                              ; ebe5 - 24 60
	cmp    al, 60h                              ; ebe7 - 3c 60
	jz     _loc_111                             ; ebe9 - 74 02 -> ebed
	clc                                          ; ebeb - f8

_loc_110:                                         ; ebec

	ret                                          ; ebec - c3

_loc_111:                                         ; ebed
	or     byte ptr ds:[002h], 40h              ; ebed - 80 0e 02 00 40
	stc                                          ; ebf2 - f9

	ret                                          ; ebf3 - c3

_sub_019 endp




	org    00bf4h

_fdc_wait proc near public

	sti

	pusha

	mov    bl, 0fh      ; loop count

	xor    cx, cx

_fdc_wait_loop:

	test   byte ptr ds:[FDDA_ISR_FLAGS], 080h
	jnz    _fdc_wait_ok
	loop   _fdc_wait_loop

	dec    bl
	jnz    _fdc_wait_loop
	or     byte ptr ds:[FDDA_LAST_STATUS], 080h
	stc

_fdc_wait_ok:

	pushf
	and    byte ptr ds:[FDDA_ISR_FLAGS], 7fh
	popf

	popa

	ret

_fdc_wait endp




	org    00c16h

_isr_fdc proc near public

	sti

	push   ds
	pusha

	mov    ax, FDDA_SEG
	mov    ds, ax

	or     byte ptr ds:[FDDA_ISR_FLAGS], 080h

	call   _pic0_eoi

	popa
	pop    ds

	iret

_isr_fdc endp






	org    00c29h

_sub_025 proc near public                         ; ec29

	mov    di, 0037h                            ; ec29 - bf 37 00
	cld                                          ; ec2c - fc
	pusha                                        ; ec2d - 60
	mov    bl, 7                                ; ec2e - b3 07

_loc_201:                                         ; ec30
	xor    cx, cx                               ; ec30 - 33 c9
	mov    dx, 0030h                            ; ec32 - ba 30 00

_loc_135:                                         ; ec35
	in     al, dx                               ; ec35 - ec FDC
	test   al, 080h                             ; ec36 - a8 80
	jnz    _loc_134                             ; ec38 - 75 0a -> ec44
	loop   _loc_135                             ; ec3a - e2 f9 -> ec35
	or     byte ptr ds:[002h], 080h             ; ec3c - 80 0e 02 00 80

_loc_166:                                         ; ec41
	stc                                          ; ec41 - f9
	popa                                         ; ec42 - 61

	ret                                          ; ec43 - c3

_loc_134:                                         ; ec44
	in     al, dx                               ; ec44 - ec FDC
	test   al, 40h                              ; ec45 - a8 40
	jnz    _loc_165                             ; ec47 - 75 07 -> ec50

_loc_202:                                         ; ec49
	or     byte ptr ds:[002h], 20h              ; ec49 - 80 0e 02 00 20
	jmp    _loc_166                             ; ec4e - eb f1 -> ec41

_loc_165:                                         ; ec50
	in     al, 32h                              ; ec50 - e4 32 FDC
	mov    ds:[di], al                 ; ec52 - 88 05
	inc    di                                   ; ec54 - 47
	mov    cx, 000fh                            ; ec55 - b9 0f 00

_loc_183:                                         ; ec58
	loop   _loc_183                             ; ec58 - e2 fe -> ec58
	in     al, dx                               ; ec5a - ec FDC
	test   al, 10h                              ; ec5b - a8 10
	jnz    _loc_184                             ; ec5d - 75 02 -> ec61
	popa                                         ; ec5f - 61

	ret                                          ; ec60 - c3

_sub_025 endp






_loc_184:                                         ; ec61
	dec    bl                                   ; ec61 - fe cb
	jnz    _loc_201                             ; ec63 - 75 cb -> ec30
	jmp    _loc_202                             ; ec65 - eb e2 -> ec49


	org    00c67h

_sub_034 proc near public                         ; ec67

	mov    al, ds:[3ah]                         ; ec67 - a0 3a 00
	cmp    al, ch                               ; ec6a - 3a c5
	mov    al, ds:[3ch]                         ; ec6c - a0 3c 00
	jz     _loc_168                             ; ec6f - 74 0a -> ec7b

	mov    bx, 4h * 2 + 0
	call   _fdc_dpt_arg ; Lookup EOT max sector number -> ah

	mov    al, ah                               ; ec77 - 8a c4
;	inc    ax                                   ; ec79 - fe c0
	db 0feh, 0c0h

_loc_168:                                         ; ec7b
	sub    al, cl                               ; ec7b - 2a c1

	ret                                          ; ec7d - c3

_sub_034 endp



	org    00c7eh

_sub_029 proc near public                         ; ec7e

	push   es                                   ; ec7e - 06
	pusha                                        ; ec7f - 60
	call   _sub_030                             ; ec80 - e8 ad 00 -> ed30
	call   _sub_031                             ; ec83 - e8 ed 00 -> ed73
	jnz    _loc_118                             ; ec86 - 75 76 -> ecfe
	mov    cx, ds:[bx + 8]             ; ec88 - 8b 4f 08
	mov    ax, ds:[bx + 6]             ; ec8b - 8b 47 06
	call   _sub_032                             ; ec8e - e8 88 00 -> ed19
	jnz    _loc_118                             ; ec91 - 75 6b -> ecfe
	out    dx, ax                               ; ec93 - ef
	mov    ax, cx                               ; ec94 - 8b c1
	inc    dx                                   ; ec96 - 42
	inc    dx                                   ; ec97 - 42
	out    dx, ax                               ; ec98 - ef
	mov    cx, ds:[bx + 00ch]          ; ec99 - 8b 4f 0c
	mov    ax, ds:[bx + 00ah]          ; ec9c - 8b 47 0a
	call   _sub_032                             ; ec9f - e8 77 00 -> ed19
	jnz    _loc_118                             ; eca2 - 75 5a -> ecfe
	inc    dx                                   ; eca4 - 42
	inc    dx                                   ; eca5 - 42
	out    dx, ax                               ; eca6 - ef
	mov    ax, cx                               ; eca7 - 8b c1
	inc    dx                                   ; eca9 - 42
	inc    dx                                   ; ecaa - 42
	out    dx, ax                               ; ecab - ef
	mov    ax, ds:[bx + 00eh]          ; ecac - 8b 47 0e
	inc    dx                                   ; ecaf - 42
	inc    dx                                   ; ecb0 - 42
	out    dx, ax                               ; ecb1 - ef
	mov    ax, FDDA_SEG
	mov    es, ax                               ; ecb5 - 8e c0
	test   byte ptr ds:[bx], 0ffh               ; ecb7 - f6 07 ff
	jz     _loc_119                             ; ecba - 74 0c -> ecc8
	mov    es:[FDDA_DMA_TARGET1 + 0], bx               ; ecbc - 26 89 1e 42 00
	mov    es:[FDDA_DMA_TARGET1 + 2], ds               ; ecc1 - 26 8c 1e 44 00
	jmp    _loc_120                             ; ecc6 - eb 0d -> ecd5

_loc_119:                                         ; ecc8
	mov    es:[FDDA_DMA_TARGET0 + 0], bx               ; ecc8 - 26 89 1e 3e 00
	mov    es:[FDDA_DMA_TARGET0 + 2], ds               ; eccd - 26 8c 1e 40 00
	call   _sub_035                             ; ecd2 - e8 67 00 -> ed3c

_loc_120:                                         ; ecd5
	mov    ax, ds:[bx + 010h]          ; ecd5 - 8b 47 10
	inc    dx                                   ; ecd8 - 42
	inc    dx                                   ; ecd9 - 42
	out    dx, ax                               ; ecda - ef
	or     al, al                               ; ecdb - 0a c0
	jmp    _loc_171                             ; ecdd - eb 37 -> ed16

_sub_029 endp




	org    00cdfh

_sub_028 proc near public                         ; ecdf

	push   es                                   ; ecdf - 06
	pusha                                        ; ece0 - 60
	call   _sub_035                             ; ece1 - e8 58 00 -> ed3c
	call   _sub_030                             ; ece4 - e8 49 00 -> ed30
	add    dx, 8                                ; ece7 - 83 c2 08
	mov    al, 0ah                              ; ecea - b0 0a

_loc_127:                                         ; ecec
	mov    cx, 0ffffh                           ; ecec - b9 ff ff

_loc_126:                                         ; ecef
	push   ax                                   ; ecef - 50
	in     ax, dx                               ; ecf0 - ed
	or     ax, ax                               ; ecf1 - 0b c0
	pop    ax                                   ; ecf3 - 58
	jz     _loc_125                             ; ecf4 - 74 17 -> ed0d
	mov    ah, ds:[bx]                 ; ecf6 - 8a 27
	loop   _loc_126                             ; ecf8 - e2 f5 -> ecef
	dec    al                                   ; ecfa - fe c8
	jnz    _loc_127                             ; ecfc - 75 ee -> ecec

_loc_118:                                         ; ecfe
	stc                                          ; ecfe - f9
	pushf                                        ; ecff - 9c
	call   _sub_030                             ; ed00 - e8 2d 00 -> ed30
	add    dx, 0ah                              ; ed03 - 83 c2 0a
	in     ax, dx                               ; ed06 - ed
	and    al, 0fdh                             ; ed07 - 24 fd
	or     al, 4                                ; ed09 - 0c 04
	out    dx, ax                               ; ed0b - ef
	popf                                         ; ed0c - 9d

_loc_125:                                         ; ed0d
	pushf                                        ; ed0d - 9c
	mov    dx, ds:[bx + 2]             ; ed0e - 8b 57 02
	in     al, dx                               ; ed11 - ec
	call   _sub_036                             ; ed12 - e8 ca 00 -> eddf
	popf                                         ; ed15 - 9d

_loc_171:                                         ; ed16
	popa                                         ; ed16 - 61
	pop    es                                   ; ed17 - 07

	ret                                          ; ed18 - c3

_sub_028 endp



	org    00d19h

_sub_032 proc near public                         ; ed19

	push   dx                                   ; ed19 - 52
	mov    dx, cx                               ; ed1a - 8b d1
	mov    cx, ax                               ; ed1c - 8b c8
	mov    ax, 0010h                            ; ed1e - b8 10 00
	mul    dx                                   ; ed21 - f7 e2
	add    ax, cx                               ; ed23 - 03 c1
	mov    cx, dx                               ; ed25 - 8b ca
	pop    dx                                   ; ed27 - 5a
	jnb    _loc_172                             ; ed28 - 73 01 -> ed2b
	inc    cx                                   ; ed2a - 41

_loc_172:                                         ; ed2b
	test   cx, 0fff0h                           ; ed2b - f7 c1 f0 ff

	ret                                          ; ed2f - c3

_sub_032 endp



	org    00d30h

_sub_030 proc near public                         ; ed30

	test   byte ptr ds:[bx], 0ffh               ; ed30 - f6 07 ff
	mov    dx, 0ffc0h                           ; ed33 - ba c0 ff
	jz     _loc_178                             ; ed36 - 74 03 -> ed3b
	mov    dx, 0ffd0h                           ; ed38 - ba d0 ff

_loc_178:                                         ; ed3b

	ret                                          ; ed3b - c3

_sub_030 endp



	org    00d3ch

_sub_035 proc near public                         ; ed3c

	push   dx                                   ; ed3c - 52
	push   ax                                   ; ed3d - 50
	mov    dx, 0ff30h                           ; ed3e - ba 30 ff
	in     ax, dx                               ; ed41 - ed
	and    ah, 7fh                              ; ed42 - 80 e4 7f
	out    dx, ax                               ; ed45 - ef
	pop    ax                                   ; ed46 - 58
	pop    dx                                   ; ed47 - 5a

	ret                                          ; ed48 - c3

_sub_035 endp






	org    00d49h

_isr_dma0 proc near public   

	pusha
	push   ds

	mov    ax, FDDA_SEG
	mov    ds, ax

	lds    si, ds:[FDDA_DMA_TARGET0]
	mov    dx, ds:[si + 2]
	in     al, dx

	call   _pici_eoi

	pop    ds
	popa

	iret

_isr_dma0 endp




	org    00d5eh

_isr_dma1 proc near public   

	pusha
	push   ds

	mov    ax, FDDA_SEG
	mov    ds, ax

	lds    si, ds:[FDDA_DMA_TARGET1]
	mov    dx, ds:[si + 2]
	in     al, dx

	call   _pici_eoi

	pop    ds
	popa

	iret

_isr_dma1 endp




	org    00d73h

_sub_031 proc near public

	push   es                                   ; ed73 - 06
	pusha                                        ; ed74 - 60
	mov    ax, FDDA_SEG
	mov    es, ax                               ; ed78 - 8e c0
	mov    cx, 0ffffh                           ; ed7a - b9 ff ff

_loc_176:                                         ; ed7d
	push   cx                                   ; ed7d - 51
	mov    cx, 4                                ; ed7e - b9 04 00
	clc                                          ; ed81 - f8
	xor    ah, ah                               ; ed82 - 32 e4
	mov    al, es:[FDDA_DMA_MUX_CTRL]

_loc_174:                                         ; ed88
	rcr    al, 1                                ; ed88 - d0 d8
	jnb    _loc_173                             ; ed8a - 73 02 -> ed8e
	inc   ah

_loc_173:                                         ; ed8e
	loop   _loc_174                             ; ed8e - e2 f8 -> ed88
	cmp    ah, 2                                ; ed90 - 80 fc 02
	jl     _loc_175                             ; ed93 - 7c 08 -> ed9d
	pop    cx                                   ; ed95 - 59
	loop   _loc_176                             ; ed96 - e2 e5 -> ed7d
	dec    cl                                   ; ed98 - fe c9
	jmp    _loc_177                             ; ed9a - eb 40 -> eddc
	nop                                          ; ed9c - 90

_loc_175:                                         ; ed9d
	pop    cx                                   ; ed9d - 59
	mov    cx, 0ffffh                           ; ed9e - b9 ff ff

_loc_182:                                         ; eda1
	mov    al, ds:[bx + 1]             ; eda1 - 8a 47 01
	and    al, 0fh                              ; eda4 - 24 0f
	test   es:[046h], al               ; eda6 - 26 84 06 46 00
	jz     _loc_181                             ; edab - 74 07 -> edb4
	loop   _loc_182                             ; edad - e2 f2 -> eda1
	dec    cl                                   ; edaf - fe c9
	jmp    _loc_177                             ; edb1 - eb 29 -> eddc
	nop                                          ; edb3 - 90

_loc_181:                                         ; edb4
	mov    ah, al                               ; edb4 - 8a e0
	rol    ah, 04h                              ; edb6 - c0 c4 04
	test   byte ptr ds:[bx], 0ffh               ; edb9 - f6 07 ff
	jnz    _loc_203                             ; edbc - 75 0a -> edc8
	not    ah                                   ; edbe - f6 d4
	and    es:[046h], ah               ; edc0 - 26 20 26 46 00
	jmp    _loc_204                             ; edc5 - eb 03 -> edca
	nop                                          ; edc7 - 90

_loc_203:                                         ; edc8
	or     al, ah                               ; edc8 - 0a c4

_loc_204:                                         ; edca
	or     es:[FDDA_DMA_MUX_CTRL], al
	mov    al, es:[FDDA_DMA_MUX_CTRL]
	out    02h, al

	xor    al, al
	or     al, es:[FDDA_DMA_ERROR_FLAG]

_loc_177:                                         ; eddc
	popa                                         ; eddc - 61
	pop    es                                   ; eddd - 07

	ret                                          ; edde - c3

_sub_031 endp



	org    00ddfh

_sub_036 proc near public

	push   es
	push   ax
	pushf

	mov    ax, FDDA_SEG
	mov    es, ax

	test   byte ptr ds:[bx + 010h], 0c0h        ; ede7 - f6 47 10 c0
	jz     _loc_167                             ; edeb - 74 12 -> edff
	mov    al, ds:[bx + 1]             ; eded - 8a 47 01
	and    al, 0fh                              ; edf0 - 24 0f
	not    al                                   ; edf2 - f6 d0
	and    al, es:[FDDA_DMA_MUX_CTRL]
	mov    es:[FDDA_DMA_MUX_CTRL], al
	out    02h, al                              ; edfd - e6 02

_loc_167:                                         ; edff

	popf
	pop    ax
	pop    es

	ret

_sub_036 endp




	org    00e03h

_isr_dma_error proc near public

	push   ds
	pusha

	mov    ax, FDDA_SEG
	mov    ds, ax

	mov    byte ptr ds:[FDDA_DMA_ERROR_FLAG], 0ffh
	call   _pic1_eoi

	popa
	pop    ds

	iret

_isr_dma_error endp



; ******************************************
; ***** HARD DRIVE CONTROLLER ROUTINES *****
; ******************************************

; Controller card uses a WD1010 which was the fore-runner
; to the IDE/ATA specs.

HDDA_SEG                         equ   01a00h
HDDA_PARAMS_OFFSET               equ    0000h     ; [W] Ptr to current params
HDDA_SLAVE_SELECT                equ    0002h     ; [B] Lower 1 bit of dl on entry
HDDA_DETECTED                    equ    0003h     ; [B] bit 0 if HDC present
HDDA_LAST_STATUS                 equ    0005h     ; [B] Last error status
HDDA_DATA_OFFSET                 equ    0008h     ; [W] es:ptr to put data
HDDA_REG_RESET                   equ    000ah     ; [W] Reg: soft reset
HDDA_REG_DATA                    equ    000ch     ; [W] Reg: data
HDDA_REG_ERROR                   equ    000eh     ; [W] Reg: error status
HDDA_REG_PRECOMP                 equ    0010h     ; [W] Reg: pre-compensation
HDDA_REG_SEC_COUNT               equ    0012h     ; [W] Reg: sector count
HDDA_REG_SEC_START               equ    0014h     ; [W] Reg: sector start
HDDA_REG_CYL_LSB                 equ    0016h     ; [W] Reg: cyl start (lsb)
HDDA_REG_CYL_MSB                 equ    0018h     ; [W] Reg: cyl start (msb)
HDDA_REG_DRIVE_SEL               equ    001ah     ; [W] Reg: drive select
HDDA_REG_STATUS                  equ    001ch     ; [W] Reg: Status read
HDDA_REG_COMMAND                 equ    001eh     ; [W] Reg: Command write
HDDA_SEC_COUNT                   equ    0020h     ; [B] Arg: AL
HDDA_SEC_START                   equ    0021h     ; [B] Arg: CL (lower 6)
HDDA_CYL_LSB                     equ    0022h     ; [B] Arg: CH
HDDA_CYL_MSB                     equ    0023h     ; [B] Arg: CL (upper 2)
HDDA_DRIVE_SELECT                equ    0024h     ; [B] Arg: Setup by DL
HDDA_COMMAND                     equ    0025h     ; [B] Current command
HDDA_PARAMS_MASTER               equ    0026h     ; [-] Master parameter block
HDDA_PARAMS_SLAVE                equ    0037h     ; [-] Slave parameter block

HDDA_PARAM_PRECOMP               equ    0005h     ; [W] Pre-comp value to use
HDDA_PARAM_TIMEOUT_IO            equ    0009h     ; [B] Status readback loops
HDDA_PARAM_TIMEOUT_IOB           equ    000bh     ; [B] Status readback loops
HDDA_PARAM_SEC_REMAIN            equ    000eh     ; [B] Remaining sector count




	org    00e15h

; install hard drive support over the top of FDC

_hdc_install proc near public

	push   ds
	push   bx
	push   cx
	push   dx

	mov    ax, LBDA_SEG
	mov    ds, ax

	cli

	; Over-ride IRQ handler, disk services, 

	mov    word ptr ds:[76h * 4 + 0], offset _isr_hdc_broken
	mov    word ptr ds:[76h * 4 + 2], cs

	mov    word ptr ds:[LBDA_HDDA_SEGMENT], HDDA_SEG

	mov    word ptr ds:[13h * 4 + 0], offset _hdc_services
	mov    word ptr ds:[13h * 4 + 2], cs

	mov    word ptr ds:[56h * 4 + 0], offset _hdc_services
	mov    word ptr ds:[56h * 4 + 2], cs

	mov    word ptr ds:[41h * 4 + 0], 0026h
	mov    word ptr ds:[41h * 4 + 2], cs

	mov    ax, HDDA_SEG
	mov    ds, ax

	; Initialize hard drive data area with defaults

	mov    cx, 0048h
	nop
	mov    si, _hdda_init
	nop
	mov    di, 0

_copy_hdda:
	mov    al, cs:[si]
	mov    ds:[di], al
	inc    si
	inc    di
	loop   _copy_hdda

	; Perform detection/test of HDC

	sti
	mov    dx, ds:[HDDA_REG_CYL_LSB]
	mov    ax, 55aah
	out    dx, al

	mov    cx, 10
_hdc_det_delay1:
	loop   _hdc_det_delay1

	in     al, dx
	cmp    al, 0aah
	jne    _hdc_fail

	mov    al, ah
	out    dx, al

	mov    cx, 10
_hdc_det_delay2:
	loop   _hdc_det_delay2

	in     al, dx
	cmp    al, 55h
	je     _hdc_det_master_go

_hdc_fail:
	jmp    _hdc_failed
	nop

_hdc_det_master_go:
	mov    cx, 0017h    ; retries

_hdc_det_master:
	push   cx
	mov    cx, 0

_hdc_det_master_reset:
	push   cx
	mov    dx, ds:[HDDA_REG_RESET]
	in     al, dx

	mov    cx, 10
_hdc_det_delay3:
	loop   _hdc_det_delay3

	mov    dx, ds:[HDDA_REG_DRIVE_SEL]
	mov    al, 20h      ; select master
	out    dx, al

	mov    dx, ds:[HDDA_REG_STATUS]
	in     al, dx
	and    al, 0f0h
	cmp    al, 50h      ; wait for seek complete and drive ready
	pop    cx
	jz     _hdc_master_ok
	loop   _hdc_det_master_reset

	pop    cx
	loop   _hdc_det_master
	jmp    _hdc_failed
	nop

_hdc_master_ok:

	pop    cx
	mov    dx, 080h     ; master drive

	call   _hdc_bios_reset
	jc     _hdc_done

	mov    dx, 0080h    ; master drive

	call   _hdc_bios_recalibrate
	jc     _hdc_done

	call   _hdc_bios_seekend
	jc     _hdc_done

	call   _hdc_bios_recalibrate
	jc     _hdc_done

	mov    byte ptr ds:[HDDA_DETECTED], 1
	jmp    _hdc_done
	nop

_hdc_install endp



	org    00ed9h

_hdc_bios_recalibrate proc near public

	mov    ax, 1101h    ; Recalibrate
	mov    cx, 1
	int    56h

	ret

_hdc_bios_recalibrate endp



	org    00ee2h

_hdc_bios_seekend proc near public

	mov    cx, 0501h    ; Cylinder 0105h (261) ?
	mov    ax, 0c01h    ; Seek cylinder
	int    56h

	ret

_hdc_bios_seekend endp



_hdc_failed:
	mov    ah, 7
	stc
	jmp    _hdc_done
	nop

	sub    ah, ah

_hdc_done:

	pop    dx
	pop    cx
	pop    bx
	pop    ds

	ret



	org    00ef8h

_hdc_bios_reset proc near public

	mov    ax, 0        ; Reset drive
	mov    cx, 1
	int    56h
	ret

_hdc_bios_reset endp



	org    00f01h

_hdda_init:
	dw      000h                  ; 00 -> Offset to current params table
	db      000h                  ; 02 -> Slave select
	dw      000h                  ; 03 -> ?
	db      000h                  ; 05 -> Last I/O operation status
	dw      000h                  ; 06 -> ?
	dw      000h                  ; 08 -> User buffer offset rel to es:

	dw      0026ch                ; 0a -> HDC soft reset
	dw      00270h                ; 0c -> HDC data
	dw      00272h                ; 0e -> HDC error status
	dw      00272h                ; 10 -> HDC write precomp
	dw      00274h                ; 12 -> HDC sector count
	dw      00276h                ; 14 -> HDC sector number
	dw      00278h                ; 16 -> HDC cyl lsb
	dw      0027ah                ; 18 -> HDC cyl msb
	dw      0027ch                ; 1a -> HDC sdh
	dw      0027eh                ; 1c -> HDC status/command
	dw      0027eh                ; 1e -> HDC status/command

	db      000h                  ; 20 -> Arg: Sector count
	db      000h                  ; 21 -> Arg: Sector start
	db      000h                  ; 22 -> Arg: Cyl LSB
	db      000h                  ; 23 -> Arg: Cyl MSB
	db      020h                  ; 24 -> Arg: Drive/head select
	db      000h                  ; 25 -> Arg: Command

	; Master parameter block
	db      032h                  ; 26 + 00 -> ?
	db      001h                  ; 26 + 01 -> ?
	db      004h                  ; 26 + 02 -> ?
	db      000h                  ; 26 + 03 -> ?
	db      000h                  ; 26 + 04 -> ?
	dw      00020h                ; 26 + 05 -> Pre-comp value
	db      000h                  ; 26 + 07 -> ?
	db      000h                  ; 26 + 08 -> ?
	db      002h                  ; 26 + 09 -> Status readback loops
	db      002h                  ; 26 + 0a -> ?
	db      01ch                  ; 26 + 0b -> Status readback loops
	db      004h                  ; 26 + 0c -> ?
	db      000h                  ; 26 + 0d -> ?
	db      000h                  ; 26 + 0e -> Unread left-over sectors
	db      000h                  ; 26 + 0f -> ?
	db      000h                  ; 26 + 10 -> ?

	; Slave parameter block
	db      032h                  ; 37 + 00 -> ?
	db      001h                  ; 37 + 01 -> ?
	db      004h                  ; 37 + 02 -> ?
	db      000h                  ; 37 + 03 -> ?
	db      000h                  ; 37 + 04 -> ?
	dw      00020h                ; 37 + 05 -> Pre-comp value
	db      000h                  ; 37 + 07 -> ?
	db      000h                  ; 37 + 08 -> ?
	db      002h                  ; 37 + 09 -> Status readback loops
	db      002h                  ; 37 + 0a -> ?
	db      01ch                  ; 37 + 0b -> Status readback loops
	db      004h                  ; 37 + 0c -> ?
	db      000h                  ; 37 + 0d -> ?
	db      000h                  ; 37 + 0e -> Unread left-over sectors
	db      000h                  ; 37 + 0f -> ?
	db      000h                  ; 37 + 10 -> ?



	org    00f49h

_int13h_func_table:
	dw      015h                  ; Count of functions in table
	dw      _hdc_setup            ; setup function
	dw      _hdc_reset_request    ; 00h
	dw      _hdc_return_error     ; 01h
	dw      _hdc_read             ; 02h
	dw      _hdc_return_error     ; 03h
	dw      _hdc_return_error     ; 04h
	dw      _hdc_return_error     ; 05h
	dw      _hdc_return_error     ; 06h
	dw      _hdc_return_error     ; 07h
	dw      _hdc_return_error     ; 08h
	dw      _hdc_return_error     ; 09h
	dw      _hdc_return_error     ; 0ah
	dw      _hdc_return_error     ; 0bh
	dw      _hdc_seek             ; 0ch
	dw      _hdc_return_error     ; 0dh
	dw      _hdc_return_error     ; 0eh
	dw      _hdc_return_error     ; 0fh
	dw      _hdc_return_error     ; 10h
	dw      _hdc_recalibrate      ; 11h
	dw      _hdc_return_error     ; 12h
	dw      _hdc_return_error     ; 13h
	dw      _hdc_return_error     ; 14h



; int 13h and 56h handler that is hard drive specific (only)

	org    00f77h

_hdc_services proc near public

	cmp    dl, 080h
	jz     _hdc_services_go

	; Return error if bit 7 (HDC) select isn't set
	mov    ah, 1
	stc
	ret    2

_hdc_services_go:

	push   di
	mov    di, _int13h_func_table
	sti
	push   ds
	push   es
	pusha

	cmp    ah, cs:[di]
	jae    _hdc_services_error

	mov    bp, sp
	cld
	push   ax
	call   cs:[di + 2]            ; Call common setup function
	pop    ax

	push   ax
	mov    al, ah
	xor    ah, ah
	add    ax, ax
	add    di, ax
	pop    ax

	call   cs:[di + 4]            ; Function specific handler
	jmp    _hdc_services_done

_hdc_services_error:
	mov    al, 1
	mov    [bp + 00fh], al        ; Update al on pusha'd stack

_hdc_services_done:

	popa
	pop    es
	pop    ds
	pop    di

	iret

_hdc_services endp



; On entry:
;    AL -> Number of sectors to transfer (0 = 256)
;    DL -> Drive number with bit 7 set
;    CL -> Sector start (lower 6), Cyl MSB (upper 2)
;    CH -> Cylinder LSB
;    ES:BX -> User target buffer
;
; Exiting this function:
;    Hard drive operation arguments are recorded in data area
;    DS -> Hard drive data area (HDDA)
;    SI -> offset to master/slave specific parameter block
;    AL, CL, DL trashed

	org    00fb2h

_hdc_setup proc near public

	; Reference DS to our hard drive data area
	push   ax
	mov    ax, HDDA_SEG
	mov    ds, ax
	pop    ax

	mov    ds:[HDDA_DATA_OFFSET], bx
	mov    ds:[HDDA_SEC_COUNT], al

	mov    al, cl
	and    al, 0c0h
	shr    al, 06h
	mov    ds:[HDDA_CYL_MSB], al

	and    cl, 3fh
	mov    ds:[HDDA_SEC_START], cl
	mov    ds:[HDDA_CYL_LSB], ch

	mov    al, ds:[HDDA_DRIVE_SELECT]
	and    al, 60h

	and    dl, 1
	mov    ds:[HDDA_SLAVE_SELECT], dl  ; master/slave (0/1)

	; Build up correct value for drive select reg
	mov    cl, 3
	shl    dl, cl
	or     dl, dh
	or     al, dl
	mov    ds:[HDDA_DRIVE_SELECT], al

	mov    byte ptr ds:[HDDA_COMMAND], 0

	mov    al, ds:[HDDA_SLAVE_SELECT]
	call   _hdc_select_block

	mov    ds:[HDDA_PARAMS_OFFSET], si
	call   _hdc_select_drive

	ret

_hdc_setup endp



	org    00fffh

_hdc_reset_request proc near public

	mov    dx, ds:[HDDA_REG_RESET]
	in     al, dx

	mov    cx, 10
_hdc_reset_request_delay:
	loop   _hdc_reset_request_delay

	mov    dx, ds:[HDDA_REG_STATUS]
	in     al, dx

	and    al, 0f0h
	cmp    al, 50h
	jz     _hdc_reset_request_ok

	mov    ah, 5        ; (.....1.1)
	stc
	ret

_hdc_reset_request_ok:
	sub    ah, ah
	ret

_hdc_reset_request endp



	org    0101bh

_hdc_read proc near public

	mov    byte ptr ds:[HDDA_COMMAND], 20h
	mov    ch, 0
	mov    cl, ds:[HDDA_SEC_COUNT]

_hdc_read_sector:
	call   _hdc_proc_command
	mov    si, ds:[HDDA_PARAMS_OFFSET]
	mov    bl, ds:[si + HDDA_PARAM_TIMEOUT_IO]
	call   _hdc_cmd_wait

	jc     _hdc_read_sector_short

	call   _hdc_read_data
	jc     _hdc_read_sector_done

	inc    byte ptr ds:[HDDA_SEC_START]
	loop   _hdc_read_sector

_hdc_read_sector_short:
	mov    al, ds:[HDDA_SEC_COUNT]
	sub    al, cl
	mov    ss:[bp + HDDA_PARAM_SEC_REMAIN], al

_hdc_read_sector_done:
	jmp    _hdc_error_check
	nop

_hdc_read endp



	org    0104bh

_hdc_seek proc near public

	mov    byte ptr ds:[HDDA_COMMAND], 70h
	call   _hdc_proc_command

	mov    si, ds:[HDDA_PARAMS_OFFSET]
	mov    bl, ds:[si + HDDA_PARAM_TIMEOUT_IO]
	call   _hdc_cmd_wait

	jmp    _hdc_error_check
	nop

_hdc_seek endp



	org    01060h

_hdc_recalibrate proc near public

	mov    byte ptr ds:[HDDA_COMMAND], 10h
	call   _hdc_proc_command

	mov    si, ds:[HDDA_PARAMS_OFFSET]
	mov    bl, ds:[si + HDDA_PARAM_TIMEOUT_IOB]
	call   _hdc_cmd_wait

	jmp    _hdc_error_check
	nop

_hdc_recalibrate endp



	org    01075h

_hdc_return_error:

	mov    ah, 1
	jmp    _hdc_error_check
	nop

_hdc_return_ok:

	mov    ah, 0
	jmp    _hdc_error_check
	nop

_hdc_error_check:
	mov    ds:[HDDA_LAST_STATUS], ah
	mov    ss:[bp + 00fh], ah
	or     ah, ah
	jz     _hdc_ok

	call   _hdc_reset
	stc
	lahf
	mov    ss:[bp + 01ah], ah
	mov    ah, ds:[HDDA_LAST_STATUS]
	ret

_hdc_ok:

	clc
	lahf
	mov    ss:[bp + 01ah], ah
	mov    ah, ds:[HDDA_LAST_STATUS]
	ret



	org    010a1h

_hdc_read_data proc near public

	push   cx
	push   dx
	mov    cx, 0
	mov    dx, ds:[HDDA_REG_STATUS]

	; Wait for data request flag set
_hdc_read_data_wait:
	in     al, dx
	test   al, 8
	jnz    _hdc_read_data_setup
	loop   _hdc_read_data_wait

	mov    ah, 080h
	stc
	jmp    _hdc_read_data_done
	nop

_hdc_read_data_setup:
	mov    cx, 512
	mov    dx, ds:[HDDA_REG_DATA]
	mov    bx, ds:[HDDA_DATA_OFFSET]
	cld

_hdc_read_data_loop:
	in     al, dx
	mov    es:[bx], al

	inc    bx
	jnz    _hdc_read_data_cont

	mov    ax, es
	add    ax, 1000h
	mov    es, ax

_hdc_read_data_cont:
	loop   _hdc_read_data_loop

	mov    ds:[HDDA_DATA_OFFSET], bx
	sub    ah, ah

_hdc_read_data_done:
	pop    dx
	pop    cx
	ret

_hdc_read_data endp



	org    010dch

_hdc_select_drive proc near public

	push   ax
	push   dx

	mov    al, ds:[HDDA_DRIVE_SELECT]
	mov    dx, ds:[HDDA_REG_DRIVE_SEL]
	out    dx, al

	mov    si, ds:[HDDA_PARAMS_OFFSET]
	mov    ax, ds:[si + HDDA_PARAM_PRECOMP]
	mov    dx, ds:[HDDA_REG_PRECOMP]
	out    dx, al

	pop    dx
	pop    ax

	ret

_hdc_select_drive endp



	org    010f5h

_hdc_select_block proc near public

	mov    cl, ds:[HDDA_SLAVE_SELECT]
	mov    al, cl
	mov    ch, 0
	mov    si, HDDA_PARAMS_MASTER
	or     cl, cl
	jz     _hdc_select_block_done

_hdc_select_block_loop:
	add    si, HDDA_PARAMS_SLAVE - HDDA_PARAMS_MASTER
	loop   _hdc_select_block_loop

_hdc_select_block_done:

	ret

_hdc_select_block endp



	org    0110ah

_hdc_reset proc near public

	push   ax
	push   dx

	mov    dx, ds:[HDDA_REG_RESET]
	in     al, dx

	mov    cx, 10
_hdc_reset_delay:
	loop   _hdc_reset_delay

	pop    dx
	pop    ax

	ret

_hdc_reset endp



; Transfer arguments setup by _hdc_setup in the HDDA to 6 registers
; in the HDC controller ending with the command byte causing the
; disk operation to commence

	org    01119h

_hdc_proc_command proc near public

	push   ax
	push   cx
	push   dx
	push   si

	mov    cx, 6
	mov    si, HDDA_SEC_COUNT
	mov    dx, ds:[HDDA_REG_SEC_COUNT]
	cld

_hdc_proc_command_loop:

	lodsb
	out    dx, al
	inc    dx
	inc    dx
	loop   _hdc_proc_command_loop

	pop    si
	pop    dx
	pop    cx
	pop    ax

	ret

_hdc_proc_command endp



	org    01133h

_hdc_cmd_wait proc near public

	push   cx
	push   dx
	mov    dx, ds:[HDDA_REG_STATUS]
	sub    cx, cx

_hdc_read_status:
	in     al, dx
	mov    ah, al
	in     al, dx
	cmp    ah, al
	jnz    _hdc_read_status

	and    al, 0f0h
	cmp    al, 50h           ; Check for drive ready and seek complete
	jz     _hdc_cmd_ready
	loop   _hdc_read_status

	dec    bl
	jnz    _hdc_read_status
	mov    ah, 080h
	jmp    _hdc_cmd_timeout
	nop

_hdc_cmd_ready:
	mov    al, ah
	test   al, 1
	jz     _hdc_cmd_ok
	mov    dx, ds:[HDDA_REG_ERROR]
	in     al, dx
	and    al, 0d6h
	call   _hdc_xlat_sts

_hdc_cmd_timeout:
	stc
	jmp    _hdc_cmd_done

_hdc_cmd_ok:
	sub    ah, ah

_hdc_cmd_done:
	pop    dx
	pop    cx

	ret

_hdc_cmd_wait endp



; Translates bits in the error register to IBM Int13h BIOS status codes

	org    0116ch

_hdc_xlat_sts proc near public

	test   al, 001h          ; bit 0: Address mark not found
	jz     _hdc_etest_bit1

	mov    ah, 2             ;   -> (......1.) Bad sector
	ret

_hdc_etest_bit1:
	test   al, 002h          ; bit 1: Track 0 not found
	jz     _hdc_etest_bit2

	mov    ah, 40h           ;   -> (.1......) Controller error
	ret

_hdc_etest_bit2:
	test   al, 004h          ; bit 2: Aborted command
	jz     _hdc_etest_bit4

	mov    ah, 1             ;   -> (.......1) Illegal command to driver
	ret

_hdc_etest_bit4:
	test   al, 010h          ; bit 4: Sector not found
	jz     _hdc_etest_bit6

	mov    ah, 4             ;   -> (.....1..) Requested sector not found
	ret

_hdc_etest_bit6:
	test   al, 040h          ; bit 6: Uncorrectable CRC error
	jz     _hdc_etest_bit7

	mov    ah, 10h           ;   -> (...1....) CRC error on disk read
	ret

_hdc_etest_bit7:
	test   al, 080h          ; bit 7: Bad block detected
	jz     _hdc_xlat_sts_unk

	mov    ah, 0bh           ;   -> (....1.11) ?
	ret

_hdc_xlat_sts_unk:
	mov    ah, 0bbh          ;   -> (1.111.11) ?
	ret

_hdc_xlat_sts endp




; When the HDC routines install themselves, the HDC interrupt request
; vector handler is replaced by this call.  I don't know why.  The
; initial handler at least issues an auto EOI to the PIC.  This doesn't
; ...cocaine was pretty popular in 1983!

	org    01199h

_isr_hdc_broken proc near public

	iret

_isr_hdc_broken endp



	org    01300h

include table_8x8.inc



	org    01700h

include table_8x16.inc



	org    01f00h

_start:

	; Ensure relocation register upper bits clear

	mov    ax, 00ffh
	mov    dx, 0fffeh
	out    dx, ax

	; Readback relocation register as a sanity test on SoC

	mov    bx, ax
	not    ax
	mov    dx, 0fffeh
	in     ax, dx
	xor    ax, bx
	and    ax, 0dfffh
	jz     _soc_passed

_soc_failure:
	jmp    _soc_failure

_soc_passed:

	; MPCS -> MCS lines are 128KB x 4
	;         PCS4-6 are 2 wait states, RDY ignored
	;         Peripherals in I/O space, 7 PCS lines

	mov    ax, 0c0beh
	mov    dx, 0ffa8h
	out    dx, ax

	; MMCS -> MCS base is at start of memory, 0 wait states, RDY used

	mov    ax, 01f8h
	mov    dx, 0ffa6h
	out    dx, ax

	; PACS -> Peripheral select base = 0
	;              PCS0: 000h -> 07fh
	;              PCS1: 080h -> 0ffh
	;              PCS2: 100h -> 17fh
	;              PCS3: 180h -> 1ffh
	;              PCS4: 200h -> 27fh
	;              PCS5: 280h -> 2ffh
	;              PCS6: 300h -> 37fh
	;         PCS0-3 are 2 wait states, RDY ignored

	mov    ax, 003eh
	mov    dx, 0ffa4h
	out    dx, ax


	; Silence speaker / gate clocks / hold peripherals in reset

	mov    al, 0
	mov    dx, 0
	out    dx, al


	; Video clock selection & frame buffer -> address 0

	mov    al, 0c0h
	mov    dx, 0101h
	out    dx, al


	; PPI: Group B -> Port C lower output, Port B input,  Mode 0
	;      Group A -> Port C upper input,  Port A output, Mode 1

	mov    dx, 0056h
	mov    al, 0aah
	out    dx, al
	nop
	nop

	; PPI: Port C -> Port A out, PCB Revision select

	mov    dx, 0054h
	mov    al, 5
	out    dx, al

	; This is bizarre - Port B read, PCB version - but now hard-coded

	mov    al, 3
	mov    dx, 0052h
	nop
	mov    bp, _pcb_revtable
	nop

	; Loop-up 

_pcb_lookup:
	cmp    al, cs:[bp + CONFIG_REV]
	jz     _pcb_found
	add    bp, 10h
	jmp    _pcb_lookup

_pcb_found:

	mov    ax, cs:[bp + CONFIG_UMCS]
	mov    dx, 0ffa0h
	out    dx, ax

	; Go to common startup

	jmpf   _TEXT:_init_entry
	nop


	org    01f6ah

_pcb_revtable:

	db     000h         ; 00h: PCB Rev.0
	db     008h         ; 01h:   Max RAM: 512KB
	dw     0e03fh       ; 02h:   UMCS: e0000+ 3 wait, RDY ignored
	db     044h         ; 04h:   128KB port 101h
	db     000h         ; 05h:   128KB port 000h
	db     048h         ; 06h:   256KB port 101h
	db     000h         ; 07h:   256KB port 000h
	db     050h         ; 08h:   384KB port 101h
	db     000h         ; 09h:   384KB port 000h
	db     060h         ; 0ah:   512KB port 101h
	db     000h         ; 0bh:   512KB port 000h
	db     060h         ; 0ch:   Unsupported
	db     000h         ; 0dh:   Unsupported
	db     060h         ; 0eh:   Unsupported
	db     000h         ; 0fh:   Unsupported

	db     001h         ; 00h: PCB Rev.1
	db     008h         ; 01h:   Max RAM: 512KB
	dw     0e03bh       ; 02h:   UMCS: e0000+ 3 wait, RDY used
	db     0c4h         ; 04h:   128KB port 101h
	db     000h         ; 05h:   128KB port 000h
	db     0c8h         ; 06h:   256KB port 101h
	db     000h         ; 07h:   256KB port 000h
	db     0d0h         ; 08h:   384KB port 101h
	db     000h         ; 09h:   384KB port 000h
	db     0e0h         ; 0ah:   512KB port 101h
	db     000h         ; 0bh:   512KB port 000h
	db     0e0h         ; 0ch:   Unsupported
	db     000h         ; 0dh:   Unsupported
	db     0e0h         ; 0eh:   Unsupported
	db     000h         ; 0fh:   Unsupported

	db     002h         ; 00h: PCB Rev.2
	db     00ch         ; 01h:   Max RAM: 768KB
	dw     0f83fh       ; 02h:   UMCS: f8000+ 3 wait, RDY ignored
	db     0c3h         ; 04h:   128KB port 101h : 32KB FB @ 18000h
	db     000h         ; 05h:   128KB port 000h
	db     0c7h         ; 06h:   256KB port 101h : 32KB FB @ 38000h
	db     000h         ; 07h:   256KB port 000h
	db     0cbh         ; 08h:   384KB port 101h : 32KB FB @ 58000h
	db     000h         ; 09h:   384KB port 000h
	db     0cfh         ; 0ah:   512KB port 101h : 32KB FB @ 78000h
	db     000h         ; 0bh:   512KB port 000h
	db     0d3h         ; 0ch:   640KB port 101h : 32KB FB @ 98000h
	db     000h         ; 0dh:   640KB port 000h
	db     0d7h         ; 0eh:   768KB port 101h : 32KB FB @ b8000h
	db     000h         ; 0fh:   768KB port 000h

	db     003h         ; 00h: PCB Rev.3
	db     00ch         ; 01h:   Max RAM: 768KB
	dw     0f83fh       ; 02h:   UMCS: f8000+ 3 wait, RDY ignored
	db     0c3h         ; 04h:   128KB port 101h : 32KB FB @ 18000h
	db     010h         ; 05h:   128KB port 000h
	db     0c7h         ; 06h:   256KB port 101h : 32KB FB @ 38000h
	db     010h         ; 07h:   256KB port 000h
	db     0cbh         ; 08h:   384KB port 101h : 32KB FB @ 58000h
	db     010h         ; 09h:   384KB port 000h
	db     0cfh         ; 0ah:   512KB port 101h : 32KB FB @ 78000h
	db     010h         ; 0bh:   512KB port 000h
	db     0d3h         ; 0ch:   640KB port 101h : 32KB FB @ 98000h
	db     010h         ; 0dh:   640KB port 000h
	db     0d7h         ; 0eh:   768KB port 101h : 32KB FB @ b8000h
	db     010h         ; 0fh:   768KB port 000h


	org    01feeh

_bios_checksum:

	dw     03afdh



	org    01ff0h

_entry:
	jmpf   _TEXT:_start

	db     11 dup (0)

_TEXT ends

end
