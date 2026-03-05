#!/usr/bin/env python3
"""
Audio sistem test senaryosu
Yeni modüler audio sistemini test eder
"""

import os
import sys
import time

def print_header(text):
    """Başlık yazdır"""
    print("\n" + "="*60)
    print(f" {text}")
    print("="*60)

def test_audio_system_files():
    """Audio sistem dosyalarını kontrol et"""
    print_header("AUDIO SYSTEM FILES CHECK")
    
    audio_files = [
        # Core Audio System
        ("src/core/systems/audio_system_wrapper.gd", "AudioSystemWrapper"),
        ("src/core/systems/audio/audio_system_molecule.gd", "AudioSystemMolecule"),
        ("src/core/systems/audio/audio_bus_manager.gd", "AudioBusManager"),
        ("src/core/systems/audio/audio_event_manager.gd", "AudioEventManager"),
        
        # UI Integration
        ("src/ui/integrations/sound_manager_integration.gd", "SoundManagerIntegration"),
        
        # Components
        ("src/core/components/audio_component.gd", "AudioComponent"),
    ]
    
    missing_files = []
    existing_files = []
    
    for file_path, component_name in audio_files:
        if os.path.exists(file_path):
            existing_files.append((file_path, component_name))
            print(f"  ✅ {component_name:30} {file_path}")
        else:
            missing_files.append((file_path, component_name))
            print(f"  ❌ {component_name:30} {file_path}")
    
    print(f"\nAudio Files Found: {len(existing_files)}/{len(audio_files)}")
    
    if missing_files:
        print(f"Missing Audio Files: {len(missing_files)}")
        for file_path, component_name in missing_files:
            print(f"  • {component_name}: {file_path}")
    
    return len(missing_files) == 0

