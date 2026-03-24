import serial

try:
    ser = serial.Serial('COM13', baudrate=9600, bytesize=8, parity='N', stopbits=1, timeout=0.1)
except serial.SerialException as e:
    print(f"Error opening serial port: {e}")
    exit()

def send_lcd_cmd(cmd_byte):
    """Sends a byte to the LCD instruction register, 0x01 prefix"""
    ser.write(bytes([0x01, cmd_byte]))

def send_lcd_string(text):
    """Sends an ASCII string to the LCD DDRAM, with 0x02 prefix, and null terminator"""
    ser.write(bytes([0x02]))
    ser.write(text.encode('ascii'))
    ser.write(bytes([0x00]))

def send_7seg_data(high_byte, low_byte):
    """Sends two bytes of data to the 7-segment display (0x03 header)"""
    ser.write(bytes([0x03, high_byte, low_byte]))

print("Initializing displays...")

send_lcd_cmd(0x01) # clear display
send_lcd_string("Overwrite this") # demo string
send_lcd_cmd(0x02) # return cursor to home position
send_lcd_cmd(0x0F) # turn cursor on, blinking

send_7seg_data(0x00, 0x00) # display 0000 on 7-segment

print("Waiting for PS/2 input, press ctrl-c to exit")

enter_count = 0

try:
    while True:
        # Check if there is data waiting in the serial buffer
        if ser.in_waiting > 0:
            char_in = ser.read()
            
            try:
                decoded_char = char_in.decode('ascii')                
                print(decoded_char, end='', flush=True)
                
                if decoded_char == '\r': # enter
                    print("\r")

                    enter_count += 1
                    
                    # display number of enters 4 digit hex
                    high = (enter_count >> 8) & 0xFF
                    low = enter_count & 0xFF
                    send_7seg_data(high, low)
                    
                    send_lcd_cmd(0x02) # return cursor to home position
                else:
                    send_lcd_string(decoded_char)
                    
            except UnicodeDecodeError:
                print("UnicodeDecodeError")
                pass

except KeyboardInterrupt:
    print("Exit")
finally:
    ser.close()