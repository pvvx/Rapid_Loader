/******************************************************************************
 * FileName: loader.c
 * Description: Alternate SDK
 * Author: PV`
 * (c) PV` 2015
*******************************************************************************/
#include "user_config.h"
#include "bios.h"
#include "hw/esp8266.h"
#include "hw/spi_register.h"
//=============================================================================
// define
//-----------------------------------------------------------------------------
#define FQSPI 80 // 80 or 40 MHz
#define LSDK_BASE 	0x402000B0
typedef void (* sdk_call)(void);
//=============================================================================
// IRAM code
//=============================================================================
// call_user_start() - вызов из заголовка, загрузчиком
// ENTRY(call_user_start) in eagle.app.v6.ld
//-----------------------------------------------------------------------------
void call_user_start(void)
{
		// коррекция QSPI на 80 MHz
		SPI0_USER |= SPI_CS_SETUP; // +1 такт перед CS = 0x80000064
#if FQSPI == 80
		GPIO_MUX_CFG |= (1<< MUX_SPI0_CLK_BIT); // QSPI = 80 MHz
		SPI0_CTRL = 0x016ab000; // ((SPI0_CTRL >> 12) << 12) | BIT(12);
#else
		GPIO_MUX_CFG &= 0xfffffeff;
		SPI0_CTRL = 0x016aa101;
#endif
		// Всё - включаем кеширование, далее можно вызывать процедуры из flash
		Cache_Read_Enable(0, 0, 0);
		((sdk_call)(0x40200064))(); // переход в область flash, на следующую команду
//		asm volatile (".byte 0xff");
		asm volatile ("memw"); // вставка, для коррекции адреса к кратности 4
		// Загрузка сегментов (bootloader SDK)
		uint32 * ps = (uint32 *)LSDK_BASE;
		uint32 count = ((*ps)>>8) & 0x0F;
		sdk_call p = (sdk_call)(ps[1]);
		ps += 2;
		while(count--) {
			    uint32 *pd = (uint32 *)(*ps++); // адрес куда
			    uint32 len = *ps++;	// размер
				len >>= 2;
				while(len--) *pd++=*ps++;
		}
		// Очистка стека и передача управления в SDK
		asm volatile (
				"movi	a2, 1;"
				"slli   a1, a2, 30;"
				);
//		Cache_Read_Disable(); // пока не вставить, о надо для поддержки стандартных вариантов
		p(); // ((sdk_call)(p[1]))
}
