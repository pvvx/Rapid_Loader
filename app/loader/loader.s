
	.text 
	.align	4 
	.literal_position 
	.global	call_user_start 
	.type	call_user_start, @function 
call_user_start: 
	movi	a3, spi0_	// 0x60000200
	addmi	a4, a3, 0x500 // a4 = rtc_ = 0x60000700
	movi.n	a2, 0       
	s32i.n	a2, a4, 16	// IO_RTC_4 = 0

	movi	a5, 0x80
	s32i	a5, a4, 308 // GPIO_MUX = VAL_MUX_GPIO0_SDK_DEF // 0x60000800
	
	movi.n	a5, 0x20    // SPI0_USER |= SPI_CS_SETUP
	l32i.n	a6, a3, 28  // 0x6000021C | 0x20
	or		a5, a6, a5 
	s32i.n	a5, a3, 28  

	l32i	a6, a4, 256 // GPIO_MUX_CFG |= BIT(MUX_SPI0_CLK_BIT) // QSPI = 80 MHz
	movi	a5, 0x100 
	or		a6, a6, a5 
	s32i	a6, a4, 256  
	l32i.n	a4, a3, 8	// SPI0_CTRL = (SPI0_CTRL & SPI_CTRL_F_MASK) | SPI_CTRL_F80MHZ; 
	srli    a5, a4, 12
	movi	a4, 1
	or		a5, a4, a5
	slli    a4, a5, 12
	s32i.n	a4, a3, 8 
	mov.n	a4, a2 		// Cache_Read_Enable(0, 0, 0);
	mov.n	a3, a2 
	call0	Cache_Read_Enable 
	movi	a2, 0x40200070+0x40 // +0x40 size: addld.bin
	movi	a3,-0x40
	add		a0,a2,a3
	jx		a0  //	call0	0x40200070+
	.byte	0xCD
	.size	call_user_start, .-call_user_start
