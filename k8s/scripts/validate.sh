#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ARGOCD_DIR="$ROOT_DIR/k3s-home/argocd"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

YAML_LINT=true
SCHEMA=true
HELM=true

KUBERNETES_VERSION="1.31"
KUBECONFORM_FLAGS=(
  --strict
  --kubernetes-version "$KUBERNETES_VERSION"
  --schema-location default
  --schema-location "https://raw.githubusercontent.com/datree-intl/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
  --ignore-missing-schemas
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validate ArgoCD applications, Kubernetes manifests, and Helm charts.

OPTIONS:
  --yaml-lint   Run only Layer 1 (YAML linting)
  --schema      Run only Layer 2 (K8s schema validation)
  --helm        Run only Layer 3 (Helm template validation)
  --all         Run all layers (default)
  -h, --help    Show this help message

EXAMPLES:
  $(basename "$0") --all
  $(basename "$0") --yaml-lint --schema
  $(basename "$0") --helm
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --yaml-lint)
      YAML_LINT=true
      SCHEMA=false
      HELM=false
      ;;
    --schema)
      YAML_LINT=false
      SCHEMA=true
      HELM=false
      ;;
    --helm)
      YAML_LINT=false
      SCHEMA=false
      HELM=true
      ;;
    --all)
      YAML_LINT=true
      SCHEMA=true
      HELM=true
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
  shift
done

log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; }
log_skip() { echo -e "${YELLOW}⊘${NC} $1"; }
log_info() { echo -e "$1"; }

cleanup() {
  if [[ -n "${HELM_TMP_DIR:-}" && -d "$HELM_TMP_DIR" ]]; then
    rm -rf "$HELM_TMP_DIR"
  fi
}
trap cleanup EXIT

layer1_yaml_lint() {
  log_info "\n${YELLOW}=== Layer 1: YAML Linting ===${NC}"
  local failed=0
  local passed=0

  while IFS= read -r -d '' yaml_file; do
    if yamllint -c "$ROOT_DIR/../.yamllint.yaml" "$yaml_file" 2>/dev/null; then
      log_pass "$yaml_file"
      ((passed++))
    else
      log_fail "$yaml_file"
      ((failed++))
    fi
  done < <(find "$ARGOCD_DIR" -name '*.yaml' -print0)

  if [[ $failed -gt 0 ]]; then
    log_fail "YAML linting failed: $failed failed, $passed passed"
    return 1
  fi
  log_pass "YAML linting passed: $passed files"
  return 0
}

layer2_schema() {
  log_info "\n${YELLOW}=== Layer 2: Kubernetes Schema Validation ===${NC}"
  local failed=0
  local passed=0
  local skipped=0

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" RETURN

  while IFS= read -r -d '' yaml_file; do
    local basename
    basename=$(basename "$yaml_file")

    if [[ "$basename" == "values.yaml" ]]; then
      log_skip "$yaml_file (Helm values, skipped)"
      ((skipped++))
      continue
    fi

    local output
    output=$(kubeconform "${KUBECONFORM_FLAGS[@]}" --output json "$yaml_file" 2>&1) || true

    if echo "$output" | grep -q '"kind":"ValidationError"'; then
      log_fail "$yaml_file"
      echo "$output" | jq -r '.[] | select(.kind == "ValidationError") | .details' 2>/dev/null || head -5 <<< "$output"
      ((failed++))
    elif echo "$output" | grep -q '"kind":"Error"'; then
      local error_msg
      error_msg=$(echo "$output" | jq -r '.[] | select(.kind == "Error") | .details.message' 2>/dev/null | head -1) || true
      if [[ -n "$error_msg" && "$error_msg" == *"missing"* ]]; then
        log_skip "$yaml_file (missing schema)"
        ((skipped++))
      else
        log_fail "$yaml_file"
        ((failed++))
      fi
    else
      log_pass "$yaml_file"
      ((passed++))
    fi
  done < <(find "$ARGOCD_DIR" -name '*.yaml' -print0)

  if [[ $failed -gt 0 ]]; then
    log_fail "Schema validation failed: $failed failed, $passed passed, $skipped skipped"
    return 1
  fi
  log_pass "Schema validation passed: $passed passed, $skipped skipped"
  return 0
}

