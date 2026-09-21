# Bugün (Today) ekranı — tasarım teslimi

> Claude Code için: Bu dosyayı ve `screens/` altındaki PNG'leri **birlikte** oku. PNG'ler görsel hedeftir;
> sayılar, kurallar ve veri eşlemesi bu dosyadadır. Çelişki olursa bu dosya kazanır.
> PNG'ler Linux'ta yedek fontlarla çizildi (SF Pro / New York yok); tipografiyi PNG'den değil §3'ten al.

Kaynak tasarım: claude.ai Design kanvası "Echo · Bugün" (15 çerçeve). `source/` altındaki `.dc.html`
dosyaları kanvasın ham kaynağıdır; kesin bir ölçüye bakman gerekirse oradan okunabilir, **koda taşınmaz**.

---

## 0. Değişmez kurallar

1. **İstemci değer hesaplamaz.** Sayaçlar, ortalamalar, streak, trend, "bugün kayıt var mı" hep sunucudan gelir.
   Bir listeyi sayıp sayaç üretme; `GoalStats`, `AuthenticatedUser`, `AIInsights` alanlarını kullan.
2. **Sahte sıfır yok.** `nil` / veri yok → bölüm gizlenir ya da anlamlı boş durum gösterilir. "0", "0,00" asla.
3. **Mood asla yalnız renkle verilmez.** Her mood işareti `EchoMoodShape` şekli + etiket ya da erişilebilirlik metniyle.
4. **Dolu, büyük kayıt düğmesi yalnız sekme çubuğunda.** Günün sorusundaki eylem metin düzeyindedir (dolu daire yok).
5. **Kart yığını yok.** Sayfada tek dolgu yüzeyi "Son 7 gün" paneli. Diğer bölümler tipografi, boşluk ve ince çizgiyle ayrılır.
6. Tüm renk/font/boşluk `AppTheme` facade'ından gelir (mevcut kural). Yeni değer gerekirse token olarak eklenir.
7. Gradient blob, cam küre, ✨ yok. Tek süs motifi: eş merkezli halkalar (yankı).

## 1. Ekranlar (`screens/`)

| Dosya | Durum |
|---|---|
| `00-veri-notlari-ve-dokunma-haritasi.png` | Durum 2, tam sayfa, her bloğun yanında veri alanı + dokunma hedefi + boş durum |
| `01-yeni-kullanici-{koyu,acik}.png`, `01-…-tamsayfa-koyu.png` | 0 kayıt |
| `02-sabah-{koyu,acik}.png` | Düzenli kullanıcı, bugün kayıt yok |
| `02-sabah-buyukyazi-{koyu,acik}.png` | Aynı, Dynamic Type xxxLarge |
| `03-aksam-{koyu,acik}.png`, `03-…-tamsayfa-acik.png` | Bugün 2 kayıt, biri analizde |
| `04-cevrimdisi-{koyu,acik}.png` | Çevrimdışı şeridi + analiz hatası |
| `90/91-bilesenler-*.png` | Yeni/değişen bileşenler, ölçüleri ve durumları |

Çerçeve: iPhone 17 Pro, 402×874 pt. Durum çubuğu yalnız referans; kodda çizilmez.

## 2. Sayfa yapısı (yukarıdan aşağı)

`ScrollView` > `LazyVStack(alignment: .leading, spacing: 0)`; bölümler arası `AppTheme.layout.sectionGap` (32),
yatay kenar `AppTheme.layout.screenHorizontalPadding` (20). Alt boşluk sekme çubuğuna göre `safeAreaInset`.

| # | Blok | Durum 1 | Durum 2 (sabah) | Durum 3 (akşam) | Durum 4 |
|---|---|---|---|---|---|
| a | Çevrimdışı şeridi | – | – | – | ✔ en üstte |
| b | Günün girişi (tarih, selam, seri, zil) | ✔ | ✔ | ✔ | ✔ |
| c | Bugünün kayıtları (zaman çizelgesi) | – | – | ✔ | ✔ (2. kayıt başarısız) |
| d | Günün sorusu (hero) | karşılama metni | ✔ | ✔ | ✔ |
| e | Kapsül satırı | – | açılabilir (amber) | sıradaki tarih (nötr) | nötr |
| f | Son 7 gün paneli (şerit + yansıma + temalar) | boş şerit + lejant | ✔ | ✔ (bugün dolu) | ✔ |
| g | "İlk kaydından sonra" açıklaması | ✔ | – | – | – |
| h | Geçmişte bugün | – | ✔ | ✔ | ✔ |
| i | Hedefler + AI önerisi | tek "hedef koy" satırı | ✔ | ✔ (biri işaretli) | ✔ |
| j | İlerleme (streak_message + sıradaki rozet) | ilk rozet | ✔ | ✔ | ✔ |
| k | Echo seni tanıyor + Koç satırı | yalnız koç ("tanış") | ✔ | ✔ | ✔ |

