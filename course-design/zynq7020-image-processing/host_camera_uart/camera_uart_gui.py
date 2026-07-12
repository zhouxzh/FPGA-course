#!/usr/bin/env python3
import queue
import threading
import time
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

DEPENDENCY_ERROR: ImportError | None = None
try:
    import cv2
    import numpy as np
    import serial
    from serial.tools import list_ports

    from camera_uart_sender import FrameSource, send_frame_by_line, send_requested_controls
except ImportError as exc:
    DEPENDENCY_ERROR = exc


DEFAULT_WIDTH = 128
DEFAULT_HEIGHT = 72


class CameraUartGui(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Zynq UART Image Sender")
        self.geometry("920x800")
        self.minsize(840, 720)

        self.stop_event = threading.Event()
        self.worker_thread: threading.Thread | None = None
        self.log_queue: queue.Queue[str] = queue.Queue()
        self.control_queue: queue.Queue[tuple[str, int, str]] = queue.Queue()
        self.preview_queue: queue.Queue[tuple[int, int, bytes]] = queue.Queue(maxsize=1)
        self.last_preview_frame: tuple[int, int, bytes] | None = None
        self.preview_image: tk.PhotoImage | None = None
        self.frame_count = 0

        self.port_var = tk.StringVar()
        self.baud_var = tk.StringVar(value="115200")
        self.source_var = tk.StringVar(value="camera")
        self.camera_var = tk.StringVar(value="0")
        self.image_path_var = tk.StringVar()
        self.image_paths: list[str] = []
        self.images_summary_var = tk.StringVar()
        self.video_path_var = tk.StringVar()
        self.fps_var = tk.StringVar(value="0.2")
        self.line_delay_var = tk.StringVar(value="0.0")
        self.width_var = tk.StringVar(value=str(DEFAULT_WIDTH))
        self.height_var = tk.StringVar(value=str(DEFAULT_HEIGHT))
        self.flip_var = tk.BooleanVar(value=False)
        self.preview_var = tk.BooleanVar(value=True)
        self.once_var = tk.BooleanVar(value=False)
        self.loop_var = tk.BooleanVar(value=False)
        self.control_mode_var = tk.StringVar(value="edge")
        self.control_threshold_var = tk.StringVar(value="80")
        self.control_overlay_var = tk.BooleanVar(value=False)
        self.status_var = tk.StringVar(value="Idle")
        self.frames_var = tk.StringVar(value="0")

        self._build_ui()
        self.refresh_ports()
        self.after(100, self._drain_log_queue)
        self.after(100, self._drain_preview_queue)
        self.protocol("WM_DELETE_WINDOW", self.on_close)

    def _build_ui(self) -> None:
        root = ttk.Frame(self, padding=12)
        root.pack(fill=tk.BOTH, expand=True)

        controls = ttk.Frame(root)
        controls.pack(fill=tk.X)
        controls.columnconfigure(1, weight=1)
        controls.columnconfigure(3, weight=1)

        ttk.Label(controls, text="Serial port").grid(row=0, column=0, sticky="w", padx=(0, 8), pady=4)
        self.port_combo = ttk.Combobox(controls, textvariable=self.port_var, width=18)
        self.port_combo.grid(row=0, column=1, sticky="ew", pady=4)
        ttk.Button(controls, text="Refresh", command=self.refresh_ports).grid(
            row=0, column=2, sticky="w", padx=8, pady=4
        )

        ttk.Label(controls, text="Baud").grid(row=0, column=3, sticky="w", padx=(16, 8), pady=4)
        self.baud_combo = ttk.Combobox(
            controls,
            textvariable=self.baud_var,
            width=12,
            values=("115200", "230400", "460800", "921600"),
        )
        self.baud_combo.grid(row=0, column=4, sticky="ew", pady=4)

        source_frame = ttk.LabelFrame(root, text="Input source", padding=10)
        source_frame.pack(fill=tk.X, pady=(12, 0))
        source_frame.columnconfigure(2, weight=1)

        ttk.Radiobutton(
            source_frame,
            text="Camera",
            variable=self.source_var,
            value="camera",
            command=self._sync_source_state,
        ).grid(row=0, column=0, sticky="w")
        ttk.Label(source_frame, text="Index").grid(row=0, column=1, sticky="w", padx=(16, 6))
        self.camera_spin = ttk.Spinbox(source_frame, from_=0, to=8, textvariable=self.camera_var, width=6)
        self.camera_spin.grid(row=0, column=2, sticky="w")

        ttk.Radiobutton(
            source_frame,
            text="Single image",
            variable=self.source_var,
            value="image",
            command=self._sync_source_state,
        ).grid(row=1, column=0, sticky="w", pady=(8, 0))
        self.image_entry = ttk.Entry(source_frame, textvariable=self.image_path_var)
        self.image_entry.grid(row=1, column=1, columnspan=3, sticky="ew", padx=(16, 8), pady=(8, 0))
        self.browse_button = ttk.Button(source_frame, text="Browse", command=self.browse_image)
        self.browse_button.grid(row=1, column=4, sticky="e", pady=(8, 0))

        ttk.Radiobutton(
            source_frame,
            text="Image sequence",
            variable=self.source_var,
            value="images",
            command=self._sync_source_state,
        ).grid(row=2, column=0, sticky="w", pady=(8, 0))
        self.images_entry = ttk.Entry(source_frame, textvariable=self.images_summary_var)
        self.images_entry.grid(row=2, column=1, columnspan=3, sticky="ew", padx=(16, 8), pady=(8, 0))
        self.browse_images_button = ttk.Button(source_frame, text="Browse", command=self.browse_images)
        self.browse_images_button.grid(row=2, column=4, sticky="e", pady=(8, 0))

        ttk.Radiobutton(
            source_frame,
            text="Video file",
            variable=self.source_var,
            value="video",
            command=self._sync_source_state,
        ).grid(row=3, column=0, sticky="w", pady=(8, 0))
        self.video_entry = ttk.Entry(source_frame, textvariable=self.video_path_var)
        self.video_entry.grid(row=3, column=1, columnspan=3, sticky="ew", padx=(16, 8), pady=(8, 0))
        self.browse_video_button = ttk.Button(source_frame, text="Browse", command=self.browse_video)
        self.browse_video_button.grid(row=3, column=4, sticky="e", pady=(8, 0))

        settings = ttk.LabelFrame(root, text="Frame settings", padding=10)
        settings.pack(fill=tk.X, pady=(12, 0))

        ttk.Label(settings, text="Width").grid(row=0, column=0, sticky="w", padx=(0, 6), pady=4)
        ttk.Entry(settings, textvariable=self.width_var, width=8).grid(row=0, column=1, sticky="w", pady=4)
        ttk.Label(settings, text="Height").grid(row=0, column=2, sticky="w", padx=(16, 6), pady=4)
        ttk.Entry(settings, textvariable=self.height_var, width=8).grid(row=0, column=3, sticky="w", pady=4)
        ttk.Label(settings, text="FPS").grid(row=0, column=4, sticky="w", padx=(16, 6), pady=4)
        ttk.Entry(settings, textvariable=self.fps_var, width=8).grid(row=0, column=5, sticky="w", pady=4)
        ttk.Label(settings, text="Line delay").grid(row=0, column=6, sticky="w", padx=(16, 6), pady=4)
        ttk.Entry(settings, textvariable=self.line_delay_var, width=9).grid(row=0, column=7, sticky="w", pady=4)

        ttk.Checkbutton(settings, text="Flip camera", variable=self.flip_var).grid(
            row=1, column=0, columnspan=2, sticky="w", pady=(8, 0)
        )
        ttk.Checkbutton(settings, text="Preview", variable=self.preview_var).grid(
            row=1, column=2, columnspan=2, sticky="w", pady=(8, 0)
        )
        ttk.Checkbutton(settings, text="Send once", variable=self.once_var).grid(
            row=1, column=4, columnspan=2, sticky="w", pady=(8, 0)
        )
        ttk.Checkbutton(settings, text="Loop file input", variable=self.loop_var).grid(
            row=1, column=6, columnspan=2, sticky="w", pady=(8, 0)
        )

        control_frame = ttk.LabelFrame(root, text="Display control for sobel_05", padding=10)
        control_frame.pack(fill=tk.X, pady=(12, 0))

        ttk.Label(control_frame, text="Mode").grid(row=0, column=0, sticky="w", padx=(0, 6), pady=4)
        self.control_mode_combo = ttk.Combobox(
            control_frame,
            textvariable=self.control_mode_var,
            width=12,
            values=("original", "gray", "edge", "overlay"),
            state="readonly",
        )
        self.control_mode_combo.grid(row=0, column=1, sticky="w", pady=4)

        ttk.Label(control_frame, text="Threshold").grid(row=0, column=2, sticky="w", padx=(16, 6), pady=4)
        ttk.Entry(control_frame, textvariable=self.control_threshold_var, width=8).grid(
            row=0, column=3, sticky="w", pady=4
        )

        ttk.Checkbutton(control_frame, text="Overlay", variable=self.control_overlay_var).grid(
            row=0, column=4, sticky="w", padx=(16, 8), pady=4
        )
        ttk.Button(control_frame, text="Send Control", command=self.send_control).grid(
            row=0, column=5, sticky="w", padx=(8, 0), pady=4
        )

        actions = ttk.Frame(root)
        actions.pack(fill=tk.X, pady=(12, 0))
        self.start_button = ttk.Button(actions, text="Start", command=self.start_sender)
        self.start_button.pack(side=tk.LEFT)
        self.stop_button = ttk.Button(actions, text="Stop", command=self.stop_sender, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=(8, 0))

        status = ttk.Frame(actions)
        status.pack(side=tk.RIGHT)
        ttk.Label(status, text="Status:").pack(side=tk.LEFT)
        ttk.Label(status, textvariable=self.status_var, width=16).pack(side=tk.LEFT, padx=(6, 16))
        ttk.Label(status, text="Frames:").pack(side=tk.LEFT)
        ttk.Label(status, textvariable=self.frames_var, width=8).pack(side=tk.LEFT, padx=(6, 0))

        preview_frame = ttk.LabelFrame(root, text="Preview", padding=8)
        preview_frame.pack(fill=tk.BOTH, expand=True, pady=(12, 0))
        preview_frame.rowconfigure(0, weight=1)
        preview_frame.columnconfigure(0, weight=1)

        self.preview_label = ttk.Label(preview_frame, text="No preview frame", anchor=tk.CENTER)
        self.preview_label.grid(row=0, column=0, sticky="nsew")
        self.preview_label.bind("<Configure>", self._redraw_preview)

        log_frame = ttk.LabelFrame(root, text="Log", padding=8)
        log_frame.pack(fill=tk.BOTH, expand=False, pady=(12, 0))
        log_frame.rowconfigure(0, weight=1)
        log_frame.columnconfigure(0, weight=1)

        self.log_text = tk.Text(log_frame, height=8, wrap=tk.WORD, state=tk.DISABLED)
        self.log_text.grid(row=0, column=0, sticky="nsew")
        scroll = ttk.Scrollbar(log_frame, orient=tk.VERTICAL, command=self.log_text.yview)
        scroll.grid(row=0, column=1, sticky="ns")
        self.log_text.configure(yscrollcommand=scroll.set)

        self._sync_source_state()

    def refresh_ports(self) -> None:
        ports = [port.device for port in list_ports.comports()]
        self.port_combo.configure(values=ports)
        if ports and not self.port_var.get():
            self.port_var.set(ports[0])
        self._log(f"found {len(ports)} serial port(s)")

    def browse_image(self) -> None:
        path = filedialog.askopenfilename(
            title="Select image",
            filetypes=(
                ("Image files", "*.png *.jpg *.jpeg *.bmp"),
                ("All files", "*.*"),
            ),
        )
        if path:
            self.image_paths = []
            self.image_path_var.set(path)

    def browse_images(self) -> None:
        paths = filedialog.askopenfilenames(
            title="Select images",
            filetypes=(
                ("Image files", "*.png *.jpg *.jpeg *.bmp"),
                ("All files", "*.*"),
            ),
        )
        if paths:
            self.image_paths = list(paths)
            self.images_summary_var.set(f"{len(self.image_paths)} image files selected")

    def browse_video(self) -> None:
        path = filedialog.askopenfilename(
            title="Select video",
            filetypes=(
                ("Video files", "*.mp4 *.avi *.mov *.mkv *.wmv"),
                ("All files", "*.*"),
            ),
        )
        if path:
            self.video_path_var.set(path)

    def start_sender(self) -> None:
        if self.worker_thread and self.worker_thread.is_alive():
            return

        try:
            config = self._read_config()
        except ValueError as exc:
            messagebox.showerror("Invalid setting", str(exc))
            return

        self.stop_event.clear()
        self._clear_preview_queue()
        self.frame_count = 0
        self.frames_var.set("0")
        self.status_var.set("Running")
        self.start_button.configure(state=tk.DISABLED)
        self.stop_button.configure(state=tk.NORMAL)

        self.worker_thread = threading.Thread(target=self._send_worker, args=(config,), daemon=True)
        self.worker_thread.start()
        self._log("sender started")

    def stop_sender(self) -> None:
        self.stop_event.set()
        self.status_var.set("Stopping")
        self.stop_button.configure(state=tk.DISABLED)
        self._log("stop requested")

    def send_control(self) -> None:
        port = self.port_var.get().strip()
        if not port:
            messagebox.showerror("Invalid setting", "Select a serial port first.")
            return

        try:
            baud = int(self.baud_var.get())
            threshold = int(self.control_threshold_var.get())
            if not 0 <= threshold <= 255:
                raise ValueError("Threshold must be in range 0..255.")
        except ValueError as exc:
            messagebox.showerror("Invalid setting", str(exc))
            return

        mode = self.control_mode_var.get()
        overlay = "on" if self.control_overlay_var.get() else "off"

        if self.worker_thread and self.worker_thread.is_alive():
            self.control_queue.put((mode, threshold, overlay))
            self._log(
                "queued control: "
                f"mode={mode} threshold={threshold} overlay={int(self.control_overlay_var.get())}"
            )
            return

        try:
            with serial.Serial(port, baud, timeout=0, write_timeout=2) as ser:
                time.sleep(0.1)
                send_requested_controls(ser, mode, threshold, overlay)
            self._log(
                "sent control: "
                f"mode={mode} threshold={threshold} overlay={int(self.control_overlay_var.get())}"
            )
        except Exception as exc:
            messagebox.showerror("Control send failed", str(exc))
            self._log(f"control error: {exc}")

    def on_close(self) -> None:
        self.stop_sender()
        self.after(100, self.destroy)

    def _read_config(self) -> dict:
        port = self.port_var.get().strip()
        if not port:
            raise ValueError("Select a serial port first.")

        baud = int(self.baud_var.get())
        width = int(self.width_var.get())
        height = int(self.height_var.get())
        fps = float(self.fps_var.get())
        line_delay = float(self.line_delay_var.get())
        camera_index = int(self.camera_var.get())
        source = self.source_var.get()
        image_path = self.image_path_var.get().strip()
        video_path = self.video_path_var.get().strip()
        control_threshold = int(self.control_threshold_var.get())

        if width <= 0 or height <= 0:
            raise ValueError("Width and height must be positive.")
        if fps <= 0:
            raise ValueError("FPS must be greater than 0.")
        if line_delay < 0:
            raise ValueError("Line delay cannot be negative.")
        if not 0 <= control_threshold <= 255:
            raise ValueError("Threshold must be in range 0..255.")
        if source == "image":
            if not image_path:
                raise ValueError("Select an image file first.")
            if not Path(image_path).is_file():
                raise ValueError(f"Image file does not exist: {image_path}")
        elif source == "images":
            if not self.image_paths:
                raise ValueError("Select one or more image files first.")
            missing = [path for path in self.image_paths if not Path(path).is_file()]
            if missing:
                raise ValueError(f"Image file does not exist: {missing[0]}")
        elif source == "video":
            if not video_path:
                raise ValueError("Select a video file first.")
            if not Path(video_path).is_file():
                raise ValueError(f"Video file does not exist: {video_path}")

        if width != DEFAULT_WIDTH or height != DEFAULT_HEIGHT:
            self._log("warning: current PS receiver normally accepts only 128x72 RGB888")

        return {
            "port": port,
            "baud": baud,
            "source": source,
            "camera": camera_index,
            "image": image_path,
            "images": list(self.image_paths),
            "video": video_path,
            "fps": fps,
            "width": width,
            "height": height,
            "line_delay": line_delay,
            "flip": self.flip_var.get(),
            "preview": self.preview_var.get(),
            "once": self.once_var.get(),
            "loop": self.loop_var.get(),
            "control_mode": self.control_mode_var.get(),
            "control_threshold": control_threshold,
            "control_overlay": "on" if self.control_overlay_var.get() else "off",
        }

    def _send_worker(self, config: dict) -> None:
        source = None
        try:
            source = FrameSource(
                source=config["source"],
                camera=config["camera"],
                image=config["image"],
                images=config["images"],
                video=config["video"],
                loop=config["loop"],
            )
            source.open()

            frame_interval = 1.0 / config["fps"]
            with serial.Serial(config["port"], config["baud"], timeout=0, write_timeout=2) as ser:
                time.sleep(0.2)
                send_requested_controls(
                    ser,
                    config["control_mode"],
                    config["control_threshold"],
                    config["control_overlay"],
                )
                self._log(
                    f"sending {config['width']}x{config['height']} RGB888 from {source.describe()} to "
                    f"{config['port']} at {config['baud']} baud"
                )

                while not self.stop_event.is_set():
                    self._send_queued_controls(ser)
                    start = time.monotonic()
                    ok, frame_bgr = source.read()
                    if not ok or frame_bgr is None:
                        break

                    if config["flip"]:
                        frame_bgr = cv2.flip(frame_bgr, 1)

                    resized_bgr = cv2.resize(
                        frame_bgr,
                        (config["width"], config["height"]),
                        interpolation=cv2.INTER_AREA,
                    )
                    frame_rgb = cv2.cvtColor(resized_bgr, cv2.COLOR_BGR2RGB)
                    send_frame_by_line(ser, frame_rgb, config["line_delay"])

                    self.frame_count += 1
                    self.log_queue.put(f"__frames__:{self.frame_count}")
                    if self.frame_count % 5 == 0:
                        self._log(f"sent {self.frame_count} frames")

                    if config["preview"]:
                        preview_rgb = cv2.cvtColor(resized_bgr, cv2.COLOR_BGR2RGB)
                        self._offer_preview_frame(preview_rgb)

                    if config["once"]:
                        break

                    elapsed = time.monotonic() - start
                    if elapsed < frame_interval:
                        time.sleep(frame_interval - elapsed)
        except Exception as exc:
            self._log(f"error: {exc}")
        finally:
            if source is not None:
                source.close()
            self.log_queue.put("__done__")

    def _send_queued_controls(self, ser) -> None:
        latest: tuple[str, int, str] | None = None
        try:
            while True:
                latest = self.control_queue.get_nowait()
        except queue.Empty:
            pass

        if latest is None:
            return

        mode, threshold, overlay = latest
        send_requested_controls(ser, mode, threshold, overlay)
        self._log(f"sent queued control: mode={mode} threshold={threshold} overlay={overlay}")

    def _offer_preview_frame(self, rgb_image) -> None:
        height, width, _ = rgb_image.shape
        payload = (width, height, rgb_image.tobytes())
        try:
            self.preview_queue.put_nowait(payload)
        except queue.Full:
            try:
                self.preview_queue.get_nowait()
            except queue.Empty:
                pass
            try:
                self.preview_queue.put_nowait(payload)
            except queue.Full:
                pass

    def _clear_preview_queue(self) -> None:
        try:
            while True:
                self.preview_queue.get_nowait()
        except queue.Empty:
            pass

    def _sync_source_state(self) -> None:
        source = self.source_var.get()
        camera_mode = source == "camera"
        image_mode = source == "image"
        images_mode = source == "images"
        video_mode = source == "video"

        self.camera_spin.configure(state=tk.NORMAL if camera_mode else tk.DISABLED)
        self.image_entry.configure(state=tk.NORMAL if image_mode else tk.DISABLED)
        self.browse_button.configure(state=tk.NORMAL if image_mode else tk.DISABLED)
        self.images_entry.configure(state=tk.NORMAL if images_mode else tk.DISABLED)
        self.browse_images_button.configure(state=tk.NORMAL if images_mode else tk.DISABLED)
        self.video_entry.configure(state=tk.NORMAL if video_mode else tk.DISABLED)
        self.browse_video_button.configure(state=tk.NORMAL if video_mode else tk.DISABLED)

        if image_mode:
            self.once_var.set(True)
        elif images_mode or video_mode:
            self.once_var.set(False)

    def _log(self, message: str) -> None:
        timestamp = time.strftime("%H:%M:%S")
        self.log_queue.put(f"[{timestamp}] {message}")

    def _append_log(self, message: str) -> None:
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, message + "\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    def _drain_log_queue(self) -> None:
        try:
            while True:
                message = self.log_queue.get_nowait()
                if message == "__done__":
                    self.status_var.set("Idle")
                    self.start_button.configure(state=tk.NORMAL)
                    self.stop_button.configure(state=tk.DISABLED)
                    self._append_log(f"[{time.strftime('%H:%M:%S')}] sender stopped")
                elif message.startswith("__frames__:"):
                    self.frames_var.set(message.split(":", 1)[1])
                else:
                    self._append_log(message)
        except queue.Empty:
            pass
        self.after(100, self._drain_log_queue)

    def _drain_preview_queue(self) -> None:
        latest = None
        try:
            while True:
                latest = self.preview_queue.get_nowait()
        except queue.Empty:
            pass

        if latest is not None:
            self.last_preview_frame = latest
            self._render_preview_frame(latest)

        self.after(100, self._drain_preview_queue)

    def _redraw_preview(self, _event=None) -> None:
        if self.last_preview_frame is not None:
            self._render_preview_frame(self.last_preview_frame)

    def _render_preview_frame(self, frame: tuple[int, int, bytes]) -> None:
        width, height, rgb_bytes = frame
        available_width = max(1, self.preview_label.winfo_width())
        available_height = max(1, self.preview_label.winfo_height())
        if available_width <= 1 or available_height <= 1:
            available_width, available_height = 640, 360

        scale = min(available_width / width, available_height / height)
        target_width = max(1, int(width * scale))
        target_height = max(1, int(height * scale))

        rgb_image = np.frombuffer(rgb_bytes, dtype=np.uint8).reshape(height, width, 3)
        interpolation = cv2.INTER_NEAREST if scale >= 1.0 else cv2.INTER_AREA
        resized = cv2.resize(rgb_image, (target_width, target_height), interpolation=interpolation)

        header = f"P6 {target_width} {target_height} 255\n".encode("ascii")
        ppm_data = header + resized.tobytes()
        self.preview_image = tk.PhotoImage(data=ppm_data, format="PPM")
        self.preview_label.configure(image=self.preview_image, text="")


def main() -> int:
    if DEPENDENCY_ERROR is not None:
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(
            "Missing Python package",
            "Python dependencies are not ready.\n\n"
            f"{DEPENDENCY_ERROR}\n\n"
            "Run these commands first:\n\n"
            "conda activate fpga\n"
            "pip install -r requirements.txt",
        )
        return 1

    app = CameraUartGui()
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
