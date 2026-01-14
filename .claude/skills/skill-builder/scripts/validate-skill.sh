#!/usr/bin/env bash
# Validate Claude Code skill structure and format

set -e

SKILL_DIR="${1:-.}"

echo "Validating skill in: $SKILL_DIR"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Check SKILL.md exists
if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    echo -e "${RED}✗ SKILL.md not found${NC}"
    ((errors++))
else
    echo -e "${GREEN}✓ SKILL.md exists${NC}"
fi

# Validate YAML frontmatter
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    # Check frontmatter delimiters
    if ! head -n 1 "$SKILL_DIR/SKILL.md" | grep -q "^---$"; then
        echo -e "${RED}✗ SKILL.md missing frontmatter opening '---'${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✓ Frontmatter opening delimiter found${NC}"
    fi

    # Check if name field exists
    if ! grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
        echo -e "${RED}✗ Missing required 'name' field${NC}"
        ((errors++))
    else
        name=$(grep "^name:" "$SKILL_DIR/SKILL.md" | head -1 | cut -d':' -f2- | xargs)
        echo -e "${GREEN}✓ Name field found: $name${NC}"

        # Validate name format
        if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
            echo -e "${RED}✗ Name must be lowercase with hyphens only${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ Name format valid${NC}"
        fi

        # Check name length
        if [ ${#name} -gt 64 ]; then
            echo -e "${RED}✗ Name exceeds 64 characters${NC}"
            ((errors++))
        fi
    fi

    # Check if description field exists
    if ! grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
        echo -e "${RED}✗ Missing required 'description' field${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✓ Description field found${NC}"

        # Extract and check description length (only from frontmatter, before closing ---)
        # Get line numbers for the frontmatter section
        first_delimiter=$(grep -n "^---$" "$SKILL_DIR/SKILL.md" | head -1 | cut -d':' -f1)
        second_delimiter=$(grep -n "^---$" "$SKILL_DIR/SKILL.md" | sed -n '2p' | cut -d':' -f1)

        if [ -n "$first_delimiter" ] && [ -n "$second_delimiter" ]; then
            # Extract description only from frontmatter
            desc_text=$(sed -n "${first_delimiter},${second_delimiter}p" "$SKILL_DIR/SKILL.md" | sed -n '/^description:/,/^[a-z-]*:/p' | head -n -1 | sed '1s/^description: *[>|]* *//')
            desc_length=$(echo -n "$desc_text" | wc -c)

            if [ "$desc_length" -gt 1024 ]; then
                echo -e "${YELLOW}⚠ Description exceeds 1024 characters (${desc_length} chars)${NC}"
                ((warnings++))
            fi
        fi
    fi

    # Check for closing frontmatter delimiter
    if ! sed -n '2,/^---$/p' "$SKILL_DIR/SKILL.md" | tail -1 | grep -q "^---$"; then
        echo -e "${RED}✗ SKILL.md missing frontmatter closing '---'${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✓ Frontmatter closing delimiter found${NC}"
    fi

    # Check for markdown content after frontmatter
    line_count=$(wc -l < "$SKILL_DIR/SKILL.md")
    frontmatter_end=$(grep -n "^---$" "$SKILL_DIR/SKILL.md" | sed -n '2p' | cut -d':' -f1)
    if [ -n "$frontmatter_end" ] && [ "$line_count" -le "$frontmatter_end" ]; then
        echo -e "${YELLOW}⚠ No markdown content after frontmatter${NC}"
        ((warnings++))
    else
        echo -e "${GREEN}✓ Markdown content present${NC}"
    fi
fi

# Check optional files
if [ -f "$SKILL_DIR/reference.md" ]; then
    echo -e "${GREEN}✓ reference.md found (optional)${NC}"
fi

if [ -f "$SKILL_DIR/examples.md" ]; then
    echo -e "${GREEN}✓ examples.md found (optional)${NC}"
fi

# Check scripts directory and permissions
if [ -d "$SKILL_DIR/scripts" ]; then
    echo -e "${GREEN}✓ scripts/ directory found${NC}"

    # Check script permissions
    for script in "$SKILL_DIR/scripts"/*; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                echo -e "${GREEN}✓ $(basename "$script") is executable${NC}"
            else
                echo -e "${YELLOW}⚠ $(basename "$script") not executable (chmod +x needed)${NC}"
                ((warnings++))
            fi
        fi
    done
fi

# Summary
echo ""
echo "================================"
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✓ Skill validation passed!${NC}"
    exit 0
elif [ $errors -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation passed with $warnings warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $errors error(s) and $warnings warning(s)${NC}"
    exit 1
fi
