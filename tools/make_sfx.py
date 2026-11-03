"""Synthesizes the game's generated sounds (suppressor break, Codec ring/answer/hang-up, intel chime, camera lock,
wind and vent beds) into assets/audio/*.ogg. No third-party sources: everything here is generated, CC0.
Run: python tools/make_sfx.py   (needs numpy, scipy and ffmpeg on PATH)."""
import os
import subprocess
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def t_of(secs):
    return np.arange(int(SR * secs)) / SR


def env(n, attack=0.002, decay=0.1):
    t = np.arange(n) / SR
    return np.minimum(t / attack, 1.0) * np.exp(-t / decay)


def noise(secs):
    return rng.standard_normal(int(SR * secs))


def band(x, lo, hi):
    return sosfilt(butter(4, [lo, hi], btype="band", fs=SR, output="sos"), x)


def low(x, hz):
    return sosfilt(butter(4, hz, btype="low", fs=SR, output="sos"), x)


def high(x, hz):
    return sosfilt(butter(4, hz, btype="high", fs=SR, output="sos"), x)


def tone(freq, secs, decay=0.1, attack=0.002, wave="sine"):
    t = t_of(secs)
    ph = 2 * np.pi * freq * t
    s = np.sin(ph) if wave == "sine" else np.sign(np.sin(ph)) * 0.6 + np.sin(ph) * 0.4
    return s * env(len(t), attack, decay)


def place(buf, clip, at):
    i = int(at * SR)
    end = min(len(buf), i + len(clip))
    buf[i:end] += clip[: end - i]


def save(name, x, peak=0.89):
    x = x / max(np.abs(x).max(), 1e-6) * peak
    with tempfile.TemporaryDirectory() as d:
        wav = os.path.join(d, name + ".wav")
        wavfile.write(wav, SR, (x * 32767).astype(np.int16))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5",
                        os.path.join(OUT, name + ".ogg")], check=True)


def loop_seam(x, fade=1.0):
    """Crossfades the tail into the head so the bed loops without a click."""
    n = int(SR * fade)
    w = np.linspace(0, 1, n)
    head = x[:n] * w + x[-n:] * (1 - w)
    return np.concatenate([head, x[n:-n]])


# A suppressor giving up: a hard metal crack, the baffles shaken loose, then three small pieces bouncing on the floor.
def suppressor_break():
    buf = np.zeros(int(SR * 1.1))
    crack = high(noise(0.05), 1500) * env(int(SR * 0.05), 0.0005, 0.012)
    place(buf, crack * 1.4, 0)
    for f, a, d in [(1180, 0.8, 0.22), (2630, 0.55, 0.16), (3910, 0.4, 0.1), (5400, 0.25, 0.07)]:
        place(buf, tone(f * 1.0, 0.4, d) * a, 0.002)
    place(buf, band(noise(0.25), 400, 3000) * env(int(SR * 0.25), 0.003, 0.07) * 0.5, 0.03)  # baffles rattling
    for at, f, a in [(0.17, 2200, 0.5), (0.27, 3100, 0.35), (0.36, 2700, 0.22), (0.43, 3300, 0.12)]:
        place(buf, (tone(f, 0.12, 0.025) + 0.6 * tone(f * 1.51, 0.12, 0.02)) * a, at)
    place(buf, low(noise(0.12), 250) * env(int(SR * 0.12), 0.001, 0.04) * 0.9, 0.0)  # the thump under it
    save("sfx_suppressor_break", buf)


# The Codec ring: a bright double chirp, twice. One ring per RING_EVERY in the screen.
def codec_ring():
    buf = np.zeros(int(SR * 0.8))
    for at in (0.0, 0.2):
        t = t_of(0.12)
        sweep = np.sin(2 * np.pi * (1750 * t + 2200 * t * t))
        place(buf, (sweep + 0.4 * np.sin(2 * np.pi * 3500 * t)) * env(len(t), 0.003, 0.06) * 0.6, at)
    save("sfx_codec_ring", buf)


def codec_answer():
    buf = np.zeros(int(SR * 0.4))
    place(buf, band(noise(0.08), 800, 5000) * env(int(SR * 0.08), 0.001, 0.03) * 0.5, 0)
    place(buf, tone(1320, 0.1, 0.04, wave="sq"), 0.02)
    place(buf, tone(1980, 0.16, 0.07, wave="sq"), 0.1)
    save("sfx_codec_answer", buf)


def codec_end():
    buf = np.zeros(int(SR * 0.45))
    place(buf, tone(1760, 0.09, 0.04, wave="sq"), 0)
    place(buf, tone(1175, 0.14, 0.07, wave="sq"), 0.08)
    place(buf, band(noise(0.22), 600, 4500) * env(int(SR * 0.22), 0.002, 0.07) * 0.4, 0.2)  # the line dropping
    save("sfx_codec_end", buf)


def intel_chime():
    buf = np.zeros(int(SR * 0.9))
    for at, f in [(0.0, 880), (0.09, 1320), (0.18, 1760)]:
        place(buf, (tone(f, 0.5, 0.18) + 0.3 * tone(f * 2, 0.5, 0.1)) * 0.7, at)
    save("sfx_intel", buf)


def camera_lock():
    buf = np.zeros(int(SR * 0.6))
    for at in (0.0, 0.14, 0.28):
        place(buf, tone(2400, 0.08, 0.04, wave="sq") * 0.8, at)
    place(buf, band(noise(0.5), 600, 1400) * env(int(SR * 0.5), 0.01, 0.2) * 0.15, 0)  # the servo
    save("sfx_camera_lock", buf)


