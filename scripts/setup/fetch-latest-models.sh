#!/bin/bash

# Fetch Latest Ollama Cloud Models & Configure Goose
# Scrapes ollama.com for all available cloud models, pulls new ones,
# and updates Goose configuration.

echo "=================================================="
echo "  FETCH LATEST OLLAMA CLOUD MODELS"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

GOOSE_CONFIG="$HOME/.config/goose/config.yaml"

# ── 1. Check prerequisites ──────────────────────────────────────
if ! command -v ollama &>/dev/null; then
    echo -e "${RED}Error: ollama is not installed${NC}"
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is not installed${NC}"
    exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo -e "${YELLOW}Starting Ollama...${NC}"
    ollama serve &>/dev/null &
    sleep 2
    if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo -e "${RED}Error: Could not start Ollama${NC}"
        exit 1
    fi
fi

# ── 2. Get currently installed cloud models ──────────────────────
echo -e "${BLUE}Currently installed cloud models:${NC}"
INSTALLED_MODELS=$(ollama list 2>/dev/null | grep ":.*cloud" | awk '{print $1}' | sort)
if [ -z "$INSTALLED_MODELS" ]; then
    echo "  (none)"
else
    echo "$INSTALLED_MODELS" | sed 's/^/  /'
fi
INSTALLED_COUNT=$(echo "$INSTALLED_MODELS" | grep -c . 2>/dev/null || echo 0)
echo ""

# ── 3. Fetch available cloud models from ollama.com ──────────────
echo -e "${BLUE}Fetching available cloud models from ollama.com...${NC}"

# Get model names from the cloud search page
MODEL_NAMES=$(curl -sL "https://ollama.com/search?c=cloud" | \
    grep -oP 'href="/library/[^"]*"' | \
    sed 's|href="/library/||;s|"||g' | \
    sort -u)

if [ -z "$MODEL_NAMES" ]; then
    echo -e "${RED}Error: Could not fetch model list from ollama.com${NC}"
    echo "Check your internet connection and try again."
    exit 1
fi

# For each model, find the :cloud tag(s)
echo -e "${BLUE}Resolving cloud tags...${NC}"
CLOUD_TAGS=()
for model_name in $MODEL_NAMES; do
    # Fetch the tags page and extract cloud tags
    tags=$(curl -sL "https://ollama.com/library/${model_name}/tags" | \
        grep -oP "href=\"/library/${model_name}:[^\"]*cloud[^\"]*\"" | \
        sed "s|href=\"/library/||;s|\"||g" | \
        sort -u)

    if [ -n "$tags" ]; then
        while IFS= read -r tag; do
            CLOUD_TAGS+=("$tag")
        done <<< "$tags"
    fi
done

