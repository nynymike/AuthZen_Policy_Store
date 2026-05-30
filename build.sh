#!/usr/bin/env bash
# Build draft-schwartz-authzen-policy-store.html from markdown (AuthZEN / OpenID format).
set -euo pipefail
cd "$(dirname "$0")"

export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:/opt/homebrew/opt/ruby/bin:${PATH:-}"

mkdir -p .refcache .cache/xml2rfc

if ! command -v kramdown-rfc2629 >/dev/null; then
  echo "Install kramdown-rfc2629: gem install kramdown-rfc2629 (Ruby >= 3.2)" >&2
  exit 1
fi

if [[ ! -x .venv/bin/xml2rfc ]]; then
  python3 -m venv .venv
  .venv/bin/pip install -q xml2rfc
fi

kramdown-rfc2629 draft-schwartz-authzen-policy-store.md 2>.refcache/kramdown-err.log \
  > draft-schwartz-authzen-policy-store.xml

.venv/bin/xml2rfc draft-schwartz-authzen-policy-store.xml \
  --html -o draft-schwartz-authzen-policy-store.html \
  --cache .cache/xml2rfc

echo "Wrote draft-schwartz-authzen-policy-store.html"
