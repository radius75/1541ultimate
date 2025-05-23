/*
 * u64ii_tester.h
 *
 *  Created on: Nov 2, 2024
 *      Author: gideon
 */

#ifndef U64II_TESTER_H_
#define U64II_TESTER_H_

#include <stdint.h>

#ifndef U2P_IO_BASE
#define U2P_IO_BASE 0xA0000000
#endif

#define U64TESTER_IO1_BASE   (U2P_IO_BASE + 0x80000) // 10 000
#define U64TESTER_IO2_BASE   (U2P_IO_BASE + 0x90000) // 10 010
#define U64TESTER_SID1_BASE  (U2P_IO_BASE + 0xA8000) // 10 101
#define U64TESTER_SID2_BASE  (U2P_IO_BASE + 0xA8020) // 10 101
#define U64TESTER_REG_BASE   (U2P_IO_BASE + 0xB0000) // 10 110
#define U64TESTER_VGA_BASE   (U2P_IO_BASE + 0xC0000)
#define U64TESTER_AUDIO_BASE (U2P_IO_BASE + 0x00600)
// #define U64II_HW_I2C_BASE    (U2P_IO_BASE + 0x00700)

#define U64II_VGA_TIMING_REGS        (U64TESTER_VGA_BASE + 0x4000)
#define U64II_VGA_CHARGEN_REGS       (U64TESTER_VGA_BASE + 0x0000)
#define U64II_VGA_CHARGEN_SCREEN_RAM (U64TESTER_VGA_BASE + 0x0800)
#define U64II_VGA_CHARGEN_COLOR_RAM  (U64TESTER_VGA_BASE + 0x1000)

#define REMOTE_CART_OUT   (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 0))
#define REMOTE_CART_IN    (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 1))
#define REMOTE_ADDR_HI    (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 2))
#define REMOTE_ADDR_LO    (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 3))
#define REMOTE_IEC        (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 4))
#define REMOTE_CAS        (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 5))
#define REMOTE_SIGNATURE  (*(volatile uint8_t *)(U64TESTER_IO1_BASE + 7))

#define LOCAL_IEC         (*(volatile uint8_t *)(U64TESTER_REG_BASE + 0))
#define LOCAL_CAS         (*(volatile uint8_t *)(U64TESTER_REG_BASE + 1))
#define LOCAL_CART        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 2))
#define LOCAL_CIA1        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 3))
#define LOCAL_CIA2        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 4))
#define LOCAL_PADDLESEL   (*(volatile uint8_t *)(U64TESTER_REG_BASE + 7))
#define LOCAL_PADDLE_X    (*(volatile uint8_t *)(U64TESTER_REG_BASE + 8))
#define LOCAL_PADDLE_Y    (*(volatile uint8_t *)(U64TESTER_REG_BASE + 9))
#define LOCAL_JOY1        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 10))
#define LOCAL_JOY2        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 11))
#define LOCAL_CIA3        (*(volatile uint8_t *)(U64TESTER_REG_BASE + 12))

typedef struct {
    uint8_t sda;
    uint8_t scl;
    uint8_t capsel;
    uint8_t capval;
    uint8_t id;
} socket_tester_t;

#define SOCKET1           ((volatile socket_tester_t *)U64TESTER_SID1_BASE)
#define SOCKET2           ((volatile socket_tester_t *)U64TESTER_SID2_BASE)

#define AUDIO_SAMPLE_COUNT  512

#ifdef __cplusplus
extern "C" {
#endif

int U64TestKeyboard();
int U64TestUserPort();
int U64TestCartridge();
int U64TestIEC();
int U64TestCassette();
int U64TestJoystick();
int U64TestPaddle();
int U64TestAudioCodecSilence();
int U64TestAudioCodecPurity();
int U64TestSidSockets();
int U64TestWiFiComm();
int U64TestVoltages();
int U64TestSpeaker();
int U64TestUsbHub();
int U64TestEthernet();
int U64TestOff();
int U64TestReboot();
int U64TestSetSerial();
int U64TestGetSerial();
int U64TestClearConfig();
int U64TestClearFlash();

#ifdef __cplusplus
}
#endif

#endif /* U64_TESTER_H_ */