if [ ${#CLOUD_TAGS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No cloud tags found${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}Available cloud models on ollama.com (${#CLOUD_TAGS[@]} total):${NC}"
echo "──────────────────────────────────────────"

# Determine which are new vs already installed
NEW_MODELS=()
EXISTING_MODELS=()
for tag in "${CLOUD_TAGS[@]}"; do
    if echo "$INSTALLED_MODELS" | grep -qx "$tag"; then
        EXISTING_MODELS+=("$tag")
        echo -e "  ${GREEN}[installed]${NC} $tag"
    else
        NEW_MODELS+=("$tag")
        echo -e "  ${YELLOW}[new]      ${NC} $tag"
    fi
done

# Find installed models that are no longer available on ollama.com
OBSOLETE_MODELS=()
if [ -n "$INSTALLED_MODELS" ]; then
    while IFS= read -r installed; do
        [ -z "$installed" ] && continue
        found=false
        for tag in "${CLOUD_TAGS[@]}"; do
            if [ "$installed" = "$tag" ]; then
                found=true
                break
            fi
        done
        if ! $found; then
            OBSOLETE_MODELS+=("$installed")
            echo -e "  ${RED}[removed]  ${NC} $installed"
        fi
    done <<< "$INSTALLED_MODELS"
fi

echo ""
echo -e "Installed: ${#EXISTING_MODELS[@]}  |  New: ${#NEW_MODELS[@]}  |  Obsolete: ${#OBSOLETE_MODELS[@]}"
echo ""

# ── 4. Remove obsolete models ───────────────────────────────────
if [ ${#OBSOLETE_MODELS[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following installed models are no longer available on ollama.com:${NC}"
    for m in "${OBSOLETE_MODELS[@]}"; do
        echo -e "  ${RED}-${NC} $m"
    done
    echo ""
    read -p "Remove these obsolete models? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        for m in "${OBSOLETE_MODELS[@]}"; do
            echo -ne "  Removing ${BOLD}$m${NC} ... "
            if ollama rm "$m" &>/dev/null; then
                echo -e "${GREEN}done${NC}"
            else
                echo -e "${RED}failed${NC}"
            fi
        done
        echo ""
    fi
fi

# ── 5. Prompt user for what to pull ─────────────────────────────
if [ ${#NEW_MODELS[@]} -eq 0 ]; then
    echo -e "${GREEN}All cloud models are already installed!${NC}"
    echo ""
    read -p "Update (re-pull) existing models? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        MODELS_TO_PULL=()
    else
        MODELS_TO_PULL=("${EXISTING_MODELS[@]}")
    fi
else
    echo "What would you like to do?"
    echo "  1) Pull new models only (${#NEW_MODELS[@]} models)"
    echo "  2) Pull all cloud models (${#CLOUD_TAGS[@]} models)"
    echo "  3) Select individually"
    echo "  4) Skip pulling"
    echo ""
    read -p "Choice [1-4]: " -n 1 -r
    echo ""

    case $REPLY in
        1)
            MODELS_TO_PULL=("${NEW_MODELS[@]}")
            ;;
        2)
            MODELS_TO_PULL=("${CLOUD_TAGS[@]}")
            ;;
        3)
            echo ""
            echo "Select models to pull (space-separated numbers):"
            for i in "${!NEW_MODELS[@]}"; do
                echo "  $((i+1))) ${NEW_MODELS[$i]}"
            done
            echo ""
            read -p "Selection: " -r selection
            MODELS_TO_PULL=()
            for num in $selection; do
                if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -le ${#NEW_MODELS[@]} ] && [ "$num" -gt 0 ]; then
                    MODELS_TO_PULL+=("${NEW_MODELS[$((num-1))]}")
                fi
            done
            ;;
        *)
            MODELS_TO_PULL=()
            ;;
    esac
fi

# ── 6. Pull models ──────────────────────────────────────────────
if [ ${#MODELS_TO_PULL[@]} -gt 0 ]; then
    echo ""
    echo -e "${BLUE}Pulling ${#MODELS_TO_PULL[@]} model(s)...${NC}"
    echo "══════════════════════════════════════════"

    SUCCESS=0
    FAILED=0
    for model in "${MODELS_TO_PULL[@]}"; do
        echo -ne "  Pulling ${BOLD}$model${NC} ... "
        if ollama pull "$model" 2>&1 | tail -1 | grep -qiE "success|up to date"; then
            echo -e "${GREEN}done${NC}"
            ((SUCCESS++))
        else
            # Try once more in case of transient failure
            if ollama pull "$model" 2>&1 | tail -1 | grep -qiE "success|up to date"; then
                echo -e "${GREEN}done (retry)${NC}"
                ((SUCCESS++))
            else
                echo -e "${RED}failed${NC}"
                ((FAILED++))
            fi
        fi
    done

    echo ""
    echo -e "Pulled: ${GREEN}$SUCCESS${NC}  Failed: ${RED}$FAILED${NC}"
fi

# ── 7. Update Goose configuration ───────────────────────────────
echo ""
if [ ! -f "$GOOSE_CONFIG" ]; then
    echo -e "${YELLOW}Goose config not found at $GOOSE_CONFIG - skipping config update${NC}"
    echo "Run setup.sh first to create the base configuration."
else
    # Get all installed cloud models after pulling
    ALL_CLOUD=$(ollama list 2>/dev/null | grep ":.*cloud" | awk '{print $1}' | sort)
    TOTAL_CLOUD=$(echo "$ALL_CLOUD" | grep -c . 2>/dev/null || echo 0)

    # Read current model
    CURRENT_MODEL=$(grep "^GOOSE_MODEL:" "$GOOSE_CONFIG" | awk '{print $2}')

    # Check if current model is still valid
    if [ -n "$CURRENT_MODEL" ] && echo "$ALL_CLOUD" | grep -qx "$CURRENT_MODEL"; then
        echo -e "${GREEN}Current model ($CURRENT_MODEL) is still available${NC}"
    elif [ -n "$CURRENT_MODEL" ]; then
        echo -e "${YELLOW}Current model ($CURRENT_MODEL) is no longer available${NC}"
        # Pick the first available cloud model as new default
        NEW_DEFAULT=$(echo "$ALL_CLOUD" | head -1)
        sed -i "s/^GOOSE_MODEL: .*/GOOSE_MODEL: $NEW_DEFAULT/" "$GOOSE_CONFIG"
        echo -e "${GREEN}Switched default to: $NEW_DEFAULT${NC}"
    fi

    echo ""
    echo -e "${BOLD}All installed cloud models ($TOTAL_CLOUD):${NC}"
    echo "$ALL_CLOUD" | sed 's/^/  /'
fi

# ── 8. Summary ──────────────────────────────────────────────────
echo ""
echo "=================================================="
echo -e "${GREEN}DONE!${NC}"
echo "=================================================="
echo ""
echo "Quick commands:"
echo "  ./switch-model.sh    Switch active model"
echo "  ./run-goose.sh       Start Goose"
echo ""
