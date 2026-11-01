# WM Switcher

Bilgisayarında üç tiling pencere yöneticisi (WM) kurulu: **AeroSpace**, **Amethyst** ve **hyprmac**.
WM Switcher aynı anda yalnızca birinin çalışmasını sağlar ve aralarında tek tıkla geçiş yapar.

---

## Neler yapabilir?

- **Tek tıkla geçiş.** Bir WM seçtiğinde çalışan diğer WM'leri kapatır, seçtiğini başlatır.
- **"Hepsini kapat".** Tüm WM'leri kapatır. Pencereler normal macOS'taki gibi serbest kalır.
- **Hatırlar.** Son seçimini kaydeder. Bilgisayar açıldığında yalnızca WM Switcher başlar ve o WM'i açar.
- **Çakışmayı önler.** Bir WM'i Spotlight'tan ya da başka bir yoldan açarsan yeni açılan kazanır.
  WM Switcher diğerlerini kapatır ve seçimi günceller.
- **Düzgün kapatır.** WM'lere önce normal "Quit" gönderir, böylece gizledikleri pencereleri geri getirirler.
  3 saniye içinde kapanmazlarsa zorla kapatır.
- **Kurulu olmayanı gösterir.** Kurulu olmayan bir WM'in kartı gri olur ve tıklanamaz.
- **Ayar dosyaları.** Her WM'in ayar dosyasını varsayılan metin editöründe açar.
- **Özelleştirilebilir kısayollar.** Her geçişin kısayolunu Ayarlar penceresinden kendin seçersin.
  Seçtiğin kısayolu bir WM kendi ayarlarında kullanıyorsa uyarır.

---

## Nasıl kullanılır?

### 1. Pencereden

Dock'taki **WM Switcher** ikonuna tıkla. Küçük bir pencere açılır:

| Öğe | Ne yapar |
|---|---|
| **A / M / H kartları** | AeroSpace / Amethyst / hyprmac'e geçer. Aktif olanın çerçevesi mavi-mor ve altında "● aktif" yazar. |
| **Ayar dosyasını aç** | O WM'in config dosyasını editörde açar. |
| **Hepsini kapat (normal macOS)** | Bütün WM'leri kapatır. |
| **Login'de başlat** | Açıksa WM Switcher bilgisayar açılınca başlar ve son seçili WM'i açar. Şu an **açık**. |
| **⚙ Ayarlar** | Ayarlar penceresini açar: kısayollar ve genel ayarlar. |

Pencereyi kapatman uygulamayı kapatmaz. Kısayollar ve Dock menüsü çalışmaya devam eder.

### 2. Dock menüsünden (pencereyi açmadan)

Dock ikonuna **sağ tıkla**:

```
✓ AeroSpace
  Amethyst
  hyprmac
  ─────────
  Hepsini kapat
  ─────────
  Ayarlar…
```

Aktif olanın yanında ✓ işareti vardır. Birine tıklamak yeterli.

### 3. Klavye kısayolları (her yerden)

| Kısayol | Geçiş |
|---|---|
| `⌃ ⌥ ⌘ 1` | AeroSpace |
| `⌃ ⌥ ⌘ 2` | Amethyst |
| `⌃ ⌥ ⌘ 3` | hyprmac |
| `⌃ ⌥ ⌘ 0` | Hepsini kapat |
| `⌘ ,` | Ayarlar (WM Switcher öndeyken) |

(Control + Option + Command + rakam.) Bunlar varsayılanlar; varsayılan halleriyle üç WM'in
hiçbirinin kısayoluyla çakışmazlar. İstediğin gibi değiştirebilirsin, aşağıya bak.

### Kısayolları değiştirmek (Ayarlar)

Ayarlar'ı üç yoldan açabilirsin: ana penceredeki **⚙ Ayarlar** butonu, Dock'ta sağ tık → **Ayarlar…**
ya da uygulama menüsünden **Ayarlar…** (`⌘,`).

