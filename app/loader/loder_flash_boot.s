
		.begin	literal_prefix	.loader
		.section	.loader.lit4, "ax"

		.align	4
		.global loader_flash_boot

loader_flash_boot:
		l32i.n	a3, a2, 0	// SPIFlashHeader.head : bit0..7: = 0xE9, bit8..15: Number of segments, ...	
		l32i.n	a7, a2, 4	// Entry point
		extui	a3, a3, 8, 4 // Number of segments & 0x0F
		addi.n	a2, a2, 8	// p SPIFlashHeadSegment
		j		4f
1:
		l32i.n	a5, a2, 0	// Memory offset
		addi.n	a4, a2, 8	// p start data
		l32i.n	a2, a2, 4	// Segment size
		srli	a2, a2, 2	// size >> 2
		addx4	a2, a2, a4	// + (size >> 2)
		j		3f
2:		
		l32i.n	a6, a4, 0	// flash data
		addi.n	a4, a4, 4
		s32i.n	a6, a5, 0	// Memory data
		addi.n	a5, a5, 4
3:		
		bne	a2, a4, 2b		// next SPIFlashHeadSegment != cur	
4:
		addi.n	a3, a3, -1	// Number of segments - 1
		bnei	a3, -1, 1b	// end segments ?
		
		movi.n	a2, 1
		slli	a1, a2, 30
//		callx0	a7
		jx		a7

		.byte	'R'
		.byte	'L'
		.byte	'd'
		.byte	'r'
		.byte	'V'
		.byte	'3'
		.byte	' '
		.byte	'8'
		.byte	'0'
		.byte	'M'
		.byte	'H'
		.byte	'z'
		.align	16

		.end	literal_prefix
