#include <pic14regs.h>
#include <stdint.h>

/* CONFIGURATION WORD 1 */
__code uint16_t __at (_CONFIG1) __config1 =
	_CP_OFF &		// Code protection off.
	_CCPMX_RB3 &		// CCP1 function on RB3.
	_DEBUG_OFF &		// In-Circuit Debugger disabled, RB6 and RB7 are general purpose I/O pins.
	_WRT_OFF &		// Write protection off.
	_CPD_OFF &		// Code protection off.
	_LVP_OFF &		// RB3 is digital I/O, HV on MCLR must be used for programming.
	_BOREN_OFF &		// BOR disabled.
	_MCLRE_ON &		// RA5/MCLR/VPP pin function is MCLR.
	_PWRTE_OFF &		// PWRT disabled.
	_WDTE_OFF &		// WDT disabled.
	_FOSC_INTOSCIO;		// INTRC oscillator; port I/O function on both RA6/OSC2/CLKO pin and RA7/OSC1/CLKI pin.
	//_FOSC_INTOSCCLK;	// INTRC oscillator; CLKO function on RA6/OSC2/CLKO pin and port I/O function on RA7/OSC1/CLKI pin.

/* CONFIGURATION WORD 2 */
__code uint16_t __at (_CONFIG2) __config2 =
	_IESO_OFF &		// Internal External Switchover mode disabled.
	_FCMEN_OFF;		// Fail-Safe Clock Monitor disabled.

/* Pin definitions */

#define RPI_UP			RB0
#define RPI_UP_TRIS		TRISB0

#define RPI_PWR_EN		RB4
#define RPI_PWR_EN_TRIS		TRISB4

#define BL_EN			RB5
#define BL_EN_TRIS		TRISB5

#define SYS_ON			RA4
#define SYS_ON_TRIS		TRISA4
#define SYS_ON_ANS		ANS4

#define RPI_MISC1		RB1
#define RPI_MISC1_TRIS		TRISB1

#define RPI_MISC2		RB2
#define RPI_MISC2_TRIS		TRISB2

#define RPI_MISC3		RB3
#define RPI_MISC3_TRIS		TRISB3

/* Helper macros */

#define rpi_is_up		(RPI_UP == 1)
#define rpi_is_down		(RPI_UP == 0)

#define system_is_on		(SYS_ON == 1)
#define system_is_off		(SYS_ON == 0)

#define turn_rpi_on		(RPI_PWR_EN = 0)
#define turn_rpi_off		(RPI_PWR_EN = 1)

#define turn_backlight_on	(BL_EN = 0)
#define turn_backlight_off	(BL_EN = 1)

/* System states */
typedef enum {
	RESET = 0,
	OFF,
	TURN_ON,
	ON,
	TURN_OFF,
} system_state;

/* Main entry point */
void main(void)
{
	system_state state;

	/* Configure the clock */
	OSCCON = _IRCF0;  /* 125 kHz internal clock */

	/* Configure the inputs */
	RPI_UP_TRIS = 1;
	SYS_ON_TRIS = 1;
	SYS_ON_ANS = 0;

	/* Configure the outputs */
	RPI_PWR_EN_TRIS = 0;
	BL_EN_TRIS = 0;

	/* System state machine */
	state = RESET;
	while (1) {
		switch(state) {
		case RESET:
			turn_rpi_off;
			turn_backlight_off;
			state = OFF;
			break;
		case OFF:
			if (system_is_on) {
				/* The system is turned on */
				turn_rpi_on;
				turn_backlight_on;
				state = TURN_ON;
			}
			break;
		case TURN_ON:
			if (system_is_off) {
				/* The system is turned off */
				turn_backlight_off;
				state = TURN_OFF;
			} else if (rpi_is_up) {
				/* The Pi is running */
				state = ON;
			}
			break;
		case ON:
			if (system_is_off) {
				/* The system is turned off */
				turn_backlight_off;
				state = TURN_OFF;
			} else if (rpi_is_down) {
				/* The Pi is shut down */
				turn_backlight_off;
				turn_rpi_off;
				state = OFF;
			}
			break;
		case TURN_OFF:
			if (system_is_on) {
				/* The system is turned back on */
				turn_backlight_on;
				state = ON;
			} else if (rpi_is_down) {
				/* The Pi is shut down */
				turn_rpi_off;
				state = OFF;
			}
			break;
		}
	}
}
