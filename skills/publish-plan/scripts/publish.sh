#!/usr/bin/env bash
# Usage: publish.sh plan.html [slug]
# Uploads an HTML plan to the R2 bucket (default "plans") with the cf CLI and prints its public URL.
# Env: PLAN_BUCKET overrides the bucket name.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

file="${1:?html file required}"
[ -f "$file" ] || die "no such file: $file"
bucket="${PLAN_BUCKET:-plans}"
command -v cf >/dev/null || die "cf CLI not found. Install it with: npm i -g cloudflare"

# Key: YYYY-MM-DD/<slug>-<random>.html. The random suffix keeps links unguessable.
slug="${2:-$(basename "$file" .html)}"
slug=$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
[ -n "$slug" ] || slug=plan
key="$(date +%Y-%m-%d)/${slug}-$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n').html"

json_get() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const v=new Function("j","return "+process.argv[1])(JSON.parse(s));if(v!=null)console.log(v)})' "$1"; }

# Prefer an active custom domain, else the r2.dev domain.
host=$(cf r2 buckets domains custom list --bucket-name "$bucket" -q 2>/dev/null \
  | json_get '(j.domains||[]).filter(d=>d.enabled!==false).map(d=>d.domain)[0]' || true)
if [ -z "$host" ]; then
  managed=$(cf r2 buckets domains managed list --bucket-name "$bucket" -q) || die "cannot read bucket '$bucket'. Run: cf auth whoami"
  [ "$(printf '%s' "$managed" | json_get 'j.enabled')" = "true" ] \
    || die "bucket '$bucket' has no public access. Ask the user before running: cf r2 buckets domains managed update $bucket --enabled true --force"
  host=$(printf '%s' "$managed" | json_get 'j.domain')
fi

cf r2 objects put "$key" --bucket-name "$bucket" --file "$file" \
  --content-type "text/html; charset=utf-8" -q >/dev/null || die "upload failed"

url="https://${host}/${key}"
code=$(curl -s -o /dev/null -w '%{http_code}' "$url" || true)
[ "$code" = "200" ] || echo "warning: $url returned HTTP $code (r2.dev can take a few seconds)" >&2
echo "$url"
