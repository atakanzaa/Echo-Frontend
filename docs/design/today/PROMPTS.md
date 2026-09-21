# Claude Code istemleri — Bugün ekranı

Sırayla, her adım ayrı bir oturum/commit olacak şekilde kullan. Her adımdan sonra Xcode Preview'da PNG'lerle karşılaştır.

## 1 · Keşif ve plan
```
docs/design/today/HANDOFF.md dosyasını ve docs/design/today/screens/ altındaki PNG'leri incele.
Ardından Features/Today, DesignSystem/Components ve DesignSystem/Tokens klasörlerini oku.
Kod yazmadan önce: hangi bileşenleri genişleteceğini, hangilerini yeni açacağını ve TodayViewModel'e
eklenecek yüklemeleri listeleyen kısa bir plan çıkar. HANDOFF §0'daki kurallara aykırı bir şey görürsen belirt.
```

## 2 · Token'lar ve temel bileşenler
```
HANDOFF §3 ve §5'e göre: EchoTextStyle'a .sectionTitle ve .question ekle; EchoMoodShape'in .low/.good
yönünü preview'da doğrula; statik EchoRings, MoodLegend ve TrendBadge bileşenlerini yaz. Her biri için
koyu+açık #Preview ekle. Açık tema mood asset düzeltmesini (§3) ayrı bir commit olarak yap.
```

## 3 · Veri görselleri ve satırlar
```
HANDOFF §5'e göre WeekMoodStrip (Canvas), WeeklyPanel, genişletilmiş EchoTimelineRow (completed/processing/failed),
PastTodayBlock, EchoChecklistRow tamamlanmış durumu, GoalSuggestionRow, BadgeProgressRing, CapsuleRow,
KnowsYouCoachBlock ve OfflineStrip bileşenlerini yaz. screens/90-bilesenler-koyu.png ve 91-bilesenler-acik.png
referans. Tüm renk/font/boşluk AppTheme'den; yeni sabit değer yok.
```

## 4 · ViewModel ve ekran
```
HANDOFF §4'e göre TodayViewModel'e user, weekly (insights 7), weekSummary, profile, achievements, capsules,
lastCoachSession yüklemelerini paralel ekle; her biri bağımsız başarısız olabilsin. TodayView'ı §2 sırası ve
§11 durum kurallarıyla yeniden kur; §6'daki dokunma hedeflerini bağla; §10'daki yerelleştirme anahtarlarını ekle.
EchoMockData ile 4 durum için #Preview oluştur (koyu/açık).
```

## 5 · Cila ve doğrulama
```
HANDOFF §7 (Dynamic Type), §8 (hareket), §9 (erişilebilirlik) ve §12 kabul listesini uygula ve tek tek kontrol et.
Build al; uyarıları temizle. Kabul listesindeki her maddeyi karşılayıp karşılamadığını raporla.
```
