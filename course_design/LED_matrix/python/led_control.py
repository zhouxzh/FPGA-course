import serial
import time
import numpy as np
import tkinter as tk
from tkinter import ttk, messagebox
from threading import Thread, Event

class LEDControlApp:
    def __init__(self, root):
        self.root = root
        self.root.title("8x8 LED阵列控制程序")
        self.root.geometry("900x700")
        self.root.resizable(True, True)
        
        # 初始化变量
        self.serial_port = None
        self.running = Event()
        self.animation_speed = 0.1  # 默认动画速度（秒）
        
        # 创建UI
        self.create_widgets()
        
        # 自动查找可用串口
        self.find_serial_ports()
        
        # 创建LED矩阵显示
        self.create_led_matrix()
    
    def create_widgets(self):
        # 串口控制面板
        port_frame = ttk.LabelFrame(self.root, text="串口设置")
        port_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(port_frame, text="选择串口:").grid(row=0, column=0, padx=5, pady=5)
        self.port_combo = ttk.Combobox(port_frame, width=15)
        self.port_combo.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(port_frame, text="波特率:").grid(row=0, column=2, padx=5, pady=5)
        self.baud_combo = ttk.Combobox(port_frame, width=10, values=["9600", "19200", "38400", "57600", "115200", "460800"])
        self.baud_combo.set("460800")
        self.baud_combo.grid(row=0, column=3, padx=5, pady=5)
        
        self.connect_btn = ttk.Button(port_frame, text="连接", command=self.toggle_connection)
        self.connect_btn.grid(row=0, column=4, padx=5, pady=5)
        
        # 控制面板
        control_frame = ttk.LabelFrame(self.root, text="LED控制")
        control_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(control_frame, text="动画速度 (秒):").grid(row=0, column=0, padx=5, pady=5)
        self.speed_scale = ttk.Scale(control_frame, from_=0.01, to=1.0, length=200, 
                                    command=lambda v: setattr(self, 'animation_speed', float(v)))
        self.speed_scale.set(0.1)
        self.speed_scale.grid(row=0, column=1, padx=5, pady=5)
        
        self.speed_label = ttk.Label(control_frame, text=f"当前速度: {self.animation_speed:.2f}s")
        self.speed_label.grid(row=0, column=2, padx=5, pady=5)
        
        ttk.Button(control_frame, text="逐一点亮", command=self.start_sequential).grid(row=0, column=3, padx=5, pady=5)
        ttk.Button(control_frame, text="全部点亮", command=self.all_on).grid(row=0, column=4, padx=5, pady=5)
        ttk.Button(control_frame, text="全部关闭", command=self.all_off).grid(row=0, column=5, padx=5, pady=5)
        
        # 颜色控制
        color_frame = ttk.LabelFrame(self.root, text="LED颜色控制")
        color_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(color_frame, text="红色 (R):").grid(row=0, column=0, padx=5, pady=5)
        self.r_slider = ttk.Scale(color_frame, from_=0, to=255, length=200, 
                                 command=lambda v: self.update_color_preview())
        self.r_slider.set(255)
        self.r_slider.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(color_frame, text="绿色 (G):").grid(row=1, column=0, padx=5, pady=5)
        self.g_slider = ttk.Scale(color_frame, from_=0, to=255, length=200, 
                                 command=lambda v: self.update_color_preview())
        self.g_slider.set(255)
        self.g_slider.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(color_frame, text="蓝色 (B):").grid(row=2, column=0, padx=5, pady=5)
        self.b_slider = ttk.Scale(color_frame, from_=0, to=255, length=200, 
                                 command=lambda v: self.update_color_preview())
        self.b_slider.set(255)
        self.b_slider.grid(row=2, column=1, padx=5, pady=5)
        
        self.color_preview = tk.Canvas(color_frame, width=50, height=50, bg="#FFFFFF")
        self.color_preview.grid(row=0, column=2, rowspan=3, padx=10, pady=5)
        
        # 状态栏
        self.status_var = tk.StringVar(value="就绪")
        status_bar = ttk.Label(self.root, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)
    
    def create_led_matrix(self):
        # 创建LED矩阵显示
        matrix_frame = ttk.LabelFrame(self.root, text="8x8 LED阵列")
        matrix_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.led_canvas = tk.Canvas(matrix_frame, width=600, height=600, bg="#222222")
        self.led_canvas.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # 创建64个LED的表示
        self.leds = []
        led_size = 60
        spacing = 70
        start_x = 30
        start_y = 30
        
        for i in range(8):
            for j in range(8):
                x1 = start_x + j * spacing
                y1 = start_y + i * spacing
                x2 = x1 + led_size
                y2 = y1 + led_size
                
                led_id = self.led_canvas.create_oval(x1, y1, x2, y2, fill="#333333", outline="#555555", width=2)
                self.leds.append({
                    'id': led_id,
                    'state': 0,
                    'color': (0, 0, 0)
                })
                
                # 添加LED编号标签
                self.led_canvas.create_text(x1 + led_size/2, y1 + led_size/2, 
                                           text=str(i*8 + j), fill="white", font=("Arial", 10))
    
    def find_serial_ports(self):
        """查找可用的串口"""
        ports = []
        for i in range(1, 21):
            port_name = f"COM{i}"  # Windows
            ports.append(port_name)
            
        # 对于Linux/Mac，可以添加类似 '/dev/ttyUSB0' 等
        self.port_combo['values'] = ports
        if ports:
            self.port_combo.current(0)
    
    def toggle_connection(self):
        """连接或断开串口"""
        if self.serial_port and self.serial_port.is_open:
            self.disconnect_serial()
            self.connect_btn.config(text="连接")
            self.status_var.set("已断开连接")
        else:
            self.connect_serial()
    
    def connect_serial(self):
        """连接串口"""
        port = self.port_combo.get()
        baud = int(self.baud_combo.get())
        
        if not port:
            messagebox.showerror("错误", "请选择串口")
            return
        
        try:
            self.serial_port = serial.Serial(
                port=port,
                baudrate=baud,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=1
            )
            self.connect_btn.config(text="断开连接")
            self.status_var.set(f"已连接到 {port} @ {baud} bps")
        except Exception as e:
            messagebox.showerror("连接错误", f"无法连接到串口: {str(e)}")
    
    def disconnect_serial(self):
        """断开串口连接"""
        if self.serial_port and self.serial_port.is_open:
            self.running.clear()  # 停止任何正在运行的动画
            try:
                self.serial_port.close()
            except:
                pass
            self.serial_port = None
    
    def send_led_data(self, led_address, r, g, b):
        """
        发送单个LED数据包（4个字节）
        格式: [地址(8位) | R(8位) | G(8位) | B(8位)]
        """
        if self.serial_port and self.serial_port.is_open:
            try:
                # 构造数据包
                packet = bytes([
                    led_address & 0xFF,  # 地址字节 (0-63)
                    int(r*0.5) & 0xFF,       # 红色分量
                    int(g*0.75) & 0xFF,       # 绿色分量
                    int(b) & 0xFF        # 蓝色分量
                ])
                
                # 发送数据
                # self.serial_port.write(packet)
                tx_data = bytes.fromhex('55 AA 09 00 03 00 00 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
                self.serial_port.write(tx_data)
                header = bytes.fromhex('55 AA 0C 00 04 04')
                tail = bytes.fromhex('00 5A')
                tx_data = header + packet + tail
                self.serial_port.write(tx_data)
                tx_data = bytes.fromhex('55 AA 09 00 03 00 01 00 5A')  # 主模式下 N SS 引脚高低电平控制控制
                self.serial_port.write(tx_data)
                
                # 更新UI上的LED状态
                self.update_led_ui(led_address, r, g, b)
                
            except Exception as e:
                self.status_var.set(f"发送错误: {str(e)}")
    
    def update_led_ui(self, address, r, g, b):
        """更新UI上的LED显示"""
        if 0 <= address < 64:
            # 将RGB值转换为十六进制颜色代码
            color_hex = f"#{r:02x}{g:02x}{b:02x}"
            led_info = self.leds[address]
            
            # 更新画布上的LED颜色
            self.led_canvas.itemconfig(led_info['id'], fill=color_hex)
            
            # 更新状态
            led_info['state'] = 1 if (r > 0 or g > 0 or b > 0) else 0
            led_info['color'] = (r, g, b)
    
    def update_color_preview(self):
        """更新颜色预览框"""
        r = int(self.r_slider.get())
        g = int(self.g_slider.get())
        b = int(self.b_slider.get())
        color_hex = f"#{r:02x}{g:02x}{b:02x}"
        self.color_preview.config(bg=color_hex)
    
    def get_current_color(self):
        """获取当前选择的颜色"""
        r = int(self.r_slider.get())
        g = int(self.g_slider.get())
        b = int(self.b_slider.get())
        return r, g, b
    
    def start_sequential(self):
        """开始逐一点亮LED"""
        if not self.serial_port or not self.serial_port.is_open:
            messagebox.showerror("错误", "请先连接串口")
            return
        
        if self.running.is_set():
            self.running.clear()
            return
        
        # 使用线程运行动画
        self.running.set()
        Thread(target=self.animate_sequential, daemon=True).start()
    
    def animate_sequential(self):
        """动画线程：逐一点亮LED"""
        r, g, b = self.get_current_color()
        
        try:
            # 先关闭所有LED
            self.all_off()
            
            # 逐一点亮每个LED
            for led in range(64):
                if not self.running.is_set():
                    break
                
                # 发送LED控制命令
                self.send_led_data(led, r, g, b)
                
                # 更新状态栏
                self.status_var.set(f"点亮LED #{led}")
                
                # 等待
                time.sleep(self.animation_speed)
            
            # 如果动画完成，重新设置状态
            if self.running.is_set():
                self.status_var.set("LED点亮动画完成")
                self.running.clear()
        
        except Exception as e:
            self.status_var.set(f"动画错误: {str(e)}")
            self.running.clear()
    
    def all_on(self):
        """点亮所有LED"""
        r, g, b = self.get_current_color()
        for led in range(64):
            self.send_led_data(led, r, g, b)
        self.status_var.set("所有LED已点亮")
    
    def all_off(self):
        """关闭所有LED"""
        for led in range(64):
            self.send_led_data(led, 0, 0, 0)
        self.status_var.set("所有LED已关闭")
    
    def on_closing(self):
        """关闭窗口时清理资源"""
        self.running.clear()  # 停止动画
        self.disconnect_serial()  # 断开串口
        self.root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = LEDControlApp(root)
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    root.mainloop()