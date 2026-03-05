#!/usr/bin/env python3
"""
Basit placeholder ses dosyalari olusturur.
WAV formatinda basit sesler uretir.
"""

import wave
import struct
import math
import os

def create_sine_wave(frequency=440, duration=0.1, volume=0.5, sample_rate=44100):
    """Basit bir sine wave olustur"""
    num_samples = int(duration * sample_rate)
    samples = []
    
    for i in range(num_samples):
        # Sine wave
        sample = volume * math.sin(2 * math.pi * frequency * i / sample_rate)
        # Envelope (attack-decay)
        envelope = 1.0
        if i < int(0.1 * num_samples):  # Attack
            envelope = i / (0.1 * num_samples)
        elif i > int(0.7 * num_samples):  # Release
            envelope = 1.0 - (i - 0.7 * num_samples) / (0.3 * num_samples)
        
        sample *= envelope
        samples.append(sample)
    
    return samples

def create_click_sound():
    """Tiklama sesi"""
    return create_sine_wave(frequency=1000, duration=0.05, volume=0.3)

def create_shoot_sound():
    """Ates sesi"""
    samples = []
    # Kisa bir atak
    samples.extend(create_sine_wave(frequency=800, duration=0.02, volume=0.8))
    # Dusen frekans
    samples.extend(create_sine_wave(frequency=400, duration=0.08, volume=0.4))
    return samples

def create_hit_sound():
    """Hasar sesi"""
    samples = []
    # Keskin atak
    samples.extend(create_sine_wave(frequency=1200, duration=0.03, volume=0.7))
    # Dusuk frekansli rezonans
    samples.extend(create_sine_wave(frequency=300, duration=0.17, volume=0.3))
    return samples

def create_hurt_sound():
    """Can azalma sesi"""
    samples = []
    # Keskin atak
    samples.extend(create_sine_wave(frequency=800, duration=0.05, volume=0.6))
    # Dusen frekans
    samples.extend(create_sine_wave(frequency=200, duration=0.15, volume=0.4))
    return samples

def create_level_up_sound():
    """Seviye atlama sesi"""
    samples = []
    # Yukselen frekans
    for freq in range(300, 1000, 100):
        samples.extend(create_sine_wave(frequency=freq, duration=0.03, volume=0.5))
    # Glissando efekti
    samples.extend(create_sine_wave(frequency=1000, duration=0.2, volume=0.3))
    return samples

def create_enemy_die_sound():
    """Dusman olme sesi"""
    samples = []
    # Yuksek frekansli atak
    samples.extend(create_sine_wave(frequency=1000, duration=0.05, volume=0.7))
    # Cok dusuk frekans
    samples.extend(create_sine_wave(frequency=100, duration=0.3, volume=0.5))
    return samples

def create_xp_collect_sound():
    """XP toplama sesi"""
    samples = []
    # Parlayan ses
    for freq in range(500, 800, 50):
        samples.extend(create_sine_wave(frequency=freq, duration=0.02, volume=0.4))
    # Kisa bir cınlama
    samples.extend(create_sine_wave(frequency=1000, duration=0.1, volume=0.3))
    return samples

def create_explosion_sound():
    """Patlama sesi"""
    samples = []
    # Yuksek frekansli atak
    samples.extend(create_sine_wave(frequency=1500, duration=0.05, volume=0.9))
    # Dusen frekans
    samples.extend(create_sine_wave(frequency=200, duration=0.45, volume=0.5))
    return samples

def create_pickup_sound():
    """Item alma sesi"""
    samples = []
    # Yukselen frekans
    for freq in range(400, 800, 50):
        samples.extend(create_sine_wave(frequency=freq, duration=0.02, volume=0.4))
    return samples

def create_background_music():
    """Basit arka plan muzigi"""
    samples = []
    # Basit bir akor progresyonu
    chords = [
        (261.63, 329.63, 392.00),  # C major
        (293.66, 369.99, 440.00),  # D minor
        (329.63, 415.30, 493.88),  # E minor
        (349.23, 440.00, 523.25),  # F major
    ]
    
    for chord in chords:
        for note in chord:
            samples.extend(create_sine_wave(frequency=note/2, duration=0.5, volume=0.1))
    
    return samples

def save_wav(filename, samples, sample_rate=44100):
    """Samples'i WAV dosyasi olarak kaydet"""
    # 16-bit PCM format
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes = 16 bits
        wav_file.setframerate(sample_rate)
        
        # Samples'i 16-bit integer'a cevir
        max_amplitude = 32767  # 16-bit signed integer max
        for sample in samples:
            # Clamp sample to [-1, 1]
            sample = max(-1.0, min(1.0, sample))
            # Convert to 16-bit integer
            int_sample = int(sample * max_amplitude)
            # Write as little-endian
            wav_file.writeframes(struct.pack('<h', int_sample))

def main():
    """Ana fonksiyon"""
    print("Placeholder ses dosyalari olusturuluyor...")
    
    # SFX sesleri - KODDA KULLANILAN ISIMLERLE
    sfx_files = {
        "shoot.wav": create_shoot_sound,
        "hurt.wav": create_hurt_sound,
        "level_up.wav": create_level_up_sound,
        "enemy_die.wav": create_enemy_die_sound,
        "xp_collect.wav": create_xp_collect_sound,
        "explosion.wav": create_explosion_sound,
        "pickup.wav": create_pickup_sound,
    }
    
    # Muzik
    music_files = {
        "background_music.wav": create_background_music,
    }
    
    # UI sesleri
    ui_files = {
        "click.wav": create_click_sound,  # KODDA: AudioSystem.play_ui_sound("click")
        "hover.wav": lambda: create_sine_wave(frequency=600, duration=0.1, volume=0.2),
        "select.wav": lambda: create_sine_wave(frequency=800, duration=0.15, volume=0.3),
    }
    
    # Dosyalari olustur
    for filename, create_func in sfx_files.items():
        filepath = os.path.join("assets", "audio", "sfx", filename)
        print(f"Olusturuluyor: {filepath}")
        samples = create_func()
        save_wav(filepath, samples)
    
    for filename, create_func in music_files.items():
        filepath = os.path.join("assets", "audio", "music", filename)
        print(f"Olusturuluyor: {filepath}")
        samples = create_func()
        save_wav(filepath, samples)
    
    for filename, create_func in ui_files.items():
        filepath = os.path.join("assets", "audio", "ui", filename)
        print(f"Olusturuluyor: {filepath}")
        samples = create_func()
        save_wav(filepath, samples)
    
    print("\nTum placeholder ses dosyalari olusturuldu!")
    print("SFX: assets/audio/sfx/")
    print("Muzik: assets/audio/music/")
    print("UI: assets/audio/ui/")
    print("\nKodda kullanilan ses isimleri:")
    print("- AudioSystem.play_sound('shoot')")
    print("- AudioSystem.play_sound('hurt')")
    print("- AudioSystem.play_sound('level_up')")
    print("- AudioSystem.play_sound('enemy_die')")
    print("- AudioSystem.play_sound('xp_collect')")
    print("- AudioSystem.play_ui_sound('click')")

if __name__ == "__main__":
    main()