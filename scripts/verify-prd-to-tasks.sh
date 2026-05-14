#!/usr/bin/env bash
# Verifies prd-to-tasks skill redesign artifacts meet the contract in
# docs/superpowers/specs/2026-05-14-prd-to-tasks-redesign-design.md
set -u
SKILL=skills/prd-to-tasks/SKILL.md
REPO_MAP=skills/prd-to-tasks/references/repo-map.md
PATTERNS=skills/prd-to-tasks/references/service-patterns.md
BUNDLE=dist/prd-to-tasks.skill
FAIL=0

# Forbidden company-internal identifiers (must NOT appear anywhere in open-source artifacts)
FORBIDDEN='idgen\.NextID|cache\.DoubleDelete|BrokerTopics|KafkaTopics|order\.booking\.created|internal/facade/mq/topic\.go|klook\.com|jake\.li@klook'

check() {
    local label="$1" cmd="$2" expect="$3"
    actual=$(eval "$cmd" 2>/dev/null; true)
    actual=${actual:-0}
    if [[ "$expect" == "gt0" && "$actual" -gt 0 ]]; then
        echo "✅ $label  (matches=$actual)"
    elif [[ "$expect" == "eq0" && "$actual" -eq 0 ]]; then
        echo "✅ $label  (no matches, as expected)"
    else
        echo "❌ $label  (expected $expect, got $actual)"
        FAIL=$((FAIL+1))
    fi
}

echo "=== Task 1: frontmatter + Phase 0 cleanup ==="
check "SKILL.md: no forbidden klook identifiers in description (lines 1-15)" \
      "sed -n '1,15p' $SKILL | grep -cE '$FORBIDDEN'" eq0
check "SKILL.md: no klook identifiers in opening example (lines 16-40)" \
      "sed -n '16,40p' $SKILL | grep -cE '$FORBIDDEN'" eq0

echo "=== Task 2: Phase 1 ==="
check "SKILL.md: contains 'PM 范围澄清清单'" \
      "grep -c 'PM 范围澄清清单' $SKILL" gt0
check "SKILL.md: contains 'HARD-GATE' (≥3 instances for Phase 1/3/4)" \
      "grep -c '<HARD-GATE>' $SKILL" gt0
check "SKILL.md: Phase 1 risk format has 考虑过的备选" \
      "grep -c '考虑过的备选\\|考虑过' $SKILL" gt0

echo "=== Task 3: Phase 2 ==="
check "SKILL.md: scan output has confidence column" \
      "grep -c 'confidence' $SKILL" gt0
check "SKILL.md: mentions LSP fallback" \
      "grep -cE 'LSP|gopls|pyright|typescript-language-server' $SKILL" gt0

echo "=== Task 4: Phase 3 ==="
check "SKILL.md: spec template has frontmatter (yaml fence)" \
      "grep -cE '^feature: ' $SKILL" gt0
check "SKILL.md: spec template has Boundaries 三段 / Always do / Never do" \
      "grep -cE 'Always do|Never do' $SKILL" gt0
check "SKILL.md: Spec default path is docs/superpowers/specs/" \
      "grep -c 'docs/superpowers/specs/' $SKILL" gt0

echo "=== Task 5: Phase 4 ==="
check "SKILL.md: sizing uses XS-XL" \
      "grep -cE '\\bXS\\b' $SKILL" gt0
check "SKILL.md: task has spec-refs:" \
      "grep -c 'spec-refs' $SKILL" gt0
check "SKILL.md: contains mermaid task DAG section" \
      "grep -cE '\`\`\`mermaid' $SKILL" gt0
check "SKILL.md: Plan default path is docs/superpowers/plans/" \
      "grep -c 'docs/superpowers/plans/' $SKILL" gt0
check "SKILL.md: plan frontmatter has routed-to field" \
      "grep -c 'routed-to:' $SKILL" gt0

echo "=== Task 6: Phase 5 + KB section ==="
check "SKILL.md: has Knowledge Base section" \
      "grep -cE '知识库|Knowledge Base' $SKILL" gt0
check "SKILL.md: documents 3-layer KB loading order" \
      "grep -cE '~/.claude/prd-to-tasks|.claude/prd-to-tasks' $SKILL" gt0

echo "=== Task 7-8: References cleanup ==="
check "repo-map.md: has 'Generic example' banner" \
      "head -5 $REPO_MAP | grep -ciE 'generic.*example|industry.*neutral'" gt0
check "repo-map.md: no klook-internal identifiers" \
      "grep -cE '$FORBIDDEN' $REPO_MAP" eq0
check "service-patterns.md: has 'Generic example' banner" \
      "head -5 $PATTERNS | grep -ciE 'generic.*example|industry.*neutral'" gt0
check "service-patterns.md: no klook-internal identifiers" \
      "grep -cE '$FORBIDDEN' $PATTERNS" eq0

echo "=== Task 9: Bundle ==="
check "dist/prd-to-tasks.skill bundle exists" \
      "[[ -f $BUNDLE ]] && echo 1 || echo 0" gt0
check "Bundle contains SKILL.md" \
      "[[ -f $BUNDLE ]] && unzip -l $BUNDLE 2>/dev/null | grep -c 'SKILL.md' || echo 0" gt0

echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "All checks passed ✅"
    exit 0
else
    echo "$FAIL check(s) failed ❌"
    exit 1
fi
