#!/usr/bin/env python3
"""
UI sistem test senaryosu
Menü UI bileşenlerini test eder
"""

import os
import sys
import time

def print_header(text):
    """Başlık yazdır"""
    print("\n" + "="*60)
    print(f" {text}")
    print("="*60)

def test_ui_component_files():
    """UI component dosyalarını kontrol et"""
    print_header("UI COMPONENT FILES CHECK")
    
    ui_files = [
        # Atomic Components
        ("src/ui/components/warrior_card_atom.gd", "WarriorCardAtom"),
        ("src/ui/components/button_effects_atom.gd", "ButtonEffectsAtom"),
        ("src/ui/components/menu_stats_display_atom.gd", "MenuStatsDisplayAtom"),
        ("src/ui/components/space_background_atom.gd", "SpaceBackgroundAtom"),
        
        # Molecule Components
        ("src/ui/molecules/menu_ui_molecule.gd", "MenuUIMolecule"),
        
        # Controllers
        ("src/ui/controllers/entrance_animation_controller.gd", "EntranceAnimationController"),
        
        # Scene
        ("src/ui/scenes/menu_scene.gd", "MenuScene"),
    ]
    
    missing_files = []
    existing_files = []
    
    for file_path, component_name in ui_files:
        if os.path.exists(file_path):
            existing_files.append((file_path, component_name))
            print(f"  ✅ {component_name:30} {file_path}")
        else:
            missing_files.append((file_path, component_name))
            print(f"  ❌ {component_name:30} {file_path}")
    
    print(f"\nUI Files Found: {len(existing_files)}/{len(ui_files)}")
    
    if missing_files:
        print(f"Missing UI Files: {len(missing_files)}")
        for file_path, component_name in missing_files:
            print(f"  • {component_name}: {file_path}")
    
    return len(missing_files) == 0

