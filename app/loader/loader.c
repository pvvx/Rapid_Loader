/******************************************************************************
 * FileName: loader.c
 * Description: Alternate SDK
 * Author: PV`
 * (c) PV` 2015
*******************************************************************************/
#include "user_config.h"
#include "bios/spiflash.h"
#include "hw/esp8266.h"
#include "hw/spi_register.h"
//=============================================================================
// define
//-----------------------------------------------------------------------------
#define FQSPI 80 // 80 or 40 MHz
//extern void loader_flash_boot(struct SPIFlashHeader *);
#define loader_flash_boot_addr 	0x40200080
#define next_flash_header_addr 	0x402000c0

typedef void (* loader_call)(void *) __attribute__ ((noreturn));
//extern char _text_end;
//=============================================================================
// IRAM code
//=============================================================================
// call_user_start() - вызов из заголовка, загрузчиком
// ENTRY(call_user_start) in eagle.app.v6.ld
//-----------------------------------------------------------------------------
void __attribute__ ((noreturn)) call_user_start(void)
{
//		Cache_Read_Disable();
		IO_RTC_4 = 0; // Отключить блок WiFi (уменьшение потребления на время загрузки)
		SPI0_USER |= SPI_CS_SETUP; // +1 такт перед CS = 0x80000064
#if FQSPI == 80	// xSPI на 80 MHz
		GPIO_MUX_CFG |= BIT(MUX_SPI0_CLK_BIT); // QSPI = 80 MHz
		SPI0_CTRL = (SPI0_CTRL & SPI_CTRL_F_MASK) | SPI_CTRL_F80MHZ;
#else			// xSPI на 40 MHz
		GPIO_MUX_CFG &= ~(1<< MUX_SPI0_CLK_BIT);
		SPI0_CTRL = (SPI0_CTRL & SPI_CTRL_F_MASK) | SPI_CTRL_F40MHZ;
#endif
		// Всё, включаем кеширование, далее можно вызывать процедуры из flash
		Cache_Read_Enable(0, 0, 0);
		// Переход в область кеширования flash,
		// Запускаем загрузку SDK с указателем на заголовок SPIFlashHeader (находится за данным загручиком по адресу с align 16)
//		((loader_call)((uint32)(&loader_flash_boot) + FLASH_BASE - IRAM_BASE + 0x10))((struct SPIFlashHeader *)(((uint32)(&_text_end) + FLASH_BASE - IRAM_BASE + 0x17) & (~15)));
		((loader_call)(loader_flash_boot_addr))((struct SPIFlashHeader *)(next_flash_header_addr));

		// контрольня сумма отображает версию и частоту
		// Checksum: 43 -> 40 MHz Ver3
		// Checksum: 83 -> 80 MHz Ver3
}
