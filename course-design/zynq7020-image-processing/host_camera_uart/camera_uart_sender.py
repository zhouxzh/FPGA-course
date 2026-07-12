#!/usr/bin/env python3
import argparse
import sys
import time
from pathlib import Path

import cv2
import numpy as np
import serial


FRAME_SYNC = bytes((0x55, 0xAA))
LINE_SYNC = bytes((0x33, 0xCC))
CONTROL_SYNC = bytes((0xA5, 0x5A))
RGB888_FORMAT = 0x18
CONTROL_MODE = 0x01
CONTROL_THRESHOLD = 0x02
CONTROL_OVERLAY = 0x03

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp"}
VIDEO_EXTENSIONS = {".mp4", ".avi", ".mov", ".mkv", ".wmv"}


class FrameSource:
    def __init__(
        self,
        source: str,
        camera: int = 0,
        image: str | None = None,
        images: list[str] | None = None,
        image_dir: str | None = None,
        video: str | None = None,
        loop: bool = False,
    ) -> None:
        self.source = source
        self.camera = camera
        self.image = image
        self.images = images or []
        self.image_dir = image_dir
        self.video = video
        self.loop = loop
        self.cap = None
        self.static_bgr = None
        self.image_paths: list[Path] = []
        self.image_index = 0

    def open(self) -> None:
        if self.source == "camera":
            self.cap = cv2.VideoCapture(self.camera)
            if not self.cap.isOpened():
                raise RuntimeError(f"failed to open camera {self.camera}")
            return

        if self.source == "image":
            if self.image is None:
                raise RuntimeError("image path is required")
            self.static_bgr = cv2.imread(self.image, cv2.IMREAD_COLOR)
            if self.static_bgr is None:
                raise RuntimeError(f"failed to open image {self.image}")
            return

        if self.source == "images":
            self.image_paths = collect_image_paths(self.images, self.image_dir)
            if not self.image_paths:
                raise RuntimeError("no input image files found")
            return

        if self.source == "video":
            if self.video is None:
                raise RuntimeError("video path is required")
            self.cap = cv2.VideoCapture(self.video)
            if not self.cap.isOpened():
                raise RuntimeError(f"failed to open video {self.video}")
            return

        raise RuntimeError(f"unsupported source: {self.source}")

    def read(self) -> tuple[bool, np.ndarray | None]:
        if self.source == "image":
            return True, self.static_bgr.copy()

        if self.source == "images":
            if self.image_index >= len(self.image_paths):
                if not self.loop:
                    return False, None
                self.image_index = 0

            path = self.image_paths[self.image_index]
            self.image_index += 1
            frame_bgr = cv2.imread(str(path), cv2.IMREAD_COLOR)
            if frame_bgr is None:
                raise RuntimeError(f"failed to open image {path}")
            return True, frame_bgr

        if self.source == "video":
            ok, frame_bgr = self.cap.read()
            if ok:
                return True, frame_bgr
            if not self.loop:
                return False, None
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            ok, frame_bgr = self.cap.read()
            return ok, frame_bgr if ok else None

        ok, frame_bgr = self.cap.read()
        return ok, frame_bgr if ok else None

    def close(self) -> None:
        if self.cap is not None:
            self.cap.release()
            self.cap = None

    def describe(self) -> str:
        if self.source == "camera":
            return f"camera {self.camera}"
        if self.source == "image":
            return f"image {self.image}"
        if self.source == "images":
            return f"{len(self.image_paths)} image files"
        if self.source == "video":
            return f"video {self.video}"
        return self.source


def collect_image_paths(images: list[str] | None = None, image_dir: str | None = None) -> list[Path]:
    paths: list[Path] = []

    for image in images or []:
        path = Path(image)
        if not path.is_file():
            raise RuntimeError(f"image file does not exist: {path}")
        paths.append(path)

    if image_dir:
        directory = Path(image_dir)
        if not directory.is_dir():
            raise RuntimeError(f"image directory does not exist: {directory}")
        for path in sorted(directory.iterdir()):
            if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
                paths.append(path)

    return paths


