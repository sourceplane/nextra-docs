#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `build-app` — the component's
#      buildCommand (`next build` with Turbopack, Pagefind over
#      `.next/server/app`, the OpenNext bundle), the same step the deploy
#      profile runs — `verify-build-output` and `deploy-dry-run` (`wrangler
#      deploy --dry-run --name <reponame>-web-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. Run in a plain
#      checkout, this tier was green while the first live bootstrap of a
#      Next 16 baseline died in the lane layout (Turbopack: "Symlink … points
#      out of the filesystem root"). The staged build must also have run on
#      Turbopack and written its OWN search index — the source tree's is
#      removed before staging, as a CI checkout has none;
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every route the site promises: the logo, the
#      titles and the footer carry the site's name, the GitHub and "Edit this
#      page" links point at the site's repository, every content page renders,
#      an unknown path is a 404, and the Pagefind index and its loader are
#      served with every page in it.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false NEXT_TELEMETRY_DISABLED=1 TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/.open-next" "$tree/apps/web/.wrangler" "$tree/apps/web/public/_pagefind"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done
# What the staged build must have been: Turbopack (a webpack build would get
# past an out-of-tree symlink and is not the build this site is verified
# with), and a search index of its own over every page in content/.
grep -q '(Turbopack)' "$scratch/build-app.log" \
  || { echo "FAIL: the staged build did not run on Turbopack" >&2; grep -m3 'Next.js' "$scratch/build-app.log" >&2; exit 1; }
python3 - "$work/apps/web" <<'PY' || exit 1
import json, pathlib, sys
app = pathlib.Path(sys.argv[1])
pages = sorted(p for p in (app / "content").rglob("*.mdx"))
entry = app / ".open-next/assets/_pagefind/pagefind-entry.json"
if not entry.is_file():
    sys.exit(f"FAIL: the staged build shipped no search index ({entry.relative_to(app)} is missing) — Pagefind did not run, or ran after the OpenNext bundle")
count = sum(l.get("page_count", 0) for l in json.loads(entry.read_text())["languages"].values())
if count != len(pages):
    sys.exit(f"FAIL: the staged build's search index holds {count} page(s); content/ has {len(pages)}")
print(f"   the staged build ran on Turbopack and indexed all {count} pages for search")
PY

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config wrangler.jsonc --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" "$tree/apps/web/content" <<'PY'
import html, json, pathlib, re, sys, urllib.error, urllib.request
base, values, content = sys.argv[1], json.load(open(sys.argv[2])), pathlib.Path(sys.argv[3])
name, repo, org = values["productname"], values["reponame"], values["githuborg"]
source = f"https://github.com/{org}/{repo}"
problems = []
def bad(m): problems.append(m)
def get(path):
    try:
        with urllib.request.urlopen(base + path, timeout=30) as r:
            return r.status, r.headers.get("content-type", ""), r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get("content-type", ""), e.read()
def text(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()

status, _, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
title = re.search(r"<title>(.*?)</title>", page, re.S)
if not title or html.unescape(title.group(1)) != f"Introduction – {name}":
    bad(f"the home page's <title> is {title and title.group(1)!r}, not 'Introduction – {name}'")
if name not in [text(m) for m in re.findall(r"<span>(.*?)</span>", page, re.S)]:
    bad(f"the navbar logo does not read {name!r}")
footer = re.search(r"<footer[^>]*>(.*?)</footer>", page, re.S)
if not footer or text(footer.group(1)) != name:
    bad(f"the footer reads {footer and text(footer.group(1))!r}, not {name!r}")
if f'href="{source}"' not in page:
    bad(f"the navbar's GitHub link is not the site's repository {source}")
if f'href="{source}/tree/main/apps/web/content/index.mdx"' not in page:
    bad(f"'Edit this page' does not point at {source}/tree/main/apps/web/content/index.mdx")
if "Welcome to Nextra! This is a basic docs template." not in page:
    bad("the home page does not carry the Introduction")
for leftover in ("My Project", "nextra-docs", "github.com/sourceplane/"):
    if leftover in page:
        bad(f"the home page still carries the baseline's {leftover!r}")

# Every page content/ holds is pre-rendered and answers under its own title.
pages = sorted(p.relative_to(content).with_suffix("").as_posix() for p in content.rglob("*.mdx"))
for rel in pages:
    path = "/" if rel == "index" else f"/{rel}"
    s, _, body = get(path)
    t = re.search(r"<title>(.*?)</title>", body.decode(errors="replace"), re.S)
    if s != 200:
        bad(f"{path} answered {s}")
    elif not t or not html.unescape(t.group(1)).endswith(f" – {name}"):
        bad(f"{path}'s <title> is {t and t.group(1)!r}, not '… – {name}'")
s, _, _ = get("/no-such-page")
if s != 404:
    bad(f"/no-such-page answered {s}, want 404")

# The search index the build wrote, and the loader the search box imports.
s, ctype, body = get("/_pagefind/pagefind-entry.json")
try:
    langs = json.loads(body)["languages"]
    indexed = sum(l.get("page_count", 0) for l in langs.values())
    if s != 200 or indexed != len(pages):
        bad(f"/_pagefind/pagefind-entry.json answered {s} indexing {indexed} page(s); content/ has {len(pages)}")
except (ValueError, KeyError) as e:
    bad(f"/_pagefind/pagefind-entry.json is not the search index ({s}, {e})")
s, ctype, body = get("/_pagefind/pagefind.js")
if s != 200 or "javascript" not in ctype or b"pagefind" not in body[:200]:
    bad(f"/_pagefind/pagefind.js answered {s} {ctype} — not the Pagefind loader")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, {len(pages) - 1} more pages, a 404 and the search index ({indexed} pages) — the site's own, named {name!r}")
PY

echo "e2e.test.sh: ok"
