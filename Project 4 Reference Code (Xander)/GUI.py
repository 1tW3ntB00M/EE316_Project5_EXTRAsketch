import tkinter as tk
from hangman import HangmanGame
import serial

HANGMAN_PICS = [
    """
     +---+
     |   |
         |
         |
         |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
         |
         |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
     |   |
         |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
    /|   |
         |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
    /|\\  |
         |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
    /|\\  |
    /    |
         |
    =========
    """,
    """
     +---+
     |   |
     O   |
    /|\\  |
    / \\  |
         |
    =========
    """
]

game = HangmanGame()
wins = 0
awaiting_restart = False

def update_hangman_art():
    wrong = game.default_lives - game.lives
    wrong = max(0, min(wrong, len(HANGMAN_PICS) - 1))
    hangman_label.config(text=HANGMAN_PICS[wrong])


def disable_input():
    entry.config(state="normal")   # keep entry active for y/n
    guess_button.config(state="disabled")


def enable_input():
    entry.config(state="normal")
    guess_button.config(state="normal")
    entry.focus()


def restart_game():
    global awaiting_restart
    game.reset()
    awaiting_restart = False

    message_label.config(text="")
    word_label.config(text=game.get_display_word())
    lives_label.config(text=f"Lives: {game.lives}")
    update_hangman_art()
    enable_input()

# serial connection
try:
    ser = serial.Serial('COM13', 9600, timeout=0) # timeout=0 results in non blocking
except serial.SerialException as e:
    print(f"SerialException: {e}")
    ser = None

def send_lcd_cmd(cmd_byte):
    if ser:
        ser.write(bytes([0x01, cmd_byte]))

def send_lcd_string(text):
    if ser:
        ser.write(bytes([0x02]))
        ser.write(text.encode('ascii'))
        ser.write(bytes([0x00]))

def send_7seg_data(high_byte, low_byte):
    if ser:
        ser.write(bytes([0x03, high_byte, low_byte]))

def poll_serial():
    if ser:
        if ser.in_waiting > 0:
            try:
                char_in = ser.read().decode('ascii')
                if char_in == '\r': # if enter
                    submit_guess() # submit data in entry box as guess
                elif char_in.isalpha(): # if letter
                    entry.insert(tk.END, char_in) # insert into entry box
            except UnicodeDecodeError:
                print("UnicodeDecodeError")
                pass
    
    root.after(10, poll_serial) # cause this to poll in another 10ms

# Long messages need to scroll across LCD
# this animates scrolling text and allows for a callback to continue program execution after scrolling done
is_scrolling = False
def scroll_message(text, index=0, callback=None):
    """Scrolls text right-to-left across the 16-char LCD."""
    global is_scrolling
    is_scrolling = True
    
    padded_text = "                " + text + "                " # 16 space padding both sides so message scrolls fully on and off
    
    if index <= len(padded_text) - 16:
        window = padded_text[index:index+16]
        send_lcd_cmd(0x01) # Clear display
        send_lcd_string(window)
        # Schedule the next frame in 300ms
        root.after(300, scroll_message, text, index+1, callback)
    else:
        is_scrolling = False
        if callback:
            callback() # Proceed to the next game phase (e.g., "New Game?")

# GUI
def submit_guess(event=None):
    global wins, awaiting_restart, is_scrolling

    if is_scrolling: # ignore inputs while scrolling message
        return

    if awaiting_restart: # if waiting for y/n response to start new game
        answer = entry.get().lower()
        entry.delete(0, tk.END)

        if answer == "y":
            restart_game()
        elif answer == "n":
            send_lcd_cmd(0x01)
            send_lcd_string(" GAME OVER ")
            root.destroy()
        else:
            message_label.config(text="Please enter 'y' or 'n'.")
        return

    letter = entry.get()
    entry.delete(0, tk.END)

    result = game.guess(letter)

    send_7seg_data(0x00, game.lives) # show lives on 7-segment
    
    if result.startswith("WIN:"):
        wins += 1
        word_label.config(text=game.get_display_word())
        lives_label.config(text=f"Lives: {game.lives}")
        update_hangman_art()

        message_label.config(
            text=f"You won! The word was: {result[4:]}\nPlay again? (y/n)"
        )
        wins_label.config(text=f"Wins: {wins}")

        disable_input()
        awaiting_restart = True
        
        msg = f"Well done! You have solved {wins} puzzles out of {game.num_words}"
        message_label.config(text=msg + "\nPlay again? (y/n)")
        scroll_message(msg, callback=lambda: prompt_new_game()) # after scrolling, prompt for new game
        return

    elif result.startswith("LOSE:"):
        word_label.config(text=game.get_display_word())
        lives_label.config(text=f"Lives: {game.lives}")
        update_hangman_art()

        message_label.config(
            text=f"You lost! The word was: {result[5:]}\nPlay again? (y/n)"
        )

        disable_input()
        awaiting_restart = True
        
        msg = f"Sorry! The correct word was {result[5:]}. You have solved {wins} puzzles out of {game.num_words}."
        message_label.config(text=msg + "\nPlay again? (y/n)")
        scroll_message(msg, callback=lambda: prompt_new_game()) # after scrolling, prompt for new game
        return

    else:
        message_label.config(text=result)

    word_label.config(text=game.get_display_word())
    lives_label.config(text=f"Lives: {game.lives}")
    
    send_lcd_cmd(0x01)
    send_lcd_string(game.get_display_word().replace(" ", "")) # Remove spaces between underscores for LCD

def disable_input():
    entry.config(state="normal")   # keep entry active for y/n
    guess_button.config(state="disabled")

def enable_input():
    entry.config(state="normal")
    guess_button.config(state="normal")
    entry.focus()

def prompt_new_game():
    send_lcd_cmd(0x01) # clear LCD
    send_lcd_string("New Game?") # prompt for new game

def restart_game():
    global awaiting_restart
    game.reset()
    awaiting_restart = False
    message_label.config(text="")
    word_label.config(text=game.get_display_word())
    lives_label.config(text=f"Lives: {game.lives}")
    
    send_7seg_data(0x00, game.lives) # show lives on 7-segment
    send_lcd_cmd(0x01) # clear LCD
    send_lcd_string(game.get_display_word().replace(" ", "")) # show word on LCD without spaces
    
    enable_input()
    # message_label.config(text=result)
    word_label.config(text=game.get_display_word())
    lives_label.config(text=f"Lives: {game.lives}")
    update_hangman_art()

## GUI setup ##
root = tk.Tk()
root.title("Hangman")

title_label = tk.Label(root, text="Hangman Game", font=("Times New Roman", 20))
title_label.pack(pady=10)

word_label = tk.Label(root, text=game.get_display_word(), font=("Times New Roman", 24))
word_label.pack(pady=10)

hangman_label = tk.Label(root, text=HANGMAN_PICS[0], font=("Consolas", 14), justify="left")
hangman_label.pack(pady=10)

lives_label = tk.Label(root, text=f"Lives: {game.lives}", font=("Times New Roman", 12))
lives_label.pack(pady=5)

wins_label = tk.Label(root, text=f"Wins: {wins}", font=("Times New Roman", 12))
wins_label.pack(pady=5)

entry = tk.Entry(root, font=("Times New Roman", 12))
entry.pack(pady=5)
entry.focus()

guess_button = tk.Button(root, text="Guess", font=("Times New Roman", 12), command=submit_guess)
guess_button.pack(pady=5)

entry.bind("<Return>", submit_guess)

message_label = tk.Label(root, text="", font=("Times New Roman", 12))
message_label.pack(pady=10)

poll_serial()
root.mainloop()