#!/usr/bin/env python3
"""
Blue-Water Rover: RealSense D455 Depth-Based Obstacle Detection
Interfaces with Intel RealSense D455 depth cameras to extract proximity data
and calculate dynamic steering offsets for COLREGs obstacle avoidance.
"""

import threading
import time
import logging
import random

logger = logging.getLogger("Perception")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

class RealSenseDetector(threading.Thread):
    def __init__(self, width=640, height=480, fps=15, min_avoid_distance=8.0):
        super().__init__()
        self.width = width
        self.height = height
        self.fps = fps
        self.min_avoid_distance = min_avoid_distance
        
        self.running = False
        
        # Thread-safe detection outputs
        self._lock = threading.Lock()
        self._obstacle_left_dist = 20.0   # meters
        self._obstacle_center_dist = 20.0
        self._obstacle_right_dist = 20.0
        self._steering_offset = 0.0       # -1.0 (hard left) to +1.0 (hard right)
        
        # Check for pyrealsense2 library
        self.rs = None
        self.pipeline = None
        try:
            import pyrealsense2 as rs
            self.rs = rs
            logger.info("Successfully imported pyrealsense2 library.")
        except ImportError:
            logger.warning("pyrealsense2 library not found! Running in Mock Perception Mode.")

    def run(self):
        self.running = True
        
        if self.rs:
            # Initialize physical camera
            try:
                self.pipeline = self.rs.pipeline()
                config = self.rs.config()
                config.enable_stream(self.rs.stream.depth, self.width, self.height, self.rs.format.z16, self.fps)
                self.pipeline.start(config)
                logger.info("RealSense D455 camera pipeline started successfully.")
                self._run_hardware_loop()
            except Exception as e:
                logger.error(f"Failed to start RealSense camera: {e}. Switching to Mock Mode.")
                self.pipeline = None
                self._run_mock_loop()
        else:
            self._run_mock_loop()

    def stop(self):
        self.running = False

    def _run_hardware_loop(self):
        """Processes live depth frames from the D455 camera."""
        while self.running:
            try:
                frames = self.pipeline.wait_for_frames(timeout_ms=1000)
                depth_frame = frames.get_depth_frame()
                if not depth_frame:
                    continue

                # Divide depth image width into Left, Center, and Right sectors
                # Width: 640. Left: [0, 213], Center: [214, 426], Right: [427, 639]
                col_split = self.width // 3
                
                left_min = 20.0
                center_min = 20.0
                right_min = 20.0

                # Probe points in the vertical center band of the frame to avoid water surface reflections
                # and sky noise. We scan lines from 180 to 300 at steps of 10.
                for y in range(self.height // 3, (2 * self.height) // 3, 15):
                    for x in range(0, self.width, 10):
                        dist = depth_frame.get_distance(x, y)
                        if dist <= 0.05 or dist > 20.0:
                            # 0.0 represents invalid readings or out of range
                            continue
                        
                        if x < col_split:
                            left_min = min(left_min, dist)
                        elif x < 2 * col_split:
                            center_min = min(center_min, dist)
                        else:
                            right_min = min(right_min, dist)

                self._process_distances(left_min, center_min, right_min)

            except Exception as e:
                logger.error(f"Error reading RealSense frame: {e}")
                time.sleep(0.1)

        # Cleanup
        if self.pipeline:
            try:
                self.pipeline.stop()
                logger.info("Stopped RealSense pipeline.")
            except Exception as e:
                logger.error(f"Error stopping RealSense pipeline: {e}")

    def _run_mock_loop(self):
        """Generates mock obstacle signals for testing on non-hardware platforms."""
        logger.info("Starting mock perception generator loop...")
        
        # Simulate moving towards a mock buoy
        mock_obstacle_seq = 0
        left_dist = 20.0
        center_dist = 20.0
        right_dist = 20.0

        while self.running:
            mock_obstacle_seq += 1
            
            # Periodically generate an obstacle in front (every 40 seconds)
            cycle = mock_obstacle_seq % 200
            if cycle < 50:
                # Obstacle approaching center
                center_dist = max(1.5, 20.0 - (cycle * 0.45))
                left_dist = 20.0
                right_dist = 20.0
            elif 50 <= cycle < 90:
                # Clear obstacle
                center_dist = 20.0
                left_dist = 20.0
                right_dist = 20.0
            elif 90 <= cycle < 140:
                # Obstacle approaching left
                left_dist = max(2.0, 20.0 - ((cycle - 90) * 0.45))
                center_dist = 20.0
                right_dist = 20.0
            else:
                left_dist = 20.0
                center_dist = 20.0
                right_dist = 20.0

            self._process_distances(left_dist, center_dist, right_dist)
            time.sleep(0.2)

    def _process_distances(self, left, center, right):
        """Calculates collision avoidance steering offsets based on closest points."""
        offset = 0.0
        
        # Collision avoidance logic
        # 1. Center Obstacle: Swerve toward the side with more clearance
        if center < self.min_avoid_distance:
            if left > right:
                # Left is clearer: steer left (negative offset)
                offset = -0.8 * (1.0 - (center / self.min_avoid_distance))
            else:
                # Right is clearer: steer right (positive offset)
                offset = 0.8 * (1.0 - (center / self.min_avoid_distance))
        
        # 2. Left Obstacle: Steer right to avoid it
        elif left < self.min_avoid_distance:
            offset = 0.6 * (1.0 - (left / self.min_avoid_distance))
            
        # 3. Right Obstacle: Steer left to avoid it
        elif right < self.min_avoid_distance:
            offset = -0.6 * (1.0 - (right / self.min_avoid_distance))

        with self._lock:
            self._obstacle_left_dist = left
            self._obstacle_center_dist = center
            self._obstacle_right_dist = right
            self._steering_offset = offset

    # Thread-safe getters
    def get_distances(self):
        with self._lock:
            return {
                "left": self._obstacle_left_dist,
                "center": self._obstacle_center_dist,
                "right": self._obstacle_right_dist
            }

    def get_steering_offset(self):
        with self._lock:
            return self._steering_offset

# Self-test block
if __name__ == "__main__":
    logger.info("Running RealSense Perception self-test...")
    detector = RealSenseDetector(min_avoid_distance=8.0)
    detector.daemon = True
    detector.start()
    
    try:
        while True:
            dists = detector.get_distances()
            offset = detector.get_steering_offset()
            print(f"Obstacles L: {dists['left']:.1f}m | C: {dists['center']:.1f}m | R: {dists['right']:.1f}m | Avoid Offset: {offset:+.2f}", end="\r")
            time.sleep(0.2)
    except KeyboardInterrupt:
        detector.stop()
        print("\nTest terminated.")