# The cut between screens: a soft breath of air, a band-passed noise that opens upward and settles. Meant to sit far under the UI.
def transition():
    secs = 0.5
    n = noise(secs)
    out = np.zeros_like(n)
    parts = 8
    seg = len(n) // parts
    for i in range(parts):  # the passband climbs, segment by segment
        c = 350 * (6.0 ** (i / (parts - 1)))
        out[i * seg:(i + 1) * seg] = band(n, c * 0.7, c * 1.4)[i * seg:(i + 1) * seg]
    t = t_of(secs)
    bell = np.sin(np.pi * np.clip(t / secs, 0, 1)) ** 2
    save("sfx_transition", out * bell)


# Game Over: a sub boom with a dead-air tail, then (separately) a drone with a slowing heartbeat that ends in a flat tone.
def gameover_hit():
    buf = np.zeros(int(SR * 2.2))
    t = t_of(2.2)
    boom = np.sin(2 * np.pi * (70 * np.exp(-t * 1.2) + 28) * t) * np.exp(-t / 0.7)
    buf += boom * 1.0
    place(buf, low(noise(0.4), 900) * env(int(SR * 0.4), 0.001, 0.12) * 0.7, 0)
    place(buf, band(noise(1.6), 200, 2400) * env(int(SR * 1.6), 0.2, 0.6) * 0.12, 0.1)  # the line going dead
    save("sfx_gameover_hit", buf)


def gameover_drone():
    secs = 9.0
    t = t_of(secs)
    x = (np.sin(2 * np.pi * 55 * t) + 0.5 * np.sin(2 * np.pi * 82.5 * t + 0.4) + 0.25 * np.sin(2 * np.pi * 110.4 * t)) * 0.35
    x *= np.minimum(t / 2.0, 1.0) * np.minimum((secs - t) / 2.5, 1.0)
    x += low(noise(secs), 300) * 0.15 * np.minimum(t / 3.0, 1.0)
    at, gap = 0.5, 0.75
    while at < secs - 1.5:  # a heartbeat, slowing
        for off, a in ((0.0, 1.0), (0.22, 0.65)):
            place(x, np.sin(2 * np.pi * 52 * t_of(0.18)) * env(int(SR * 0.18), 0.004, 0.05) * a * 0.9, at + off)
        at += gap
        gap *= 1.16
    save("sfx_gameover_drone", x, 0.7)


# Mission complete: a short, quiet resolve in an open fifth, with a glassy tail.
def mission_complete():
    buf = np.zeros(int(SR * 2.4))
    for at, f in [(0.0, 392.0), (0.16, 587.3), (0.34, 784.0)]:
        place(buf, (tone(f, 1.8, 0.55) + 0.35 * tone(f * 2.01, 1.8, 0.3) + 0.15 * tone(f * 3.0, 1.8, 0.15)) * 0.6, at)
    place(buf, tone(196.0, 2.2, 0.9) * 0.5, 0.0)
    save("sfx_mission_complete", buf)


# The Scanner switching on: a rising sweep and a ping.
def scanner_on():
    buf = np.zeros(int(SR * 0.9))
    t = t_of(0.35)
    place(buf, np.sin(2 * np.pi * (500 * t + 2400 * t * t)) * env(len(t), 0.01, 0.2) * 0.5, 0)
    place(buf, (tone(2200, 0.6, 0.18) + 0.3 * tone(4400, 0.6, 0.08)) * 0.7, 0.3)
    save("sfx_scanner_on", buf)


# The freight lift's door: a grind along a rail, a clunk at the end.
def lift_door():
    buf = np.zeros(int(SR * 2.2))
    n = int(SR * 1.7)
    t = np.arange(n) / SR
    grind = band(noise(1.7), 80, 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t)) * np.minimum(t / 0.2, 1.0) * np.minimum((1.7 - t) / 0.3, 1.0)
    place(buf, grind * 0.6, 0.05)
    place(buf, band(noise(1.7), 1200, 3500) * 0.05 * np.minimum(t / 0.3, 1.0), 0.05)
    place(buf, tone(95, 0.5, 0.15) * 1.2, 1.7)
    place(buf, band(noise(0.1), 500, 3000) * env(int(SR * 0.1), 0.0005, 0.03) * 0.8, 1.7)
    save("sfx_lift_door", buf)


# Beds: slow-moving filtered noise.
def swell(secs, lo, hi, rate, depth):
    x = band(noise(secs), lo, hi)
    t = t_of(secs)
    lfo = 1.0 + depth * np.sin(2 * np.pi * rate * t) * np.sin(2 * np.pi * rate * 0.37 * t + 1.3)
    return x * lfo


def wind():
    x = swell(24, 120, 900, 0.11, 0.6) + 0.5 * swell(24, 900, 2600, 0.07, 0.8) * 0.4
    save("ambience_wind", loop_seam(x), 0.6)


def vent():
    x = low(noise(20), 500) * 0.7 + band(noise(20), 600, 2200) * 0.08
    x += 0.35 * np.sin(2 * np.pi * 60 * t_of(20)) + 0.2 * np.sin(2 * np.pi * 120.7 * t_of(20))
    save("ambience_vent", loop_seam(x), 0.6)


if __name__ == "__main__":
    for fn in (suppressor_break, codec_ring, codec_answer, codec_end, intel_chime, camera_lock, transition, gameover_hit, gameover_drone, mission_complete, scanner_on, lift_door, wind, vent):
        fn()
    print("ok")
