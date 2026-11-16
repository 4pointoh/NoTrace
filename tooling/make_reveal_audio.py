"""Synthesizes the placeholder build-up sound for the portrait -> landscape reveal.

    python tooling/make_reveal_audio.py

Writes src/cinematic/reveal/reveal_build.wav (stereo, 44.1 kHz): a breeze that swells in
one smooth curve for BUILD seconds, peaks, and passes. Deliberately:
  - unpitched, so it cannot clash with whatever key the incoming music is in
  - free of tremolo, pulsing or pitch sweeps, which read as sci-fi rather than romance
There is no impact sound: the hit at the end of the build is the music's own downbeat
(see musicDownbeat on LandscapeRevealConfig).

Replace it with real sound design whenever you like. Only the time of its peak matters to the
choreography, and that must match buildDuration on the LandscapeReveal scene.
"""
import os
import wave

import numpy as np

RATE = 44100
BUILD = 2.88    # seconds from silence to the peak. Keep in sync with buildDuration.
RELEASE = 1.1   # the gust passing, under the first bar of the music
OUT = os.path.join(os.path.dirname(__file__), "..", "src", "cinematic", "reveal")
rng = np.random.default_rng(11)


def wind(count, low, high, tilt):
    """Noise limited to a band, with energy falling off toward the top (tilt) so it is soft, not hissy."""
    spectrum = np.fft.rfft(rng.standard_normal(count))
    freqs = np.fft.rfftfreq(count, 1 / RATE)
    shape = np.where((freqs >= low) & (freqs <= high), 1.0 / np.maximum(freqs, low) ** tilt, 0.0)
    out = np.fft.irfft(spectrum * shape, count)
    return out / (np.abs(out).max() + 1e-9)


def build():
    count = int((BUILD + RELEASE) * RATE)
    t = np.arange(count) / RATE
    x = np.clip(t / BUILD, 0, 1)

    # One smooth curve up to the peak, then the gust dies away. No modulation of any kind.
    swell = np.where(t <= BUILD, x ** 2.2, np.exp(-(t - BUILD) * 4.2))
    # The air brightens slightly as it grows, which gives a sense of opening without any pitch.
    bright = np.where(t <= BUILD, x ** 3.2, np.exp(-(t - BUILD) * 6.0))

    channels = []
    for _ in range(2):  # independent noise per ear, so it surrounds rather than sits in the middle
        body = wind(count, 110, 1100, 0.9) * swell
        air = wind(count, 900, 4200, 0.6) * bright * 0.3
        channels.append(body + air)
    stereo = np.array(channels)

    fade_in = int(0.08 * RATE)
    stereo[:, :fade_in] *= np.linspace(0, 1, fade_in)
    stereo[:, -int(0.05 * RATE):] *= np.linspace(1, 0, int(0.05 * RATE))
    return stereo


def save(name, stereo, peak_db):
    stereo = stereo / (np.abs(stereo).max() + 1e-9) * 10 ** (peak_db / 20)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes((stereo.T * 32767).astype("<i2").tobytes())
    print(f"{name}: {stereo.shape[-1] / RATE:.2f} s, peak {peak_db} dB")


if __name__ == "__main__":
    save("reveal_build.wav", build(), -8)