layer3_helm() {
  log_info "\n${YELLOW}=== Layer 3: Helm Template Validation ===${NC}"

  HELM_TMP_DIR=$(mktemp -d)

  local repos=()
  local failed=0
  local passed=0
  local skipped=0

  local category_dirs=()
  while IFS= read -r -d '' category_dir; do
    category_dirs+=("$category_dir")
  done < <(find "$ARGOCD_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

  for category_dir in "${category_dirs[@]}"; do
    local subdirs=()
    while IFS= read -r -d '' subdir; do
      subdirs+=("$subdir")
    done < <(find "$category_dir" -mindepth 1 -maxdepth 1 -type d -print0)

    for app_dir in "${subdirs[@]}"; do
      local app_name
      app_name=$(basename "$app_dir")

      local app_yaml="$app_dir/application.yaml"
      local values_yaml="$app_dir/values.yaml"

      if [[ ! -f "$app_yaml" ]]; then
        log_skip "$app_name (no application.yaml)"
        ((skipped++))
        continue
      fi

      if [[ ! -f "$values_yaml" ]]; then
        log_skip "$app_name (no values.yaml)"
        ((skipped++))
        continue
      fi

      local first_line
      IFS= read -r first_line < "$app_yaml" || true
      if [[ "$first_line" == "#"* ]]; then
        log_skip "$app_name (commented out)"
        ((skipped++))
        continue
      fi

      local chart repo_url version
      chart=$(yq '.spec.sources[1].chart // ""' "$app_yaml" 2>/dev/null) || continue
      repo_url=$(yq '.spec.sources[1].repoURL // ""' "$app_yaml" 2>/dev/null) || continue
      version=$(yq '.spec.sources[1].targetRevision // ""' "$app_yaml" 2>/dev/null) || continue

      if [[ -z "$chart" || -z "$repo_url" || -z "$version" ]]; then
        log_skip "$app_name (missing chart metadata)"
        ((skipped++))
        continue
      fi

      local repo_name
      repo_name=$(echo "$repo_url" | sed -E 's|https?://||' | sed -E 's/[^a-zA-Z0-9.-]/_/g')

      local found=false
      for r in "${repos[@]}"; do
        if [[ "$r" == "$repo_url" ]]; then
          found=true
          break
        fi
      done

      if [[ "$found" == "false" ]]; then
        log_info "Adding helm repo: $repo_name ($repo_url)"
        helm repo add "$repo_name" "$repo_url" > /dev/null 2>&1 || true
        repos+=("$repo_url")
      fi

      local release_name
      release_name=$(yq -r '.spec.sources[1].helm.releaseName // .metadata.name' "$app_yaml")

      local rendered
      rendered=$(helm template "$release_name" "$repo_name/$chart" \
        --version "$version" \
        -f "$values_yaml" \
        --namespace default 2>&1) || {
        log_fail "$app_name (helm template failed)"
        head -10 <<< "$rendered"
        ((failed++))
        continue
      }

      local result
      result=$(kubeconform "${KUBECONFORM_FLAGS[@]}" - 2>&1 <<< "$rendered") || true

      if echo "$result" | grep -q '"kind":"ValidationError"'; then
        log_fail "$app_name (rendered manifest invalid)"
        ((failed++))
      elif echo "$result" | grep -q '"kind":"Error"' && ! echo "$result" | grep -q "missing schema"; then
        log_fail "$app_name (validation error)"
        ((failed++))
      else
        log_pass "$app_name"
        ((passed++))
      fi
    done
  done

  helm repo update > /dev/null 2>&1 || true

  if [[ $failed -gt 0 ]]; then
    log_fail "Helm validation failed: $failed failed, $passed passed, $skipped skipped"
    return 1
  fi
  log_pass "Helm validation passed: $passed passed, $skipped skipped"
  return 0
}

main() {
  log_info "Validating ArgoCD applications in: $ARGOCD_DIR"

  local layer_failed=0

  if [[ "$YAML_LINT" == "true" ]]; then
    layer1_yaml_lint || ((layer_failed++))
  fi

  if [[ "$SCHEMA" == "true" ]]; then
    layer2_schema || ((layer_failed++))
  fi

  if [[ "$HELM" == "true" ]]; then
    layer3_helm || ((layer_failed++))
  fi

  if [[ $layer_failed -gt 0 ]]; then
    log_fail "\n=== Validation Failed: $layer_failed layer(s) failed ==="
    exit 1
  fi

  log_pass "\n=== All Validations Passed ==="
  exit 0
}

main