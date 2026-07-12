#include "xparameters.h"
#include "xuartps.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "xtime_l.h"

#define IMG_WIDTH        128U
#define IMG_HEIGHT       72U
#define RGB888_FORMAT    0x18U
#define UART_BAUD_RATE   115200U
#define UART_WAIT_MS     2000U

#define FRAME_SYNC_0     0x55U
#define FRAME_SYNC_1     0xaaU
#define LINE_SYNC_0      0x33U
#define LINE_SYNC_1      0xccU
#define CTRL_SYNC_0      0xa5U
#define CTRL_SYNC_1      0x5aU

#define CTRL_CMD_MODE    0x01U
#define CTRL_CMD_THRESH  0x02U
#define CTRL_CMD_OVERLAY 0x03U

#ifndef UART_DEVICE_ID
#if defined(XPAR_PS7_UART_1_DEVICE_ID)
#define UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID
#elif defined(XPAR_XUARTPS_1_DEVICE_ID)
#define UART_DEVICE_ID XPAR_XUARTPS_1_DEVICE_ID
#elif defined(XPAR_PS7_UART_0_DEVICE_ID)
#define UART_DEVICE_ID XPAR_PS7_UART_0_DEVICE_ID
#elif defined(XPAR_XUARTPS_0_DEVICE_ID)
#define UART_DEVICE_ID XPAR_XUARTPS_0_DEVICE_ID
#else
#error "No XUartPs device id macro found in xparameters.h"
#endif
#endif

#ifndef FRAMEBUFFER_BASEADDR
#if defined(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR)
#define FRAMEBUFFER_BASEADDR XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR
#else
#define FRAMEBUFFER_BASEADDR 0x40000000U
#endif
#endif

#define CTRL_MODE_ADDR      (FRAMEBUFFER_BASEADDR + 0x9000U)
#define CTRL_THRESHOLD_ADDR (FRAMEBUFFER_BASEADDR + 0x9004U)
#define CTRL_OVERLAY_ADDR   (FRAMEBUFFER_BASEADDR + 0x9008U)

static XUartPs UartInst;
static u8 display_mode = 2U;
static u8 threshold_value = 80U;
static u8 overlay_enable = 0U;

static int uart_recv_byte_timeout(u8 *byte_value, u32 timeout_ms)
{
    XTime start_time;
    XTime now_time;
    XTime timeout_ticks = ((XTime)timeout_ms * (XTime)COUNTS_PER_SECOND) / 1000U;

    if (XUartPs_Recv(&UartInst, byte_value, 1U) == 1U) {
        return XST_SUCCESS;
    }

    XTime_GetTime(&start_time);

    while (1) {
        if (XUartPs_Recv(&UartInst, byte_value, 1U) == 1U) {
            return XST_SUCCESS;
        }

        XTime_GetTime(&now_time);
        if ((now_time - start_time) >= timeout_ticks) {
            return XST_FAILURE;
        }
    }
}

