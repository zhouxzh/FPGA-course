import serial
import time

# 配置串口参数 - 根据实际情况修改
PORT = 'COM9'       # Windows系统示例（如：COM3），Linux/macOS示例：'/dev/ttyUSB0'
BAUDRATE = 460800     # 波特率（根据设备要求调整）
TIMEOUT = 1         # 超时时间（秒）

# 要发送的十六进制数据（字节数组）
# tx_data = bytes.fromhex('55 AA 08 00 03 00 00 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
# tx_data = bytes.fromhex('55 AA 0C 01 04 04 00 FF FF FF 0D 5A')
# tx_data = bytes.fromhex('55 AA 08 00 03 00 01 00 5A')  # 主模式下 N SS 引脚高低电平控制控制

# tx_data = bytes.fromhex('55 AA 0B 00 02 01 00 00 07 00 5A')
# tx_data = bytes.fromhex('55 AA 08 00 02 01 00 5A') #查询spi 主 从 模式 、模式 0 0 11 、分频值
# tx_data = bytes.fromhex('55 AA 08 00 03 01 00 5A')  # 主模式下 N SS 引脚高低电平控制查询
# tx_data = bytes.fromhex('55 AA 08 00 03 00 00 00 5A')  # 主模式下 N SS 引脚高低电平控制控制

try:
    # 打开串口
    with serial.Serial(port=PORT, baudrate=BAUDRATE, 
                      bytesize=serial.EIGHTBITS,
                      parity=serial.PARITY_NONE,
                      stopbits=serial.STOPBITS_ONE,
                      timeout=TIMEOUT) as ser:
        
        print(f"已连接串口: {ser.name}")
        
        # 发送数据
        tx_data = bytes.fromhex('55 AA 09 00 03 00 00 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
        ser.write(tx_data)
        header = bytes.fromhex('55 AA 0C 00 04 04')
        addr = bytes.fromhex('01')
        red = bytes.fromhex('FF')
        green = bytes.fromhex('FF')
        blue = bytes.fromhex('FF')
        tail = bytes.fromhex('00 5A')
        tx_data = header + addr + red + green + blue + tail
        ser.write(tx_data)
        tx_data = bytes.fromhex('55 AA 09 00 03 00 01 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
        ser.write(tx_data)
        # print(f"已发送: {tx_data.hex(' ').upper()}")

except serial.SerialException as e:
    print(f"串口错误: {e}")
except KeyboardInterrupt:
    print("程序被用户中断")
except Exception as e:
    print(f"发生错误: {e}")