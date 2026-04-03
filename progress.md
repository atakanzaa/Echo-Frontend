# Echo iOS — Proje İlerleme Dosyası

> Bu dosya her büyük değişiklikten sonra güncellenir.
> Bağlamı anlamak için tüm kaynak dosyaları okumak yerine buraya bak.

---

## Proje Özeti

**Platform:** iOS (SwiftUI + Combine)  
**Mimari:** MVVM  
**Branch:** `claude/fix-project-translations-b1pkb`  
**API:** REST — `http://localhost:8080` (TokenManager ile auth)

### Klasör Yapısı
```
Echo/Echo/
├── *View.swift          — 20+ SwiftUI ekran dosyası
├── ViewModels/          — ObservableObject VM'ler (13 dosya)
├── Models/              — APIModels.swift, APIRequests.swift
├── Networking/          — APIClient, APIRouter, TokenManager
├── LocalizationManager.swift   ← YENİ (bu sessionda oluşturuldu)
└── Translations.swift          ← YENİ (bu sessionda oluşturuldu, henüz boş)
```

---

## Aktif Görev: Proje Geneli Çeviri Sistemi

### Problem
- Uygulama TR/EN karışık hardcoded text kullanıyor
- Settings'te dil değiştirme seçeneği yok
- Hiçbir i18n altyapısı mevcut değil

### Seçilen Yaklaşım
Swift Dictionary tabanlı çeviri (Xcode proje dosyası değişikliği gerektirmez):
- `LocalizationManager` → `@ObservableObject`, `currentLanguage`, `t(_ key:)`
- `Translations.swift` → tüm TR/EN stringleri içeren dictionary
- Her view `@EnvironmentObject var locManager: LocalizationManager` alır
- `EchoApp.swift` → `.environmentObject(locManager)` ile inject

### Tamamlananlar ✅
- [x] `LocalizationManager.swift` oluşturuldu
- [x] `Translations.swift` oluşturuldu (içerik henüz boş — doldurulacak)

### Yapılacaklar 🔲
- [ ] `Translations.swift` — tüm TR+EN stringleri doldur (200+ anahtar)
- [ ] `EchoApp.swift` — LocalizationManager inject et
- [ ] `SettingsView.swift` — Dil seçici ekle (Türkçe / English)
- [ ] `HamburgerMenu.swift` — 17 string çevir
- [ ] `BottomNavBar.swift` — 4 string çevir
- [ ] `ContentView.swift` — 13 string çevir
- [ ] `VoiceRecordingView.swift` — 8 mixed TR/EN string
- [ ] `CoachSessionsListView.swift` — 12 Turkish string
- [ ] `ReflectionCoachView.swift` — 3 Turkish string
- [ ] `JournalDetailView.swift` — 8 mixed string
- [ ] `JournalView.swift` — 3 string
- [ ] `CalendarView.swift` — gün kısaltmaları + 3 string
- [ ] `AuthenticationView.swift` — 25 string
- [ ] `CommunityView.swift` — 4 string
- [ ] `CreatePostView.swift` — 10 mixed TR/EN string
- [ ] `PostDetailView.swift` — 5 string
- [ ] `InsightsView.swift` — 10 string
- [ ] `AIInsightsView.swift` — 8 string
- [ ] `NotificationsView.swift` — 15 string
- [ ] `PremiumView.swift` — 17 string
- [ ] `TimeCapsuleView.swift` — 12 string
- [ ] `AchievementsView.swift` — 6 string
- [ ] `HelpSupportView.swift` — 5 string
- [ ] Commit & push

### Translation Key Kategorileri
```
common.*     → Sil, İptal, Tamam, Kaydet, İptal
nav.*        → Home, Community, Coach, Profile, Journal...
settings.*   → Settings view tüm metinler + dil seçici
journal.*    → Journal view metinler
coach.*      → Coach/Reflection metinler
auth.*       → Authentication metinler
community.*  → Community + CreatePost + PostDetail
insights.*   → Insights + AIInsights
calendar.*   → Calendar + gün kısaltmaları
profile.*    → Profile view
premium.*    → Premium view
timecapsule.*→ Time Capsule view
achievements.*→ Achievements view
notifications.*→ Notifications view
help.*       → Help & Support view
```

---

## Önemli Notlar

### Mevcut View Yapısı
- Her view `@Binding var selectedTab: String` alır
- Hamburger menü tüm view'larda: `HamburgerMenuView(isMenuOpen:selectedTab:)`
- İkincil sayfalar için ayrı `BottomNavigationView` var (Journal/Calendar/Insights/Settings)
- Ana 4 tab için `BottomNavBar` var (Home/Community/Coach/Profile)

### LocalizationManager Kullanımı
```swift
// Her view'da:
@EnvironmentObject var locManager: LocalizationManager

// Kullanım:
Text(locManager.t("settings.title"))
TextField(locManager.t("auth.email_placeholder"), text: $email)

// Format string:
locManager.t("coach.days_ago", day)  // "%d gün önce"
```

### Dil Değiştirme (SettingsView'da)
```swift
Picker("", selection: $locManager.currentLanguage) {
    Text("Türkçe").tag("tr")
    Text("English").tag("en")
}
.pickerStyle(.segmented)
```

---

## Sonraki Adım
**`Translations.swift` dosyasını tüm TR+EN stringleriyle doldur**, ardından EchoApp.swift'ten başlayarak view'ları güncelle.
