#!/usr/bin/env bash
# Static checks for the whole repo. Run locally before pushing; CI runs the
# same script, so there is one definition of "passes".
#
#   tests/lint.sh
#
# Needs: shellcheck, bash, luac (lua), python3.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

fail=0
step() { printf '==> %s\n' "$*"; }
bad() {
    printf '    x %s\n' "$*"
    fail=1
}

# Tracked files only, so generated palettes are never linted. matugen
# templates are excluded too: they are not valid shell until rendered.
mapfile -t shell_files < <(
    git ls-files '*.sh' 'bin/*' '.githooks/*' | grep -v '^config/matugen/templates/' | sort -u
)

# Severity "error": the bar is "nothing broken". The older scripts still
# carry style warnings; run `shellcheck -S warning` on a file you are editing.
step "shellcheck (${#shell_files[@]} files)"
shellcheck -S error "${shell_files[@]}" || fail=1

step "bash syntax"
for f in "${shell_files[@]}"; do
    head -1 "$f" | grep -q 'bash\|sh$' || continue
    bash -n "$f" || bad "$f"
done

step "lua syntax"
while IFS= read -r f; do
    luac -p "$f" || bad "$f"
done < <(git ls-files 'config/hypr/*.lua' 'system/*.lua')

step "python syntax"
while IFS= read -r f; do
    python3 -m py_compile "$f" || bad "$f"
done < <(git ls-files 'config/*.py' | grep -v '^config/matugen/templates/')

step "waybar config is valid JSON"
python3 - <<'PY' || fail=1
import json, re, sys
ok = True
for f in ("config/waybar/config", "config/waybar/modules.jsonc"):
    text = re.sub(r"^\s*//.*$", "", open(f).read(), flags=re.M)
    try:
        json.loads(text)
    except ValueError as e:
        print("    x %s: %s" % (f, e))
        ok = False
sys.exit(0 if ok else 1)
PY

step "every script a keybind runs exists and is executable"
while IFS= read -r s; do
    [ -x "config/hypr/scripts/$s" ] || bad "config/hypr/scripts/$s (referenced from lua, missing or not executable)"
done < <(grep -rhoE 'scripts(/| \.\. ")[a-z-]+\.sh' config/hypr/lua | grep -oE '[a-z-]+\.sh' | sort -u)

step "installer parses its own flags"
./install.sh --help >/dev/null || bad "install.sh --help"

step "migrations are named YYYYMMDD-NN-*.sh and describe themselves"
for f in migrations/*.sh; do
    [[ $(basename "$f") =~ ^[0-9]{8}-[0-9]{2}-[a-z0-9-]+\.sh$ ]] || bad "$f: bad name"
    sed -n '2p' "$f" | grep -q '^# ' || bad "$f: line 2 must be a '# description'"
done

if [ "$fail" -eq 0 ]; then echo "all checks passed"; else
    echo "FAILED"
    exit 1
fi
