# Echo — iOS Design System & Implementation Spec
### Rosebud'dan ilham alınmış, ama Echo'ya özgü bir tasarım dili

> **Bu doküman ne işe yarar?**
> 1. `Bölüm 1-2` → Rosebud analizi ve Echo'nun tasarım dili kararları (oku, onayla)
> 2. `Bölüm 3-5` → Design token'lar, component kütüphanesi, ekran layout'ları (spec)
> 3. `Bölüm 6` → Claude Code'a sırayla verilecek hazır prompt blokları (kopyala-yapıştır)
>
> **Hedef:** SwiftUI, iOS 17+, light + dark tema, Spring Boot backend.

---

# Bölüm 1 — Rosebud UI/UX Analizi

Kaynak: App Store ekran görüntüleri, rosebud.app, screensdesign.com akış dökümü.

## 1.1 Rosebud'ın yaptığı doğru şeyler

| # | Desen | Neden işe yarıyor |
|---|---|---|
| 1 | **Boş sayfa yok** | Composer her zaman bir soruyla açılıyor ("What's on your mind?"). Kullanıcı yazmaya değil, *cevaplamaya* başlıyor. |
| 2 | **AI metni farklı renkte** | Kullanıcı metni koyu nötr, AI cevabı mavi. Konuşma değil, tek akışlı bir "yazışma" hissi. Ayrı balon yok → daha sakin. |
| 3 | **Alt bar = mod seçici** | Composer'ın altında mikrofon / sesli konuşma / sesli okuma ikonları. Mod değiştirmek için ekran değiştirmiyorsun. |
| 4 | **Kayıt ekranı minimal** | Sadece dalga formu + iptal (X) + onayla (✓). Süre sayacı bile ikincil. |
| 5 | **Haftalık rapor kart yığını** | Insights tek uzun sayfa değil; "Weekly Report" başlıklı, tarih aralıklı, kaydırılabilir kart. Paylaşılabilir bir nesne gibi duruyor. |
| 6 | **Emoji eksenli mood grafiği** | Bar chart'ın X ekseninde sayı değil emoji var. Okuması sıfır efor. |
| 7 | **Key Themes = pill bulutu** | Tekrar eden temalar chip olarak. Tıklanabilir filtre gibi duruyor. |
| 8 | **Today ekranı 2 büyük karttan ibaret** | "Morning Intention" / "Evening Reflection" — günün iki ritüeli. Altında hedef listesi. Karar yorgunluğu yok. |
| 9 | **Insight kartı entry içine gömülü** | AI çıkarımı ayrı sekmede değil, okuduğun yazının altında bir alıntı kutusunda. |
| 10 | **Soft paywall** | İlk AI yansımasından *sonra* çıkıyor. Değeri görmeden para istemiyor. |
| 11 | **Uzun onboarding (20 adım)** | Kişiselleştirme verisi topluyor; kullanıcı "bu benim için kurulmuş" hissi alıyor. |

## 1.2 Almayacaklarımız (kopya olmasın diye bilinçli farklılaşma)