Akşam (bugün kayıt varsa) zaman çizelgesi hero'nun **üstüne** çıkar: `recordedToday == true && !entries.isEmpty`.

## 3. Token eşlemesi

### Renk (mevcut Asset Catalog)
| Tasarımda | Token |
|---|---|
| Zemin #120F1C / #F6F4FB | `color.bg.canvas` |
| "Son 7 gün" paneli #1A1628 / #FFFFFF | `color.bg.surface` |
| Çip, iskelet çubuğu | `color.bg.surfaceRaised` |
| Birincil / ikincil metin | `color.content.primary` / `.secondary` |
| Menekşe metin, bağlantılar | `color.content.accent` |
| Kayıt düğmesi, işlenen kayıt düğümü | `color.accent.primary` |
| Menekşe %10–16 zemin (öneri, bugün sütunu, koç ikonu) | `color.bg.accentSoft` |
| Akuamarin (işaretli hedef, "İyileşiyor") | `color.accent.secondary`, zemin `color.bg.aquaSoft` |
| Amber (kapsül, rozet yayı) | `EchoPrimitive.amber500` dolgu; metin `color.feedback.warning` |
| Mercan (çevrimdışı, hata) | `color.feedback.danger` |
| Çizgiler | `color.border.subtle` (hairline), `.default` (kesikli boş sütun, koç satırı çerçevesi) |
| Mood | `color.mood.heavy/low/neutral/good/bright` |

**Önerilen asset düzeltmesi (açık tema, "Any" değerleri):** mevcut açık mood renkleri beyaz zeminde grafik
kontrastı 3:1'in altında (#2AC7AE ≈ 2,1:1, #A6A1BA ≈ 2,5:1). Tasarımda kullanılan açık değerler:
`moodHeavy #E06666 · moodLow #D9774F · moodNeutral #8C86A3 · moodGood #109A85 · moodBright #7A52F0`.
Koyu değerler değişmez. Bu değişiklik tüm uygulamayı etkiler; ayrı commit yap.

### Tipografi (`echoTextStyle`)
| Öğe | Token | Not |
|---|---|---|
| Selam "Günaydın, Atakan" | `.display` (34 rounded bold) | |
| Bölüm başlığı ("Son 7 gün", "Bugün için hedeflerin") | **yeni** `.sectionTitle`: 21/26, bold, `.rounded`, relativeTo `.title3` | EchoTextStyle'a ekle |
| Günün sorusu | **yeni** `.question`: 32/38, regular, `.serif`, relativeTo `.title` (yeni kullanıcıda 30) | EchoQuestionHero'daki sabit 30'un yerine |
| Haftalık yansıma (narrative_summary) | `.entry` (18/28 serif) | tasarımda 19; `.entry` kabul |
| Geçmişte bugün alıntısı | `.entryQuote` (17/26 serif italik) | |
| Zaman çizelgesi özeti | `.entry`, `lineLimit(3)` | tasarımda 16; okunurluk için `.entry` |
| İşlenen kaydın transcript'i | `.entryQuote` + `content.secondary` | |
| Tarih, bölüm alt satırı, etiketler | `.subhead` / `.footnote` | |
| Saat, sayılar | `.monospacedDigit()` | |
| Grafik gün etiketi | `.caption` (en çok `.xxLarge` ölçek; bkz. §7) | |

Boşluk/köşe: panel köşe `radius.lg` (20) ya da `radius.xl` (28) — tasarım 24; `lg` seç. Satır min 56 (`listRowMinHeight`), dokunma ≥ 44.

## 4. Veri kaynakları ve ViewModel değişiklikleri

`TodayViewModel` şu an: calendar, bugünün kayıtları, onThisDay, unreadCount, recent(5), activeGoals(3), goal stats, suggestions.
**Eklenecek** (hepsi `async let` ile paralel; her biri bağımsız başarısız olabilir, başarısız olan bölüm gizlenir):

