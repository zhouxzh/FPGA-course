import serial
import time
import numpy as np
import random
import pygame
from pygame.locals import *
import math
import sys

# 配置串口参数
PORT = 'COM9'        # Windows系统示例（如：COM3），Linux/macOS示例：'/dev/ttyUSB0'
BAUDRATE = 460800    # 波特率（根据设备要求调整）
TIMEOUT = 1          # 超时时间（秒）

# 初始化常量
GRID_SIZE = 8
CELL_SIZE = 80
WINDOW_SIZE = GRID_SIZE * CELL_SIZE
FPS = 10  # 控制游戏速度

# 颜色定义 (RGB)
BACKGROUND = (15, 15, 30)
GRID_COLOR = (30, 30, 60)
ALIVE_COLORS = [
    (0, 255, 100),    # 新生细胞 - 亮绿色
    (50, 200, 150),   # 成熟细胞
    (100, 180, 255),  # 稳定细胞 - 淡蓝色
]
DEAD_COLOR = (10, 10, 20)

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

def send_grid_to_leds(ser, grid):
    """将网格状态发送到LED阵列"""
    for x in range(GRID_SIZE):
        for y in range(GRID_SIZE):
            addr = x * GRID_SIZE + y  # 计算LED地址（行优先）
            
            if grid[x][y] > 0:  # 活细胞
                # 活细胞根据年龄选择颜色
                color_idx = min(grid[x][y] - 1, len(ALIVE_COLORS) - 1)
                r, g, b = ALIVE_COLORS[color_idx]
            else:  # 死细胞
                r, g, b = 0, 0, 0
                
            # 发送控制命令
            tx_data = bytes.fromhex('55 AA 09 00 03 00 00 00 5A')  # 片选低
            ser.write(tx_data)
            
            # 创建并发送LED命令
            cmd = create_led_command(addr, r, g, b)
            ser.write(cmd)
            
            tx_data = bytes.fromhex('55 AA 09 00 03 00 01 00 5A')  # 片选高
            ser.write(tx_data)

class GameOfLife:
    def __init__(self, grid_size):
        self.grid_size = grid_size
        self.grid = np.zeros((grid_size, grid_size), dtype=int)
        self.generation = 0
        self.initialize_grid()
        
    def initialize_grid(self, pattern=None):
        """初始化网格，可以指定模式或随机"""
        self.grid = np.zeros((self.grid_size, self.grid_size), dtype=int)
        self.generation = 0
        
        if pattern == "random":
            # 随机模式
            self.grid = np.random.choice([0, 1], size=(self.grid_size, self.grid_size))
        elif pattern == "glider":
            # 滑翔机模式
            self.grid[1][2] = 1
            self.grid[2][3] = 1
            self.grid[3][1] = 1
            self.grid[3][2] = 1
            self.grid[3][3] = 1
        elif pattern == "blinker":
            # 闪烁模式
            self.grid[3][3] = 1
            self.grid[3][4] = 1
            self.grid[3][5] = 1
        elif pattern == "pulsar":
            # 脉冲星模式 (简化版)
            coords = [(1,4), (1,5), (1,6), 
                      (2,4), (2,6),
                      (4,1), (4,2), (4,3), (4,5), (4,6), (4,7),
                      (5,1), (5,3), (5,5), (5,7),
                      (6,1), (6,2), (6,3), (6,5), (6,6), (6,7)]
            for x, y in coords:
                self.grid[x][y] = 1
        else:
            # 默认随机模式
            self.grid = np.random.choice([0, 1], size=(self.grid_size, self.grid_size))
    
    def count_neighbors(self, x, y):
        """计算给定位置周围的活细胞数量（使用环形边界）"""
        count = 0
        for i in range(-1, 2):
            for j in range(-1, 2):
                if i == 0 and j == 0:
                    continue
                # 使用模运算实现环形边界
                xi = (x + i) % self.grid_size
                yj = (y + j) % self.grid_size
                count += self.grid[xi][yj]
        return count
    
    def update(self):
        """更新到下一代"""
        new_grid = self.grid.copy()
        for x in range(self.grid_size):
            for y in range(self.grid_size):
                neighbors = self.count_neighbors(x, y)
                
                # 应用康威生命游戏规则
                if self.grid[x][y] == 1:  # 活细胞
                    if neighbors < 2 or neighbors > 3:
                        new_grid[x][y] = 0  # 死亡
                    else:
                        # 活细胞根据年龄显示不同颜色
                        new_grid[x][y] = min(self.grid[x][y] + 1, len(ALIVE_COLORS))
                else:  # 死细胞
                    if neighbors == 3:
                        new_grid[x][y] = 1  # 新生
        
        self.grid = new_grid
        self.generation += 1
        
        # 如果所有细胞都死亡，重新初始化
        if np.sum(self.grid) == 0:
            self.initialize_grid("random")

