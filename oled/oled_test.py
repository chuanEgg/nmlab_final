from luma.core.interface.serial import i2c
from luma.oled.device import sh1106
from PIL import Image, ImageDraw, ImageFont
import time

# Create I2C interface
serial = i2c(port=1, address=0x3C)

# Create SH1106 device (128x64)
device = sh1106(serial, width=128, height=64)

# Create image buffer
image = Image.new("1", device.size)
draw = ImageDraw.Draw(image)

# Draw text
draw.text((0, 0), "SH1106 OK", fill=255)
draw.text((0, 16), "Raspberry Pi 5", fill=255)

# Display
device.display(image)

time.sleep(5)