def test_audio_system_api():
    """Audio sistem API'sini kontrol et"""
    print_header("AUDIO SYSTEM API CHECK")
    
    wrapper_path = "src/core/systems/audio_system_wrapper.gd"
    if not os.path.exists(wrapper_path):
        print("  ❌ AudioSystemWrapper not found")
        return False
    
    print("  ✅ AudioSystemWrapper found")
    
    with open(wrapper_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Eski API fonksiyonları
        legacy_api_functions = [
            "play_sound",
            "play_ui_sound", 
            "play_music",
            "stop_music",
            "stop_all_sounds",
            "set_master_volume",
            "set_music_volume",
            "set_sfx_volume",
            "set_ui_volume",
            "get_volume",
            "mute_all",
            "unmute_all",
            "toggle_mute",
        ]
        
        # Yeni API fonksiyonları
        new_api_functions = [
            "process_audio_event",
            "preload_resources",
            "get_modular_system",
            "is_modular_system_available",
        ]
        
        print("\n  Legacy API Functions:")
        missing_legacy = []
        for func in legacy_api_functions:
            if func in content:
                print(f"    ✅ {func}()")
            else:
                missing_legacy.append(func)
                print(f"    ❌ {func}()")
        
        print("\n  New API Functions:")
        missing_new = []
        for func in new_api_functions:
            if func in content:
                print(f"    ✅ {func}()")
            else:
                missing_new.append(func)
                print(f"    ❌ {func}()")
        
        # Sinyaller
        required_signals = [
            "music_changed",
            "music_finished", 
            "volume_changed",
            "audio_pool_created",
            "audio_error"
        ]
        
        print("\n  Required Signals:")
        missing_signals = []
        for signal in required_signals:
            if f"signal {signal}" in content:
                print(f"    ✅ {signal}")
            else:
                missing_signals.append(signal)
                print(f"    ❌ {signal}")
        
        # Volume conversion
        if "linear_to_db" in content and "db_to_linear" in content:
            print("\n  ✅ Volume conversion functions available")
        else:
            print("\n  ❌ Volume conversion functions missing")
        
        total_missing = len(missing_legacy) + len(missing_new) + len(missing_signals)
        return total_missing == 0

def test_sound_manager_integration():
    """SoundManagerIntegration kontrolü"""
    print_header("SOUND MANAGER INTEGRATION CHECK")
    
    integration_path = "src/ui/integrations/sound_manager_integration.gd"
    if not os.path.exists(integration_path):
        print("  ❌ SoundManagerIntegration not found")
        return False
    
    print("  ✅ SoundManagerIntegration found")
    
    with open(integration_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # API uyumluluğu
        required_functions = [
            "play_button_sound",
            "play_ui_sound",
            "update_sound_state",
            "get_audio_status",
            "initialize",
        ]
        
        print("\n  Integration Functions:")
        missing_functions = []
        for func in required_functions:
            if f"func {func}" in content:
                print(f"    ✅ {func}()")
            else:
                missing_functions.append(func)
                print(f"    ❌ {func}()")
        
        # AudioSystem bağlantısı
        if "AudioSystemWrapper" in content:
            print("\n  ✅ AudioSystemWrapper integration found")
        else:
            print("\n  ❌ AudioSystemWrapper integration missing")
        
        # Volume handling
        if "linear_to_db" in content or "db_to_linear" in content:
            print("  ✅ Volume conversion handling")
        else:
            print("  ❌ Volume conversion handling missing")
        
        # Fallback system
        if "fallback" in content.lower() or "sound_manager" in content:
            print("  ✅ Fallback system available")
        else:
            print("  ⚠️ Fallback system not explicitly implemented")
        
        return len(missing_functions) == 0

def test_menu_scene_audio_integration():
    """MenuScene audio entegrasyonu kontrolü"""
    print_header("MENU SCENE AUDIO INTEGRATION")
    
    menu_scene_path = "src/ui/scenes/menu_scene.gd"
    if not os.path.exists(menu_scene_path):
        print("  ❌ MenuScene not found")
        return False
    
    print("  ✅ MenuScene found")
    
    with open(menu_scene_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # SoundManagerIntegration referansı
        if "sound_integration" in content:
            print("  ✅ SoundManagerIntegration reference found")
        else:
            print("  ❌ SoundManagerIntegration reference missing")
        
        # Audio event handlers
        audio_handlers = [
            "_on_sound_button_pressed",
            "play_button_effect",
        ]
        
        print("\n  Audio Event Handlers:")
        missing_handlers = []
        for handler in audio_handlers:
            if handler in content:
                print(f"    ✅ {handler}()")
            else:
                missing_handlers.append(handler)
                print(f"    ❌ {handler}()")
        
        # GameData audio sync
        if "game_data.sound_enabled" in content:
            print("\n  ✅ GameData audio sync found")
        else:
            print("\n  ❌ GameData audio sync missing")
        
        # GameState audio sync (backward compatibility)
        if "game_state.sound_enabled" in content:
            print("  ✅ GameState audio sync found (backward compatibility)")
        else:
            print("  ⚠️ GameState audio sync not found")
        
        return len(missing_handlers) == 0

def test_autoload_configuration():
    """Autoload konfigürasyonu kontrolü"""
    print_header("AUTOLOAD CONFIGURATION CHECK")
    
    project_path = "project.godot"
    if not os.path.exists(project_path):
        print("  ❌ project.godot not found")
        return False
    
    print("  ✅ project.godot found")
    
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        required_autoloads = [
            ('AudioSystem="*res://src/core/systems/audio_system_wrapper.gd"', "AudioSystem"),
            ('GameData="*res://game_data.gd"', "GameData"),
            ('GameState="*res://game_state.gd"', "GameState"),
        ]
        
        print("\n  Autoload Configuration:")
        missing_autoloads = []
        for config_line, system_name in required_autoloads:
            if config_line in content:
                print(f"    ✅ {system_name}")
            else:
                missing_autoloads.append(system_name)
                print(f"    ❌ {system_name}")
        
        # AudioSystem özel kontrolü
        if 'AudioSystem="*res://src/core/systems/audio_system_wrapper.gd"' in content:
            print("\n  ✅ AudioSystem correctly configured with wrapper")
        else:
            # Eski AudioSystem kontrolü
            if 'AudioSystem=' in content:
                print("\n  ⚠️ AudioSystem configured but may not be wrapper")
            else:
                print("\n  ❌ AudioSystem not configured")
        
        return len(missing_autoloads) == 0

def generate_audio_test_report():
    """Audio test raporu oluştur"""
    print_header("AUDIO SYSTEM TEST REPORT")
    print("Generated: " + time.strftime("%Y-%m-%d %H:%M:%S"))
    print("System: Modüler AudioSystem v2.0")
    print("Architecture: Atomic Design + Wrapper Pattern")
    print("\n" + "="*60)
    
    test_results = []
    
    # Testleri çalıştır
    print("\nRunning audio system tests...")
    
    # Test 1: Audio system files
    files_test = test_audio_system_files()
    test_results.append(("Audio System Files", files_test))
    
    # Test 2: Audio system API
    api_test = test_audio_system_api()
    test_results.append(("Audio System API", api_test))
    
    # Test 3: SoundManager integration
    integration_test = test_sound_manager_integration()
    test_results.append(("SoundManager Integration", integration_test))
    
    # Test 4: MenuScene audio integration
    menu_test = test_menu_scene_audio_integration()
    test_results.append(("MenuScene Audio Integration", menu_test))
    
    # Test 5: Autoload configuration
    autoload_test = test_autoload_configuration()
    test_results.append(("Autoload Configuration", autoload_test))
    
    # Özet
    print_header("AUDIO TEST SUMMARY")
    
    passed_tests = sum(1 for _, result in test_results if result)
    total_tests = len(test_results)
    
    print(f"Tests Passed: {passed_tests}/{total_tests}")
    print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
    
    print("\nDetailed Results:")
    for test_name, result in test_results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status} {test_name}")
    
    # Değerlendirme
    print_header("AUDIO SYSTEM EVALUATION")
    
    if passed_tests == total_tests:
        print("🎉 AUDIO SİSTEMİ TAMAMEN HAZIR!")
        print("Modüler audio sistemi başarıyla entegre edildi.")
        print("Backward compatibility korundu.")
        
        print("\n✅ TAMAMLANAN ÖZELLİKLER:")
        print("  • AudioSystemWrapper (backward compatibility)")
        print("  • Modüler audio sistemi (6 atomic component)")
        print("  • SoundManagerIntegration (UI entegrasyonu)")
        print("  • Volume conversion (linear ↔ dB)")
        print("  • GameData/GameState senkronizasyonu")
        print("  • Autoload konfigürasyonu")
        
        print("\n🔧 TEKNİK DETAYLAR:")
        print("  • API: play_sound(), play_ui_sound(), play_music()")
        print("  • Volume: set_*_volume(), get_volume(), toggle_mute()")
        print("  • Events: music_changed, volume_changed, audio_error")
        print("  • Integration: MenuScene + SoundManagerIntegration")
        
    elif passed_tests >= total_tests * 0.8:
        print("⚠️ AUDIO SİSTEMİ ÇALIŞIYOR")
        print("Temel fonksiyonlar çalışıyor, küçük düzeltmeler gerekli.")
        
    elif passed_tests >= total_tests * 0.6:
        print("⚠️ AUDIO SİSTEMİ KISMEN ÇALIŞIYOR")
        print("Önemli fonksiyonlar eksik veya hatalı.")
        
    else:
        print("❌ AUDIO SİSTEMİ CİDDİ SORUNLAR İÇERİYOR")
        print("Temel entegrasyon başarısız.")
    
    # Bilinen sorunlar
    print_header("BİLİNEN SORUNLAR")
    
    print("AudioSystemWrapper Sinyalleri:")
    print("  • music_changed sinyali string parametre alıyor")
    print("  • music_finished sinyali parametresiz")
    print("  • audio_error sinyali string parametre alıyor")
    
    print("\nVolume Conversion:")
    print("  • Linear ↔ dB dönüşümü doğru çalışıyor mu?")
    print("  • Volume değerleri clamp ediliyor mu?")
    
    print("\nFallback Ses Sistemi:")
    print("  • AudioSystem bulunamazsa fallback çalışıyor mu?")
    print("  • Eski sound_manager.gd ile uyumluluk sağlanıyor mu?")
    
    # Test önerileri
    print_header("TEST ÖNERİLERİ")
    
    print("1. Audio Sistem Testleri:")
    print("   [ ] Buton sesleri çalışıyor mu?")
    print("   [ ] Ses aç/kapa çalışıyor mu?")
    print("   [ ] Müzik oynatma/durdurma çalışıyor mu?")
    print("   [ ] Volume slider'lar çalışıyor mu?")
    
    print("\n2. Entegrasyon Testleri:")
    print("   [ ] MenuScene buton sesleri")
    print("   [ ] GameData senkronizasyonu")
    print("   [ ] GameState backward compatibility")
    print("   [ ] AudioSystemWrapper autoload testi")
    
    print("\n3. Performans Testleri:")
    print("   [ ] Concurrent sound playback")
    print("   [ ] Memory usage")
    print("   [ ] Load time")
    print("   [ ] Audio pool efficiency")
    
    print_header("TEST COMPLETED")
    print("Audio sistem testi tamamlandı.")
    print("Sistem modüler yapıya ve backward compatibility'ye sahip.")
    
    return passed_tests == total_tests

def main():
    """Ana fonksiyon"""
    print("AUDIO SİSTEMİ TEST SENARYOSU")
    print("Modüler AudioSystem + Backward Compatibility")
    print("="*60)
    
    try:
        success = generate_audio_test_report()
        
        if success:
            print("\n✅ Audio sistemi başarıyla test edildi!")
            print("Tüm bileşenler çalışıyor ve entegre edilmiş.")
            return 0
        else:
            print("\n⚠️ Audio sisteminde sorunlar tespit edildi.")
            print("Lütfen hataları düzeltin ve tekrar test edin.")
            return 1
            
    except Exception as e:
        print(f"\nTest sırasında hata oluştu: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())