| Alan | Kaynak | Kullanıldığı blok |
|---|---|---|
| `user` (displayName, currentStreak, longestStreak, totalEntries, recordedToday) | `SessionStore` içindeki `AuthenticatedUser` | b, j |
| `weekly: AIInsights?` | `insights.insights(periodDays: 7)` | f (weeklyTrend, weeklyAverage, moodTrend, themes, hasSufficientData, periodLabel) |
| `weekSummary: PeriodSummary?` | `insights.summary(periodDays: 7, endDay: today)` | f (narrativeSummary) |
| `profile: ProfileSummary?` | `insights.profileSummary()` | k (emotionalPatterns) |
| `achievements: Achievements?` | `insights.achievements()` | j (streakMessage, earnedCount/totalCount, badges) |
| `capsules: CapsuleSummary?` | `CapsuleService.summary()` | e (openableCount, nextUnlockAt, nextCapsuleID) |
| `lastCoachSession: CoachSession?` | `CoachService.sessions(cursor: nil, size: 1)` | k (başlık) |

Türetilen gösterimler (hesap değil, seçim):
- **Günün sorusu:** `entries + recentEntries` içinde `status == completed` olan en yeni kaydın `analysis.reflectiveQuestion`.
  Etiket o kaydın `entryDay`'ine göre: bugün → "Sabahki/Az önceki kaydından", dün → "Dünkü kaydından", daha eski → "Son kaydından".
  Halkaların rengi/şekli: `EchoMoodLevel(moodScore: analysis.moodScore)`. Soru yoksa → Durum 1 karşılama metni.
- **Selam:** cihaz saatine göre "Günaydın / İyi günler / İyi akşamlar" (yalnız metin seçimi). `displayName` nil → sadece selam.
- **Sıradaki rozet:** sunucuda ayrı alan yok. Geçici kural: `badges.filter { !$0.isEarned }.max(by: progress)`.
  Backend'e `next_badge` eklenmesi tercih edilir; bunu koda `// TODO(backend)` olarak bırak.
- **Mood seviyesi:** mevcut `EchoMoodLevel(moodScore:)` eşikleri (0,2 adım) tasarımla birebir.

## 5. Bileşenler

Önce mevcut olanı genişlet, yoksa `DesignSystem/Components/` altına yeni dosya aç. Hepsinde `#Preview` (koyu + açık + boş durum).

