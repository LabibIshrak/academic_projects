from graphics import Canvas

# Canvas size for plotting
CANVAS_WIDTH = 400
CANVAS_HEIGHT = 400

def main():
    print("Welcome to the Political Compass Game!")
    print("Answer the following questions with 'yes' or 'no'.\n")

    x = 0  # Economic axis: Left (-) to Right (+)
    y = 0  # Social axis: Libertarian (-) to Authoritarian (+)

    #questions
    questions = [
        {"question": "Should the government regulate the economy more strictly?", "x": -1, "y": 0},
        {"question": "Should taxes be lowered for everyone?", "x": 1, "y": 0},
        {"question": "Should the state provide free healthcare?", "x": -1, "y": 0},
        {"question": "Is a strong military more important than civil liberties?", "x": 0, "y": 1},
        {"question": "Should drugs be legalized?", "x": 0, "y": -1},
        {"question": "Is national security more important than individual privacy?", "x": 0, "y": 1},
        {"question": "Should immigration be less restricted?", "x": -1, "y": -1},
        {"question": "Should the government control the media?", "x": 0, "y": 1}
    ]

    for q in questions:
        answer = input(q["question"] + " ").strip().lower()
        if answer == "yes":
            x += q["x"]
            y += q["y"]
        elif answer == "no":
            x -= q["x"]
            y -= q["y"]
        else:
            print("Please answer 'yes' or 'no'. Skipping this question.")

        print()  # Blank line for clarity

    print(f"Your final position is: ({x}, {y})\n")
    draw_compass(x, y)


def draw_compass(x, y):
    canvas = Canvas(CANVAS_WIDTH, CANVAS_HEIGHT)

    #center line
    canvas.create_line(CANVAS_WIDTH / 2, 0, CANVAS_WIDTH / 2, CANVAS_HEIGHT, "black")  # Vertical line
    canvas.create_line(0, CANVAS_HEIGHT / 2, CANVAS_WIDTH, CANVAS_HEIGHT / 2, "black")  # Horizontal line

    # Labels
    canvas.create_text(50, CANVAS_HEIGHT / 2 - 20, "Left", "black")
    canvas.create_text(CANVAS_WIDTH - 50, CANVAS_HEIGHT / 2 - 20, "Right", "black")
    canvas.create_text(CANVAS_WIDTH / 2 + 40, 30, "Authoritarian", "black")
    canvas.create_text(CANVAS_WIDTH / 2 + 40, CANVAS_HEIGHT - 30, "Libertarian", "black")

    # position
    plot_x = CANVAS_WIDTH / 2 + x * 30  # 30 pixels per score step
    plot_y = CANVAS_HEIGHT / 2 - y * 30  # Y is inverted on canvas

    canvas.create_oval(plot_x - 5, plot_y - 5, plot_x + 5, plot_y + 5, "red")

    print("Your position has been plotted on the compass!")

if __name__ == '__main__':
    main()