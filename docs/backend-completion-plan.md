# Backend tamamlama planı (iOS Faz 2 öncesi)

> **Repo:** Echo Backend · **Branch:** `feature/mobile-contract-completion` · **Başlangıç commit'i:** `0f01fb1` (Codex dönüşümü)
> **Amaç:** `docs/ios-frontend-plan.md` §5–6'daki backend eksikleri kapansın; eksik kalacaksa yalnız frontend'de kalsın.
> Normatif davranış `rules.md`'ye yazılır (§32–33 kontrol listeleri). Bu belge iş sırasını ve ürün varsayılanlarını özetler; ikinci bir standart değildir.
> **Başlangıç doğrulaması:** `scripts/verify-backend.sh` → 111 test, 0 hata, 0 atlanan (commit `0f01fb1`).

---

## Dalga A — Sözleşme hijyeni

| # | Değişiklik | Sözleşme | Varsayılan karar |
|---|---|---|---|
| A1 | Tüm create uçlarında `Idempotency-Key` (§21) | goals, capsules, community posts/comments, reports | Kullanıcı + operasyon kapsamlı kayıt; aynı anahtar + aynı gövde → önceki kaynak, farklı gövde → 409 `IDEMPOTENCY_CONFLICT` |
| A2 | Transcript `duration_seconds` opsiyonel (C4, §10) | `CreateJournalFromTranscriptRequest` | `Integer`, 3–600; yazılı kayıtta `null` |
| A3 | Tipli uygulama ayarları (C7, §8, §29) + zorunlu güncelleme (B-21) | `GET /app/config?app_version=` → `AppConfigResponse` | Link/metinler ConfigurationProperties; `update.required/recommended` backend kararı; reklam yerleşimleri config (varsayılan kapalı) |
| A4 | Sessiz fallback yok (§10) | `ai-insights`/`summary` period, timezone | Desteklenmeyen dönem 400; IANA timezone `ZoneId.of` ile |
| A5 | Gövdesiz başarı 204 (§13) | like/unlike, follow/unfollow | 204 |
| A6 | OpenAPI başlık ve sürüm tutarlılığı | `info` | "draft" etiketi kalkar |
| A7 | Swift paketi (C2, C8) | `EchoClient.make(serverURL:tokenStore:configuration:)` | Toleranslı ISO-8601 transcoder varsayılan; coach idempotent yolları retry listesinde; fraksiyonlu tarih için Java serializer fixture'ı |

## Dalga B — Yayın engelleri

| # | Değişiklik | Sözleşme | Varsayılan karar |
|---|---|---|---|
| B1 | Günlük kaydı silme (B-1) | `DELETE /journal/entries/{id}` → 204 | Süren iş iptal + rezervasyon bir kez iade; geçici ses silme talebi; analiz, etiket, öneriler silinir; hedef/koç/kapsül referansları `null`; kullanıcı istatistikleri yeniden hesaplanır; AI profil özeti yenilenmek üzere işaretlenir. Tamamlanmış kaydın kotası iade edilmez. |
| B2 | Topluluk moderasyonu (B-2, App Store 1.2) | Aşağıda | |
| | · Topluluk kuralları onayı | consent'e `community_terms_version` | Paylaşım/yorum öncesi zorunlu → 403 `COMMUNITY_TERMS_REQUIRED` |
| | · İçerik filtresi | create post/comment | AI moderasyonu (3 sn); red → 400 `CONTENT_REJECTED`; sağlayıcı yanıt vermezse içerik yayınlanır ve admin inceleme kuyruğuna düşer |
| | · Şikayet | `POST /community/posts/{id}/reports`, `POST /community/comments/{id}/reports` | Nedenler: `spam, harassment, hate, sexual_content, violence, self_harm, other`; kullanıcı başına tek şikayet; şikayet eden artık görmez; 3 farklı şikayette inceleme sonuna kadar gizlenir |
| | · Engelleme | `POST /community/posts/{id}/block-author`, `POST /community/comments/{id}/block-author`, `GET /community/blocks`, `DELETE /community/blocks/{id}` | Anonim içerikte kimlik açığa çıkmaz; iki yönlü görünmezlik; takipler kaldırılır |
| | · Admin | `GET /admin/moderation/reports`, `POST /admin/moderation/reports/{id}/resolve` | `dismiss` veya `remove_content` |
| B3 | Apple ile giriş (B-3, App Store 4.8) | `POST /auth/apple` | JWKS + iss/aud/exp/nonce doğrulaması; `apple_subject` ile eşleşme, doğrulanmış e-postayla bağlama (Google ile aynı politika); hesap silmede Apple token iptali için yeni `authorization_code`, yoksa 400 `APPLE_REAUTHORIZATION_REQUIRED` |
| B4 | Abonelik kataloğu ve paywall kararı (B-4) | `GET /subscription/products`, `status.paywall`, `POST /subscription/paywall-dismissals` | Backend'de sabit yazılı `echo_premium_monthly` ve `echo_premium_yearly` doğrulanmış config'e taşınır; tier bazlı özellik limitleri faydalar olarak döner; katalog dışı ürün reddedilir; paywall önerisi: free tier + ilk başarılı analiz + 7 gün kapatma beklemesi |

## Dalga C — Günlük ve Bugün