| Bileşen | Durum | Özellik |
|---|---|---|
| `EchoMoodShape` / `EchoMoodGlyph` | mevcut | **Kontrol et:** `.low` = alt yarım daire (düz kenar üstte, kase), `.good` = üst yarım daire (kubbe). SwiftUI'da y ekseni aşağı; preview'da doğrula. |
| `EchoRings` (statik) | **yeni** | `Canvas`; `count` 3–6, `baseRadius`, `step`, `color`, `opacityRange` (.55→.06), `lineWidth` 1.25, `dashed: Bool`. Hero arka planı (r0 30, step 30, 6 halka, sağ kenardan taşar), geçmişte bugün (64 pt), seri glifi (18 pt), grafikte bugün-boş. `accessibilityHidden`. |
| `EchoRippleView` | mevcut | İşlenen kayıt düğümü (28 pt, 3 halka) ve sekme çubuğundaki kayıt düğmesinin etrafı. Reduce Motion zaten destekli. |
| `TodayHeader` | **yeni** | Satır 1: tarih (`subhead`, secondary) + zil (`EchoIconButton` 44, rozet: `unreadCount > 0` ise mercan kapsül, koyu metin). Satır 2: selam `.display`. Satır 3 (Button → Başarımlar): seri glifi + "**12 günlük seri** · bugün henüz kaydın yok". Glif: `recordedToday` false → iç halka boş; true → iç daire akuamarin dolu; `currentStreak == 0` → kesikli, metin "Echo'daki ilk günün". |
| `EchoQuestionHero` | **değiştir** | Dolu mikrofon dairesini kaldır. Yapı: etiket (`footnote` semibold, secondary) → soru (`.question`) → "🎙 Dokun, sesle yanıtla" (`subhead` semibold, `content.accent`, SF Symbol `mic`). Etiket+soru+eylem tek `Button` → kayıt. Sağ altta ayrı "✎ Yaz" (`square.and.pencil`, secondary) → composer. Arkada `EchoRings`, merkezinde mood glifi (18), soru metninin arkasından taşar, `.clipped()` bölüm sınırında. |
| `CapsuleRow` | **yeni** | `openableCount > 0`: amber %12 zemin, 52 yükseklik, `radius.md`, 34 pt amber daire ikon (`pills` benzeri kapsül simgesi), "Açılmayı bekleyen N kapsülün var", sağda "Aç ›". Aksi halde `nextUnlockAt` varsa: üst/alt hairline, nötr metin "Sonraki kapsülün 28 Eylül'de açılıyor". İkisi de yoksa gizli. |
| `WeekMoodStrip` | **yeni** (Canvas önerilir; Swift Charts da olur) | 7 eşit sütun. Her dolu gün: sütun "gökyüzü" = 28 genişlik kapsül, üstü `y(score)`, mood rengi %34→%2 dikey gradient; üstünde mood şekli (15) + etrafında `entryCount` kadar halka (r = 12 + 5n, opaklık .55/.30); ardışık dolu günler catmull-rom çizgiyle (secondary %45, 1.5) bağlanır, `nil`'de kopar. Boş geçmiş gün: kesikli kapsül çerçeve (`border.default`, 3/4). Bugün: `bg.accentSoft` sütun zemini, etiket "Bugün" `content.accent`; bugün boşsa 3 kesikli halka. Altta gün kısaltması + `entryCount` kadar nokta (0 → kısa çizgi). Yükseklik 170; y alanı 18…108. Erişilebilirlik: tek öğe, etiket "Son 7 gün ruh hâli. Salı: İyi, 1 kayıt; …". Günlere dokunma: `.moodTracker(periodDays: 7)`. |
| `MoodLegend` | **yeni** | 5 şekil (12) + etiket, `caption`, tek satır `space-between`, büyük yazıda sarar. |
| `TrendBadge` | **yeni** | `EchoMoodTrend`: improving → `chart.line.uptrend.xyaxis` + "İyileşiyor" aqua; stable → "Dengeli" nötr; declining → "Düşüşte" mercan. 30 yükseklik kapsül. |
| `WeeklyPanel` | **yeni** | `bg.surface`, `radius.lg`, iç boşluk 20/18. Başlık `.sectionTitle` + "Ortalama ◠ **İyi** 0,64" (weeklyAverage nil → satır yok) + sağda TrendBadge. → Şerit → Lejant → hairline → "◎ Echo'nun haftalık yansıması" etiketi → narrative (menekşe tırnaklar) → temalar (ilk 3; `EchoChip` genişlet: tag + count (secondary, tabular) + trending ↗) → hairline → "Haftalık raporun tamamı ›" (`.insights`). `hasSufficientData == false` → yansıma+temalar gizli, şerit kalır. |
| `EchoTimelineRow` | **genişlet** | Kolonlar: saat 46 · düğüm 28 · içerik. Düğümler arası dikey çizgi (`border.default`, 1.5). `completed`: glif 16 + ince halka, üst satır "**mood_label** · Enerji {energy}", özet `.entry` 3 satır, altta topics "iş · planlama". `processing`: `EchoRippleView` düğüm, "Echo dinliyor, analiz ediliyor" (accent), transcript italik secondary 2 satır, 2 iskelet çubuğu. `failed`: mercan düğüm (!), "Analiz tamamlanamadı", "Kaydın güvende…" açıklama, "↻ Şimdi dene" (44). Satır → `.journalEntry(id:)`. |
| `PastTodayBlock` | **EchoQuoteBlock yerine** | Sol kenar çizgisi yok. Solda 64 pt `EchoRings` + mood glifi; sağda "1 yıl önce bugün · 21 Eylül 2025" (footnote), "◠ Sakin" (mood_label), alıntı `.entryQuote`. Birden çok kayıt → `TabView(.page)` ya da yatay `ScrollView` + sayfa noktası. |
| `EchoChecklistRow` | **genişlet** | `isCompleted`: 26 daire akuamarin dolgu + `checkmark` (koyu), başlık secondary + üstü çizili. Dokunma alanı 44, `.sensoryFeedback(.success)`. |
| `GoalSuggestionRow` | **yeni** | `bg.accentSoft`, `radius.lg`; solda 20 pt halka glifi; `message` (`subhead`); altta iki metin butonu: `primaryActionLabel` (accent semibold), `secondaryActionLabel` (secondary). Metinler sunucudan. |
| `BadgeProgressRing` | **yeni** | 64 pt; iz halkası `border.subtle` 5; `Circle().trim(0, progress)` amber 5, `.round`; dışta amber %18 ince halka; ortada `emoji` (24). |
| `ProgressSection` | **yeni** | `streakMessage` (`.headline` regular, primary) → Button (ring + "Sıradaki rozet · 8/24" / title / "%42 · 9 gün kaldı" amber) → alt satır "En uzun serin 21 gün · toplam 148 kayıt". |
| `KnowsYouCoachBlock` | **yeni** | `profile?.emotionalPatterns` varsa: "◎ Echo seni tanıyor" etiketi + serif alıntı (`.entryQuote` italik değil → `.entry`). Altında satır (68, `border.default` çerçeve, `radius.lg`): 40 pt accentSoft daire `bubble.left` + "Koçunla konuş" / "Son oturum: {title}" + ›. |
| `OfflineStrip` | **EchoBanner kompakt** | 44 yükseklik, `feedback.danger` %14 zemin, `wifi.slash`, "Çevrimdışısın · 20:58'deki veriler gösteriliyor", sağda "↻ Yenile". Bağlantı durumu `NWPathMonitor`/mevcut ağ durumu kaynağından; son eşitleme zamanı son başarılı `load()` zamanı. |
| `EchoTabBar` | mevcut, dokunma | İsteğe bağlı: kayıt düğmesinin arkasına 2 statik halka (`accent.primary`, .35/.08). Başka değişiklik yok. |

