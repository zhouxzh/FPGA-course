import serial
import time
import math

# 配置串口参数
PORT = 'COM9'        # Windows系统示例（如：COM3），Linux/macOS示例：'/dev/ttyUSB0'
BAUDRATE = 460800    # 波特率（根据设备要求调整）
TIMEOUT = 1          # 超时时间（秒）

# 创建命令的函数
def create_led_command(addr, red, green, blue):
    red = int(red/3)
    green = int(green/2)
    blue = int(blue)
    header = bytes.fromhex('55 AA 0C 00 04 04')
    addr_byte = addr.to_bytes(1, 'big')
    # 颜色值：每个1字节
    red_byte = red.to_bytes(1, 'big')
    green_byte = green.to_bytes(1, 'big')
    blue_byte = blue.to_bytes(1, 'big')
    tail = bytes.fromhex('00 5A')
    return header + addr_byte + red_byte + green_byte + blue_byte + tail

try:
    # 打开串口
    with serial.Serial(port=PORT, baudrate=BAUDRATE, 
                      bytesize=serial.EIGHTBITS,
                      parity=serial.PARITY_NONE,
                      stopbits=serial.STOPBITS_ONE,
                      timeout=TIMEOUT) as ser:
        
        print(f"已连接串口: {ser.name}")
        
        # 呼吸灯参数
        brightness = 0
        step = 1  # 亮度变化步长
        duration = 0.02  # 每帧持续时间（秒）
        
        while True:
            # 计算当前亮度值（使用正弦函数实现平滑变化）
            # 将亮度范围映射到0-255，使用正弦函数实现平滑呼吸效果
            brightness = int(127 + 127 * math.sin(time.time() * 1.5))
            
            # 为所有64个LED设置相同的亮度
            for addr in range(64):  # 8x8阵列共有64个LED
                # 创建RGB命令 - 白色呼吸灯（所有颜色通道相同）
                tx_data = bytes.fromhex('55 AA 09 00 03 00 00 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
                ser.write(tx_data)
                cmd = create_led_command(addr, brightness, brightness, brightness)
                ser.write(cmd)
                tx_data = bytes.fromhex('55 AA 09 00 03 00 01 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
                ser.write(tx_data)
            
            # 控制刷新率
            time.sleep(duration)

except serial.SerialException as e:
    print(f"串口错误: {e}")
except KeyboardInterrupt:
    print("程序被用户中断")
except Exception as e:
    print(f"发生错误: {e}")