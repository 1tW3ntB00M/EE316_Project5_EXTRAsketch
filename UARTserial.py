import serial

try:
    ser = serial.Serial('COM5', 9600, bytesize=8, parity='N', stopbits=1, timeout=0.1)
except serial.SerialException as e:
    print(f"Error opening serial port: {e}")
    exit()


def send_lcd_cmd(cmd_byte):
    ser.write(bytes([0x01, cmd_byte]))

def send_lcd_string(text):
    ser.write(bytes([0x02]))
    ser.write(text.encode('ascii'))
    ser.write(bytes([0x00]))