static int uart_recv_u16_le(u16 *value, u32 timeout_ms)
{
    u8 low;
    u8 high;

    if (uart_recv_byte_timeout(&low, timeout_ms) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    if (uart_recv_byte_timeout(&high, timeout_ms) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    *value = (u16)low | ((u16)high << 8);
    return XST_SUCCESS;
}

static void control_write_defaults(void)
{
    Xil_Out32(CTRL_MODE_ADDR, (u32)display_mode);
    Xil_Out32(CTRL_THRESHOLD_ADDR, (u32)threshold_value);
    Xil_Out32(CTRL_OVERLAY_ADDR, (u32)overlay_enable);
}

static void control_print_state(void)
{
    xil_printf("control: mode=%d threshold=%d overlay=%d\r\n",
               (u32)display_mode,
               (u32)threshold_value,
               (u32)overlay_enable);
}

static int handle_control_packet(void)
{
    u8 cmd;
    u8 value;

    if (uart_recv_byte_timeout(&cmd, UART_WAIT_MS) != XST_SUCCESS) {
        return -10;
    }
    if (uart_recv_byte_timeout(&value, UART_WAIT_MS) != XST_SUCCESS) {
        return -11;
    }

    switch (cmd) {
    case CTRL_CMD_MODE:
        display_mode = value & 0x03U;
        Xil_Out32(CTRL_MODE_ADDR, (u32)display_mode);
        break;

    case CTRL_CMD_THRESH:
        threshold_value = value;
        Xil_Out32(CTRL_THRESHOLD_ADDR, (u32)threshold_value);
        break;

    case CTRL_CMD_OVERLAY:
        overlay_enable = value ? 1U : 0U;
        Xil_Out32(CTRL_OVERLAY_ADDR, (u32)overlay_enable);
        break;

    default:
        xil_printf("unknown control command: 0x%02x value=0x%02x\r\n", (u32)cmd, (u32)value);
        return -12;
    }

    control_print_state();
    return 1;
}

static int wait_for_packet_start(u32 timeout_ms)
{
    u8 prev = 0U;
    u8 cur;

    while (1) {
        if (uart_recv_byte_timeout(&cur, timeout_ms) != XST_SUCCESS) {
            return 0;
        }

        if ((prev == FRAME_SYNC_0) && (cur == FRAME_SYNC_1)) {
            return 1;
        }

        if ((prev == CTRL_SYNC_0) && (cur == CTRL_SYNC_1)) {
            return 2;
        }

        prev = cur;
    }
}

static int wait_for_line_sync(u32 timeout_ms)
{
    u8 prev = 0U;
    u8 cur;

    while (1) {
        if (uart_recv_byte_timeout(&cur, timeout_ms) != XST_SUCCESS) {
            return XST_FAILURE;
        }
        if ((prev == LINE_SYNC_0) && (cur == LINE_SYNC_1)) {
            return XST_SUCCESS;
        }
        prev = cur;
    }
}

static void framebuffer_write_pixel(u32 x, u32 y, u8 r, u8 g, u8 b)
{
    u32 offset = ((y * IMG_WIDTH) + x) << 2;
    u32 pixel = ((u32)r << 16) | ((u32)g << 8) | (u32)b;

    Xil_Out32(FRAMEBUFFER_BASEADDR + offset, pixel);
}

static void fill_test_pattern(void)
{
    u32 x;
    u32 y;

    for (y = 0U; y < IMG_HEIGHT; y++) {
        for (x = 0U; x < IMG_WIDTH; x++) {
            u8 r = (u8)((x * 255U) / (IMG_WIDTH - 1U));
            u8 g = (u8)((y * 255U) / (IMG_HEIGHT - 1U));
            u8 b = ((x / 8U) & 1U) ? 0x40U : 0x00U;

            if ((x == 0U) || (x == IMG_WIDTH - 1U) ||
                (y == 0U) || (y == IMG_HEIGHT - 1U)) {
                r = 0xffU;
                g = 0xffU;
                b = 0xffU;
            }

            framebuffer_write_pixel(x, y, r, g, b);
        }
    }
}

static int uart_init(void)
{
    XUartPs_Config *config;
    int status;

    config = XUartPs_LookupConfig(UART_DEVICE_ID);
    if (config == NULL) {
        return XST_FAILURE;
    }

    status = XUartPs_CfgInitialize(&UartInst, config, config->BaseAddress);
    if (status != XST_SUCCESS) {
        return status;
    }

    XUartPs_SetOperMode(&UartInst, XUARTPS_OPER_MODE_NORMAL);
    status = XUartPs_SetBaudRate(&UartInst, UART_BAUD_RATE);
    if (status != XST_SUCCESS) {
        return status;
    }

    return XST_SUCCESS;
}

static int receive_frame_body(void)
{
    u16 width;
    u16 height;
    u8 format;
    u32 row_expected;

    if (uart_recv_u16_le(&width, UART_WAIT_MS) != XST_SUCCESS) {
        return -4;
    }
    if (uart_recv_u16_le(&height, UART_WAIT_MS) != XST_SUCCESS) {
        return -4;
    }
    if (uart_recv_byte_timeout(&format, UART_WAIT_MS) != XST_SUCCESS) {
        return -4;
    }

    if ((width != IMG_WIDTH) || (height != IMG_HEIGHT) || (format != RGB888_FORMAT)) {
        return -1;
    }

    for (row_expected = 0U; row_expected < IMG_HEIGHT; row_expected++) {
        u16 row;
        u32 x;

        if (wait_for_line_sync(UART_WAIT_MS) != XST_SUCCESS) {
            return -5;
        }
        if (uart_recv_u16_le(&row, UART_WAIT_MS) != XST_SUCCESS) {
            return -6;
        }

        if (row != row_expected) {
            return -2;
        }

        for (x = 0U; x < IMG_WIDTH; x++) {
            u8 r;
            u8 g;
            u8 b;

            if (uart_recv_byte_timeout(&r, UART_WAIT_MS) != XST_SUCCESS) {
                return -7;
            }
            if (uart_recv_byte_timeout(&g, UART_WAIT_MS) != XST_SUCCESS) {
                return -7;
            }
            if (uart_recv_byte_timeout(&b, UART_WAIT_MS) != XST_SUCCESS) {
                return -7;
            }
            framebuffer_write_pixel(x, row, r, g, b);
        }
    }

    return 0;
}

int main(void)
{
    int status;
    u32 frame_count = 0U;
    u32 wait_count = 0U;

    status = uart_init();
    if (status != XST_SUCCESS) {
        xil_printf("UART init failed: %d\r\n", status);
        return status;
    }

    xil_printf("\r\nPS UART PL Control HDMI display\r\n");
    xil_printf("BRAM base: 0x%x, baud: %d, image: %dx%d\r\n",
               (u32)FRAMEBUFFER_BASEADDR,
               (u32)UART_BAUD_RATE,
               (u32)IMG_WIDTH,
               (u32)IMG_HEIGHT);
    xil_printf("control frame: a5 5a cmd value, cmd 1=mode 2=threshold 3=overlay\r\n");

    fill_test_pattern();
    control_write_defaults();
    control_print_state();

    while (1) {
        status = wait_for_packet_start(UART_WAIT_MS);
        if (status == 1) {
            status = receive_frame_body();
            if (status == 0) {
                frame_count++;
                wait_count = 0U;
                xil_printf("received frame %d\r\n", frame_count);
            } else {
                xil_printf("frame error: %d\r\n", status);
            }
        } else if (status == 2) {
            (void)handle_control_packet();
            wait_count = 0U;
        } else {
            wait_count++;
            if ((wait_count & 0x3U) == 1U) {
                xil_printf("waiting for frame or control header\r\n");
            }
        }
    }
}
