import random

class HangmanGame:
    def __init__(self, word_file="rand.txt", lives=6):
        self.word_file = word_file
        self.default_lives = lives
        self.reset()

    def reset(self):
        with open(self.word_file, "r", encoding="utf-8") as file:
            self.words = file.read().split()
            self.num_words = len(self.words)

        self.word = random.choice(self.words)
        self.lives = self.default_lives
        self.guessed_letters = set()
        self.correct_letters = set()

    def get_display_word(self):
        return " ".join([c if c in self.correct_letters else "_" for c in self.word])

    def guess(self, letter):
        letter = letter.lower()

        if not letter.isalpha() or len(letter) != 1:
            return "Enter a single letter."

        if letter in self.guessed_letters:
            return "You already guessed that letter!"

        self.guessed_letters.add(letter)

        if letter in self.word:
            self.correct_letters.add(letter)
            if self.is_won():
                return f"WIN:{self.word}"
            return f"Correct! '{letter}' is in the word."
        else:
            self.lives -= 1
            if self.lives <= 0:
                return f"LOSE:{self.word}"
            return f"Wrong! '{letter}' is not in the word."

    def is_won(self):
        return all(c in self.correct_letters for c in self.word)