| Rosebud | Echo'da ne yapacağız |
|---|---|
| Magenta/gül (#e70f61) marka rengi + gül ikonu | **Menekşe-mor + akuamarin** paleti; ikon: eş-merkezli **yankı halkası (ripple)** |
| Mavi AI metni, aynı akış içinde | AI metni **ayrı `EchoReflectionBlock`** — sol tarafında ince accent şeridi olan, hafif tint'li blok |
| Tüm gövde metni sans-serif | Günlük **gövde metni serif** (New York) — "yazılmış" hissi; UI sans (SF Pro) |
| Düz beyaz/gri yüzeyler | **Aurora gradient** yüzeyler: yalnızca 3 yerde (record ekranı, streak, paywall) — geri kalan sakin |
| Statik dalga formu | **Canlı ripple + waveform** — Echo'nun imza hareketi |
| Emoji mood ekseni | **Renk + şekil** tabanlı mood ölçeği (renk körlüğü uyumlu), emoji opsiyonel süs |
| Bar chart | **Dot-plot + trend çizgisi** (7/30/90 gün) |
| 5 sekmeli klasik tab bar | **4 sekme + merkezde yükseltilmiş kayıt butonu** |
| Community yok | Echo'da **Community Posts** var → anonim-varsayılan, "echo'la" (rezonans) etkileşimi |

## 1.3 Echo'ya özel, Rosebud'da olmayan yapı taşları

- **Voice-first:** Birincil giriş yolu ses. Metin ikincil mod.
- **Community:** Anonim paylaşım + "Echo" (beğeni yerine rezonans) + yorum.
- **Coach Chat:** Ayrı, sürekli hafızalı sohbet sekmesi.
- **Achievements:** Streak + rozet sistemi.

---

# Bölüm 2 — Echo Tasarım Dili

## 2.1 Prensipler

1. **Sessizlik varsayılandır.** Ekranda aynı anda en fazla 1 vurgulu renk alanı. Gradient bir "olay" işaretidir, dekorasyon değil.
2. **Ses görünür olsun.** Kayıt, oynatma ve AI düşünme durumları hep aynı ripple/waveform diliyle anlatılır.
3. **Yazı okunmak için.** Günlük gövdesi serif, 18/28, max 68 karakter satır genişliği.
4. **Her ekran tek bir eylem önerir.** İkincil eylemler ghost buton veya overflow menüde.
5. **Karanlık tema birinci sınıf.** Dark'ta gölge yok — **ışıma (glow)** ve yüzey açıklığı kullanılır.
6. **Dokunsal geri bildirim ücretsiz zarafettir.** Kayıt başlat/bitir, mood seçimi, streak artışı, achievement → haptic.

## 2.2 Motif: Ripple (Yankı Halkası)

Echo'nun imza grafik öğesi: bir merkezden dışa doğru açılan, opaklığı azalan 3–5 eş merkezli halka.

Kullanım yerleri:
- App icon & splash
- Kayıt butonunun aktif hali (halkalar ses seviyesine göre nefes alır)
- AI "düşünüyor" göstergesi (halkalar yavaş pulse)
- Empty state illüstrasyonları
- Achievement unlock animasyonu
- Community'de "echo" (rezonans) etkileşimi

---

# Bölüm 3 — Design Tokens

> Hedef dosya: `Echo/DesignSystem/Tokens/` altında `EchoColor.swift`, `EchoTypography.swift`, `EchoSpacing.swift`, `EchoRadius.swift`, `EchoElevation.swift`, `EchoMotion.swift` + `AppTheme.swift` (facade).

## 3.1 Renk — Primitive Ramp'lar

Bunlar **doğrudan UI'da kullanılmaz**. Sadece semantic token'lar bunlara referans verir.

### Violet (primary)
```
violet50   #F4F0FF
violet100  #E7DEFF
violet200  #CDBBFF
violet300  #B095FF
violet400  #9270FB
violet500  #7A52F0   ← base
violet600  #6538D6
violet700  #5029AC
violet800  #3B1E80
violet900  #271455
violet950  #170B33
```

### Aqua (secondary / ses)
```
aqua50   #E8FBF7
aqua100  #C7F5EC
aqua200  #92EBDB
aqua300  #57DCC6
aqua400  #2AC7AE
aqua500  #14AB94   ← base
aqua600  #0C8A78
aqua700  #0A6B5E
aqua800  #085145
aqua900  #06362E
```

### Amber (streak / başarı)
```
amber100 #FFF2D6
amber300 #FFD27A
amber500 #F5A524   ← base
amber700 #8F5A08   (kontrast için koyulaştırıldı — beyaz üzerinde 5.78:1)
```

### Coral (dikkat / negatif mood)
```
coral100 #FFE4E4
coral300 #FF9F9F
coral500 #F4606A   ← base
coral700 #C0303C
```

### Neutral (mor-nötr, sıcak değil soğuk)
```
neutral0    #FFFFFF
neutral25   #FBFAFE
neutral50   #F6F4FB
neutral100  #EFEDF6
neutral200  #E2DFEC
neutral300  #CBC7DA
neutral400  #A6A1BA
neutral450  #8C87A3
neutral500  #736D8A
neutral600  #5D5873
neutral700  #443F58
neutral800  #2E2A40
neutral850  #241F33
neutral900  #1A1628
neutral950  #120F1C
neutral1000 #0A0812
```

## 3.2 Renk — Semantic Token'lar

| Token | Light | Dark | Kullanım |
|---|---|---|---|
| `bg.canvas` | `neutral50` | `neutral950` | Ekran zemini |
| `bg.surface` | `neutral0` | `neutral900` | Kart, list row, sheet |
| `bg.surfaceRaised` | `neutral0` | `neutral850` | Sheet üstündeki kart, popover |
| `bg.surfaceSunken` | `neutral100` | `neutral1000` | Input alanı, kod bloğu, sekmeli track |
| `bg.overlay` | `#120F1C` @ 40% | `#000000` @ 60% | Modal arkası |
| `bg.accentSoft` | `violet50` | `violet950` | Seçili chip, AI blok tint'i |
| `bg.aquaSoft` | `aqua50` | `aqua900` @ 50% | Ses/transcript rozetleri |
| `bg.inverse` | `neutral900` | `neutral0` | Toast, tooltip |
| `content.primary` | `neutral900` | `neutral50` | Başlık, gövde |
| `content.secondary` | `neutral600` | `neutral400` | Alt başlık, meta |
| `content.tertiary` | `neutral500` | `neutral450` | Placeholder, timestamp |
| `content.disabled` | `neutral400` | `neutral600` | Pasif |
| `content.accent` | `violet600` | `violet300` | Link, vurgulu ikon |
| `content.onAccent` | `neutral0` | `neutral0` | Primary buton yazısı |
| `content.inverse` | `neutral0` | `neutral900` | Toast yazısı |
| `border.subtle` | `neutral100` | `neutral850` | Kart kenarı, ayraç |
| `border.default` | `neutral200` | `neutral800` | Input kenarı |
| `border.strong` | `neutral300` | `neutral700` | Vurgulu kenar |
| `border.accent` | `violet400` | `violet400` | Focus ring |
| `accent.primary` | `violet500` | `violet500` | Primary buton, FAB (beyaz yazı AA geçsin diye dark'ta da 500) |
| `accent.primaryPressed` | `violet600` | `violet600` | Basılı |
| `accent.secondary` | `aqua500` | `aqua400` | Waveform, ses göstergeleri |
| `feedback.success` | `aqua700` | `aqua300` | Tamamlandı |
| `feedback.warning` | `amber700` | `amber300` | Uyarı |
| `feedback.danger` | `coral700` | `coral300` | Hata, silme |
| `feedback.info` | `violet600` | `violet300` | Bilgi |

### Kontrast doğrulaması (hesaplandı, WCAG 2.1)

| Çift | Light | Dark |
|---|---|---|
| `content.primary` / `bg.surface` | 17.7 ✅ | 16.2 ✅ |
| `content.primary` / `bg.canvas` | 16.2 ✅ | 17.3 ✅ |
| `content.secondary` / `bg.surface` | 6.8 ✅ | 7.1 ✅ |
| `content.tertiary` / `bg.surface` | 4.9 ✅ | 5.1 ✅ |
| `content.accent` / `bg.surface` | 6.8 ✅ | 7.2 ✅ |
| `content.accent` / `bg.accentSoft` | 6.1 ✅ | 7.6 ✅ |
| `content.onAccent` / `accent.primary` | 4.9 ✅ | 4.9 ✅ |
| `feedback.success` / `bg.surface` | 6.4 ✅ | 10.5 ✅ |
| `feedback.warning` / `bg.surface` | 5.8 ✅ | 12.4 ✅ |
| `feedback.danger` / `bg.surface` | 5.6 ✅ | 9.0 ✅ |

> `content.disabled` bilinçli olarak AA altındadır (WCAG pasif elemanları muaf tutar), ama **asla tek bilgi taşıyıcısı olamaz** — pasiflik ayrıca ikon/metinle belirtilir.

### Mood ölçeği (5 seviye — renk **+ şekil**, renk körlüğü uyumlu)

| Seviye | Ad (TR) | Renk (light) | Renk (dark) | Şekil |
|---|---|---|---|---|
| 1 | Ağır | `coral500` | `coral300` | Aşağı üçgen |
| 2 | Durgun | `#E08A6E` | `#F0A98E` | Yarım daire (alt) |
| 3 | Nötr | `neutral400` | `neutral400` | Daire |
| 4 | İyi | `aqua400` | `aqua300` | Yarım daire (üst) |
| 5 | Parlak | `violet400` | `violet300` | Yukarı üçgen (ripple'lı) |

> **Kural:** Mood asla tek başına renkle anlatılmaz. Şekil + etiket her zaman eşlik eder.

### Gradient'ler (sadece 3 yerde kullanılır)

```
aurora.primary     linear 145°  violet500 → violet700 → aqua700
aurora.record      radial       violet400 @ center → violet900 @ edge   (record ekranı zemini)
aurora.celebration linear 145°  amber500 → coral500 → violet500          (achievement/streak)
```

## 3.3 Tipografi

| Token | Font | Size/Line | Weight | Tracking | Kullanım |
|---|---|---|---|---|---|
| `display` | SF Pro Rounded | 34/40 | Bold | -0.4 | Onboarding, paywall başlığı |
| `title1` | SF Pro Rounded | 28/34 | Bold | -0.3 | Ekran büyük başlığı |
| `title2` | SF Pro Display | 22/28 | Semibold | -0.2 | Kart/section başlığı |
| `title3` | SF Pro Display | 20/25 | Semibold | -0.1 | Alt section |
| `headline` | SF Pro Text | 17/22 | Semibold | 0 | List row başlığı, buton lg |
| `body` | SF Pro Text | 17/24 | Regular | 0 | UI gövde |
| `bodyEmphasis` | SF Pro Text | 17/24 | Semibold | 0 | Vurgulu gövde |
| **`entry`** | **New York (serif)** | **18/28** | Regular | 0 | **Günlük gövde metni** |
| **`entryQuote`** | **New York** | **17/26** | Regular Italic | 0 | **AI alıntısı / insight** |
| `callout` | SF Pro Text | 16/21 | Regular | 0 | Sheet açıklaması |
| `subhead` | SF Pro Text | 15/20 | Medium | 0 | Chip, buton md |
| `footnote` | SF Pro Text | 13/18 | Regular | 0 | Meta, tarih |
| `caption` | SF Pro Text | 12/16 | Medium | 0.2 | Rozet, sayaç |
| `caption2` | SF Pro Text | 11/13 | Semibold | 0.4 | Overline, ALL CAPS etiket |
| `numeric` | SF Pro Display | 28/32 | Bold, **tabular** | -0.2 | İstatistik sayıları, süre |

**Kurallar**
- Tüm token'lar `Dynamic Type` destekler (`.custom(_:size:relativeTo:)`). Max `.accessibility3`'e kadar layout bozulmaz.
- Günlük gövdesi max genişlik **68 karakter** (iPad/landscape'te ortalanır).
- ALL CAPS yalnızca `caption2` ile.

## 3.4 Spacing (4pt grid)

```
space.4xs   2
space.3xs   4
space.2xs   8
space.xs    12
space.sm    16
space.md    20
space.lg    24
space.xl    32
space.2xl   40
space.3xl   48
space.4xl   64
```

**Layout sabitleri**
```
screen.hPadding      20        Ekran yatay kenar boşluğu
screen.sectionGap    32        Section'lar arası
card.padding         16        Kart iç boşluğu (compact: 12, roomy: 20)
list.rowMinHeight    56
list.rowGap          8
tabBar.height        56  (+ safe area)
navBar.heightLarge   96
navBar.heightInline  44
touchTarget.min      44
```

## 3.5 Radius

```
radius.xs    6     Chip, rozet
radius.sm    10    Input, küçük buton
radius.md    14    Buton, list row
radius.lg    20    Kart
radius.xl    28    Sheet, büyük kart, modal
radius.full  999   Pill buton, avatar, record butonu
```

> **Kurallar**
> - Tüm köşeler `.continuous` (squircle) — iOS'un native hissi için zorunlu.
> - İç içe geçen kutularda iç radius, dış radius'tan **padding kadar küçük** olmalı ki köşeler paralel kalsın. Formül: `inner = max(xs, outer - padding)`.
>   Örn: `lg(20)` kart + 16 padding → iç eleman `max(6, 4)` = **xs(6)**.
>   Örn: `xl(28)` sheet + 20 padding → iç kart `sm(10)` civarı → pratikte **sm(10)**.
> - Pill/full radius bu formülün dışındadır.

## 3.6 Elevation

**Light tema — gölge**
```
elev.0   yok
elev.1   y2  blur 8   #120F1C @ 6%
elev.2   y4  blur 16  #120F1C @ 8%
elev.3   y8  blur 28  #120F1C @ 10%
elev.4   y16 blur 48  #120F1C @ 14%   (sheet, modal)
```

**Dark tema — gölge YOK, yüzey + ışıma**
```
elev.0   bg.surface
elev.1   bg.surface + 1px border.subtle
elev.2   bg.surfaceRaised
elev.3   bg.surfaceRaised + violet400 @ 8% outer glow, blur 24
elev.4   bg.surfaceRaised + violet400 @ 14% outer glow, blur 40
```

## 3.7 Motion

```
duration.instant  100ms
duration.fast     180ms
duration.base     260ms
duration.slow     400ms
duration.ambient  1800ms   (ripple pulse, shimmer)

spring.snappy     response 0.32  damping 0.86
spring.smooth     response 0.45  damping 0.90
spring.bouncy     response 0.50  damping 0.68   (achievement, streak)

easing.standard   easeInOut
easing.enter      easeOut
easing.exit       easeIn
```

**Kurallar**
- `Reduce Motion` açıkken: ripple/pulse durur (statik halka), geçişler `opacity`'ye düşer, parallax kapanır.
- Ekran geçişi: push = standart NavigationStack; modal = `.sheet` + `presentationDetents`.
- Liste öğeleri girişte **stagger yok** (yorucu). Sadece ilk yüklemede fade.

## 3.8 İkonografi

- **SF Symbols**, ağırlık `.medium`, boyut `.body` ile hizalı.
- Boyutlar: `icon.sm 16`, `icon.md 20`, `icon.lg 24`, `icon.xl 32`.
- Özel ikonlar (SVG → SF Symbol custom): `echo.ripple`, `echo.waveform`, `echo.resonate`.
- Tab bar ikonları: outline (pasif) / filled (aktif).

---

# Bölüm 4 — Component Kütüphanesi

> Hedef dizin: `Echo/DesignSystem/Components/`
> Her component: ayrı dosya + aynı dosyada `#Preview` (light + dark + Dynamic Type XL).

## 4.1 EchoButton

**Anatomi:** `[leadingIcon] label [trailingIcon]` — HStack, spacing `2xs(8)`.

| Variant | Zemin | Yazı | Kenar |
|---|---|---|---|
| `.primary` | `accent.primary` | `content.onAccent` | yok |
| `.secondary` | `bg.accentSoft` | `content.accent` | yok |
| `.tertiary` | `bg.surface` | `content.primary` | 1px `border.default` |
| `.ghost` | şeffaf | `content.accent` | yok |
| `.destructive` | `feedback.danger` | `content.onAccent` | yok |

| Size | Height | H-padding | Type | Radius |
|---|---|---|---|---|
| `.sm` | 36 | 14 | `subhead` | `sm(10)` |
| `.md` | 46 | 18 | `headline` | `md(14)` |
| `.lg` | 54 | 22 | `headline` | `md(14)` |
| `.pill` | 46 | 22 | `headline` | `full` |

**State'ler**
- `pressed`: scale 0.97, zemin `accent.primaryPressed`, `spring.snappy`
- `disabled`: opacity 0.4, etkileşim kapalı
- `loading`: label yerine `ProgressView` (aynı genişlik korunur — layout zıplamaz)
- `fullWidth: Bool` → `.frame(maxWidth: .infinity)`

**Kurallar:** Bir ekranda **en fazla 1 adet `.primary`**. Yıkıcı eylem her zaman onay ister.

## 4.2 EchoIconButton
Kare, `44×44` min. Variantlar: `.plain`, `.soft` (`bg.accentSoft`), `.filled` (`accent.primary`), `.glass` (ultraThinMaterial — sadece medya üstünde). Radius `full` veya `md`.

## 4.3 EchoChip
Height 32, h-padding 12, radius `xs(6)`, type `subhead`.
- `.static` — `bg.surfaceSunken` / `content.secondary`
- `.selectable` — seçili: `bg.accentSoft` + `content.accent` + 1px `border.accent`
- `.removable` — sağda `xmark` 14pt
- `.mood(level)` — mood renginin %12 tint'i + şekil ikonu

## 4.4 EchoCard
Container. `bg.surface`, radius `lg(20)` `.continuous`, padding `card.padding`, elevation `elev.1`.
- `.flat` — elevation 0, 1px `border.subtle`
- `.raised` — `elev.2`
- `.gradient(aurora.primary)` — içerik `content.onAccent`, sadece paywall/streak
- `.interactive` — basılı halde scale 0.985 + elevation bir kademe düşer

## 4.5 EchoListRow
`[leading] (title / subtitle) [trailing]` — minHeight 56, h-padding 16, v-padding 12.
- leading: `Icon(soft container 32×32)` | `EchoAvatar` | `moodDot` | yok
- trailing: `chevron` | `Toggle` | `Text(value)` | `EchoIconButton` | badge
- Ayraç: leading içeriğin bittiği noktadan başlar (inset).

## 4.6 EchoTextField / EchoTextEditor
- Zemin `bg.surfaceSunken`, radius `sm(10)`, padding 14/12, type `body`.
- Focus: 2px `border.accent` + `bg.surface`, `duration.fast`.
- Error: 2px `feedback.danger` + altta `footnote` hata metni.
- `EchoTextEditor`: min 120pt, otomatik büyür, sağ altta opsiyonel karakter sayacı.
- **`EchoComposer`** (özel): serif `entry` tipografisi, placeholder = aktif prompt, klavye üstünde `EchoComposerToolbar`.

## 4.7 EchoComposerToolbar
Klavyenin üstünde sabit bar. Sol: `mic` (sese geç), `sparkles` (öneri iste), `tag`. Sağ: mood seçici kısayolu, `Kaydet`.
Zemin: `.ultraThinMaterial` + üstte 1px `border.subtle`. Height 48.

## 4.8 EchoSegmentedControl
`bg.surfaceSunken` track, radius `full`, seçili thumb `bg.surface` + `elev.1`, type `subhead`. Geçiş `spring.snappy` + `matchedGeometryEffect`.

## 4.9 EchoTabBar
4 sekme + merkezde yükseltilmiş kayıt butonu.

```
[ Bugün ]  [ Günlük ]  ( ● )  [ Topluluk ]  [ Profil ]
```
- Height 56 + safe area, zemin `.ultraThinMaterial`, üstte 1px `border.subtle`.
- Pasif: `content.tertiary` outline ikon. Aktif: `content.accent` filled ikon + altında 4pt nokta.
- Merkez buton: 58×58, `accent.primary` dolgu, `aurora.record` gradient, 8pt yukarı taşar, `elev.3`.
- Kayıt aktifken merkez buton kare "stop" ikonuna morph olur + etrafında ripple.

## 4.10 EchoNavBar
- Large title: `title1`, sol hizalı, scroll ile `headline` inline'a küçülür.
- Sağda max 2 `EchoIconButton`.
- Scroll edilince altında 1px `border.subtle` belirir (`duration.fast`).

## 4.11 EchoBottomSheet
`presentationDetents([.medium, .large])`, radius `xl(28)` üst köşeler, grabber, `elev.4`.
Başlık `title2` + sağda kapat butonu. İçerik `screen.hPadding`.

## 4.12 EchoToast / EchoBanner
- **Toast:** alttan gelir, `bg.inverse`, radius `full`, `subhead`, 2.5s, swipe-to-dismiss. İkon + metin + opsiyonel "Geri al".
- **Banner:** ekran içi, `feedback.*` soft zemin + 1px kenar, radius `md`, kalıcı, kapatılabilir.

## 4.13 EchoAvatar
Boyutlar: `xs 24`, `sm 32`, `md 40`, `lg 56`, `xl 88`. Daire. Fallback: baş harfler, zemin = isimden türetilen violet/aqua tint. Opsiyonel `ring` (streak aktifse `amber500`).

## 4.14 EchoProgressRing
Boyutlar 32 / 56 / 88. Track `border.subtle`, progress `accent.primary` (veya `aurora.primary` 88'de). Line width = size/10, `.round` cap. Merkezde `numeric` değer. Animasyon `spring.smooth`.

## 4.15 EchoStreakBadge
Pill, `aurora.celebration` gradient zemin veya `amber100`/`amber500`. İçerik: ripple ikon + `numeric` sayı + "gün". Artış anında `spring.bouncy` scale 1.0→1.18→1.0 + haptic `.success`.

## 4.16 EchoWaveform
Üç mod, tek component:
1. **`.live(level:)`** — kayıt sırasında. 40 bar, ortadan dışa doğru, `accent.secondary`, height = son 40 örneğin RMS'i. 60fps, `duration.instant` interpolasyon.
2. **`.static(samples:)`** — entry kartında özet. 60 bar, `content.tertiary`.
3. **`.player(samples:progress:)`** — oynatıcı. Çalınan kısım `accent.secondary`, kalanı `border.default`. Sürüklenebilir scrubber.

Bar genişliği 3pt, boşluk 2pt, radius `full`, min height 4pt.

## 4.17 EchoRecordButton
- **idle:** 72×72 daire, `accent.primary`, ortada mikrofon ikonu.
- **recording:** 72×72, ortada 28×28 yuvarlak kare (radius 8) "stop", etrafında **3 ripple halkası** ses seviyesine göre nefes alır (`duration.ambient`).
- **paused:** halkalar donar, opacity 0.5.
- **processing:** halkalar yavaş dönen kısmi ark olur.
- Basılı tutma = "push to talk", tek dokunuş = toggle. Her geçişte haptic.

## 4.18 EchoMoodPicker
Yatay 5 seçenek, her biri 56×72 (şekil + etiket). Seçili: şekil scale 1.15 + `bg.accentSoft` kapsül + `subhead` etiket görünür.
`.compact` varyantı: 5 nokta, sadece şekil, 32×32 — composer toolbar için.
Haptic `.selection` her değişimde.

## 4.19 EchoMoodChart
Dot-plot + trend çizgisi. X: gün (7/30/90 aralık seçici `EchoSegmentedControl` ile). Y: 1-5 mood.
- Noktalar: mood renginde, 8pt, seçili 12pt.
- Trend: 2pt `content.accent` @ 40%, `.catmullRom` yumuşatma.
- Boş günler: `border.subtle` içi boş 6pt daire.
- Dokunma: en yakın noktayı seçer, üstte `EchoCard` tooltip (tarih + mood + entry başlığı).
- Y ekseni: sayı değil, mood şekilleri.
- **`.compact` varyantı:** height 88pt, eksen etiketleri yok, trend çizgisi + noktalar, dokunma kapalı. Haftalık rapor kartının içinde kullanılır.

## 4.20 EchoChatBubble
| Rol | Hizalama | Zemin | Radius | Tipografi |
|---|---|---|---|---|
| `.user` | sağ | `accent.primary` | `lg` (sağ alt `xs`) | `body` / `content.onAccent` |
| `.coach` | sol | `bg.surface` + 1px `border.subtle` | `lg` (sol alt `xs`) | `body` / `content.primary` |
| `.system` | orta | yok | — | `footnote` / `content.tertiary` |

- Max genişlik %78.
- **Streaming:** metin karakter karakter değil, **kelime kelime** fade-in (`duration.fast`). Sonunda imleç yanıp söner.
- **Typing:** 3 ripple halkası pulse (3 nokta değil).
- Uzun basma: Kopyala / Yeniden üret / Günlüğe kaydet.

## 4.21 EchoReflectionBlock  *(Echo'nun imzası)*
AI yansımasını günlük metninin içine gömen blok.
- Sol kenarda 3pt dikey `accent.primary` şerit.
- Zemin `bg.accentSoft`, radius `md(14)`, padding 16, sol padding 20.
- Üstte `caption2` overline: "ECHO" + ripple ikon.
- Gövde `entryQuote` (serif italic).
- Altta ghost aksiyonlar: `Devam et` · `Başka açıdan` · `Kaydet`.

## 4.22 EchoPromptCard
Rehberli günlük önerisi. `EchoCard .flat`, üstte kategori chip'i, `title3` soru, `footnote` süre tahmini ("~5 dk"), sağ altta ok. Karusel içinde 280pt genişlik.

## 4.23 EchoEntryCard
Feed öğesi.
```
[moodShape]  14 Eylül · 07:42        [•••]
             Sabah düşünceleri
             Bugün kendimi şaşırtıcı derecede...
             [~~ waveform 2:14 ]  [#iş] [#uyku]
```
- Radius `lg`, `bg.surface`, `elev.1`, padding 16.
- Snippet max 3 satır, `entry` tipografisi, `content.secondary`.
- Sesli entry ise mini `.static` waveform + süre; değilse kelime sayısı.
- Sola kaydır: Arşivle / Sil. Sağa kaydır: Favori.

## 4.24 EchoInsightCard
`EchoCard .raised`. Üstte 32×32 soft ikon container + `caption2` kategori. `title3` başlık, `body` gövde. Altta: `Paylaş` ghost + `bookmark` ikon.

## 4.25 EchoWeeklyReportCard
Tam genişlik, radius `xl(28)`.
- Header: küçük illüstrasyon + `title2` hafta başlığı + `footnote` tarih aralığı.
- Gövde: `entry` tipografisiyle 3-4 cümlelik özet.
- Alt bölüm: `EchoMoodChart .compact` + "Ana Temalar" chip bulutu.
- Footer: `Paylaş` · `Tam raporu aç`.

## 4.26 EchoAchievementTile
Grid hücresi (3 sütun). 
- **Kilitli:** `bg.surfaceSunken`, grayscale ikon, opacity 0.45, altta kilit.
- **Açık:** `bg.accentSoft`, renkli ikon, `caption` isim, `caption2` tarih.
- Açılma anı: ripple patlaması + `spring.bouncy` + haptic `.success`.

## 4.27 EchoStatTile
`numeric` büyük sayı + `caption2` etiket + opsiyonel trend oku (`aqua`/`coral`). 3'lü satır halinde profilde.

## 4.28 EchoEmptyState
Dikey ortalı: ripple illüstrasyonu (120pt) + `title3` başlık + `callout` açıklama + `EchoButton .secondary` CTA. Max genişlik 300pt.

## 4.29 EchoSkeleton
Shimmer: `bg.surfaceSunken` → `border.subtle` gradient, 1.4s döngü, 20° eğim. Kart/satır/metin şekillerinde hazır preset'ler. `Reduce Motion`'da sabit `bg.surfaceSunken`.

## 4.30 EchoPlanCard (paywall)
- Seçili: 2px `border.accent` + `bg.accentSoft` + sağ üstte tik.
- İçerik: plan adı `headline`, fiyat `numeric`, periyot `footnote`, tasarruf rozeti (`amber` pill).
- "En popüler" şeridi üst kenarda.

## 4.31 EchoOnboardingProgress
Üstte ince bar: `border.subtle` track + `accent.primary` dolgu, height 4, radius `full`, `spring.smooth`. Solda geri oku, sağda `caption` "4 / 12".

## 4.32 Yardımcılar
`EchoDivider` (1px `border.subtle`, opsiyonel inset) · `EchoSectionHeader` (`caption2` ALL CAPS `content.tertiary` + opsiyonel sağ aksiyon) · `EchoBadge` (sayı rozeti) · `EchoShimmerText`.

---

# Bölüm 5 — Ekran Layout'ları

## 5.0 Navigasyon Haritası

```
RootView
├── AuthFlow (çıkış yapmışsa)
│   ├── SplashView
│   ├── WelcomeView
│   └── SignInView
├── OnboardingFlow (ilk kez)
│   └── 12 adım → PaywallView (soft)
└── MainTabView
    ├── Bugün      → TodayView → GuidedSessionView
    ├── Günlük     → JournalFeedView → EntryDetailView
    │                             └── InsightsView (segment)
    ├── ( ● Kayıt ) → RecordingView → TranscriptReviewView → EntryDetailView
    ├── Topluluk   → CommunityFeedView → PostDetailView / ComposePostView
    └── Profil     → ProfileView → AchievementsView / SettingsView / MoodTrackerView

Modal: CoachChatView (Bugün'den ve EntryDetail'den açılır)
```

---

## 5.1 Onboarding (12 adım)

Ortak iskelet: `EchoOnboardingProgress` (üst) → içerik (ortalı, max 340pt) → `EchoButton .primary .lg .fullWidth` (alt, safe area üstü 16pt).
Zemin: `bg.canvas`. Sadece 1. ve 12. adımda `aurora.primary` gradient.

| # | Ekran | İçerik |
|---|---|---|
| 1 | Karşılama | Ripple animasyonu + `display` "Sesin, senin aynan" + `Başla` |
| 2 | İsim | `EchoTextField` — "Sana nasıl hitap edelim?" |
| 3 | Amaç | Çoklu seçim chip grid: Stresi azaltmak · Kendimi tanımak · Alışkanlık kurmak · Duyguları anlamak · Kararlarımı netleştirmek |
| 4 | Odak alanları | Chip grid: İş · İlişkiler · Sağlık · Yaratıcılık · Para · Aile |
| 5 | Günlük deneyimi | 3 seçenek kartı: Hiç yazmadım / Ara sıra / Düzenli |
| 6 | Tercih edilen mod | 2 büyük kart: **Sesli** (önerilen) / **Yazılı** |
| 7 | Koç tonu | 3 kart: Sıcak & destekleyici · Doğrudan & net · Meraklı & sorgulayıcı |
| 8 | Hatırlatma zamanı | `DatePicker .wheel` + gün seçici chip'ler |
| 9 | Bildirim izni | Açıklama + `Bildirimlere izin ver` (sistem prompt'u sonra) |
| 10 | Mikrofon izni | Ripple animasyonu + `Mikrofona izin ver` |
| 11 | Kurulum | `EchoProgressRing` 88pt + sırayla beliren adım metinleri (2.5s toplam) |
| 12 | Hazır | `aurora.primary` zemin, `display` "Hazırsın, {isim}" + `İlk kaydını yap` |

> Her adımda **Atla** ghost butonu sağ üstte (3, 4, 8 hariç). İlerleme `UserDefaults`'ta saklanır; uygulama kapanırsa kaldığı yerden devam.

---

## 5.2 Paywall (soft — ilk AI yansımasından sonra)

```
┌─────────────────────────────────┐
│  ✕                              │
│                                 │
│     [ripple illüstrasyon]       │
│                                 │
│  Echo Pro                       │  display
│  Sınırsız yansıma, kalıcı       │  callout / content.secondary
│  hafıza ve haftalık raporlar    │
│                                 │
│  ✓ Sınırsız sesli günlük        │  ListRow, aqua tik
│  ✓ Uzun dönem hafıza            │
│  ✓ Haftalık içgörü raporu       │
│  ✓ Rehberli günlük kütüphanesi  │
│  ✓ Koç sohbeti                  │
│                                 │
│  ┌───────────┐  ┌───────────┐   │  EchoPlanCard ×2
│  │ Aylık     │  │ Yıllık ★  │   │
│  │ ₺X /ay    │  │ ₺Y /ay    │   │
│  └───────────┘  └───────────┘   │  %40 tasarruf rozeti
│                                 │
│  [ 7 gün ücretsiz dene ]        │  EchoButton .primary .lg
│  Sonra ₺Y/yıl · İstediğin       │  footnote, ortalı
│  zaman iptal et                 │
│  Geri yükle · Şartlar · Gizlilik│  caption, ghost
└─────────────────────────────────┘
```
- Zemin: `bg.canvas`, üstte hafif `aurora.primary` @ 12% radial.
- Kapatma (✕) **ilk 2 saniye gizli** değil — hemen görünür (karanlık desen yok).

---

## 5.3 Bugün (TodayView)

```
Merhaba, Atakan                    [🔔] [👤]   ← NavBar large
Perşembe, 14 Eylül                              footnote

┌──── EchoStreakBadge ────┐
│  ◎ 12 gün               │  aurora.celebration
└─────────────────────────┘

┌─────────────┐  ┌─────────────┐       ← 2 sütun, eşit
│  ☀️         │  │  🌙         │
│  Sabah      │  │  Akşam      │
│  Niyeti     │  │  Yansıması  │
│  Güne başla │  │  Günü kapat │
│  ✓ tamam    │  │  bekliyor   │
└─────────────┘  └─────────────┘       EchoCard .interactive

BUGÜN İÇİN                             SectionHeader
┌──────────────────────────────────┐
│ [chip: Farkındalık]              │   EchoPromptCard karuseli
│ Bugün seni en çok ne yordu?      │   yatay scroll
│ ~4 dk                         →  │
└──────────────────────────────────┘

SON KAYITLARIN                         SectionHeader + "Tümü"
┌──────────────────────────────────┐
│ EchoEntryCard ×2                 │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ 💬 Koçunla konuş                 │   EchoListRow → CoachChat modal
└──────────────────────────────────┘
```

---

## 5.4 Kayıt (RecordingView) — tam ekran modal

```
┌─────────────────────────────────┐
│  ✕                        0:42  │  numeric, tabular
│                                 │
│         aurora.record           │  radial gradient zemin
│                                 │
│    "Bugün seni en çok ne        │  entry, ortalı, max 300pt
│     yordu?"                     │  content.onAccent @ 90%
│                                 │
│                                 │
│         ◉ ◉ ◉                   │  EchoRecordButton
│      ripple halkalar            │  (ses seviyesine göre)
│                                 │
│    ~~~~~~~~~~~~~~~~~~~~         │  EchoWaveform .live
│                                 │
│   [⏸]      [●]      [✓]         │  duraklat / kayıt / bitir
│                                 │
│  Aa Yazıya geç                  │  ghost buton
└─────────────────────────────────┘
```
- Ekran uyanık kalır (`isIdleTimerDisabled`).
- Canlı transkripsiyon opsiyonel: alt kısımda son 2 satır, `content.onAccent` @ 60%, fade-in.
- Bitirince → `TranscriptReviewView`.

## 5.5 Transkript İnceleme

- Üstte `EchoWaveform .player` + süre + hız (1x/1.5x/2x).
- Ortada düzenlenebilir transkript (`entry` serif, `EchoTextEditor`).
- Altta: `EchoMoodPicker`, etiket chip'leri (AI önerir, kullanıcı ekler/çıkarır).
- CTA: `Kaydet ve yansıt` (`.primary`) · `Sadece kaydet` (`.ghost`).
- Kaydetme sonrası → `EntryDetailView`, AI yansıması streaming ile gelir.

## 5.6 Günlük (JournalFeedView)

- `EchoSegmentedControl`: **Akış** · **Takvim** · **İçgörüler**
- **Akış:** tarihe göre gruplanmış `EchoEntryCard` listesi, sticky `EchoSectionHeader` (ay).
- **Takvim:** ay görünümü; her gün mood renginde nokta; dolu günler kalın. Gün seçince altta o günün entry'leri.
- **İçgörüler:** → 5.9
- NavBar sağında: `magnifyingglass` (search) + `line.3.horizontal.decrease` (filtre sheet: mood, etiket, tür, tarih).
- Empty state: `EchoEmptyState` + "İlk kaydını yap".

## 5.7 Entry Detay

```
← 14 Eylül · 07:42               [•••]
Sabah düşünceleri                       title1

[~~~~ player waveform 2:14 ~~~~]        sesli ise

Bugün kendimi şaşırtıcı derecede        entry (serif 18/28)
dingin hissettim. Dün akşamki...

┌│ ECHO ◎                             │  EchoReflectionBlock
 │ Son üç kaydında "dinginlik"          │
 │ kelimesi hep sabah saatlerinde       │
 │ geçiyor. Sabah rutinin işe           │
 │ yarıyor olabilir.                    │
 │ Devam et · Başka açıdan · Kaydet     │
└──────────────────────────────────────┘

◐ İyi          [#iş] [#uyku] [+]        mood + etiketler

[Koçla konuş]  [Toplulukla paylaş]      EchoButton .secondary ×2
```
`•••` menü: Düzenle · Sesi indir · Paylaş · Arşivle · Sil (onaylı).

## 5.8 Rehberli Günlük (Guided)

- **Liste:** kategori chip filtreleri (CBT · Şükran · IFS · Hedef · İlişki · Uyku) + `EchoPromptCard` grid (2 sütun).
- **Oturum:** tek soru ekranı, üstte `EchoOnboardingProgress` (3/7), `title2` soru, altında `EchoComposer` (ses/yazı toggle), `İleri`. Son adımda özet + AI yansıması.

## 5.9 İçgörüler (InsightsView)

```
İçgörüler                                title1
[ Hafta ] [ Ay ] [ 3 Ay ]                SegmentedControl

┌── EchoWeeklyReportCard ──────────────┐
│ 🏔  Sakin Sabahlar ve Yoğun Akşamlar │
│ 8–14 Eylül                           │
│ Bu hafta sabahların belirgin şekilde │ entry
│ daha dingin geçti...                 │
│                                      │
│ [mood chart compact]                 │
│ ANA TEMALAR                          │
│ [iş stresi] [uyku] [sabah rutini]    │
│                                      │
│ Paylaş · Tam raporu aç               │
└──────────────────────────────────────┘

DUYGU HARİTASI                          SectionHeader
┌── EchoMoodChart (tam) ───────────────┐

ÖRÜNTÜLER                               SectionHeader
┌── EchoInsightCard ×3 ────────────────┐
│ 💤 "Geç yattığın günlerin ertesinde   │
│    mood'un ortalama 1.2 puan düşük"  │

İSTATİSTİK                              SectionHeader
[ 47 kayıt ] [ 12 gün streak ] [ 6.2sa ]  EchoStatTile ×3
```

## 5.10 Mood Takibi
Tam ekran `EchoMoodChart` + altında gün gün liste (`EchoListRow`, leading mood şekli, trailing entry sayısı). Üstte aralık seçici + "En iyi gün / En zor gün" özet kartları.

## 5.11 Koç Sohbeti (modal, `.large` detent)
- NavBar: "Echo Koç" + `content.secondary` alt satır "Günlüklerini hatırlıyor" + kapat.
- `EchoChatBubble` listesi, streaming.
- Boşken: 3 `EchoPromptCard` öneri ("Bu hafta neden yorgunum?" gibi).
- Alt bar: `EchoTextField` + mic + gönder. Klavye açıkken `.ultraThinMaterial`.
- Koç bir günlüğe atıfta bulunursa → tıklanabilir `EchoChip` (entry'ye gider).

## 5.12 Topluluk
- **Feed:** `EchoSegmentedControl` (Keşfet · Takip · Benim). Post kartı: avatar (anonim ise ripple avatar) + takma ad + zaman + gövde (`entry`, max 6 satır) + opsiyonel mood chip + aksiyon satırı `◎ Echo'la (24)` · `💬 8` · `↗`.
- **Post detay:** tam gövde + yorumlar (threaded, 1 seviye).
- **Compose:** "Bir günlüğünden paylaş" (entry seçici) veya sıfırdan yaz. **Anonim varsayılan açık.** Paylaşmadan önce AI hassas-bilgi uyarısı (isim/adres tespit edilirse banner).

## 5.13 Başarımlar
3 sütun `EchoAchievementTile` grid, kategori section'ları (Süreklilik · Keşif · Derinlik · Topluluk). Üstte büyük `EchoProgressRing` (toplam ilerleme) + streak.

## 5.14 Profil & Ayarlar
- Header: `EchoAvatar .xl` (streak ring'li) + isim + üyelik rozeti.
- `EchoStatTile` ×3.
- Gruplu `EchoListRow` listesi:
  - **Günlük:** Hatırlatmalar · Rehberli günlükler · Etiketler · Dışa aktar
  - **Echo:** Koç tonu · Hafıza ayarları · Dil
  - **Görünüm:** Tema (Sistem/Açık/Koyu) · Metin boyutu · Hareketi azalt
  - **Gizlilik:** Face ID kilidi · Topluluk anonimliği · Veri & silme
  - **Hesap:** Abonelik · Destek · Çıkış

---

# Bölüm 6 — Claude Code Prompt Blokları

> **Kullanım:** Her bloğu sırayla Claude Code'a ver. Bir blok bitmeden diğerine geçme.
> Her bloğun başında bu dokümanı referans olarak ekle:
> `Bu projede @echo-design-system.md dosyasındaki spec'i takip et.`

---

## P0 — Proje iskeleti ve tema altyapısı

```
Echo adlı SwiftUI iOS uygulaması için design system altyapısını kur. iOS 17+, SwiftUI, MVVM.

Dizin yapısı:
Echo/
  App/                      EchoApp.swift, RootView.swift
  DesignSystem/
    Tokens/                 EchoColor.swift, EchoTypography.swift, EchoSpacing.swift,
                            EchoRadius.swift, EchoElevation.swift, EchoMotion.swift
    Theme/                  AppTheme.swift, ThemeManager.swift, EchoTheme+Environment.swift
    Components/             (sonraki adımlarda dolacak)
    Modifiers/              EchoCardStyle.swift, EchoPressable.swift, EchoShimmer.swift
  Features/                 (sonraki adımlarda)
  Core/                     Models/, Services/, Extensions/

Gereksinimler:
1. EchoColor: önce primitive ramp'lar (violet50-950, aqua50-900, amber, coral,
   neutral0-1000) statik Color sabitleri olarak. Sonra ColorScheme'e duyarlı
   semantic token'lar: bg.canvas, bg.surface, bg.surfaceRaised, bg.surfaceSunken,
   bg.accentSoft, bg.aquaSoft, bg.inverse, content.primary/secondary/tertiary/
   disabled/accent/onAccent/inverse, border.subtle/default/strong/accent,
   accent.primary/primaryPressed/secondary, feedback.success/warning/danger/info.
   Hex değerleri için @echo-design-system.md Bölüm 3.2 tablosunu birebir kullan.
2. Semantic token'lar Asset Catalog color set'leri OLARAK üretilsin (light+dark
   appearance), koda gömülü if-else ile DEĞİL. Asset Catalog Contents.json
   dosyalarını da oluştur.
3. EchoTypography: Bölüm 3.3'teki tüm token'lar. Dynamic Type destekli
   (.custom(_:size:relativeTo:)). "entry" ve "entryQuote" için New York serif
   (.serif design). display/title1 için SF Pro Rounded (.rounded design).
4. EchoSpacing, EchoRadius (.continuous corner style), EchoElevation
   (light=gölge, dark=yüzey+glow — ColorScheme'e duyarlı ViewModifier),
   EchoMotion (duration sabitleri + Animation preset'leri).
5. ThemeManager: @Observable, AppStorage ile system/light/dark seçimi,
   reduceMotion ve dynamicTypeSize köprüleri.
6. AppTheme.swift: yukarıdakileri tek bir namespace altında toplayan facade
   (AppTheme.color.bg.surface, AppTheme.type.entry, AppTheme.space.md gibi).
7. Bir TokenGalleryView ekle: tüm renk, tipografi, spacing, radius ve
   elevation token'larını görsel olarak listeleyen debug ekranı. #Preview'ları
   light ve dark için ayrı ayrı ekle.

UI kodu YAZMA, sadece token + tema altyapısı. Her dosyaya kısa doc comment ekle.
```

---

## P1 — Temel component'ler (form & container)

```
@echo-design-system.md Bölüm 4.1-4.8'i uygula.

Echo/DesignSystem/Components/ altında şu component'leri yaz:
- EchoButton (variant: primary/secondary/tertiary/ghost/destructive,
  size: sm/md/lg/pill, leadingIcon, trailingIcon, isLoading, isFullWidth)
- EchoIconButton (plain/soft/filled/glass, 44pt min touch target)
- EchoChip (static/selectable/removable/mood)
- EchoCard (flat/raised/gradient/interactive) — ViewModifier + View wrapper ikisi de
- EchoListRow (generic leading/trailing slot'ları ile)
- EchoTextField, EchoTextEditor (focus/error/disabled state'leri)
- EchoSegmentedControl (matchedGeometryEffect ile animasyonlu thumb)
- EchoDivider, EchoSectionHeader, EchoBadge

Kurallar:
- Hiçbir yerde hard-coded renk/font/spacing/radius OLMASIN. Sadece AppTheme.*
- Her component ayrı dosyada, sonunda #Preview: light + dark + Dynamic Type
  .accessibility1 varyantları yan yana.
- Pressed state için ortak EchoPressable ButtonStyle kullan (scale 0.97,
  AppTheme.motion.springSnappy).
- Tüm interaktif component'lere .accessibilityLabel / .accessibilityAddTraits ekle.
- EchoButton'da isLoading iken genişlik sabit kalmalı (layout zıplamasın).
```

---

## P2 — Navigasyon kabuğu

```
@echo-design-system.md Bölüm 4.9-4.12 ve 5.0'ı uygula.

- EchoTabBar: 4 sekme (Bugün, Günlük, Topluluk, Profil) + merkezde yükseltilmiş
  kayıt butonu. NOT: gerçek EchoRecordButton P3'te gelecek — burada sadece
  statik bir daire + mikrofon ikonu koy, protokolü/arayüzü P3 ile uyumlu tut.
  Custom tab bar (sistem TabView'ı gizle, kendi barını çiz).
  .ultraThinMaterial zemin, aktif sekmede filled ikon + 4pt accent nokta.
  Merkez buton 58x58, 8pt yukarı taşar, aurora.record gradient, elev.3.
- EchoNavBar: large title -> inline collapse, scroll'da alt border fade-in.
- EchoBottomSheet: presentationDetents wrapper + grabber + başlık satırı.
- EchoToast: alttan slide-in, 2.5s auto-dismiss, swipe-to-dismiss, undo action
  slot'u. ToastManager (@Observable) + .echoToast() view modifier ile global kullanım.
- EchoBanner: inline, feedback renk varyantları.
- MainTabView + RootView: AuthFlow / OnboardingFlow / MainTabView arasında geçiş.
  Şimdilik her sekme için placeholder ekran.
- Merkez kayıt butonuna basınca RecordingView fullScreenCover olarak açılsın
  (şimdilik boş ekran).

Navigation: her sekme kendi NavigationStack'ine sahip olsun, NavigationPath ile
programatik yönlendirme desteklensin.
```

---

## P3 — Ses component'leri (Echo'nun imzası)

```
@echo-design-system.md Bölüm 4.16-4.17 ve 2.2'yi uygula.

- EchoRippleView: 3-5 eş merkezli halka, dışa doğru açılan, opaklığı azalan.
  Parametreler: ringCount, intensity (0-1), speed, color, isAnimating.
  TimelineView + Canvas ile 60fps. Reduce Motion açıkken statik halka.
- EchoWaveform: tek component, üç mod —
  .live(level: Float)          40 bar, ortadan dışa, accent.secondary
  .static(samples: [Float])    60 bar, content.tertiary
  .player(samples:progress:onScrub:)  çalınan kısım accent.secondary
  Bar 3pt genişlik, 2pt boşluk, radius full, min height 4pt. Canvas ile çiz.
- EchoRecordButton: idle / recording / paused / processing state machine.
  recording'de EchoRippleView intensity = ses seviyesi. Geçişlerde
  matchedGeometryEffect ile mikrofon <-> stop kare morph'u.
  Tek dokunuş = toggle, basılı tutma = push-to-talk.
  Her state geçişinde UIImpactFeedbackGenerator.
- EchoTypingIndicator: 3 ripple halkası pulse (nokta değil).

Hepsi mock veriyle çalışan #Preview'lara sahip olsun (sahte ses seviyesi
üreten bir Timer ile canlı önizleme).
```

---

## P4 — İçerik component'leri

```
@echo-design-system.md Bölüm 4.18-4.32'yi uygula.

- EchoMoodPicker (full + compact) — renk + ŞEKİL, renk körlüğü uyumlu.
  Şekiller: aşağı üçgen / alt yarım daire / daire / üst yarım daire /
  yukarı üçgen(ripple'lı). Her değişimde selection haptic.
- EchoMoodChart — Swift Charts ile dot-plot + catmullRom trend çizgisi.
  7/30/90 gün aralıkları, boş günler içi boş daire, dokunmayla en yakın
  nokta seçimi + tooltip kartı. Y ekseni sayı değil mood şekilleri.
- EchoChatBubble (user/coach/system) + kelime kelime streaming fade-in +
  uzun basma context menu (Kopyala / Yeniden üret / Günlüğe kaydet).
- EchoReflectionBlock — sol 3pt accent şerit, bg.accentSoft, "ECHO" overline +
  ripple ikon, entryQuote serif italic gövde, ghost aksiyon satırı.
- EchoPromptCard, EchoEntryCard (swipe actions dahil), EchoInsightCard,
  EchoWeeklyReportCard, EchoAchievementTile, EchoStatTile, EchoStreakBadge,
  EchoProgressRing, EchoAvatar, EchoEmptyState, EchoSkeleton, EchoPlanCard,
  EchoOnboardingProgress.

Her component için mock data factory'si yaz (EchoMockData.swift) ki
Preview'lar ve sonraki ekranlar gerçekçi veriyle çalışsın.
```

---

## P5 — Onboarding + Paywall

```
@echo-design-system.md Bölüm 5.1 ve 5.2'yi uygula.

- OnboardingFlow: 12 adımlı, ortak OnboardingScaffold (üst EchoOnboardingProgress,
  ortada içerik max 340pt, altta primary CTA). Adım listesi ve içerikleri
  Bölüm 5.1 tablosunda.
- OnboardingViewModel (@Observable): cevapları toplar, UserDefaults'a yazar,
  uygulama kapanıp açılırsa kaldığı adımdan devam eder.
- Adım 11 (Kurulum): EchoProgressRing 88pt + sırayla fade-in olan adım metinleri,
  toplam 2.5s.
- Geçişler: yatay slide + fade, AppTheme.motion.springSmooth. Reduce Motion'da
  sadece fade.
- PaywallView: Bölüm 5.2'deki layout. EchoPlanCard x2 (aylık/yıllık, yıllıkta
  "En popüler" şeridi + tasarruf rozeti). StoreKit 2 ile ürün çekme iskeleti
  (PaywallViewModel, Product listesi, purchase/restore fonksiyonları — gerçek
  ürün ID'leri TODO olarak bırak).
- Paywall "soft": kapat butonu baştan görünür. Dismiss edilince onboarding
  tamamlanmış sayılır.
```

---

## P6 — Kayıt akışı

```
@echo-design-system.md Bölüm 5.4 ve 5.5'i uygula.

- RecordingView (fullScreenCover): aurora.record radial gradient zemin,
  üstte süre (numeric tabular) + kapat, ortada prompt metni (entry serif,
  content.onAccent @90%), EchoRecordButton + EchoWaveform .live,
  altta duraklat / bitir, en altta "Aa Yazıya geç" ghost butonu.
- AudioRecorderService: AVAudioEngine ile kayıt, RMS seviyesi publish
  (@Observable, 60Hz), pause/resume, m4a olarak dosyaya yazma.
  AVAudioSession kategorisi ve interruption handling dahil.
- SpeechTranscriptionService: SFSpeechRecognizer ile canlı transkripsiyon
  (on-device tercih), Türkçe + İngilizce. Canlı sonuçlar RecordingView'ın
  altında son 2 satır olarak fade-in ile gösterilsin.
- Ekran uyanık kalsın (isIdleTimerDisabled).
- TranscriptReviewView: EchoWaveform .player + hız kontrolü (1x/1.5x/2x),
  düzenlenebilir transkript (EchoTextEditor, entry serif), EchoMoodPicker,
  AI'ın önerdiği etiket chip'leri (şimdilik mock), CTA'lar:
  "Kaydet ve yansıt" (.primary) / "Sadece kaydet" (.ghost).
- İzin akışları: mikrofon ve konuşma tanıma izni reddedilirse EchoEmptyState +
  Ayarlar'a yönlendirme.
```

---

## P7 — Günlük akışı ve entry detay

```
@echo-design-system.md Bölüm 5.6 ve 5.7'yi uygula.

- JournalFeedView: EchoSegmentedControl (Akış / Takvim / İçgörüler).
  * Akış: aya göre gruplu, sticky EchoSectionHeader, EchoEntryCard listesi,
    swipe actions (Arşivle/Sil, Favori), pull-to-refresh, sayfalama.
  * Takvim: ay grid'i, her günde mood rengi noktası, gün seçince altta o günün
    entry listesi.
- SearchView: debounce'lu arama, sonuçlarda eşleşen metin highlight.
- FilterSheet (EchoBottomSheet): mood aralığı, etiketler, tür (sesli/yazılı),
  tarih aralığı. Aktif filtre sayısı NavBar ikonunda badge olarak görünsün.
- EntryDetailView: Bölüm 5.7 layout'u. Sesli ise üstte EchoWaveform .player,
  gövde entry serif (max 68 karakter satır genişliği), EchoReflectionBlock,
  mood + etiket satırı, altta "Koçla konuş" / "Toplulukla paylaş".
  ••• menüsü: Düzenle · Sesi indir · Paylaş · Arşivle · Sil (onaylı alert).
- AI yansıması streaming ile gelsin (EchoReflectionBlock içinde kelime kelime).
- Boş durumlar için EchoEmptyState.
```

---

## P8 — İçgörüler, mood takibi, koç sohbeti

```
@echo-design-system.md Bölüm 5.9, 5.10, 5.11'i uygula.

- InsightsView: aralık seçici (Hafta/Ay/3 Ay), EchoWeeklyReportCard,
  tam EchoMoodChart, EchoInsightCard listesi, EchoStatTile satırı.
  Haftalık raporun paylaşılabilir görsel export'u (ImageRenderer ile PNG).
- MoodTrackerView: tam ekran chart + gün gün EchoListRow listesi +
  "En iyi gün / En zor gün" özet kartları.
- CoachChatView (.sheet, .large detent): EchoChatBubble listesi, streaming
  yanıt, boşken 3 EchoPromptCard önerisi, alt bar (EchoTextField + mic + gönder).
  Koç bir günlüğe atıf yaparsa tıklanabilir EchoChip -> EntryDetailView.
- CoachChatViewModel: mesaj geçmişi, streaming token handling, hata/retry.
- Tüm veri şimdilik EchoMockData'dan gelsin; servis katmanı protokol arkasında
  olsun (InsightsServiceProtocol, CoachServiceProtocol) ki P10'da gerçek
  backend'e bağlanabilsin.
```

---

## P9 — Topluluk, başarımlar, profil, ayarlar

```
@echo-design-system.md Bölüm 5.12, 5.13, 5.14'ü uygula.

- CommunityFeedView: segment (Keşfet/Takip/Benim), post kartı (anonim ise
  ripple avatar), aksiyon satırı "◎ Echo'la (n) · 💬 n · ↗".
- PostDetailView: tam gövde + tek seviye threaded yorumlar.
- ComposePostView: "Bir günlüğünden paylaş" (entry seçici sheet) veya sıfırdan
  yaz. Anonim toggle VARSAYILAN AÇIK. Paylaşmadan önce metinde isim/adres/
  telefon tespit edilirse EchoBanner ile uyarı (NSDataDetector + basit regex).
- Raporlama ve engelleme akışı (App Store UGC gereksinimi).
- AchievementsView: 3 sütun grid, kategori section'ları, üstte büyük
  EchoProgressRing + streak. Açılma animasyonu: ripple patlaması +
  springBouncy + success haptic.
- ProfileView: EchoAvatar .xl (streak ring), EchoStatTile x3, gruplu ayar
  listesi (Bölüm 5.14'teki tüm satırlar).
- SettingsView alt ekranları: Tema seçici (Sistem/Açık/Koyu — canlı önizleme),
  Hatırlatmalar (UNUserNotificationCenter), Face ID kilidi (LocalAuthentication),
  Veri dışa aktarma (JSON + ses dosyaları -> ShareLink), Hesap silme (çift onay).
```

---

## P10 — Veri katmanı ve backend bağlantısı

```
Echo için veri katmanını kur ve Spring Boot backend'e bağla.

- Core/Models: Entry, Reflection, MoodLog, Tag, GuidedJournal, CommunityPost,
  Comment, Achievement, UserProfile, WeeklyReport. Codable + Identifiable.
- SwiftData ile yerel kalıcılık (offline-first). Ses dosyaları Application
  Support altında, model'de sadece relative path.
- APIClient: async/await, URLSession, typed error, token refresh interceptor,
  retry policy (exponential backoff, 3 deneme).
- Repository katmanı: her feature için protokol + LiveRepository (API+SwiftData)
  + MockRepository (Preview/test). ViewModel'ler protokole bağımlı olsun.
- Senkronizasyon: offline yazılan entry'ler kuyruğa alınsın, bağlantı gelince
  gönderilsin. Çakışmada "son yazan kazanır" + kullanıcıya toast.
- Ses yükleme: multipart upload, arka planda URLSession background task,
  ilerleme göstergesi.
- Keychain'de token saklama.
- Tüm ViewModel'lerdeki mock çağrılarını repository'lere taşı.
```

---

## P11 — Erişilebilirlik, performans ve kalite geçişi

```
Echo uygulamasında final kalite geçişi yap.

Erişilebilirlik:
- Tüm ekranlarda VoiceOver geçişi: her interaktif elemanda label + hint + value.
- Mood'lar asla sadece renkle anlatılmasın (şekil + metin kontrolü).
- Dynamic Type .accessibility3'e kadar hiçbir ekranda taşma/kesme olmasın —
  gerekirse ViewThatFits veya dikey stack'e düş.
- Reduce Motion: ripple/pulse/shimmer dursun, geçişler opacity'ye düşsün.
- Renk kontrastı: tüm content/bg çiftleri WCAG AA (metin 4.5:1, büyük 3:1).
  Kontrast testini yazan bir unit test ekle.
- Increase Contrast ayarında border.subtle -> border.strong'a geçsin.

Performans:
- JournalFeed'de LazyVStack + görünür olmayan waveform'ları çizme.
- EchoWaveform ve EchoRippleView'da Canvas + TimelineView; gereksiz
  body yeniden hesaplamalarını Instruments ile doğrula.
- Görsel ve ses dosyaları için NSCache tabanlı cache.
- Uygulama açılışı < 400ms'e kadar (soğuk başlangıç ölçümü ekle).

Test:
- Design token'lar için snapshot test (light + dark).
- Kritik ViewModel'ler için unit test.
- Kayıt -> transkript -> kaydet akışı için UI test.
```

---

# Bölüm 7 — Uygulama Sırası ve Kabul Kriterleri

| Adım | Blok | Çıktı | Kabul kriteri |
|---|---|---|---|
| 1 | P0 | Token + tema | TokenGalleryView light/dark'ta doğru render ediyor |
| 2 | P1 | Temel component'ler | Hiçbir dosyada hard-coded renk/font yok |
| 3 | P2 | Navigasyon | 4 sekme + merkez kayıt butonu çalışıyor |
| 4 | P3 | Ses component'leri | Ripple + waveform 60fps, Reduce Motion'da statik |
| 5 | P4 | İçerik component'leri | Tüm Preview'lar mock data ile doluyor |
| 6 | P5 | Onboarding + paywall | 12 adım tamamlanıyor, state kalıcı |
| 7 | P6 | Kayıt akışı | Gerçek cihazda kayıt + canlı transkript çalışıyor |
| 8 | P7 | Günlük + detay | Feed/takvim/arama/filtre çalışıyor |
| 9 | P8 | İçgörüler + koç | Chart etkileşimli, sohbet streaming |
| 10 | P9 | Topluluk + profil | Anonimlik varsayılan, raporlama akışı var |
| 11 | P10 | Veri katmanı | Offline-first, sync kuyruğu çalışıyor |
| 12 | P11 | Kalite | WCAG AA testi geçiyor, DT .accessibility3 sorunsuz |

## Değişmez kurallar (her prompt'a hatırlat)

1. `AppTheme` dışında renk/font/spacing/radius **yok**.
2. Her component kendi dosyasında + light/dark `#Preview`.
3. Her ekranda **en fazla 1 primary buton**.
4. Gradient sadece 3 yerde: record ekranı, streak rozeti, paywall.
5. Mood asla tek başına renkle anlatılmaz.
6. Dark temada gölge yok — yüzey açıklığı + glow.
7. Yıkıcı eylem her zaman onay ister.
8. Günlük gövde metni serif, UI sans.
9. `Reduce Motion` ve Dynamic Type her component'te test edilir.
10. Servis katmanı protokol arkasında — ViewModel somut sınıfa bağlanmaz.