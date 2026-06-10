def calculate_xor_checksum(hex_data):
    # 将十六进制字符串分割成字节列表
    bytes_list = hex_data.split()
    
    # 初始化异或校验值为0
    checksum = 0
    
    # 遍历每个字节并进行异或运算
    for byte_str in bytes_list:
        # 将十六进制字符串转换为整数
        byte_val = int(byte_str, 16)
        # 执行异或运算
        checksum ^= byte_val
    
    # 将结果转换为十六进制，并确保大写两位格式
    return format(checksum, '02X')

# 输入数据
data = "55 AA 0C 01 04 04 00 FF FF FF"

# 计算并输出校验值
result = calculate_xor_checksum(data)
print(f"数据 '{data}' 的异或校验值为: {result}")