import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageDraw

#Configuration------------------------------
DEFAULT_SIZE = 256
DOUBLE_SIZE = 512
BG_COLOR = "white"
DEFAULT_PEN_COLOR = "#000000"
PEN_COLORS = ["#000000", "#FF0000", "#00FF00", "#0000FF"]

# ------------------------------------------


class EtchASketchApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Etch-a-Sketch")

        #State
        self.sketch_size = DEFAULT_SIZE
        self.pen_color_index = 0
        self.pen_color = PEN_COLORS[self.pen_color_index]
        self.pen_width = 1
        self.x = self.sketch_size // 2
        self.y = self.sketch_size // 2

        #Image buffer for saving
        self.image = Image.new("RGB", (self.sketch_size, self.sketch_size), BG_COLOR)
        self.draw = ImageDraw.Draw(self.image)

        #User Interface
        self.create_widgets()
        self.bind_keys()
        self.update_status()

    def create_widgets(self):
        #Top frame for canvas and controls
        top_frame = tk.Frame(self.root)
        top_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        #Canvas
        self.canvas = tk.Canvas(
            top_frame,
            width=self.sketch_size,
            height=self.sketch_size,
            bg=BG_COLOR,
            highlightthickness=1,
            highlightbackground="black",
        )
        self.canvas.pack(side=tk.LEFT, padx=10, pady=10)

        #Right panel
        right_frame = tk.Frame(top_frame)
        right_frame.pack(side=tk.LEFT, fill=tk.Y, padx=10, pady=10)

        #Color box
        tk.Label(right_frame, text="Current Color:").pack(anchor="w")
        self.color_box = tk.Canvas(right_frame, width=40, height=40, bg=self.pen_color, highlightthickness=1)
        self.color_box.pack(anchor="w", pady=(0, 10))

        #Buttons
        self.clear_button = tk.Button(right_frame, text="Erase (E)", command=self.clear_canvas)
        self.clear_button.pack(fill=tk.X, pady=2)

        self.save_button = tk.Button(right_frame, text="Save Image", command=self.save_image)
        self.save_button.pack(fill=tk.X, pady=2)

        #Provided User Instructions (User Friendly... I think)
        instructions = (
            "Controls:\n"
            "Arrow keys: draw\n"
            "C: change color\n"
            "1/2/3: pen width\n"
            "E: erase\n"
            "S: toggle size"
        )
        tk.Label(right_frame, text=instructions, justify="left").pack(anchor="w", pady=10)

        #Status bar
        self.status_var = tk.StringVar()
        status_frame = tk.Frame(self.root)
        status_frame.pack(side=tk.BOTTOM, fill=tk.X)
        self.status_label = tk.Label(status_frame, textvariable=self.status_var, anchor="w")
        self.status_label.pack(fill=tk.X)

    def bind_keys(self):
        #Movement
        self.root.bind("<Up>", self.move_up)
        self.root.bind("<Down>", self.move_down)
        self.root.bind("<Left>", self.move_left)
        self.root.bind("<Right>", self.move_right)

        #Color
        self.root.bind("c", self.change_color)
        self.root.bind("C", self.change_color)

        #Width
        self.root.bind("1", lambda e: self.set_pen_width(1))
        self.root.bind("2", lambda e: self.set_pen_width(2))
        self.root.bind("3", lambda e: self.set_pen_width(3))

        #Erase Drawing (Keybinded at E for now)
        self.root.bind("e", self.erase_key)
        self.root.bind("E", self.erase_key)

        # Size toggle
        self.root.bind("s", self.toggle_size)
        self.root.bind("S", self.toggle_size)

    #Drawing Helper Functions

    def draw_line(self, x1, y1, x2, y2):
        #Draw on canvas
        self.canvas.create_line(
            x1, y1, x2, y2,
            fill=self.pen_color,
            width=self.pen_width,
            capstyle=tk.ROUND
        )
        #Draw in image buffer
        self.draw.line((x1, y1, x2, y2), fill=self.pen_color, width=self.pen_width)

    def clamp(self, v):
        return max(0, min(self.sketch_size - 1, v))

    #Sketch Movement

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

    #User Actions

    def change_color(self, event=None):
        self.pen_color_index = (self.pen_color_index + 1) % len(PEN_COLORS)
        self.pen_color = PEN_COLORS[self.pen_color_index]
        self.color_box.config(bg=self.pen_color)
        self.update_status()

    def set_pen_width(self, w):
        self.pen_width = w
        self.update_status()

    def clear_canvas(self):
        self.canvas.delete("all")
        self.image = Image.new("RGB", (self.sketch_size, self.sketch_size), BG_COLOR)
        self.draw = ImageDraw.Draw(self.image)
        self.x = self.sketch_size // 2
        self.y = self.sketch_size // 2

    def erase_key(self, event=None):
        self.clear_canvas()

    def toggle_size(self, event=None):
        new_size = DOUBLE_SIZE if self.sketch_size == DEFAULT_SIZE else DEFAULT_SIZE

        #Resize image buffer
        self.image = self.image.resize((new_size, new_size), Image.NEAREST)
        self.draw = ImageDraw.Draw(self.image)

        #Update canvas
        self.sketch_size = new_size
        self.canvas.config(width=self.sketch_size, height=self.sketch_size)
        self.redraw_from_image()

        #Re-center pen
        self.x = self.sketch_size // 2
        self.y = self.sketch_size // 2

        self.update_status()

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

    #Status Update

    def update_status(self):
        size_label = "S1 (256x256)" if self.sketch_size == DEFAULT_SIZE else "S2 (512x512)"
        status = f"Size: {size_label} | Color: {self.pen_color} | Width: {self.pen_width}px"
        self.status_var.set(status)


if __name__ == "__main__":
    root = tk.Tk()
    app = EtchASketchApp(root)
    root.mainloop()