"""Makes Tik's two short sounds as WAV files, straight from math.

- tick.wav:      a soft "pop" when a task is ticked
- celebrate.wav: four bright bell notes when everything is done

Usage (from the repo root):  python3 Scripts/make-sounds.py
"""

import math
import os
import struct
import wave

RATE = 44100
FOLDER = "Tik/Resources/Sounds"


def write(name, samples):
    os.makedirs(FOLDER, exist_ok=True)
    with wave.open(os.path.join(FOLDER, name), "w") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        file.writeframes(frames)
    print("Wrote", name)


def tick():
    """A quick tone that falls in pitch and fades fast."""
    samples = []
    phase = 0.0
    for i in range(int(RATE * 0.11)):
        t = i / RATE
        frequency = 1400 * math.exp(-t * 18) + 650
        phase += 2 * math.pi * frequency / RATE
        envelope = math.exp(-t * 38) * min(1, t / 0.002)
        samples.append(0.45 * envelope * (math.sin(phase) + 0.25 * math.sin(2 * phase)))
    return samples


def celebrate():
    """C6, E6, G6 and then C7, each a small bell that rings out."""
    notes = [(1046.5, 0.00), (1318.5, 0.09), (1568.0, 0.18), (2093.0, 0.30)]
    total = int(RATE * 0.9)
    samples = [0.0] * total
    for frequency, start in notes:
        first = int(start * RATE)
        for i in range(total - first):
            t = i / RATE
            envelope = math.exp(-t * 7) * min(1, t / 0.003)
            tone = (math.sin(2 * math.pi * frequency * t)
                    + 0.35 * math.sin(2 * math.pi * frequency * 2.01 * t)
                    + 0.12 * math.sin(2 * math.pi * frequency * 3.03 * t))
            samples[first + i] += 0.18 * envelope * tone
    return samples


if __name__ == "__main__":
    write("tick.wav", tick())
    write("celebrate.wav", celebrate())
