#!/usr/bin/env python3
"""
Blue-Water Rover: Single Drive & Rudder PWM Controller
Manages hardware-timed PWM output for a single propulsion ESC and rudder servo.
Utilizes the pigpio library for jitter-free PWM, falling back to mock mode if unavailable.
"""

import time
import logging

logger = logging.getLogger("DriveControl")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

class DriveControl:
    def __init__(self, throttle_pin=18, rudder_pin=19, use_hardware_pwm=True):
        self.throttle_pin = throttle_pin
        self.rudder_pin = rudder_pin
        self.use_hardware_pwm = use_hardware_pwm
        
        # Calibration constants (in microseconds)
        self.THROTTLE_MIN = 1000    # Full reverse
        self.THROTTLE_NEUTRAL = 1500 # Stopped
        self.THROTTLE_MAX = 2000    # Full forward
        
        self.RUDDER_LEFT = 1100     # Maximum left deflection
        self.RUDDER_CENTER = 1500   # Center
        self.RUDDER_RIGHT = 1900    # Maximum right deflection

        # Slew rate limits (max change in pulse width per second)
        self.THROTTLE_MAX_SLEW = 500  # Takes 1 second to go from neutral to full forward

        # Internal state
        self.current_throttle_pulse = self.THROTTLE_NEUTRAL
        self.current_rudder_pulse = self.RUDDER_CENTER
        self.killed = False
        
        # Initialize pigpio connection
        self.pi = None
        if self.use_hardware_pwm:
            try:
                import pigpio
                self.pi = pigpio.pi()
                if not self.pi.connected:
                    logger.warning("Could not connect to pigpio daemon! Running in Mock Mode.")
                    self.pi = None
                else:
                    logger.info("Successfully initialized pigpio. Hardware PWM active.")
            except ImportError:
                logger.warning("pigpio library not found! Running in Mock Mode.")
                self.pi = None

        # Set default state to neutral
        self.apply_pwm()

    def set_throttle(self, target_fraction, dt=0.02):
        """
        Sets target throttle. Target fraction ranges from -1.0 (full reverse) to 1.0 (full forward).
        Applies slew rate limiting to prevent current spikes.
        """
        if self.killed:
            self.current_throttle_pulse = self.THROTTLE_NEUTRAL
            self.apply_pwm()
            return

        # Map target fraction (-1.0 to 1.0) to microseconds
        if target_fraction >= 0:
            target_pulse = self.THROTTLE_NEUTRAL + (target_fraction * (self.THROTTLE_MAX - self.THROTTLE_NEUTRAL))
        else:
            target_pulse = self.THROTTLE_NEUTRAL + (target_fraction * (self.THROTTLE_NEUTRAL - self.THROTTLE_MIN))

        # Clamp target pulse
        target_pulse = max(self.THROTTLE_MIN, min(self.THROTTLE_MAX, target_pulse))

        # Apply slew-rate limit to throttle
        max_change = self.THROTTLE_MAX_SLEW * dt
        diff = target_pulse - self.current_throttle_pulse
        
        if abs(diff) > max_change:
            direction = 1.0 if diff > 0 else -1.0
            self.current_throttle_pulse += direction * max_change
        else:
            self.current_throttle_pulse = target_pulse

        self.apply_pwm()

    def set_rudder(self, target_fraction):
        """
        Sets target rudder angle. Target fraction ranges from -1.0 (full left) to 1.0 (full right).
        No slew rate limit on steering to allow immediate wave reaction corrections.
        """
        if self.killed:
            self.current_rudder_pulse = self.RUDDER_CENTER
            self.apply_pwm()
            return

        # Map target fraction (-1.0 to 1.0) to microseconds
        if target_fraction >= 0:
            target_pulse = self.RUDDER_CENTER + (target_fraction * (self.RUDDER_RIGHT - self.RUDDER_CENTER))
        else:
            target_pulse = self.RUDDER_CENTER + (target_fraction * (self.RUDDER_CENTER - self.RUDDER_LEFT))

        # Clamp target pulse
        self.current_rudder_pulse = max(self.RUDDER_LEFT, min(self.RUDDER_RIGHT, target_pulse))
        self.apply_pwm()

    def apply_pwm(self):
        """Outputs current pulse widths to pins via pigpio or prints values in Mock Mode."""
        # Force neutral if killed
        if self.killed:
            self.current_throttle_pulse = self.THROTTLE_NEUTRAL
            self.current_rudder_pulse = self.RUDDER_CENTER

        throttle = int(self.current_throttle_pulse)
        rudder = int(self.current_rudder_pulse)

        if self.pi:
            try:
                self.pi.set_servo_pulsewidth(self.throttle_pin, throttle)
                self.pi.set_servo_pulsewidth(self.rudder_pin, rudder)
            except Exception as e:
                logger.error(f"Failed to set PWM pulse widths via pigpio: {e}")
        else:
            logger.debug(f"[MOCK PWM] Pin {self.throttle_pin}: {throttle} us | Pin {self.rudder_pin}: {rudder} us")

    def kill(self):
        """Emergency cutoff. Immediately resets both outputs to neutral and ignores further inputs."""
        self.killed = True
        self.current_throttle_pulse = self.THROTTLE_NEUTRAL
        self.current_rudder_pulse = self.RUDDER_CENTER
        self.apply_pwm()
        logger.critical("EMERGENCY KILL TRIGGERED! Drive outputs cut and locked at neutral.")

    def reset_kill(self):
        """Resets the emergency kill flag."""
        self.killed = False
        logger.info("Emergency kill reset. Normal control resumed.")

    def get_current_values(self):
        """Returns currently applied pulse widths."""
        return {
            "throttle_us": int(self.current_throttle_pulse),
            "rudder_us": int(self.current_rudder_pulse),
            "killed": self.killed
        }

# Self-test block
if __name__ == "__main__":
    logger.info("Starting Drive Controller self-test...")
    controller = DriveControl(throttle_pin=18, rudder_pin=19, use_hardware_pwm=True)
    
    try:
        # Test rudder sweeps
        logger.info("Sweeping rudder left to right...")
        for val in [-1.0, -0.5, 0.0, 0.5, 1.0, 0.0]:
            controller.set_rudder(val)
            print(f"Rudder Target: {val:+.1f} | State: {controller.get_current_values()}")
            time.sleep(0.5)
            
        # Test throttle ramp-up
        logger.info("Ramping up throttle...")
        for step in range(51):
            fraction = step / 50.0  # 0.0 to 1.0
            controller.set_throttle(fraction, dt=0.1)
            print(f"Throttle Target: {fraction:.2f} | Current: {controller.current_throttle_pulse:.0f} us", end="\r")
            time.sleep(0.1)
            
        print()
        
        # Test Emergency Kill
        logger.info("Testing emergency kill...")
        controller.set_throttle(0.8, dt=0.1)
        time.sleep(0.2)
        controller.kill()
        print(f"Killed State: {controller.get_current_values()}")
        
    except KeyboardInterrupt:
        controller.kill()