| # | Değişiklik | Sözleşme | Varsayılan karar |
|---|---|---|---|
| C1 | Kullanıcı mood'u (B-12) | create'te ve yanıtta `user_mood` | `heavy, low, neutral, good, bright`; AI mood'u ayrı kalır |
| C2 | Başlık/metin düzenleme ve yeniden analiz (B-11) | `PATCH /journal/entries/{id}`, `POST /journal/entries/{id}/reanalysis` (202) | İş sürerken 409; metin değişince `analysis_stale=true`; yeniden analiz yeni kayıt kotası tüketir |
| C3 | Favori ve arşiv (B-11) | `PUT/DELETE …/favorite`, `PUT/DELETE …/archive`; listelerde `filter` | `active` (varsayılan), `favorites`, `archived` |
| C4 | Etiketler (B-11) | `PUT /journal/entries/{id}/tags`, `GET /journal/tags` | Kayıt başına ≤10 etiket, her biri ≤32 karakter |
| C5 | Arama (B-10) | `GET /journal/entries/search?q=&cursor=&size=` | Metin, başlık, özet, konu ve etiketlerde PostgreSQL full-text |
| C6 | Prompt kütüphanesi (B-13) | `GET /prompts`, `GET /prompts/categories` | TR/EN içerik migration ile; rehberli promptlarda `steps` |
| C7 | Bugün ekranı (B-9) | `GET /today`; create'te `ritual`, `prompt_id` | Kullanıcı saat dilimi; sabah niyeti 04–12, akşam yansıması 17–04; durumlar `completed, available, upcoming, missed`; `recorded_today` |
| C8 | Mood takibi | `DailyMoodScore.entry_count` | |

## Dalga D — Profil, koç ve diğerleri

| # | Değişiklik | Sözleşme | Varsayılan karar |
|---|---|---|---|
| D1 | Onboarding profili (B-14) | `GET/PUT /users/me/onboarding`, `UserResponse.onboarding_completed` | goals, focus_areas, journaling_experience, preferred_input_mode, coach_tone |
| D2 | Koç tercihleri ve hafıza (B-15) | `GET/PUT /coach/preferences`, `DELETE /users/me/profile-summary` | Ton ve uzun dönem hafıza anahtarı koç bağlamına girer |
| D3 | Koç yeniden üretme ve öneriler (B-15) | `POST …/messages/{id}/regeneration` (202), `GET /coach/suggestions` | Yalnız son asistan mesajı yeniden üretilir. Kayıt referansı için yeni alan gerekmez: koç bağlamı oturumun `journal_entry_id` kaydını kullanır ve bu alan zaten yanıtta |
| D4 | Hatırlatma günleri | bildirim tercihlerinde `reminder_weekdays` | 1–7; zamanlayıcı seçili olmayan günde göndermez |
| D5 | E-posta doğrulama (B-19) | `POST /auth/email-verification`, `POST /auth/email-verification/confirm` | 6 haneli kod, OTP kalıbı |
| D6 | Veri dışa aktarma (B-18) | `POST /privacy/export` → JSON dosyası | Saatte bir |
| D7 | Rozet kategorisi ve "yeni" sinyali (B-17) | `category`, `is_new`, `POST /achievements/seen` | `streak, exploration, depth, community` |
| D8 | Topluluk (B-16) | `tab=mine`, postta `is_following_author` ve `mood` | Anonim/kendi postunda `is_following_author=null` |
| D9 | Sesli kapsül (B-20) | kapsülde `source` + süre metadata'sı | Ses cihazda yazıya dökülür; dosya saklanmaz |

## Dalga E — Kabul

Her dalgada: migration + PostgreSQL entegrasyon testi + MVC/sözleşme testi → `scripts/sync-api-contract.py` → Swift build/test → `render-frontend-handoff.py` → `rules.md` ve `implementation-status.json` → tek parça yeşil `scripts/verify-backend.sh` → graphify → dalga commit'i.

---

## Güvenlik bulgusu

- **Kriz hattı numarası:** uygulama ayarları ve üç koç prompt'u kriz hattı olarak **182** gösteriyordu. 182, MHRS (hastane randevu) hattıdır; kriz hattı değildir. Numara `app.crisis.*` config'ine taşındı, varsayılan **112 (Acil Çağrı Merkezi)**. Koç prompt'ları numarayı config'ten alır. Doğru kriz hattının teyidi gerekiyor.

## Kapsam dışı (gerekçeli)

- **Ses dosyası saklayan kapsül:** `rules.md` §30 ses saklama kuralıyla (en geç 24 saat) çelişir; D9 ile karşılanır.
- **"Başka açıdan" yansıması, koç mesajını günlüğe kaydetme:** ayrı AI üretim akışı ve kota tanımı gerektirir; koçta "Devam et" ve yeniden üretme aynı ihtiyacı karşılar.

## Senin sağlaman gereken dış yapılandırma

- **Sign in with Apple anahtarı** (Team ID, Key ID, `.p8`): hesap silmede token iptali için gerekli; yoksa Apple girişi production'da açılmaz.
- **Abonelik ürün kimliklerinin teyidi:** backend `echo_premium_monthly` ve `echo_premium_yearly` bekliyor; App Store Connect'tekilerle aynı olmalı.
- **Kriz hattı teyidi:** varsayılan 112; farklı bir ulusal hat kullanılacaksa `APP_CRISIS_PHONE_NUMBER`.
- **Gizlilik ve şartlar sayfalarının gerçek adresleri:** config şu an `echo-app.com` gösteriyor.
- **Moderasyon için OpenAI anahtarı:** mevcut AI anahtarı kullanılabilir.
