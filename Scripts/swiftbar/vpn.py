import pyautogui
import time
import random

# Set a pause between each pyautogui action
pyautogui.PAUSE = 0.5

# Define a list of "harmless" keys that have no visible side effects
harmless_keys = ["esc", "shift", "ctrl", "alt", "command", "option"]


def scroll_down(amount=1):
    """Simulate scrolling down in the VS Code window"""
    pyautogui.scroll(-amount)


def scroll_up(amount=1):
    """Simulate scrolling up in the VS Code window"""
    pyautogui.scroll(amount)


def switch_tab(direction="right"):
    """Simulate switching to the next tab in VS Code on macOS"""
    pyautogui.hotkey("command", "option", direction)


def press_random_harmless_key():
    """Press a random harmless key that has no side effects"""
    random_key = random.choice(harmless_keys)
    pyautogui.press(random_key)


MOVEMENT_LEVELS = {
    "none": {
        "scroll_interval": None,
        "key_interval": None,
        "tab_interval": None,
    },
    "low": {
        "scroll_interval": 8,
        "key_interval": 10,
        "tab_interval": 15,
    },
    "medium": {
        "scroll_interval": 4,
        "key_interval": 5,
        "tab_interval": 8,
    },
    "high": {
        "scroll_interval": 2,
        "key_interval": 3,
        "tab_interval": 5,
    },
}


def run_activity_cycle(level, duration=60):
    """
    Run activity at the given movement level for `duration` seconds.
    Returns when the duration has elapsed.
    """
    config = MOVEMENT_LEVELS[level]

    if level == "none":
        print(f"  No movement — sleeping for {duration}s")
        time.sleep(duration)
        return

    scroll_interval = config["scroll_interval"]
    key_interval = config["key_interval"]
    tab_interval = config["tab_interval"]

    actions = [
        (lambda: scroll_up(), scroll_interval),
        (lambda: press_random_harmless_key(), key_interval),
        (lambda: scroll_down(), scroll_interval),
        (lambda: press_random_harmless_key(), key_interval),
        (lambda: switch_tab(), tab_interval),
    ]

    start = time.time()
    action_index = 0
    while time.time() - start < duration:
        action, interval = actions[action_index % len(actions)]
        action()
        remaining = duration - (time.time() - start)
        if remaining <= 0:
            break
        time.sleep(min(interval, remaining))
        action_index += 1


def simulate_continuous_activity():
    """
    Continuously simulate activity. Every minute, randomly pick a movement
    level (none, low, medium, high) and use it for that entire minute.
    """
    print("Started")
    levels = list(MOVEMENT_LEVELS.keys())
    while True:
        level = random.choice(levels)
        print(f"[{time.strftime('%H:%M:%S')}] Movement level: {level}")
        run_activity_cycle(level, duration=60)


# Example usage
print("Starting...")
time.sleep(5)  # Give you time to switch to the VS Code window

simulate_continuous_activity()