## 6. Dokunma → hedef

| Öğe | Eylem |
|---|---|
| Zil | `router.push(.notifications)` |
| Seri satırı | `router.push(.achievements)` |
| Günün sorusu | `router.present(.recording)` — soru bağlamı için `AppSheet.recording`'e opsiyonel `prompt: String?, sourceEntryID: String?` ekle (ekleme mevcut kayıt akışını bozmamalı) |
| "Yaz" | `router.present(.composer)` |
| Kapsül satırı | açılabilir → `.capsule(id: nextCapsuleID)` varsa, yoksa `.capsules`; bekliyor → `.capsules` |
| Şeritte gün | `.moodTracker(periodDays: 7)` |
| "Haftalık raporun tamamı" | `.insights` |
| Zaman çizelgesi satırı | `.journalEntry(id:)`; "Günlüğe git" → Günlük sekmesi |
| "Şimdi dene" | mevcut yeniden deneme akışı (`JournalSubmissionStore`), `isRetryable` ise |
| Geçmişte bugün | `.journalEntry(id: memory.id)` |
| Hedef dairesi | `model.complete(goal)` (yerinde) |
| Hedef metni / "Tümü" | `.goals` |
| Öneri butonları | `model.accept` / `model.reject` |
| Rozet satırı | `.achievementDetail(badgeKey:)` |
| Koç satırı | `router.present(.coachChat(sessionId: lastCoachSession?.id))` |
| Sekme ● | mevcut kayıt |

Not: şu an `complete()` hedefi listeden siliyor. Tasarım (Durum 3) tamamlanan hedefi gün boyunca üstü çizili gösteriyor.
Tercih: tamamlananı `completedAt` bugünse listede tut; sunucu yanıtı buna izin vermiyorsa mevcut davranışı koru.

## 7. Dynamic Type

- Tüm metinler `echoTextStyle` ile ölçeklenir; sabit `frame(height:)` kullanma (grafik hariç).
- `dynamicTypeSize >= .xxLarge`: başlık durum satırı sarar; tema çipleri `FlowLayout`/`ViewThatFits` ile sarar; rozet satırında halka üstte, metin altta olabilir.
- `>= .accessibility1`: zaman çizelgesinde saat, içeriğin üstüne geçer (VStack); şerit gün etiketleri `.dynamicTypeSize(...DynamicTypeSize.xxLarge)` ile sınırlanır, grafik yüksekliği 170→200.
- Referans: `02-sabah-buyukyazi-*.png` (≈ xxxLarge, gövde 17→23).

## 8. Hareket

Yavaş ve sakin. İşlenen kayıt düğümü: halkalar ~3,2 sn'de dışa yayılır (EchoRippleView `speed` ≈ 0,55).
Bölümler ilk yüklemede `motion.enter` ile opaklık. Reduce Motion: hepsi durur, halkalar sabit.

## 9. Erişilebilirlik

- Hero: tek öğe, etiket "Günün sorusu: {soru}", ipucu "Sesle yanıtlamak için dokun".
- Şerit: tek öğe, gün gün özet (bkz. §5). Mood glifleri tek başına `accessibilityHidden`, etiket metinle verilir.
- Zil: "Bildirimler, N okunmamış". Hedef dairesi: "Tamamlandı olarak işaretle: {başlık}".
- Kontrast: metin 4,5:1; menekşe metin için `content.accent` (dolgu menekşesi değil).