1. Değiştirmek istediğin eylemin yanındaki kısayol kutusuna tıkla. Kutuda **"Tuşlara bas…"** yazar.
2. Yeni kısayola bas, örneğin `⌃⌥⌘A`. Kayıt hemen geçerli olur, uygulamayı yeniden başlatman gerekmez.
   - `⌫` kısayolu siler (o eylemin kısayolu olmaz).
   - `⎋` vazgeçer.
   - En az bir `⌃`, `⌥` veya `⌘` gerekir. Yalnız `⇧` ya da modifier'sız tek bir tuş kabul edilmez,
     çünkü yazı yazmayı bozar.
   - Aynı kısayolu iki eyleme veremezsin, kutunun altında uyarı çıkar.
3. Satırın sağındaki **↺** o eylemi varsayılanına döndürür. **Varsayılanlara dön** hepsini döndürür.

**Çakışma uyarısı:** Seçtiğin kısayol bir WM'in kendi kısayoluysa satırın altında turuncu uyarı çıkar.
Örneğin `⌥H` için şunlar görünür:
`Çakışma — AeroSpace: alt-h → focus left` ve `Çakışma — hyprmac: $mod, H → movefocus l`.
Bu kontrol AeroSpace'in `aerospace.toml`, hyprmac'in `hyprmac.conf` ve Amethyst'in `amethyst.yml`
dosyalarını okur. Amethyst'in kendi tercih penceresinden değiştirdiğin kısayolları göremez.

Ayarlar penceresinin altındaki **Genel** bölümünde **Login'de başlat** anahtarı da var.
Ana penceredekiyle aynı ayardır, birini değiştirince öbürü de değişir.

Kısayollar `~/.config/wm-switcher/shortcuts.json` dosyasında saklanır. İstersen elle de
düzenleyebilirsin (değişiklik, uygulama yeniden açılınca geçerli olur):

```json
{
  "aerospace" : "ctrl-alt-cmd-1",
  "amethyst" : "ctrl-alt-cmd-2",
  "hyprmac" : "ctrl-alt-cmd-3",
  "none" : "ctrl-alt-cmd-0"
}
```

Biçim AeroSpace'teki gibidir: `ctrl`, `alt`, `shift`, `cmd` + tuş adı. Tuş adları `a`–`z`, `0`–`9`,
`f1`–`f20`, `space`, `enter`, `tab`, `left`, `minus`, `leftSquareBracket`… olabilir. `""` kısayol yok demektir.

### 4. Dock rozeti

Dock ikonunun köşesinde aktif WM'in harfi görünür: **A**, **M** veya **H**.
Hiçbiri çalışmıyorsa rozet olmaz.

### 5. Terminalden

```bash
~/wm-switcher/switch.sh aerospace   # veya amethyst, hyprmac, none
~/wm-switcher/switch.sh status      # kayıtlı seçim + çalışan WM
~/wm-switcher/switch.sh restore     # son seçili WM'i aç
```

---

## Her WM'in temel kısayolları

| | AeroSpace | Amethyst | hyprmac |
|---|---|---|---|
| Odak değiştir | `⌥ H J K L` | `⌥⇧ J / K` | `⌥ H J K L` |
| Pencere taşı | `⌥⇧ H J K L` | `⌥⇧ Enter` (ana pencere yap) | `⌥⇧ H J K L` |
| Workspace | `⌃ 1–9` | `⌃ 1–9` (macOS Spaces) | `⌥ 1–5` |
| Yerleşim | `⌥T` yan yana, `⌥A` kart | `⌥⇧ Space` yerleşim değiştir | `⌥S` bölmeyi çevir |
| Yüzen pencere | `⌥⇧ Space` | `⌥⇧ T` | `⌥V` |
| Tam ekran | `⌥F` | `⌥⇧ D` | `⌥F` |
| Tüm kısayollar | config dosyası | Amethyst menüsü → Settings | `⌥ /` |

> Türkçe klavyede `⌥ + rakam` karakter yazar (`#`, `$`, `{` …). hyprmac'in `⌥1–5` workspace
> kısayolları bu yüzden bazı uygulamalarda karakter yazabilir. Gerekirse hyprmac ayar
> dosyasından değiştir.

---

## Ayar dosyaları

