#!/bin/bash
# Test for peer-review.sh: verifies that long CLI responses are not truncated
# and that the script exposes a bounded, structured stdout.

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPT_DIR/peer-review.sh"
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t peer-review-test)
FAKE_BIN="$TMPDIR/bin"
OUT_DIR="$TMPDIR/output"
FIXTURES="$TMPDIR/fixtures"
LINE_COUNT=500

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$FIXTURES"

# Build a deterministic 500-line payload per CLI.
for cli in gemini codex claude; do
    {
        echo "=== Begin $cli review ==="
        for i in $(seq 1 $LINE_COUNT); do
            echo "$cli line $i: lorem ipsum dolor sit amet consectetur adipiscing elit"
        done
        echo "=== End $cli review ==="
    } > "$FIXTURES/${cli}.txt"
done

# Fake gemini: gemini -p "prompt" → emit fixture to stdout
cat > "$FAKE_BIN/gemini" <<EOF
#!/bin/bash
cat "$FIXTURES/gemini.txt"
EOF

# Fake codex: codex exec -o OUTFILE "prompt" → write fixture to OUTFILE
cat > "$FAKE_BIN/codex" <<EOF
#!/bin/bash
out=""
while [ \$# -gt 0 ]; do
    case "\$1" in
        -o) out="\$2"; shift 2 ;;
        *)  shift ;;
    esac
done
if [ -n "\$out" ]; then
    cat "$FIXTURES/codex.txt" > "\$out"
else
    cat "$FIXTURES/codex.txt"
fi
EOF

# Fake claude: claude -p "prompt" → emit fixture to stdout
cat > "$FAKE_BIN/claude" <<EOF
#!/bin/bash
cat "$FIXTURES/claude.txt"
EOF

chmod +x "$FAKE_BIN"/*

export PATH="$FAKE_BIN:$PATH"
export PEER_REVIEW_DIR="$OUT_DIR"

# Run the script and capture stdout.
STDOUT_FILE="$TMPDIR/stdout.txt"
bash "$SCRIPT" execute "test prompt" gemini codex claude > "$STDOUT_FILE" 2>&1

fail() {
    echo "FAIL: $1" >&2
    echo "----- stdout -----" >&2
    cat "$STDOUT_FILE" >&2
    echo "----- output dir contents -----" >&2
    ls -la "$OUT_DIR" 2>&1 >&2 || true
    exit 1
}

# Assertion 1: per-CLI output files exist in OUT_DIR with full content.
expected_lines=$((LINE_COUNT + 2))  # 500 body + 2 sentinel lines
for cli in gemini codex claude; do
    file="$OUT_DIR/${cli}.txt"
    [ -f "$file" ] || fail "$file does not exist"
    actual=$(wc -l < "$file" | tr -d ' ')
    [ "$actual" = "$expected_lines" ] \
        || fail "$cli: expected $expected_lines lines in $file, got $actual"
    grep -q "Begin $cli review" "$file" \
        || fail "$cli: missing begin sentinel in $file"
    grep -q "End $cli review" "$file" \
        || fail "$cli: missing end sentinel in $file"
done

# Assertion 2: stdout is bounded — must not contain the full bodies of CLI
# responses. We reject any stdout that contains 200+ "lorem ipsum" body lines
# (that would indicate the script is streaming bodies through stdout, which is
# the truncation-prone design).
body_line_count=$(grep -c "lorem ipsum" "$STDOUT_FILE" || true)
[ "$body_line_count" -lt 50 ] \
    || fail "stdout contains $body_line_count body lines — script is streaming \
full responses through stdout instead of writing to files. This makes \
truncation by piped consumers possible."

# Assertion 3: stdout points the agent at the output directory so it can read
# files even when invoked via run_in_background.
grep -q "$OUT_DIR" "$STDOUT_FILE" \
    || fail "stdout does not surface PEER_REVIEW_DIR ($OUT_DIR); agent has \
no way to locate output files"

# Assertion 4: stale-file guard. When the same PEER_REVIEW_DIR is reused and a
# CLI fails before writing, the previous run's content must NOT linger in the
# output file. We replace the codex fake with one that exits non-zero without
# writing anything, then re-run with the same OUT_DIR. codex.txt must end up
# empty so the FAILED status block can't point at stale data.
cat > "$FAKE_BIN/codex" <<'EOF'
#!/bin/bash
# Fail before writing the -o file
exit 7
EOF
chmod +x "$FAKE_BIN/codex"

STDOUT_FILE2="$TMPDIR/stdout2.txt"
bash "$SCRIPT" execute "test prompt" gemini codex claude > "$STDOUT_FILE2" 2>&1 || true

stale_codex="$OUT_DIR/codex.txt"
[ -f "$stale_codex" ] || fail "codex.txt missing after re-run with failing codex fake"
stale_size=$(wc -c < "$stale_codex" | tr -d ' ')
[ "$stale_size" = "0" ] \
    || fail "codex.txt retains $stale_size bytes from previous run despite codex \
failing in second run; stale-file guard not in place. Status block could \
mislead an agent into reading prior-run content."

echo "PASS: outputs preserved; stdout bounded; stale-file guard works."