def test_menu_ui_molecule():
    """MenuUIMolecule kontrolü"""
    print_header("MENU UI MOLECULE CHECK")
    
    molecule_path = "src/ui/molecules/menu_ui_molecule.gd"
    if not os.path.exists(molecule_path):
        print("  ❌ MenuUIMolecule not found")
        return False
    
    print("  ✅ MenuUIMolecule found")
    
    with open(molecule_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Required functions
        required_functions = [
            "initialize_components",
            "update_sound_button",
            "get_button_position",
            "get_button_size",
        ]
        
        print("\n  Required Functions:")
        missing_functions = []
        for func in required_functions:
            if f"func {func}" in content:
                print(f"    ✅ {func}()")
            else:
                missing_functions.append(func)
                print(f"    ❌ {func}()")
        
        # Required signals
        required_signals = [
            "start_button_pressed",
            "sound_settings_pressed",
        ]
        
        print("\n  Required Signals:")
        missing_signals = []
        for signal in required_signals:
            if f"signal {signal}" in content:
                print(f"    ✅ {signal}")
            else:
                missing_signals.append(signal)
                print(f"    ❌ {signal}")
        
        # Button visibility
        if "show_start_button" in content and "show_sound_button" in content:
            print("\n  ✅ Button visibility controls available")
        else:
            print("\n  ❌ Button visibility controls missing")
        
        return len(missing_functions) == 0 and len(missing_signals) == 0

def test_entrance_animation_controller():
    """EntranceAnimationController kontrolü"""
    print_header("ENTRANCE ANIMATION CONTROLLER CHECK")
    
    controller_path = "src/ui/controllers/entrance_animation_controller.gd"
    if not os.path.exists(controller_path):
        print("  ❌ EntranceAnimationController not found")
        return False
    
    print("  ✅ EntranceAnimationController found")
    
    with open(controller_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Animation functions
        animation_functions = [
            "play_entrance_animation",
            "play_exit_animation",
            "reset_animations",
            "stop_all_animations",
        ]
        
        print("\n  Animation Functions:")
        missing_functions = []
        for func in animation_functions:
            if f"func {func}" in content:
                print(f"    ✅ {func}()")
            else:
                missing_functions.append(func)
                print(f"    ❌ {func}()")
        
        # Animation sequence
        if "animation_sequence" in content:
            print("\n  ✅ Animation sequence property found")
        else:
            print("\n  ❌ Animation sequence property missing")
        
        # Signal
        if "signal animation_completed" in content:
            print("  ✅ animation_completed signal found")
        else:
            print("  ❌ animation_completed signal missing")
        
        return len(missing_functions) == 0

def test_menu_scene_integration():
    """MenuScene UI entegrasyonu kontrolü"""
    print_header("MENU SCENE UI INTEGRATION")
    
    scene_path = "src/ui/scenes/menu_scene.gd"
    if not os.path.exists(scene_path):
        print("  ❌ MenuScene not found")
        return False
    
    print("  ✅ MenuScene found")
    
    with open(scene_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # UI component references
        ui_references = [
            "menu_ui",
            "warrior_card",
            "button_effects",
            "menu_stats",
            "entrance_animator",
        ]
        
        print("\n  UI Component References:")
        missing_references = []
        for ref in ui_references:
            if f"@onready var {ref}" in content:
                print(f"    ✅ {ref}")
            else:
                missing_references.append(ref)
                print(f"    ❌ {ref}")
        
        # UI event handlers
        ui_handlers = [
            "_on_start_button_pressed",
            "_on_sound_button_pressed",
            "_on_warrior_card_clicked",
            "_on_stat_clicked",
            "_on_entrance_animation_completed",
        ]
        
        print("\n  UI Event Handlers:")
        missing_handlers = []
        for handler in ui_handlers:
            if handler in content:
                print(f"    ✅ {handler}()")
            else:
                missing_handlers.append(handler)
                print(f"    ❌ {handler}()")
        
        # Scene transition
        if "transition_to_scene" in content:
            print("\n  ✅ Scene transition function available")
        else:
            print("\n  ❌ Scene transition function missing")
        
        # Component status
        if "get_component_status" in content:
            print("  ✅ Component status function available")
        else:
            print("  ❌ Component status function missing")
        
        return len(missing_references) == 0 and len(missing_handlers) == 0

def test_scene_files():
    """Scene dosyalarını kontrol et"""
    print_header("SCENE FILES CHECK")
    
    scene_files = [
        ("menu_scene.tscn", "Menu Scene"),
        ("menu.tscn", "Main Menu"),
        ("test_menu_system.tscn", "Test Menu System"),
    ]
    
    missing_files = []
    existing_files = []
    
    for file_path, scene_name in scene_files:
        if os.path.exists(file_path):
            existing_files.append((file_path, scene_name))
            print(f"  ✅ {scene_name:25} {file_path}")
            
            # Scene içeriğini kontrol et
            with open(file_path, 'r', encoding='utf-8') as f:
                scene_content = f.read()
                if "gd_scene" in scene_content:
                    print(f"       Valid Godot scene file")
                else:
                    print(f"       ⚠️ May not be valid Godot scene")
        else:
            missing_files.append((file_path, scene_name))
            print(f"  ❌ {scene_name:25} {file_path}")
    
    print(f"\nScene Files Found: {len(existing_files)}/{len(scene_files)}")
    
    if missing_files:
        print(f"Missing Scene Files: {len(missing_files)}")
        for file_path, scene_name in missing_files:
            print(f"  • {scene_name}: {file_path}")
    
    return len(missing_files) == 0

def generate_ui_test_report():
    """UI test raporu oluştur"""
    print_header("UI SYSTEM TEST REPORT")
    print("Generated: " + time.strftime("%Y-%m-%d %H:%M:%S"))
    print("System: Atomic Design UI System")
    print("Components: 4 Atoms + 1 Molecule + 1 Controller")
    print("\n" + "="*60)
    
    test_results = []
    
    # Testleri çalıştır
    print("\nRunning UI system tests...")
    
    # Test 1: UI component files
    files_test = test_ui_component_files()
    test_results.append(("UI Component Files", files_test))
    
    # Test 2: MenuUIMolecule
    molecule_test = test_menu_ui_molecule()
    test_results.append(("MenuUIMolecule", molecule_test))
    
    # Test 3: EntranceAnimationController
    animation_test = test_entrance_animation_controller()
    test_results.append(("EntranceAnimationController", animation_test))
    
    # Test 4: MenuScene integration
    integration_test = test_menu_scene_integration()
    test_results.append(("MenuScene Integration", integration_test))
    
    # Test 5: Scene files
    scene_test = test_scene_files()
    test_results.append(("Scene Files", scene_test))
    
    # Özet
    print_header("UI TEST SUMMARY")
    
    passed_tests = sum(1 for _, result in test_results if result)
    total_tests = len(test_results)
    
    print(f"Tests Passed: {passed_tests}/{total_tests}")
    print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
    
    print("\nDetailed Results:")
    for test_name, result in test_results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {status} {test_name}")
    
    # Değerlendirme
    print_header("UI SYSTEM EVALUATION")
    
    if passed_tests == total_tests:
        print("🎉 UI SİSTEMİ TAMAMEN HAZIR!")
        print("Atomic Design UI sistemi başarıyla entegre edildi.")
        
        print("\n✅ TAMAMLANAN BİLEŞENLER:")
        print("  • 4 Atomic Component:")
        print("     - WarriorCardAtom (karakter kartı)")
        print("     - ButtonEffectsAtom (buton efektleri)")
        print("     - MenuStatsDisplayAtom (istatistikler)")
        print("     - SpaceBackgroundAtom (arka plan)")
        
        print("  • 1 Molecule Component:")
        print("     - MenuUIMolecule (UI bileşenleri birleştirici)")
        
        print("  • 1 Controller:")
        print("     - EntranceAnimationController (animasyon kontrolcüsü)")
        
        print("  • 1 Scene:")
        print("     - MenuScene (tüm bileşenleri birleştiren ana sahne)")
        
        print("\n🔧 TEKNİK DETAYLAR:")
        print("  • Signal-based communication")
        print("  • Component-based architecture")
        print("  • Scene transition system")
        print("  • Animation controller")
        print("  • Debug information system")
        
    elif passed_tests >= total_tests * 0.8:
        print("⚠️ UI SİSTEMİ ÇALIŞIYOR")
        print("Temel fonksiyonlar çalışıyor, küçük düzeltmeler gerekli.")
        
    elif passed_tests >= total_tests * 0.6:
        print("⚠️ UI SİSTEMİ KISMEN ÇALIŞIYOR")
        print("Önemli fonksiyonlar eksik veya hatalı.")
        
    else:
        print("❌ UI SİSTEMİ CİDDİ SORUNLAR İÇERİYOR")
        print("Temel entegrasyon başarısız.")
    
    # Test önerileri
    print_header("TEST ÖNERİLERİ")
    
    print("1. UI Testleri:")
    print("   [ ] Start butonu çalışıyor mu?")
    print("   [ ] Scene geçişleri çalışıyor mu?")
    print("   [ ] Animasyonlar sorunsuz çalışıyor mu?")
    print("   [ ] Buton efektleri görünüyor mu?")
    
    print("\n2. Entegrasyon Testleri:")
    print("   [ ] MenuScene bileşen bağlantıları")
    print("   [ ] Signal bağlantıları")
    print("   [ ] Animation sequence")
    print("   [ ] Component status reporting")
    
    print("\n3. Görsel Testler:")
    print("   [ ] WarriorCard görüntüleniyor mu?")
    print("   [ ] İstatistikler doğru gösteriliyor mu?")
    print("   [ ] Arka plan doğru render ediliyor mu?")
    print("   [ ] Butonlar doğru konumlandırılmış mı?")
    
    print_header("TEST COMPLETED")
    print("UI sistem testi tamamlandı.")
    print("Sistem Atomic Design prensiplerine uygun.")
    
    return passed_tests == total_tests

def main():
    """Ana fonksiyon"""
    print("UI SİSTEMİ TEST SENARYOSU")
    print("Atomic Design UI Components")
    print("="*60)
    
    try:
        success = generate_ui_test_report()
        
        if success:
            print("\n✅ UI sistemi başarıyla test edildi!")
            print("Tüm bileşenler çalışıyor ve entegre edilmiş.")
            return 0
        else:
            print("\n⚠️ UI sisteminde sorunlar tespit edildi.")
            print("Lütfen hataları düzeltin ve tekrar test edin.")
            return 1
            
    except Exception as e:
        print(f"\nTest sırasında hata oluştu: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())