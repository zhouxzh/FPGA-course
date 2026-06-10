#!/usr/bin/env python3
import argparse
import sys
import time

import cv2
import numpy as np
import serial


FRAME_SYNC = bytes((0x55, 0xAA))
LINE_SYNC = bytes((0x33, 0xCC))
RGB888_FORMAT = 0x18


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture a camera frame, resize it to 128x72 RGB888, and send it to ZYNQ PS UART."
    )
    parser.add_argument("--port", required=True, help="Serial port, for example COM5 or /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115_200, help="UART baud rate")
    parser.add_argument("--camera", type=int, default=0, help="OpenCV camera index")
    parser.add_argument("--fps", type=float, default=0.2, help="Send frame rate")
    parser.add_argument("--width", type=int, default=128, help="Output image width")
    parser.add_argument("--height", type=int, default=72, help="Output image height")
    parser.add_argument("--image", help="Send an image file instead of reading the camera")
    parser.add_argument("--once", action="store_true", help="Send one frame and exit")
    parser.add_argument("--preview", action="store_true", help="Show a local preview window")
    parser.add_argument("--flip", action="store_true", help="Horizontally flip the camera image")
    parser.add_argument("--line-delay", type=float, default=0.0, help="Delay after each line, in seconds")
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


def main() -> int:
    args = parse_args()
    if args.width != 128 or args.height != 72:
        print("warning: PS receiver currently accepts only 128x72 RGB888", file=sys.stderr)
    if args.fps <= 0:
        raise ValueError("--fps must be greater than 0")

    cap = None
    static_bgr = None
    if args.image:
        static_bgr = cv2.imread(args.image, cv2.IMREAD_COLOR)
        if static_bgr is None:
            print(f"failed to open image {args.image}", file=sys.stderr)
            return 1
    else:
        cap = cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            print(f"failed to open camera {args.camera}", file=sys.stderr)
            return 1

    frame_interval = 1.0 / args.fps
    frame_count = 0

    with serial.Serial(args.port, args.baud, timeout=0, write_timeout=2) as ser:
        time.sleep(0.2)
        print(f"sending {args.width}x{args.height} RGB888 to {args.port} at {args.baud} baud")

        try:
            while True:
                start = time.monotonic()
                if static_bgr is not None:
                    frame_bgr = static_bgr.copy()
                else:
                    ok, frame_bgr = cap.read()
                    if not ok:
                        print("failed to read camera frame", file=sys.stderr)
                        return 1

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
            if cap is not None:
                cap.release()
            if args.preview:
                cv2.destroyAllWindows()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
