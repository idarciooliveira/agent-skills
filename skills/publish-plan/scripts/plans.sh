#!/usr/bin/env bash
# Usage:
#   plans.sh list [filter]          List plans in the bucket, newest first: date, size, public URL.
#   plans.sh get <key|url|filter> [out_dir]
#                                   Download one plan and print its local path.
#                                   out_dir defaults to ~/.t3/scratch/plans/r2.
# A filter is a case-insensitive substring of the key, e.g. "onboarding" or "2026-11".
# `get` with a filter fetches the newest match.
# Env: PLAN_BUCKET overrides the bucket name.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
command -v cf >/dev/null || die "cf CLI not found. Install it with: npm i -g cloudflare"
bucket="${PLAN_BUCKET:-plans}"

json_get() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const v=new Function("j","return "+process.argv[1])(JSON.parse(s));if(v!=null)console.log(v)})' "$1"; }

public_host() {
  local host
  host=$(cf r2 buckets domains custom list --bucket-name "$bucket" -q 2>/dev/null \
    | json_get '(j.domains||[]).filter(d=>d.enabled!==false).map(d=>d.domain)[0]' || true)
  if [ -z "$host" ]; then
    host=$(cf r2 buckets domains managed list --bucket-name "$bucket" -q 2>/dev/null | json_get 'j.enabled ? j.domain : null' || true)
  fi
  printf '%s' "$host"
}

# Keys matching the filter, newest first, one per line.
keys() {
  cf r2 objects list --bucket-name "$bucket" -q || die "cannot read bucket '$bucket'. Run: cf auth whoami"
}

cmd="${1:-list}"; shift || true
case "$cmd" in
  list)
    filter="${1:-}"
    host=$(public_host)
    keys | FILTER="$filter" HOST="$host" node -e '
      let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
        const f=(process.env.FILTER||"").toLowerCase(), h=process.env.HOST;
        const rows=JSON.parse(s).filter(o=>o.key.toLowerCase().includes(f))
          .sort((a,b)=>b.last_modified.localeCompare(a.last_modified));
        if(!rows.length){console.error("no plans match");process.exit(1)}
        for(const o of rows){
          const kb=(o.size/1024).toFixed(0).padStart(4)+" KB";
          console.log(`${o.last_modified.slice(0,16).replace("T"," ")}  ${kb}  ${h?`https://${h}/${o.key}`:o.key}`);
        }})'
    ;;
  get)
    target="${1:?key, url or filter required}"
    out="${2:-$HOME/.t3/scratch/plans/r2}"
    key="${target#https://*/}"   # accept a public URL
    if [[ ! "$key" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}/.+\.html$ ]]; then
      key=$(keys | FILTER="$target" json_get '(() => { const f=process.env.FILTER.toLowerCase(); const m=j.filter(o=>o.key.toLowerCase().includes(f)).sort((a,b)=>b.last_modified.localeCompare(a.last_modified)); return m.length ? m[0].key : null })()')
      [ -n "$key" ] || die "no plan matches '$target'"
    fi
    dest="$out/$key"
    mkdir -p "$(dirname "$dest")"
    cf r2 objects get "$key" --bucket-name "$bucket" -q > "$dest" || { rm -f "$dest"; die "download failed: $key"; }
    [ -s "$dest" ] || { rm -f "$dest"; die "empty download: $key"; }
    echo "$dest"
    ;;
  *) die "unknown command '$cmd'. Use: list [filter] | get <key|url|filter> [out_dir]" ;;
esac
