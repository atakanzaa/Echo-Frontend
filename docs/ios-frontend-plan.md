# Echo iOS — Yeniden Tasarım ve Backend Entegrasyon Planı

> **Tarih:** 18 Eylül 2026 (Faz S sözleşme kapısı yeniden geçildi)
> **Sözleşme snapshot'ı:** `engineering/contracts/runtime-draft/mobile.json` = `ios/EchoAPI/Sources/EchoAPIContract/openapi.json` (symlink), sha256 `69b06d0459fc…`, 18 Eylül 14:52, **92 operasyon / 127 şema / 32 açık enum**
> **Kaynaklar:** `docs/implementation.md` (tasarım dili), `Echo Backend/engineering/frontend-handoff.html` + `rules.md` (entegrasyon kuralları), `mobile.json`, `ios/EchoAPI` (Swift paketi), `engineering/implementation-status.json`
>
> Bu belge **yalnız yukarıdaki snapshot'ı** mevcut kabul eder. Snapshot hash'i değiştiğinde Bölüm 4–7 yeniden doğrulanır (Faz S kapısı).
>
> **18 Eylül kapısı:** 14 Eylül snapshot'ında eksik olan uçların neredeyse tamamı backend'e girdi (kalıcı coach 202/operation, cursor sayfalama, kota karar alanları, Apple ile giriş, abonelik ürünleri ve paywall kararı, günlük silme, topluluk şikâyet/engelleme, sunucu tarafı arama, hedef sayaçları, kapsül özeti/preset'leri, takvim `today`, haftalık içgörü serisi, okunmamış sayısı, kayıt sınırları, sunucu sözlüğü etiketleri). Tipli tarih/enum/required sözleşmesi ve `EchoClient.make(serverURL:tokenStore:configuration:language:)` geldiği için Bölüm 6'daki geçici çözümler kaldırıldı. Ayrıntı: `Echo Backend/rules.md` ve `engineering/frontend-handoff.html`.

---

## 1. Değişmez kurallar

1. **Frontend karar hesaplamaz:** kota, premium, reklam, puan, streak, kapsül açma izni, job terminal kararı, sahiplik. Yalnız backend alanları gösterilir. Karar alanı yoksa özellik gösterilmez ve Bölüm 5'e yazılır.
2. **Planlanan ≠ mevcut:** cursor sayfalama, kalıcı coach (202/operation), `remaining/allowed_actions/reason_code`, entitlement resolver, ayrı replies sayfalaması sözleşmeye girene kadar kullanılmaz.
3. **Bilinmeyen değer korunur:** string enum'lar `unknown(raw)` ile taşınır; bilinmeyen durum başarılı veya izinli sayılmaz.
4. **Journal create:** kullanıcı niyeti başına tek `Idempotency-Key`; anahtar, gövde, journal id ve operation id cihazda kalıcı. Timeout = başarısızlık değil; aynı anahtar ve aynı gövdeyle uzlaştırılır.
5. **HTTP:** 204 decode edilmez; gövdesiz 200'ler ayrı ele alınır; `null`, boş liste ve eksik alan ayrı durumlardır; 429 `Retry-After`'a uyar.
6. **Hata gösterimi:** `Problem.detail` (güvenli metin) + `code` eşlemesi; `request_id` yalnız destek için; iç hata/Swift hata metni kullanıcıya gösterilmez.
7. **Tasarım (implementation.md §7):** `AppTheme` dışında renk/font/spacing/radius yok · ekran başına ≤1 primary buton · gradient yalnız 3 yerde · mood renk + şekil + etiketle anlatılır · dark temada gölge yok · yıkıcı eylem onaylı · günlük gövdesi serif.

---

## 2. Mimari kararlar

| Konu | Karar | Gerekçe |
|---|---|---|
| Minimum iOS | **17.0** (proje 26.2'den düşürülür) | implementation.md hedefi; `@Observable`, Swift Charts |
| UI | SwiftUI + Observation, her sekmede `NavigationStack` | spec P2 |
| Ağ | Yerel paket `../../Echo Backend/ios/EchoAPI`; generated `Client` + paketin `SessionCoordinator` / `SessionTransport` / `KeychainTokenStore` | "Mevcut Swift paketini kullan" |
| Client fabrikası | Doğrudan `EchoClient.make(serverURL:tokenStore:configuration:language:)`; uygulama kendi transport'unu kurmaz | Paket güvenlik ayarlarını, ortak refresh'i, güvenli retry'ı ve `Accept-Language`'i zaten yönetiyor (C1/C2/C8 kapandı) |
| Katmanlar | `Core/Networking` → `Core/Services` (domain başına protokol + Live + Preview) → `Features/*` ViewModel → View | spec kural 10; DI framework yok |
| Modeller | Generated DTO View'a sızmaz; domain modelleri + `unknown(String)` enum'ları | Sözleşme değişince yalnız mapper değişir |
| Liste soyutlaması | `ListPage<T>` (`items`, `nextCursor`, `hasMore`) | Sözleşmedeki cursor sayfalamasının birebir karşılığı |
| Kalıcılık | Yalnız bekleyen journal gönderimleri (Application Support JSON + ses dosyası) | SwiftData offline-first (P10) **uygulanmaz**: sözleşmede senkron/çakışma semantiği yok |
| Offline | Oturum içi son veri "son güncelleme" bilgisiyle korunur | rules.md iOS rehberi |
| Yerelleştirme | Uygulama metinleri `Localizable.xcstrings` (en kaynak, tr tam çeviri); **sunucudan gelen metin çevrilmez**, `Accept-Language` ile istenir ve olduğu gibi gösterilir | rules.md §11: rozet/streak/koç başlığı/sözlük etiketi/hata metni sunucu sorumluluğu |
| Tema | Semantic renkler Asset Catalog color set (light/dark), `ThemeManager` (Sistem/Açık/Koyu) | spec P0 |
| Sunucu adresi | Build setting `ECHO_API_BASE_URL` → Info.plist `EchoAPIBaseURL` (mevcut uygulamadaki `https://api.echojournal.net`) | Adres uydurulmaz, yapılandırılabilir |
| StoreKit ürünleri | `GET /subscription/products` (`product_id`) → StoreKit; Info.plist listesi kullanılmaz | Katalog sunucudan geldi (B-4 kapandı) |
| Kaldırılanlar | Admin izleme kabuğu, sabit fiyatlı eski Premium ekranı | Admin uçları mobil sözleşmede yok. Apple ile giriş **eklenir** (uç geldi) |
| Paket plugin'i | Xcode ilk açılışta "Trust & Enable" ister; CLI build `-skipPackagePluginValidation` | swift-openapi-generator build plugin'i |

---

## 3. Navigasyon haritası

```
RootView
├── LaunchView ── GET /app/config + Keychain oturum → GET /auth/me
├── AuthFlow ──── Welcome → SignIn | SignUp | ForgotPassword → ResetPassword
├── OnboardingFlow (hesap başına bir kez, 6 adım)
│     Karşılama → Rıza (KVKK + AI) → Hatırlatma saati → Bildirim izni → Mikrofon/Konuşma izni → Hazır
└── MainTabView   [ Bugün ] [ Günlük ] ( ● ) [ Topluluk ] [ Profil ]
      ├── Bugün     → EntryDetail · Goals · Notifications · CoachChat (modal)
      ├── Günlük    → Akış | Takvim | İçgörüler → EntryDetail · MoodTracker
      ├── ●         → Recording (fullScreen) → Review → EntryDetail   |   Composer (yazılı)
      ├── Topluluk  → Feed (Keşfet | Takip) → PostDetail · ComposePost
      └── Profil    → Achievements · Capsules · CoachSessions · Settings · Subscription/Paywall
```

---

## 4. Ekran – endpoint eşlemesi

**Durum:** ✅ sözleşmede var, uygulanır · 📱 cihaz içi · ⛔ backend alanı yok, UI'da gösterilmez

Tüm yollar `/api/v1` ile başlar. Değişken listeler `cursor` + `size` alır (varsayılan 20, üst sınır 100) ve `items` / `next_cursor` / `has_more` döndürür.

### 4.1 Açılış

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Uygulama ayarları | `GET /app/config?app_version=` (public) | ✅ | Tipli: `legal`, `support_email`, `ai_disclaimer{tr,en}`, `crisis_resource`, `consent_requirements`, `release`, `ads`, `recording`, `capsules.presets`. |
| Sözlük etiketleri | `GET /app/vocabulary` (public) | ✅ | mood kategorisi, enerji, trend, hedef durumu etiketleri istek dilinde. Dil değişince yeniden okunur. |
| Zorunlu güncelleme | `config.release.update_required` / `update_recommended` | ✅ | Sürüm karşılaştırmasını sunucu yapar; istemci `app_version` gönderir ve kararı uygular. |
| Oturum | Keychain → `GET /auth/me` | ✅ | Refresh paket içinde. Refresh 401 → çıkış; ağ/503 → oturum korunur, "tekrar dene". |
| Kayıt sınırları | `config.recording` | ✅ | `min_seconds`, `max_seconds`, `max_transcript_characters`; uygulamada sabit sayı tutulmaz. |

### 4.2 Kimlik doğrulama

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Karşılama | config (`legal.terms_url`, `privacy_policy_url`) | ✅ | Null link gizlenir. |
| E-posta ile giriş | `POST /auth/login` (200) | ✅ | 401 `INVALID_CREDENTIALS` form hatasıdır, refresh başlatmaz. |
| Kayıt | `POST /auth/register` (201) | ✅ | `display_name` zorunlu 2–100, şifre 8–100, IANA `timezone`, `language` `tr`/`en`. |
| Google ile giriş | GoogleSignIn SDK → `POST /auth/google` (200) | ✅ | `id_token` + timezone + language. |
| Apple ile giriş | AuthenticationServices → `POST /auth/apple` (200) | ✅ | Uygulama raw nonce üretir, Apple'a SHA-256 özetini verir, backend'e `identity_token` + `raw_nonce` (+ ilk yetkilendirmede `display_name`) gönderir. Apple yapılandırılmamışsa 503. |
| Şifremi unuttum | `POST /auth/forgot-password` (200) | ✅ | E-postanın kayıtlı olup olmadığı gösterilmez. |
| Şifre sıfırlama | `POST /auth/reset-password` (204) | ✅ | E-posta + 6 haneli kod + yeni şifre. |
| Şifre değiştir | `POST /auth/change-password` (200) | ✅ | Yalnız `password_login_enabled=true`; yeni token döner. |
| Çıkış | `POST /auth/logout` (204) | ✅ | Gövdede refresh token; ardından yerel temizlik. |
| E-posta doğrulama | — | ⛔ | `email_verified` alanı var, akış yok (B-19). |

### 4.3 Onboarding (spec 5.1: 12 adım → 6 adım)

| Spec adımı | Kaynak | Durum | Not |
|---|---|---|---|
| 1 Karşılama | 📱 | ✅ | |
| 2 İsim | `register.display_name`, `PATCH /users/me` | ✅ | |
| 3 Amaç · 4 Odak · 5 Deneyim · 6 Mod · 7 Koç tonu | — | ⛔ | Backend alanı yok; kullanılmayacak veri toplanmaz (B-14). |
| 8 Hatırlatma zamanı | `GET/PUT /notifications/preferences` | ✅ | `daily_reminders_enabled`, `preferred_local_hour`, `quiet_hours_*`, `timezone`. Gün seçimi ⛔. |
| 9 Bildirim izni | UNUserNotificationCenter + `POST /notifications/push-token` (201) | ✅ | `platform=ios`, `environment` `production`/`sandbox`. |
| 10 Mikrofon + konuşma tanıma izni | 📱 | ✅ | |
| 11 "Kurulum" animasyonu | — | ⛔ | Sahte ilerleme gösterilmez. |
| 12 Hazır | 📱 | ✅ | |
| + KVKK / AI eğitim rızası | `GET/PUT /privacy/consent` + `config.consent_requirements` | ✅ | Zorunluluk bilgisi config'ten. Topluluk kuralları da bu uçtan kabul edilir. |
| + AI sorumluluk reddi, kriz hattı | `config.ai_disclaimer`, `config.crisis_resource` | ✅ | |
| Onboarding tamamlandı bilgisi | — | ⛔ | Backend alanı yok; cihazda kullanıcı id'si başına saklanır (B-14). |

### 4.4 Paywall ve abonelik (5.2)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Ürün kataloğu | `GET /subscription/products` | ✅ | `product_id`, `plan` (`monthly`/`yearly`), `tier`, `highlighted`, özellik başına free/premium limit. |
| Fiyat / deneme | StoreKit 2 `Product.products(for:)` | ✅ | Ürün kimlikleri backend'den; fiyat asla sabit yazılmaz. |
| Paywall gösterim kararı | `subscription/status` → `paywall.offer`, `paywall.reason_code` | ✅ | Gösterim zamanlaması istemcide hesaplanmaz. |
| Paywall kapatma | `POST /subscription/paywall-dismissals` (204) | ✅ | Tekrar gösterme aralığını backend tutar. |
| Satın al / geri yükle | `POST /subscription/verify`, `POST /subscription/restore` | ✅ | Backend onayına kadar "beklemede"; sonra `transaction.finish()`. |
| Kota ve yetki | `subscription/status.quotas[]` | ✅ | `used`, `limit`, `unlimited`, `remaining`, `scope`, `allowed_actions`, `reason_code` olduğu gibi gösterilir; kalan hak hesaplanmaz. |

### 4.5 Bugün (5.3)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Selamlama + tarih | `GET /auth/me` | ✅ | Tarih kullanıcının backend timezone'uyla biçimlenir. |
| Streak rozeti | `me.current_streak`, `me.recorded_today` | ✅ | Aktiflik kararı da sunucudan. |
| Bugünkü kayıtlar | `GET /journal/entries?date=YYYY-MM-DD` | ✅ | Gün değeri `GET /calendar` yanıtındaki `today` ile aynı kaynaktan. |
| Son kayıtlar | `GET /journal/entries/recent?size=5` | ✅ | |
| Geçmişte bugün | `GET /journal/entries/on-this-day` | ✅ | |
| Hedefler + öneriler | `GET /goals`, `GET /goals/stats`, `GET /goals/suggestions`, accept/reject | ✅ | Sayaçlar `goals/stats`'tan; istemci saymaz. |
| Bekleyen gönderimler | cihaz kaydı + `GET /operations/{id}` | ✅ | `poll_after_ms`, `terminal`, `retryable`, `stage`, `error_code`, `allowed_actions`. |
| Bildirim zili rozeti | `GET /notifications/unread-count` | ✅ | Okundu işaretleme yanıtı da güncel `count` döner. |
| Sabah niyeti / Akşam yansıması | — | ⛔ | Ritüel alanı yok (B-9). Yerine "Bugünkü kayıtların". |
| Rehberli prompt karuseli | — | ⛔ | B-13. Yerine son analizlerin `reflective_question` alanları. |

### 4.6 Kayıt, inceleme, yazılı giriş (5.4, 5.5)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Kayıt, dalga formu, ripple, süre | 📱 AVAudioEngine → m4a (AAC mono) | ✅ | Sınırlar `config.recording`'den. |
| Canlı transkripsiyon | 📱 SFSpeechRecognizer (tr-TR/en-US) | ✅ | |
| Oynatıcı + hız | 📱 cihazdaki kayıt | ✅ | Yalnız kayıttan hemen sonra; yanıtta ses URL'si yok. |
| Kaydet (transkript var) | `POST /journal/entries/transcript` (202) + `Idempotency-Key` | ✅ | `recorded_at` tipli `date-time`, `duration_seconds` opsiyonel (yazılı girişte gönderilmez). |
| Kaydet (transkript yok) | `POST /journal/entries` multipart (202) + `Idempotency-Key` | ✅ | Generated client multipart gövdeyi üretir; `recorded_at` ve `duration_seconds` query. Prod'da özel R2 gerekir, local profil 503. |
| Mood seçici · etiket | — | ⛔ | B-12, B-11. Analiz sonrası konular salt okunur. |
| AI yansıması streaming | — | ⛔ | SSE yok; operation `succeeded` sonrası `GET /journal/entries/{id}`. |

### 4.7 Günlük (5.6)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Akış | `GET /journal/entries/recent` (cursor) | ✅ | Ay grupları `entry_date`e göre. |
| Arama | `GET /journal/entries/search?query=` (cursor) | ✅ | 2–100 karakter, sunucuda transcript üzerinde; istemci sayfa filtrelemez. |
| Silme | `DELETE /journal/entries/{id}` (204) | ✅ | Sunucu devam eden işi iptal eder, sayaçları yeniden hesaplar; istemci sayaç düşürmez. |
| Takvim ayı | `GET /calendar?year&month` | ✅ | `today`, gün başına `mood_category/label/score`, `entry_count`, `has_coach_session`; ay özeti `active_days`. |
| Gün seçimi | `GET /journal/entries?date=` | ✅ | |
| Arşivle / Favori | — | ⛔ | B-11. |

### 4.8 Kayıt detayı (5.7)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Metin, tarih, durum | `GET /journal/entries/{id}` | ✅ | `status` açık enum; bilinmeyen değer başarı sayılmaz. |
| İşleniyor + polling | `GET /operations/{operation_id}`, id null ise `GET /journal/entries/{id}/status` | ✅ | `poll_after_ms` aralığı, terminalde durur, ekrandan çıkınca iptal. |
| Echo yansıma bloğu | `analysis.summary`, `analysis.reflective_question` | ✅ | |
| Mood + konular | `analysis.mood_label/mood_category/mood_score/topics/key_emotions/energy_level` | ✅ | Etiket metni `app/vocabulary`'den; renk `mood_category`'den. Kelime eşlemesi yapılmaz. |
| "Devam et" | `POST /coach/sessions {journal_entry_id}` + `Idempotency-Key` | ✅ | |
| Hedef önerileri | `GET /goals/suggestions?source_type=journal&journal_entry_id=` | ✅ | `suggestion_type` ile filtrelenebilir. |
| Toplulukla paylaş · Paylaş | ComposePost · 📱 ShareLink | ✅ | |
| Sil | `DELETE /journal/entries/{id}` | ✅ | Onaylı. |
| Düzenle / Arşivle | — | ⛔ | B-11. |

### 4.9 İçgörüler ve mood takibi (5.9, 5.10)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Aralık seçici | `GET /ai-insights/eligibility` | ✅ | `default_period`, dönem `label`, `unlocked`, required/current sayıları. |
| Haftalık rapor kartı | `GET /summary?period=N` | ✅ | `narrative_summary`, `entry_count`, `recorded_days`, `coverage_percent`, `daily_mood_scores`, `dominant_topics`, `energy_distribution`, `mood_category_distribution`. |
| Örüntüler, öneriler, temalar | `GET /ai-insights?period=N` | ✅ | `period_label`, `weekly_trend[]` (7 gün, boş günde `mood_score` null), `weekly_average`, `mood_category_stats[]`, `recorded_days`, `has_sufficient_data`. |
| İstatistik kutuları | `GET /users/me/stats/detailed` + `/auth/me` | ✅ | `most_active_hour` kullanıcının saat diliminde; veri yoksa null → boş durum. |
| "Echo seni tanıyor" | `GET /users/me/profile-summary` | ✅ | 200 ve 204 belgeli; 204 → boş durum. |
| En iyi / en zor gün | `summary.best_day`, `worst_day` | ✅ | |
| Rapor paylaşımı | 📱 ImageRenderer PNG | ✅ | |

### 4.10 Koç (5.11)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Oturum listesi | `GET /coach/sessions` (cursor) | ✅ | `title` sunucudan gösterime hazır ve yerelleştirilmiş gelir. |
| Oturum başlat | `POST /coach/sessions` (201) + `Idempotency-Key` | ✅ | |
| Mesajlar | `GET /coach/sessions/{id}/messages` (cursor) | ✅ | |
| Mesaj gönder | `POST …/messages` (202 `OperationResponse`) + `Idempotency-Key` | ✅ | Sonuç `GET /operations/{id}` ile poll edilir; aynı anahtar güvenle tekrarlanır. |
| Yazıyor göstergesi | operation `processing` | ✅ | SSE yok; ripple "düşünüyor". |
| Bitir / sil | `POST …/end` (204), `DELETE …` (204) | ✅ | |
| Prompt önerileri, yeniden üret, koç tonu | — | ⛔ | B-15. |

### 4.11 Topluluk (5.12)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Keşfet / Takip / Benim | `GET /community/feed?tab=global\|following\|mine` (cursor) | ✅ | Bilinmeyen `tab` 400. |
| Post kartı | `CommunityPostResponse` | ✅ | `display_name` sunucudan (anonim/adsız etiketi çevrili); sahiplik `is_mine`/`can_delete`; `moderation_status`. |
| Echo'la (beğeni) | `POST/DELETE /community/posts/{id}/like` (200) | ✅ | Yanıt güncel sayaçlı post; istemci ±1 yapmaz. |
| Yorumlar (1 seviye) | `GET …/comments` (cursor) + `GET …/replies` (cursor) + `POST` (201, `Idempotency-Key`) | ✅ | Yorum yanıtı `post_comments_count`, `reply_count`, `is_mine`, `can_delete` taşır. |
| Yorum beğeni | `POST/DELETE /community/comments/{id}/like` (200) | ✅ | Güncel sayaçlı yorum döner. |
| Yorum / post silme | `DELETE …/comments/{commentId}`, `DELETE /community/posts/{postId}` (204) | ✅ | Yalnız `can_delete=true`. |
| Paylaş (metin / görsel) | `POST /community/posts` JSON veya multipart (201, `Idempotency-Key`) | ✅ | `content_type` sunucu kararıdır; anonim varsayılan açık. Kural kabulü yoksa 403 `COMMUNITY_TERMS_REQUIRED` → kabul ekranı. İçerik reddedilirse 400 `CONTENT_REJECTED`. |
| Şikâyet / engelleme | `POST …/posts/{id}/reports`, `…/comments/{id}/reports`, `…/block-author`, `GET/DELETE /community/blocks` | ✅ | `reason` sabit sözlüğü + ≤500 karakter `details`. App Store 1.2 karşılanır. |
| Takip et / bırak | `POST/DELETE /community/users/{userId}/follow` (204) | ⛔ durum | Takip durumu alanı yok (B-16): Keşfet'te "Takip et", Takip sekmesinde "Takibi bırak". |
| Hassas bilgi uyarısı | 📱 NSDataDetector | ✅ | Engellemez, uyarır. |

### 4.12 Hedefler

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Aktif / tümü | `GET /goals`, `GET /goals/all` (cursor) | ✅ | |
| Sayaçlar | `GET /goals/stats` | ✅ | `active_count`, `completed_count`, `dismissed_count`, `completed_this_week`, `week_start`. |
| Oluştur | `POST /goals` (201) + `Idempotency-Key` | ✅ | |
| Tamamla / geri al / vazgeç / sil | `PUT …/complete`, `…/not-completed`, `…/dismiss`, `DELETE` | ✅ | Durum etiketi `app/vocabulary`'den. |
| Öneriler | `GET /goals/suggestions` (+`source_type`, `suggestion_type`) + accept/reject | ✅ | Buton metinleri `primary/secondary_action_label`. |

### 4.13 Zaman kapsülleri

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Liste | `GET /capsules` (cursor) | ✅ | |
| Özet | `GET /capsules/summary` | ✅ | `sealed_count`, `opened_count`, `openable_count`, `next_capsule_id`, `next_unlock_at`. |
| Oluştur (metin) | `POST /capsules` (201) + `Idempotency-Key` | ✅ | Süre seçenekleri `config.capsules.presets`; `unlock_at` tipli `date-time`. Ses kapsülü ⛔ (B-20). |
| Detay / aç / sil | `GET /capsules/{id}`, `POST …/open`, `DELETE …` | ✅ | Düğme yalnız `can_open=true`; 403 `CAPSULE_LOCKED`. |

### 4.14 Başarımlar (5.13)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Özet + rozet ızgarası | `GET /achievements` | ✅ | `streak_message`, `earned_count`/`total_count`, rozet başına `progress`, `remaining`, `title`, `description`, `criteria_description` — hepsi istek dilinde. Ayrı rozet isteği gerekmez. |
| Rozet detayı + paylaş | `GET /achievements/{badgeKey}` | ✅ | `share_text` sunucudan. |
| Kategori bölümleri, "yeni kazanıldı" sinyali | — | ⛔ | B-17. |

### 4.15 Profil ve ayarlar (5.14)

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Header | `/auth/me` + `GET /subscription/status` | ✅ | Tier yalnız etiket. |
| İstatistik kutuları | `me.total_entries`, `current/longest_streak` | ✅ | |
| Profil düzenle | `PATCH /users/me` (`display_name`, `timezone`, `language`) | ✅ | |
| Bildirim tercihleri | `GET/PUT /notifications/preferences` | ✅ | Yerel hatırlatma kurulmaz. |
| Dil | `PATCH /users/me language` + uygulama dili (`Accept-Language`) | ✅ | Dil değişince config/vocabulary yeniden okunur. |
| Tema, metin boyutu, hareketi azalt, Face ID | 📱 | ✅ | |
| Rıza yönetimi | `GET/PUT /privacy/consent` | ✅ | |
| Hesap silme | `POST /privacy/delete-account` (202) | ✅ | Apple ile bağlı hesapta taze `apple_authorization_code`; eksikse 400 `APPLE_REAUTHORIZATION_REQUIRED`. Çift onay, yerel temizlik, "geri alınabilir" sözü yok. |
| Abonelik ve kullanım | `GET /subscription/status` | ✅ | 4.4. |
| Destek | 📱 mailto `config.support_email` | ✅ | |
| Gizlilik / Şartlar | `config.legal.*` | ✅ | Null link gizlenir. |
| Çıkış | `DELETE /notifications/push-token` → `POST /auth/logout` → yerel temizlik | ✅ | |
| Dışa aktar · rehberli günlükler · etiketler · hafıza ayarları | — | ⛔ | B-18, B-13, B-11, B-15. |

### 4.16 Bildirimler

| Özellik | Kaynak | Durum | Not |
|---|---|---|---|
| Liste | `GET /notifications` (cursor) | ✅ | |
| Okundu / tümü okundu | `PUT /notifications/{id}/read`, `PUT /notifications/read-all` (200) | ✅ | Yanıt güncel `count`; rozet yerel düşürülmez. |
| Dokununca yönlendirme | `target_type` + `target_id` | ✅ | Açık enum; bilinmeyen değerde yönlendirme yok. |
| Push dokunuşu | APNs custom alanları | ✅ | Detay API'den yüklenir. |

---

## 5. Ekranı engelleyen backend eksikleri

14 Eylül listesindeki P0 maddelerinin tamamı (B-1 … B-9) ve B-10, B-17 (sayaç/ilerleme kısmı), B-21 sözleşmeye girdi. Kalanlar yalnız tasarımdaki ikincil özellikleri etkiler; hiçbiri istemci tarafında hesapla kapatılmaz.

| # | Eksik | Engellenen | Frontend davranışı |
|---|---|---|---|
| B-11 | Kayıt düzenleme, transkript düzeltme, etiket, favori, arşiv | Kayıt detayı menüsü, etiket chip'leri, kaydırma eylemleri | Gösterilmez |
| B-12 | Kullanıcı mood seçimi alanı | İnceleme ekranında mood seçici | Gösterilmez (mood analizden gelir) |
| B-13 | Rehberli günlük / prompt kütüphanesi | Bugün karuseli, Rehberli ekranı (5.8) | Yerine analiz `reflective_question` |
| B-14 | Onboarding kişiselleştirme alanları + `onboarding_completed` | Onboarding 3–7. adımlar | 6 adımlı akış; tamamlanma cihazda |
| B-15 | Koç tonu, hafıza ayarları, yeniden üret, prompt önerileri | Koç ve ayarlar satırları | Gösterilmez |
| B-16 | Takip durumu alanı, rozet kategorileri | Takip düğmesinin durumu, kategorili rozet ızgarası | Sekme bağlamına göre tek eylem |
| B-17 | "Yeni kazanıldı" sinyali | Rozet açılma animasyonunun tetiği | Animasyon rozet detayında |
| B-18 | Veri dışa aktarma | Ayarlar > Dışa aktar | Gösterilmez |
| B-19 | E-posta doğrulama akışı | Doğrulama ekranı | Gösterilmez |
| B-20 | Ses kapsülü | Sesli kapsül | Yalnız metin kapsülü |
| B-9 (kalan) | Ritüel/tamamlanma alanları | Sabah/Akşam ritüel kartları | "Bugünkü kayıtların" |

## 6. Sözleşme bulguları — durum

| # | Bulgu | Durum |
|---|---|---|
| C1 | Generated `create` ses gövdesi üretmiyor | ✅ Kapandı: multipart gövde `required`, operasyon üretiliyor. |
| C2 | Date-time decode edilemiyor | ✅ Kapandı: tek wire biçimi (UTC, milisaniye) + paketin `EchoDateTranscoder`'ı; `EchoClient.make` `configuration` alıyor. |
| C3 | profile-summary 200 belgesiz | ✅ Kapandı: 200 ve 204 belgeli. |
| C4 | Transcript `duration_seconds` uyumsuz | ✅ Kapandı: opsiyonel; yazılı girişte gönderilmez. |
| C5 | `FeatureQuota` snapshot'ı eski | ✅ Kapandı. |
| C6 | Coach/yorum DTO'ları eski | ✅ Kapandı. |
| C7 | `app/config` tipsiz | ✅ Kapandı: tipli `AppConfigResponse`; linkler config'ten, null ise gizlenir. |
| C8 | Paket genişletilemiyor | ✅ Kapandı: `EchoClient.make(serverURL:tokenStore:configuration:language:)`; idempotent POST'lar güvenli retry listesinde. |
| C9 | Problem dışı hata gövdeleri (proxy HTML) | Bilgi: HTTP koduna göre genel mesaj gösterilir. |

## 7. Sözleşmeye giren yeni yetenekler (18 Eylül)

| Yetenek | Frontend karşılığı |
|---|---|
| Cursor sayfalama (`items`/`next_cursor`/`has_more`) | `ListPage<T>`; UI yalnız "daha fazla yükle" bilir |
| Kalıcı coach (202 + `OperationResponse`) | Ortak operation polling bileşeni; koç ve journal aynı bileşeni kullanır |
| Açık enum'lar (`value1` bilinen, `value2` ham) | Domain enum'larında `unknown(raw)`; bilinmeyen değer başarı/izin sayılmaz |
| Tipli tarihler | `Date` (anlık) ve `LocalDay` (takvim günü) ayrımı; gün alanı `Date`'e çevrilmez |
| `required`/`nullable` sözleşmesi | Optional alan gerçek "veri yok" demektir: sıfır yerine boş durum gösterilir |
| `Accept-Language` + sunucu metinleri | `EchoClient.make(language:)`; rozet/streak/koç başlığı/sözlük etiketi çevrilmez, gösterilir |
| Sunucu sözlüğü (`/app/vocabulary`) | Tek sözlük servisi, dil değişiminde yenilenir |
| Karar alanları (`can_open`, `is_mine`, `can_delete`, `allowed_actions`, `remaining`, `reason_code`, `update_required`, `paywall.offer`) | Ekran bu alanlara bakar; kural istemcide yazılmaz |

---

## 8. Fazlar

| Faz | Kapsam | Çıktı | Kabul kriteri |
|---|---|---|---|
| **0** ✅ | Proje sıfırlama | Eski kaynaklar kaldırıldı; iOS 17; EchoAPI paketi bağlı; Info.plist anahtarları; dizin iskeleti; string catalog | Simulator build geçer |
| **1** ✅ | Design token'ları + tema (P0) | EchoColor (Asset Catalog), Typography, Spacing, Radius, Elevation, Motion, AppTheme, ThemeManager, TokenGallery (DEBUG) | Galeri light/dark doğru; dosyalarda sabit renk/font yok |
| **2** | Temel component'ler (P1) | Button, IconButton, Chip, Card, ListRow, TextField/Editor, SegmentedControl, Divider, SectionHeader, Badge, Banner, Toast, EmptyState, Skeleton, Avatar | Light/dark/Dynamic Type preview'ları |
| **3** | Navigasyon kabuğu (P2) | RootView, MainTabView, EchoTabBar (merkez kayıt), Router, sheet/toast altyapısı | 4 sekme + merkez buton çalışır |
| **4** | Ses component'leri (P3) | Ripple, Waveform (live/static/player), RecordButton, TypingIndicator, AudioRecorder, SpeechTranscriber, AudioPlayer | Reduce Motion'da statik; cihazda kayıt |
| **5** | İçerik component'leri (P4) | MoodGlyph, MoodChart, ChatBubble, ReflectionBlock, EntryCard, InsightCard, WeeklyReportCard, AchievementTile, StatTile, StreakBadge, ProgressRing, PlanCard, OnboardingProgress | Preview verisiyle dolu |
| **S** ✅ | **Sözleşme kapısı** | 18 Eylül: snapshot `69b06d0459fc…` (92/127) ile Bölüm 4–7 yeniden yazıldı; C1–C8 kapandı | Belge ve sözleşme aynı hash'i gösterir |
| **6** | Veri katmanı | `EchoClient.make` sarmalayıcısı, Problem → AppError, domain modelleri, servis protokolleri + Live + Preview, PendingJournalStore, SessionStore, AppConfig/Vocabulary deposu, push kaydı | Tüm operasyonlar derlenir; mapper'larda bilinmeyen değer korunur |
| **7** | Açılış + Auth + Onboarding/Rıza | Launch (config + release kararı), Welcome, SignIn, SignUp, Google, **Apple**, Forgot/Reset, 6 adımlı onboarding | Gerçek backend ile giriş/kayıt/çıkış |
| **8** | Kayıt akışı (P6) | Recording → Review → gönderim → bekleyen iş/polling; Composer | Uygulama kapanıp açılınca bekleyen iş devam eder |
| **9** | Bugün + Günlük + Detay + Takvim (P7) | Today, JournalFeed (Akış/Takvim), EntryDetail | Kayıt → analiz → detay uçtan uca |
| **10** | İçgörüler + Mood + Koç (P8) | Insights, MoodTracker, CoachSessions, CoachChat | Kilitli aralık backend'den; koç timeout uzlaştırması |
| **11** | Topluluk + Hedefler + Kapsüller + Başarımlar (P9) | Feed, PostDetail, ComposePost, Goals, Capsules, Achievements | Sahiplik yalnız backend alanlarıyla |
| **12** | Profil + Ayarlar + Bildirimler + Abonelik (P9/P5) | Profile, Settings alt ekranları, Notifications, Subscription, Paywall | Hesap silme ve çıkış yerel veriyi temizler |
| **13** | Kalite geçişi (P11) | VoiceOver etiketleri, Dynamic Type, Reduce Motion, kontrast, uyarı temizliği, simulator smoke testi | Build uyarısız; ana akışlar ekran görüntüleriyle doğrulanır |

---

## 9. Doğrulama komutu

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Echo/Echo.xcodeproj -scheme Echo -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation build
```

Gereksinim: `Echo Frontend` ve `Echo Backend` klasörleri aynı dizinde (yerel paket göreli yolu).

---

## Ek A — 92 operasyonun kullanım yeri (18 Eylül)

| Alan | Operasyon → ekran |
|---|---|
| auth (10) | `register` → SignUp · `login` → SignIn · `loginWithGoogle`, `loginWithApple` → Welcome/SignIn · `refresh` → paket içi · `logout` → Ayarlar/Çıkış · `getCurrentUser` → Launch/Bugün/Profil · `changePassword` → Hesap · `forgotPassword` → Forgot · `resetPassword` → Reset |
| app (3) | `getAppConfig` → Launch/Onboarding/Ayarlar/Kayıt sınırları/Kapsül preset'leri · `getAppVocabulary` → sözlük deposu (analiz etiketleri, hedef durumu) · `getHealth` → kullanılmaz |
| journal (9) | `createTranscriptJournalEntry` → Kayıt/Composer · `createAudioJournalEntry` → Kayıt (ses) · `listJournalEntriesByDate` → Bugün/Takvim · `listRecentJournalEntries` → Bugün/Akış/Paylaş · `searchJournalEntries` → Günlük arama · `getJournalEntry` → Detay · `getJournalEntryStatus` → Detay (operation_id null) · `getOnThisDay` → Bugün · `deleteJournalEntry` → Detay menüsü |
| operations (1) | `getOperation` → bekleyen gönderimler, kayıt detayı, koç yanıtı |
| calendar, insights (4) | `getCalendarMonth` → Takvim (`today`) · `getPeriodSummary` → İçgörüler/Mood · `getAIInsights`, `getInsightEligibility` → İçgörüler |
| users (4) | `getProfileSummary` → İçgörüler ("Echo seni tanıyor") · `getDetailedUserStats` → İçgörüler/Profil · `updateProfile` → Profil düzenle/Dil · `getUserStats` → kullanılmaz (`getCurrentUser` ile aynı DTO) |
| achievements (2) | `getAchievements` → Başarımlar/Profil (streak mesajı, sayaçlar, ilerleme) · `getAchievementDetail` → Rozet detayı/paylaşım |
| goals (11) | `listActiveGoals`, `getGoalStats`, `listGoalSuggestions`, `acceptGoalSuggestion`, `rejectGoalSuggestion` → Bugün/Hedefler/Kayıt detayı · `listGoals`, `createGoal`, `completeGoal`, `markGoalNotCompleted`, `dismissGoal`, `deleteGoal` → Hedefler |
| coach (6) | `listCoachSessions`, `deleteCoachSession` → Koç oturumları · `createCoachSession`, `listCoachMessages`, `sendCoachMessage` (202 → `getOperation`), `endCoachSession` → Koç sohbeti |
| community (20) | `getCommunityFeed` → Feed (global/following/mine) · `getCommunityPost`, `listPostComments`, `listCommentReplies`, `createPostComment`, `likeComment`, `unlikeComment`, `deletePostComment` → Post detayı · `createCommunityPost` → Paylaş · `deleteCommunityPost`, `likePost`, `unlikePost` → Feed/Detay · `reportPost`, `reportComment`, `blockPostAuthor`, `blockCommentAuthor` → İçerik menüsü · `listCommunityBlocks`, `deleteCommunityBlock` → Ayarlar > Engellenenler · `followUser`, `unfollowUser` → Post menüsü |
| capsules (6) | `listCapsules`, `getCapsuleSummary`, `createCapsule`, `getCapsule`, `openCapsule`, `deleteCapsule` → Kapsüller |
| notifications (8) | `listNotifications`, `markNotificationRead`, `markAllNotificationsRead` → Bildirimler · `getUnreadNotificationCount` → Bugün rozeti · `getNotificationPreferences`, `updateNotificationPreferences` → Onboarding/Ayarlar · `registerPushToken`, `unregisterPushToken` → Push izni/Çıkış |
| privacy (3) | `getConsent`, `updateConsent` → Onboarding/Gizlilik/Topluluk kuralları · `requestAccountDeletion` → Hesap silme |
| subscription (5) | `getSubscriptionStatus` → Profil/Abonelik/Paywall kararı · `listSubscriptionProducts` → Paywall · `verifyPurchase`, `restorePurchase` → Paywall · `dismissPaywall` → Paywall kapatma |