def resolve_source(args: argparse.Namespace) -> str:
    selected = [
        args.image is not None,
        bool(args.images),
        args.image_dir is not None,
        args.video is not None,
    ]
    if sum(selected) > 1:
        raise ValueError("choose only one of --image, --images, --image-dir, or --video")
    if args.image is not None:
        return "image"
    if args.images or args.image_dir is not None:
        return "images"
    if args.video is not None:
        return "video"
    return "camera"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resize camera/image/video frames to RGB888 and send them to ZYNQ PS UART."
    )
    parser.add_argument("--port", required=True, help="Serial port, for example COM5 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115_200, help="UART baud rate")
    parser.add_argument("--camera", type=int, default=0, help="OpenCV camera index")
    parser.add_argument("--fps", type=float, default=0.2, help="Send frame rate")
    parser.add_argument("--width", type=int, default=128, help="Output image width")
    parser.add_argument("--height", type=int, default=72, help="Output image height")
    parser.add_argument("--image", help="Send one image file instead of reading the camera")
    parser.add_argument("--images", nargs="+", help="Send several image files in the given order")
    parser.add_argument("--image-dir", help="Send all supported images in one directory, sorted by file name")
    parser.add_argument("--video", help="Send frames from a video file such as MP4")
    parser.add_argument("--loop", action="store_true", help="Loop image sequence or video after reaching the end")
    parser.add_argument("--once", action="store_true", help="Send one frame and exit")
    parser.add_argument("--preview", action="store_true", help="Show a local preview window")
    parser.add_argument("--flip", action="store_true", help="Horizontally flip the camera/image/video frame")
    parser.add_argument("--line-delay", type=float, default=0.0, help="Delay after each line, in seconds")
    parser.add_argument(
        "--mode",
        choices=("original", "gray", "edge", "overlay"),
        help="sobel_05 display mode control command",
    )
    parser.add_argument("--threshold", type=int, help="sobel_05 threshold control command, 0..255")
    parser.add_argument(
        "--overlay",
        choices=("off", "on"),
        help="sobel_05 color edge overlay control command",
    )
    parser.add_argument("--control-only", action="store_true", help="Send only sobel_05 control commands and exit")
    return parser.parse_args()


def build_frame_packet(rgb_image: np.ndarray) -> bytes:
    height, width, channels = rgb_image.shape
    if channels != 3:
        raise ValueError("RGB image must have 3 channels")
    if rgb_image.dtype != np.uint8:
        raise ValueError("RGB image must be uint8")

    packet = bytearray()
    packet.extend(FRAME_SYNC)
    packet.extend((width & 0xFF, (width >> 8) & 0xFF))
    packet.extend((height & 0xFF, (height >> 8) & 0xFF))
    packet.append(RGB888_FORMAT)

    contiguous = np.ascontiguousarray(rgb_image)
    for row in range(height):
        packet.extend(LINE_SYNC)
        packet.extend((row & 0xFF, (row >> 8) & 0xFF))
        packet.extend(contiguous[row].tobytes())

    return bytes(packet)


def send_frame_by_line(ser: serial.Serial, rgb_image: np.ndarray, line_delay: float) -> None:
    height, width, _ = rgb_image.shape
    ser.write(FRAME_SYNC)
    ser.write(bytes((width & 0xFF, (width >> 8) & 0xFF)))
    ser.write(bytes((height & 0xFF, (height >> 8) & 0xFF)))
    ser.write(bytes((RGB888_FORMAT,)))

    contiguous = np.ascontiguousarray(rgb_image)
    for row in range(height):
        ser.write(LINE_SYNC)
        ser.write(bytes((row & 0xFF, (row >> 8) & 0xFF)))
        ser.write(contiguous[row].tobytes())
        if line_delay > 0.0:
            time.sleep(line_delay)


def send_control_command(ser: serial.Serial, command: int, value: int) -> None:
    if not 0 <= value <= 255:
        raise ValueError("control command value must be in range 0..255")
    ser.write(CONTROL_SYNC)
    ser.write(bytes((command & 0xFF, value & 0xFF)))


def send_requested_controls(
    ser: serial.Serial,
    mode: str | None = None,
    threshold: int | None = None,
    overlay: str | None = None,
) -> None:
    mode_values = {
        "original": 0,
        "gray": 1,
        "edge": 2,
        "overlay": 3,
    }
    if mode is not None:
        send_control_command(ser, CONTROL_MODE, mode_values[mode])
    if threshold is not None:
        if not 0 <= threshold <= 255:
            raise ValueError("--threshold must be in range 0..255")
        send_control_command(ser, CONTROL_THRESHOLD, threshold)
    if overlay is not None:
        send_control_command(ser, CONTROL_OVERLAY, 1 if overlay == "on" else 0)


def main() -> int:
    args = parse_args()
    source_name = resolve_source(args)

    if args.width != 128 or args.height != 72:
        print("warning: PS receiver currently accepts only 128x72 RGB888", file=sys.stderr)
    if args.fps <= 0:
        raise ValueError("--fps must be greater than 0")
    if args.line_delay < 0:
        raise ValueError("--line-delay cannot be negative")
    if args.control_only and not any(
        value is not None for value in (args.mode, args.threshold, args.overlay)
    ):
        raise ValueError("--control-only needs at least one of --mode, --threshold, or --overlay")

    source = FrameSource(
        source=source_name,
        camera=args.camera,
        image=args.image,
        images=args.images,
        image_dir=args.image_dir,
        video=args.video,
        loop=args.loop,
    )

    if not args.control_only:
        source.open()

    frame_interval = 1.0 / args.fps
    frame_count = 0

    try:
        with serial.Serial(args.port, args.baud, timeout=0, write_timeout=2) as ser:
            time.sleep(0.2)
            send_requested_controls(ser, args.mode, args.threshold, args.overlay)
            if any(value is not None for value in (args.mode, args.threshold, args.overlay)):
                print("sent sobel_05 control command(s)")
            if args.control_only:
                return 0

            print(
                f"sending {args.width}x{args.height} RGB888 from {source.describe()} "
                f"to {args.port} at {args.baud} baud"
            )

            while True:
                start = time.monotonic()
                ok, frame_bgr = source.read()
                if not ok or frame_bgr is None:
                    break

                if args.flip:
                    frame_bgr = cv2.flip(frame_bgr, 1)

                resized_bgr = cv2.resize(
                    frame_bgr, (args.width, args.height), interpolation=cv2.INTER_AREA
                )
                frame_rgb = cv2.cvtColor(resized_bgr, cv2.COLOR_BGR2RGB)
                send_frame_by_line(ser, frame_rgb, args.line_delay)
                frame_count += 1

                if args.preview:
                    preview = cv2.resize(resized_bgr, (args.width * 5, args.height * 5))
                    cv2.imshow("camera uart sender", preview)
                    if cv2.waitKey(1) & 0xFF == 27:
                        break

                if frame_count % 10 == 0:
                    print(f"sent {frame_count} frames")

                if args.once:
                    break

                elapsed = time.monotonic() - start
                if elapsed < frame_interval:
                    time.sleep(frame_interval - elapsed)
    except KeyboardInterrupt:
        print("\nstopped")
    finally:
        source.close()
        if args.preview:
            cv2.destroyAllWindows()

    print(f"sent {frame_count} frame(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