def draw_grid(screen, game):
    """绘制游戏网格"""
    for x in range(GRID_SIZE):
        for y in range(GRID_SIZE):
            rect = pygame.Rect(y * CELL_SIZE, x * CELL_SIZE, CELL_SIZE, CELL_SIZE)
            
            # 绘制细胞
            if game.grid[x][y] > 0:
                # 活细胞根据年龄选择颜色
                color_idx = min(game.grid[x][y] - 1, len(ALIVE_COLORS) - 1)
                color = ALIVE_COLORS[color_idx]
                pygame.draw.rect(screen, color, rect)
                
                # 添加发光效果
                glow_rect = rect.inflate(-10, -10)
                pygame.draw.rect(screen, (min(color[0]+100, 255), min(color[1]+100, 255), min(color[2]+100, 255)), glow_rect)
            else:
                pygame.draw.rect(screen, DEAD_COLOR, rect)
            
            # 绘制网格线
            pygame.draw.rect(screen, GRID_COLOR, rect, 1)
    
    # 添加LED点阵效果
    for x in range(GRID_SIZE):
        for y in range(GRID_SIZE):
            center = (y * CELL_SIZE + CELL_SIZE // 2, x * CELL_SIZE + CELL_SIZE // 2)
            pygame.draw.circle(screen, (30, 30, 60), center, 2)

def draw_info(screen, game):
    """绘制游戏信息"""
    font = pygame.font.SysFont(None, 24)
    
    # 显示代数
    gen_text = font.render(f"Generation: {game.generation}", True, (200, 200, 255))
    screen.blit(gen_text, (10, 10))
    
    # 显示细胞数量
    cells = np.sum(game.grid)
    cells_text = font.render(f"Cells: {cells}", True, (200, 200, 255))
    screen.blit(cells_text, (WINDOW_SIZE - 120, 10))
    
    # 显示控制说明
    controls = [
        "Controls:",
        "R - Random pattern",
        "G - Glider pattern",
        "B - Blinker pattern",
        "P - Pulsar pattern",
        "Space - Pause/Resume",
        "C - Clear grid",
        "Click - Toggle cells"
    ]
    
    for i, text in enumerate(controls):
        ctrl_text = font.render(text, True, (180, 180, 220))
        screen.blit(ctrl_text, (10, WINDOW_SIZE - 150 + i * 25))

def main():
    # 初始化Pygame
    pygame.init()
    screen = pygame.display.set_mode((WINDOW_SIZE, WINDOW_SIZE))
    pygame.display.set_caption("康威生命游戏 - 8x8 LED阵列模拟")
    clock = pygame.time.Clock()
    
    # 创建游戏实例
    game = GameOfLife(GRID_SIZE)
    paused = False
    
    # 尝试打开串口
    ser = None
    try:
        ser = serial.Serial(port=PORT, baudrate=BAUDRATE, 
                          bytesize=serial.EIGHTBITS,
                          parity=serial.PARITY_NONE,
                          stopbits=serial.STOPBITS_ONE,
                          timeout=TIMEOUT)
        print(f"已连接串口: {ser.name}")
    except serial.SerialException as e:
        print(f"无法打开串口: {e}")
        print("将在模拟模式下运行，不连接实际硬件")
    
    # 主游戏循环
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == QUIT:
                running = False
            
            elif event.type == KEYDOWN:
                if event.key == K_SPACE:
                    paused = not paused
                elif event.key == K_r:
                    game.initialize_grid("random")
                    if ser: send_grid_to_leds(ser, game.grid)
                elif event.key == K_g:
                    game.initialize_grid("glider")
                    if ser: send_grid_to_leds(ser, game.grid)
                elif event.key == K_b:
                    game.initialize_grid("blinker")
                    if ser: send_grid_to_leds(ser, game.grid)
                elif event.key == K_p:
                    game.initialize_grid("pulsar")
                    if ser: send_grid_to_leds(ser, game.grid)
                elif event.key == K_c:
                    game.initialize_grid()
                    if ser: send_grid_to_leds(ser, game.grid)
            
            elif event.type == MOUSEBUTTONDOWN and paused:
                # 在暂停时允许手动切换细胞状态
                x, y = pygame.mouse.get_pos()
                grid_x = y // CELL_SIZE
                grid_y = x // CELL_SIZE
                
                if 0 <= grid_x < GRID_SIZE and 0 <= grid_y < GRID_SIZE:
                    game.grid[grid_x][grid_y] = 1 if game.grid[grid_x][grid_y] == 0 else 0
                    if ser: send_grid_to_leds(ser, game.grid)
        
        # 更新游戏状态
        if not paused:
            game.update()
            # 将更新后的网格发送到LED
            if ser: send_grid_to_leds(ser, game.grid)
        
        # 绘制
        screen.fill(BACKGROUND)
        draw_grid(screen, game)
        draw_info(screen, game)
        
        # 显示暂停状态
        if paused:
            font = pygame.font.SysFont(None, 48)
            pause_text = font.render("PAUSED", True, (255, 100, 100))
            screen.blit(pause_text, (WINDOW_SIZE // 2 - 70, WINDOW_SIZE // 2 - 24))
        
        pygame.display.flip()
        clock.tick(FPS)
    
    # 关闭串口
    if ser:
        ser.close()
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()