import tkinter as tk
from tkinter import filedialog
from tkinter import messagebox
from PIL import Image, ImageDraw
import serial

# Configuration------------------------------
DEFAULT_SIZE = 256
DOUBLE_SIZE = 512
BG_COLOR = "white"

# Color commands → exact colors
COLOR_MAP = {
    "#BB": "#0000FF",  # Blue
    "#RR": "#FF0000",  # Red
    "#GG": "#00FF00",  # Green
    "#RB": "#FF00FF",  # Purple (Red + Blue)
    "#RG": "#FFFF00",  # Yellow (Red + Green)
    "#BG": "#00FFFF",  # Teal (Blue + Green)
}
# ------------------------------------------


def UART_serial():
    try:
        ser = serial.Serial('COM5', baudrate=9600, bytesize=8, parity='N', stopbits=1, timeout=0.1)
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        ser = None
    return ser


class EtchASketchApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Etch-a-Sketch")

        # State
        self.sketch_size = DEFAULT_SIZE
        self.pen_color = "#000000"
        self.pen_width = 1
        self.x = self.sketch_size // 2
        self.y = self.sketch_size // 2
        self.rotary_tag = 0  # received from FPGA

        # Image buffer for saving
        self.image = Image.new("RGB", (self.sketch_size, self.sketch_size), BG_COLOR)
        self.draw = ImageDraw.Draw(self.image)

        # UI
        self.create_widgets()
        self.bind_keys()
        self.update_status()

        # Serial
        self.ser = UART_serial()
        self.root.after(10, self.poll_serial)

    # ---------------- SERIAL HELPERS ----------------

    def uart_send_line(self, line: str):
        if self.ser is not None:
            try:
                self.ser.write(line.encode('ascii'))
            except serial.SerialException:
                pass

    def uart_send_draw(self, x1, y1, x2, y2):
        line = f"D {x1} {y1} {x2} {y2} {self.pen_color} {self.pen_width}\n"
        self.uart_send_line(line)

    def uart_send_clear(self):
        self.uart_send_line("CLR\n")

    def uart_send_size(self):
        size_code = 1 if self.sketch_size == DEFAULT_SIZE else 2
        self.uart_send_line(f"S {size_code}\n")

    # ---------------- SERIAL POLLING ----------------

    def poll_serial(self):
        """Read UART from FPGA: movement, commands, rotary tag."""
        if self.ser is not None and self.ser.in_waiting > 0:
            char_in = self.ser.read()

            try:
                decoded = char_in.decode('ascii')

                # PS/2 MOVEMENT (WASD ONLY)
                if decoded in ('w', 'W'):
                    self.move_up()
                elif decoded in ('s', 'S'):
                    self.move_down()
                elif decoded in ('a', 'A'):
                    self.move_left()
                elif decoded in ('d', 'D'):
                    self.move_right()

                # ENTER -> submit command
                elif decoded == '\r':
                    self.show_input()
                    self.entry.delete(0, tk.END)

                # BACKSPACE
                elif decoded == '\b':
                    current = self.entry.get()
                    self.entry.delete(0, tk.END)
                    self.entry.insert(0, current[:-1])

                # ROTARY TAG FROM FPGA: expecting "T123\n"
                elif decoded == 'T':
                    tag_bytes = self.ser.readline().decode('ascii').strip()
                    if tag_bytes.isdigit():
                        self.rotary_tag = int(tag_bytes) & 0xFF
                        print(f"Rotary tag received: {self.rotary_tag}")
                        self.update_status()

                # Ignore everything else
                else:
                    pass

            except UnicodeDecodeError:
                pass

        self.root.after(10, self.poll_serial)

    # ---------------- UI SETUP ----------------

    def create_widgets(self):
        top_frame = tk.Frame(self.root)
        top_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        self.canvas = tk.Canvas(
            top_frame,
            width=self.sketch_size,
            height=self.sketch_size,
            bg=BG_COLOR,
            highlightthickness=1,
            highlightbackground="black",
        )
        self.canvas.pack(side=tk.LEFT, padx=10, pady=10)

        right_frame = tk.Frame(top_frame)
        right_frame.pack(side=tk.LEFT, fill=tk.Y, padx=10, pady=10)

        tk.Label(right_frame, text="Current Color:").pack(anchor="w")
        self.color_box = tk.Canvas(
            right_frame,
            width=40,
            height=40,
            bg=self.pen_color,
            highlightthickness=1
        )
        self.color_box.pack(anchor="w", pady=(0, 10))

        self.clear_button = tk.Button(right_frame, text="Erase (E/Delete)", command=self.clear_canvas)
        self.clear_button.pack(fill=tk.X, pady=2)

        self.save_button = tk.Button(right_frame, text="Save Image", command=self.save_image)
        self.save_button.pack(fill=tk.X, pady=2)

        instructions = (
            "Controls:\n"
            "Arrow Keys: draw\n"
            "E or Delete: erase\n"
            "Q: toggle size\n"
            "Commands:\n"
            "  Colors: #BB,#RR,#GG,#RB,#RG,#BG\n"
            "  Size:   S1,S2\n"
            "  Width:  W1,W2,W3"
        )
        tk.Label(right_frame, text=instructions, justify="left").pack(anchor="w", pady=10)

        self.status_var = tk.StringVar()
        status_frame = tk.Frame(self.root)
        status_frame.pack(side=tk.BOTTOM, fill=tk.X)
        self.status_label = tk.Label(status_frame, textvariable=self.status_var, anchor="w")
        self.status_label.pack(fill=tk.X)

        self.input_label = tk.Label(self.root, text="Enter Command:")
        self.input_label.pack(pady=5)

        self.entry = tk.Entry(self.root, width=30)
        self.entry.pack(pady=5)
        self.entry.focus()
        self.entry.bind("<KeyPress>", self.filter_entry_keys)

    # ---------------- ENTRY FILTER ----------------

    def filter_entry_keys(self, event):
        if event.keysym == "Return":
            self.show_input()
            self.entry.delete(0, tk.END)
            return "break"
        return

    # ---------------- COMMAND SUBMIT ----------------

    def show_input(self, event=None):
        user_text = self.entry.get().strip()
        if not user_text:
            return

        if user_text[0] not in ('#', 'W', 'S'):
            messagebox.showerror("Invalid Command", "Commands must start with #, W, or S.")
            return

        handled = self.handle_command(user_text)
        if not handled:
            messagebox.showerror("Invalid Command", f"Unrecognized command: {user_text}")

    def handle_command(self, cmd: str) -> bool:
        # Color commands
        if cmd in COLOR_MAP:
            self.pen_color = COLOR_MAP[cmd]
            self.color_box.config(bg=self.pen_color)
            self.update_status()
            return True

        # Size commands
        if cmd == "S1":
            if self.sketch_size != DEFAULT_SIZE:
                self.sketch_size = DEFAULT_SIZE
                self.resize_canvas_and_image()
            return True

        if cmd == "S2":
            if self.sketch_size != DOUBLE_SIZE:
                self.sketch_size = DOUBLE_SIZE
                self.resize_canvas_and_image()
            return True

        # Width commands (ONLY via W1/W2/W3)
        if cmd == "W1":
            self.set_pen_width(1)
            return True
        if cmd == "W2":
            self.set_pen_width(2)
            return True
        if cmd == "W3":
            self.set_pen_width(3)
            return True

        return False

    # ---------------- KEY BINDINGS ----------------

    def bind_keys(self):
        # PC KEYBOARD MOVEMENT (ARROWS ONLY)
        self.root.bind("<Up>", self.move_up)
        self.root.bind("<Down>", self.move_down)
        self.root.bind("<Left>", self.move_left)
        self.root.bind("<Right>", self.move_right)

        # NO WASD movement on PC keyboard
        # W should ONLY matter when typed as W1/W2/W3 in the command box

        # REMOVE number-key width changes
        # Width now ONLY changes via commands: W1, W2, W3

        # Erase: E and Delete
        self.root.bind("e", self.erase_key)
        self.root.bind("E", self.erase_key)
        self.root.bind("Delete", self.erase_key)
        self.root.bind("delete", self.erase_key)

        # Toggle size
        self.root.bind("q", self.toggle_size)
        self.root.bind("Q", self.toggle_size)

    # ---------------- DRAWING ----------------

    def draw_line(self, x1, y1, x2, y2):
        self.canvas.create_line(
            x1, y1, x2, y2,
            fill=self.pen_color,
            width=self.pen_width,
            capstyle=tk.ROUND
        )
        self.draw.line((x1, y1, x2, y2), fill=self.pen_color, width=self.pen_width)
        self.uart_send_draw(x1, y1, x2, y2)

    def clamp(self, v):
        return max(0, min(self.sketch_size - 1, v))

    def move_up(self, event=None):
        step = self.pen_width
        new_x, new_y = self.x, self.clamp(self.y - step)
        self.draw_line(self.x, self.y, new_x, new_y)
        self.x, self.y = new_x, new_y

    def move_down(self, event=None):
        step = self.pen_width
        new_x, new_y = self.x, self.clamp(self.y + step)
        self.draw_line(self.x, self.y, new_x, new_y)
        self.x, self.y = new_x, new_y

    def move_left(self, event=None):
        step = self.pen_width
        new_x, new_y = self.clamp(self.x - step), self.y
        self.draw_line(self.x, self.y, new_x, new_y)
        self.x, self.y = new_x, new_y

    def move_right(self, event=None):
        step = self.pen_width
        new_x, new_y = self.clamp(self.x + step), self.y
        self.draw_line(self.x, self.y, new_x, new_y)
        self.x, self.y = new_x, new_y

    # ---------------- MISC ----------------

    def set_pen_width(self, w):
        self.pen_width = w
        self.update_status()

    def clear_canvas(self):
        """Erase drawing but DO NOT reset position."""
        self.canvas.delete("all")
        self.image = Image.new("RGB", (self.sketch_size, self.sketch_size), BG_COLOR)
        self.draw = ImageDraw.Draw(self.image)
        self.uart_send_clear()

    def erase_key(self, event=None):
        self.clear_canvas()

    def toggle_size(self, event=None):
        new_size = DOUBLE_SIZE if self.sketch_size == DEFAULT_SIZE else DEFAULT_SIZE
        self.sketch_size = new_size
        self.resize_canvas_and_image()

    def resize_canvas_and_image(self):
        self.image = self.image.resize((self.sketch_size, self.sketch_size), Image.NEAREST)
        self.draw = ImageDraw.Draw(self.image)

        self.canvas.config(width=self.sketch_size, height=self.sketch_size)
        self.redraw_from_image()

        self.x = self.clamp(self.x)
        self.y = self.clamp(self.y)

        self.update_status()
        self.uart_send_size()

    def redraw_from_image(self):
        self.canvas.delete("all")
        self.tk_image = tk.PhotoImage(width=self.sketch_size, height=self.sketch_size)

        for y in range(self.sketch_size):
            row = ""
            for x in range(self.sketch_size):
                r, g, b = self.image.getpixel((x, y))
                row += "#{:02x}{:02x}{:02x} ".format(r, g, b)
            self.tk_image.put("{" + row.strip() + "}", to=(0, y))

        self.canvas.create_image(0, 0, anchor="nw", image=self.tk_image)

    def save_image(self):
        file_path = filedialog.asksaveasfilename(
            defaultextension=".png",
            filetypes=[("PNG Image", "*.png"), ("All Files", "*.*")],
            title="Save Drawing",
        )
        if file_path:
            self.image.save(file_path, format="PNG")

    def update_status(self):
        size_label = "S1 (256x256)" if self.sketch_size == DEFAULT_SIZE else "S2 (512x512)"
        status = (
            f"Size: {size_label} | Color: {self.pen_color} | "
            f"Width: {self.pen_width}px | Rotary Tag: {self.rotary_tag}"
        )
        self.status_var.set(status)


if __name__ == "__main__":
    root = tk.Tk()
    app = EtchASketchApp(root)
    root.mainloop()
