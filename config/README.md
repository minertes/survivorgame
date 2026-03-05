# Ortam yapılandırması

Bu klasör oyunun ortam (dev/staging/prod) ayarlarını tutar.

## default_env.cfg

- **environment**: `dev`, `staging`, `prod`
- **backend_url**: Bulut kayıt ve liderlik tablosu API’nin base URL’i. Boş bırakılırsa bulut özellikleri devre dışı kalır.
- **analytics_enabled**: Analitik olaylarının gönderilip gönderilmeyeceği.
- **crash_reporting_enabled**: Hata raporlama açık/kapalı.
- **log_level**: `debug`, `info`, `warn`, `error`, `fatal`. Production’da `warn` veya `error` önerilir.

### backend_url örnekleri

- **Staging**: Kendi Supabase/Firebase veya test API adresiniz, örn. `https://xxxx.supabase.co/rest/v1/`
- **Production**: Canlı backend base URL’i.

API’nin beklediği uç noktalar (dokümante edildiği şekliyle):

- `PUT /save` — bulut kayıt yazma (cihaz kimliği ile)
- `GET /save?device_id=...` — bulut kayıt okuma
- `PUT /leaderboard/submit` — skor gönderme
- `GET /leaderboard/list` — liderlik listesi

Bu uç noktalar sunucuda tanımlanıp açıldığında client tarafı hazırdır; backend_url doldurulduğunda kullanılır.

## .env veya override

Export (release) yaparken farklı bir ortam kullanmak için:

- `default_env.cfg` kopyasını staging/prod için düzenleyip build’e dahil edebilirsiniz, veya
- İleride ortam değişkenleri (örn. `BACKEND_URL`) ile override eklenebilir.
