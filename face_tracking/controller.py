class PIDController:
    def __init__(self, kp, ki=0.0, kd=0.0):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.prev_error = (0, 0)
        self.integral = (0, 0)

    def compute(self, setpoint: tuple, measured_value: tuple) -> tuple:
        x, y = setpoint
        mx, my = measured_value
        error_x = x - mx
        error_y = y - my
        self.integral = (self.integral[0] + error_x, self.integral[1] + error_y)
        derivative_x = error_x - self.prev_error[0]
        derivative_y = error_y - self.prev_error[1]
        output_x = (self.kp * error_x) + (self.ki * self.integral[0]) + (self.kd * derivative_x)
        output_y = (self.kp * error_y) + (self.ki * self.integral[1]) + (self.kd * derivative_y)
        self.prev_error = (error_x, error_y)
        return output_x, output_y