## 10. Yerelleştirme (Localizable.xcstrings'e eklenecek anahtarlar, TR)

```
today.greeting.morning = "Günaydın"            today.greeting.day = "İyi günler"      today.greeting.evening = "İyi akşamlar"
today.greeting.welcome = "Hoş geldin"          today.streak.days = "%lld günlük seri"
today.status.none = "bugün henüz kaydın yok"   today.status.count = "bugün %lld kayıt"  today.status.firstDay = "Echo’daki ilk günün"
today.question.fromYesterday = "Dünkü kaydından bir soru"   today.question.fromToday = "Sabahki kaydından bir soru"
today.question.fromLast = "Son kaydından bir soru"          today.question.action = "Dokun, sesle yanıtla"   today.question.write = "Yaz"
today.welcome.label = "Başlamak için"   today.welcome.question = "Aklından ne geçiyor? Birkaç cümle yeter."
today.welcome.body = "Konuş ya da yaz. Echo dinler, özetler ve sana bir soru bırakır."
today.capsule.openable = "Açılmayı bekleyen %lld kapsülün var"   today.capsule.next = "Sonraki kapsülün %@ açılıyor"   today.capsule.open = "Aç"
today.week.average = "Ortalama"   today.week.reflection = "Echo’nun haftalık yansıması"   today.week.more = "Haftalık raporun tamamı"
today.week.emptyTitle = "Haftan burada şekillenecek"   today.week.emptyBody = "Her kayıttan sonra Echo o günün ruh hâlini bir şekil ve renkle işaretler."
today.week.today = "Bugün"   trend.improving = "İyileşiyor"   trend.stable = "Dengeli"   trend.declining = "Düşüşte"
today.timeline.processing = "Echo dinliyor, analiz ediliyor"   today.timeline.failed = "Analiz tamamlanamadı"
today.timeline.failedBody = "Kaydın güvende. Bağlantı gelince yeniden denenir."   today.timeline.retry = "Şimdi dene"   today.timeline.energy = "Enerji %@"
today.memory.yearsAgo = "%lld yıl önce bugün"
today.goals.title = "Bugün için hedeflerin"   today.goals.completedThisWeek = "Bu hafta %lld hedef tamamladın"   today.goals.empty = "Kendine küçük bir hedef koy"
today.progress.nextBadge = "Sıradaki rozet"   today.progress.stats = "En uzun serin %lld gün · toplam %lld kayıt"
today.knowsYou = "Echo seni tanıyor"   today.coach.title = "Koçunla konuş"   today.coach.meet = "Koçunla tanış"   today.coach.last = "Son oturum: %@"
today.offline = "Çevrimdışısın"   today.offline.since = "%@’deki veriler gösteriliyor"   common.refresh = "Yenile"
```
Mevcut `today.*` anahtarlarıyla çakışanı yeniden kullan; eskimiş olanları sil.

## 11. Durum kuralları (özet)

- **Durum 1 (totalEntries == 0):** b (glif kesikli), d karşılama, f boş şerit + lejant, g, i boş satır, j ilk rozet (badges'tan), k yalnız koç.
- **Durum 2 (recordedToday == false):** a yok, c yok, sıralama §2.
- **Durum 3 (bugün kayıt var):** c hero'nun üstünde; en az bir `processing` kayıt varsa mevcut polling (`OperationProgress.pollInterval`) sürer, tamamlanınca satır yerinde güncellenir (animasyon `motion.smooth`).
- **Durum 4 (çevrimdışı / yükleme hatası):** önbellekteki son veri gösterilir, üstte OfflineStrip. `error` varken içerik **silinmez**. Başarısız kayıt satırı `failed` görünümü.
- Her blok kendi verisi `nil` ise gizlenir; iskelet yalnız ilk yüklemede (`EchoSkeleton`).

## 12. Kabul listesi

- [ ] 4 durum × koyu/açık `#Preview` (mock veriyle: `EchoMockData`), PNG'lerle görsel karşılaştırma
- [ ] xxxLarge ve AX1'de taşma/kesilme yok
- [ ] Reduce Motion açıkken hiçbir şey hareket etmiyor
- [ ] Hiçbir yerde istemci tarafı sayma/ortalama yok; nil'de "0" yok
- [ ] Sayfada tek dolgu yüzey (Son 7 gün), tek dolu kayıt düğmesi (sekme çubuğu)
- [ ] VoiceOver ile tüm blokların sırası ve etiketleri anlamlı
- [ ] Tüm dokunma hedefleri §6'daki rotalara gidiyor
