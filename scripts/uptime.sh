#!/usr/bin/env bash
# Production endpointlarni tekshiradi va README dagi status jadvalini yangilaydi.
# GitHub Actions (.github/workflows/uptime.yml) tomonidan har 6 soatda ishga tushadi.
set -euo pipefail

README="${README:-README.md}"

# nom | url | stack
SITES=(
  "bizdaoson.uz|https://bizdaoson.uz|Nginx · Let's Encrypt · Cloudflare"
  "market.bizdaoson.uz|https://market.bizdaoson.uz|Caddy · FastAPI · PostgreSQL · Docker"
  "cybermentor.uz|https://cybermentor.uz|Nginx · code-server · fail2ban · Cloudflare"
)

table="| Servis | Holat | HTTP | Javob vaqti | Stack |\n|---|---|---|---|---|"

for s in "${SITES[@]}"; do
  IFS='|' read -r name url stack <<<"$s"
  # timeout yoki DNS xatosida ham curl "000 <vaqt>" qaytaradi
  out=$(curl -sS -o /dev/null -m 15 -w '%{http_code} %{time_total}' "$url" 2>/dev/null || true)
  code=${out%% *}
  secs=${out##* }
  ms=$(awk -v t="${secs:-0}" 'BEGIN { printf "%d", t * 1000 }')
  if [[ $code =~ ^[23] ]]; then status="🟢 online"; else status="🔴 down"; fi
  table+="\n| [$name]($url) | $status | \`$code\` | ${ms} ms | $stack |"
done

ts=$(TZ=Asia/Tashkent date '+%Y-%m-%d %H:%M')
table+="\n\n<sub>GitHub Actions orqali har 6 soatda avtomatik tekshiriladi · oxirgi tekshiruv: $ts (Toshkent) · [workflow](.github/workflows/uptime.yml) · [skript](scripts/uptime.sh)</sub>"

# Markerlar orasidagi blokni almashtirish
awk -v t="$table" '
  /<!-- STATUS:START -->/ { print; print t; skip = 1; next }
  /<!-- STATUS:END -->/   { skip = 0 }
  !skip
' "$README" > "$README.tmp" && mv "$README.tmp" "$README"