| WM | Dosya |
|---|---|
| AeroSpace | `~/.config/aerospace/aerospace.toml` |
| Amethyst | `~/.config/amethyst/amethyst.yml` |
| hyprmac | `~/.config/wisp/hyprmac.conf` (`⌥⇧C` ile yeniden yüklenir) |

---

## İzinler

Her WM'in çalışması için **Accessibility (Erişilebilirlik)** izni gerekir:
System Settings → Privacy & Security → Accessibility → AeroSpace, Amethyst ve hyprmac'i aç.

WM Switcher'ın kendisi Accessibility izni istemez. İlk geçişte macOS
*"WM Switcher, X'i denetlemek istiyor"* diye sorabilir. **İzin ver** dersen WM'ler düzgün kapanır.

---

## Önemli notlar

- WM'lerin kendi **"launch at login"** ayarlarını açma. Açarsan login'de iki WM birden başlar.
- Bir geçişte pencereler ekran dışında kalırsa geçiş zorla kapatmayla bitmiş olabilir.
  O WM'i yeniden açıp normal şekilde başka birine geç.
- Geçiş günlüğü: `~/.config/wm-switcher/switch.log`

---

## Yeni bir WM eklemek

1. WM'i kur.
2. `~/wm-switcher/wms.conf` dosyasına bir satır ekle:
   ```
   id|Görünen ad|bundle id|/Applications/X.app|~/ayar/dosyasi|Harf
   ```
   Bundle id'yi şu komut verir: `osascript -e 'id of app "X"'`.
   Satırın sırası varsayılan kısayol numarasıdır: 4. satır `⌃⌥⌘4` olur. Ayarlar'dan değiştirebilirsin.
3. WM Switcher'dan çık (Dock → sağ tık → Çık) ve yeniden aç.

---

## Dosyalar nerede?

| | |
|---|---|
| Uygulama | `/Applications/WM Switcher.app` |
| Kaynak kod + script | `~/wm-switcher/` (geliştirici notları `README.md`'de) |
| Yeniden derleme | `~/wm-switcher/build.sh` |
| Son seçim | `~/.config/wm-switcher/current` |
| Kısayollar | `~/.config/wm-switcher/shortcuts.json` |

---

## Sürüm notları

### 22 Ekim 2026 — Özelleştirilebilir kısayollar

- Ayarlar penceresi eklendi. Açmanın üç yolu var: ana penceredeki **⚙ Ayarlar** butonu,
  Dock'ta sağ tık → **Ayarlar…**, uygulama menüsünde **Ayarlar…** (`⌘,`).
- Her geçişin kısayolu değiştirilebiliyor. Kutuya tıklayıp yeni tuşlara basman yeterli.
  Değişiklik hemen geçerli olur, uygulamayı yeniden başlatman gerekmez.
- Çakışma uyarısı: seçtiğin kısayolu AeroSpace (`aerospace.toml`), hyprmac (`hyprmac.conf`)
  ya da Amethyst (varsayılanlar + `amethyst.yml`) kullanıyorsa satırın altında turuncu uyarı çıkar.
- Kısayollar `~/.config/wm-switcher/shortcuts.json` dosyasında AeroSpace biçiminde saklanır.
- **Login'de başlat** anahtarı Ayarlar'daki Genel bölümüne de eklendi.
- Uygulamaya standart menü eklendi: Hakkında, Ayarlar…, Gizle (`⌘H`), Çık (`⌘Q`), Pencereyi kapat (`⌘W`).

**Test edilenler:**
- Çakışma uyarıları üç WM için de doğru çıktı.
- Özel kısayollar (`⌃⌥⌘A/M/H`) dosyadan yüklendi ve geçiş yaptı. Eski `⌃⌥⌘2` artık bir şey yapmadı.
- Varsayılanlar (`⌃⌥⌘1/2/3/0`) geri yüklendi ve çalışıyor.
- Login öğesi yeniden derlemeden sonra da etkin.

**Henüz denenmedi:**
- Kutuya tıklayıp tuşlara basarak kısayol kaydetme. İlk denemeyi sen yapacaksın.
- `⌘,` tuşu. Ayarlar'ı menüden açmak çalışıyor.
