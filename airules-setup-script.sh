#!/bin/bash

# Create directory structure
mkdir -p ascii-art/{examples/{good,bad},templates}
mkdir -p claude-code/{prompts,patterns,fixes}
mkdir -p tools/bin
mkdir -p reference/{charts,diagrams,tables}

# Create README.md
cat > README.md << 'EOF'
# airules - AI Assistant Rules & Guidelines

A comprehensive collection of rules, patterns, and best practices for working with AI assistants, particularly focused on ASCII art and Claude Code.

## 📁 Directory Structure

```
airules/
├── ascii-art/          # ASCII art creation rules
│   ├── basics.md       # Fundamental rules
│   ├── tables.md       # Table formatting
│   ├── diagrams.md     # Flow charts, architecture
│   ├── charts.md       # Gantt, timeline, etc.
│   ├── examples/       # Reference examples
│   └── templates/      # Reusable templates
├── claude-code/        # Claude Code specific
│   ├── prompts/        # Effective prompting
│   ├── patterns/       # Common patterns
│   └── fixes/          # Common issues & solutions
├── tools/              # Helper scripts
│   └── bin/            # Executable tools
└── reference/          # Quick reference guides
```

## 🚀 Quick Start

1. Clone this repository
2. Add `tools/bin` to your PATH
3. Use `airules` command to access rules

## 📖 Usage

```bash
# Show ASCII art rules
airules ascii

# Show Claude Code rules
airules claude

# List all available rules
airules list

# Show specific rule
airules ascii-art/tables.md
```

## 🤝 Contributing

Feel free to add your own rules and patterns!
EOF

# Create ASCII Art Basics
cat > ascii-art/basics.md << 'EOF'
# ASCII Art Rules for Professional Diagrams

## Core Rules

1. **Count characters precisely** for each column
2. **Use consistent box-drawing characters**: └─┘├─┤┌─┐│
3. **Maintain equal padding** in all cells
4. **Add separators** between ALL logical sections
5. **Test alignment** by checking if vertical lines form straight columns

## Character Reference

### Single Line Boxes
```
┌─┬─┐
│ │ │
├─┼─┤
└─┴─┘
```

### Double Line Boxes
```
╔═╦═╗
║ ║ ║
╠═╬═╣
╚═╩═╝
```

### Rounded Boxes
```
╭─┬─╮
│ │ │
├─┼─┤
╰─┴─╯
```

## Never Use

- **Bold/italic/colors** (not ASCII)
- **Mixed character styles** in same diagram
- **Tabs** (use spaces only)
- **Trailing spaces**

## Testing

Always view in plain text editor to verify alignment
EOF

# Create ASCII Tables Guide
cat > ascii-art/tables.md << 'EOF'
# ASCII Tables Guide

## Basic Table Structure

```
┌──────────┬──────────┬──────────┐
│ Header 1 │ Header 2 │ Header 3 │
├──────────┼──────────┼──────────┤
│ Data 1   │ Data 2   │ Data 3   │
│ Data 4   │ Data 5   │ Data 6   │
└──────────┴──────────┴──────────┘
```

## Alignment Rules

### Text Alignment
- Left: `│ Text     │`
- Center: `│  Text   │`
- Right: `│     Text │`

### Number Alignment
```
│    1.50 │
│   15.00 │
│  150.75 │
│ 1500.00 │
```

## Section Separators

```
├──────────┼──────────┼──────────┤  # Regular separator
╞══════════╪══════════╪══════════╡  # Section separator
├──────────┴──────────┴──────────┤  # Spanning separator
```

## Complex Tables

### With Subheaders
```
┌──────────────────────┬──────────────────────┐
│     Sales Data       │    Performance       │
├──────────┬───────────┼───────────┬──────────┤
│   Q1     │    Q2     │    KPI    │  Status  │
├──────────┼───────────┼───────────┼──────────┤
│ $100K    │ $150K     │   150%    │    ✓     │
└──────────┴───────────┴───────────┴──────────┘
```
EOF

# Create ASCII Diagrams Guide
cat > ascii-art/diagrams.md << 'EOF'
# ASCII Diagrams Guide

## Flow Charts

### Basic Flow
```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Start  │────▶│ Process │────▶│   End   │
└─────────┘     └─────────┘     └─────────┘
```

### Decision Flow
```
                ┌─────────┐
                │  Start  │
                └────┬────┘
                     │
                ┌────▼────┐
           ┌────│ Check?  │────┐
           │ No └─────────┘ Yes│
           │                   │
      ┌────▼────┐         ┌────▼────┐
      │  Stop   │         │ Continue│
      └─────────┘         └─────────┘
```

## Architecture Diagrams

### Three-Tier Architecture
```
┌─────────────────────────────────────────┐
│            Presentation Layer           │
├─────────────────────────────────────────┤
│            Business Logic Layer         │
├─────────────────────────────────────────┤
│              Data Layer                 │
└─────────────────────────────────────────┘
```

### Microservices
```
┌─────────┐     ┌─────────┐     ┌─────────┐
│Service A│◀───▶│   API   │◀───▶│Service B│
└─────────┘     │ Gateway │     └─────────┘
                └────┬────┘
                     │
                ┌────▼────┐
                │Database │
                └─────────┘
```

## Connection Types

```
────▶  Direct flow
- - ▶  Optional flow
═══▶  Emphasized flow
···▶  Weak connection
◀──▶  Bidirectional
```
EOF

# Create Charts Guide
cat > ascii-art/charts.md << 'EOF'
# ASCII Charts Guide

## Bar Charts

### Horizontal Bar Chart
```
Performance Metrics
├─────────────────────────────────────┐
│ CPU    ████████████████░░░░░░ 65%  │
│ Memory ██████████████████████ 90%   │
│ Disk   ████████░░░░░░░░░░░░░░ 35%  │
│ Network████████████░░░░░░░░░░ 50%  │
└─────────────────────────────────────┘
```

### Vertical Bar Chart
```
Sales by Quarter ($M)
     │
  50 ┤                    ████
  40 ┤           ████     ████
  30 ┤    ████   ████     ████
  20 ┤    ████   ████     ████
  10 ┤    ████   ████     ████
   0 └────┴────┴────┴────┴────
       Q1   Q2   Q3   Q4
```

## Timeline Charts

```
Project Timeline
│
├─── Phase 1: Planning
│    └─── Q1 2024 ███████
│
├─── Phase 2: Development
│    └─── Q2-Q3 2024 ██████████████
│
└─── Phase 3: Launch
     └─── Q4 2024 ████████
```

## Gantt Charts

```
Tasks        │Jan│Feb│Mar│Apr│May│Jun│
─────────────┼───┼───┼───┼───┼───┼───┤
Planning     │███│███│   │   │   │   │
Development  │   │███│███│███│   │   │
Testing      │   │   │   │███│███│   │
Deployment   │   │   │   │   │███│███│
```
EOF

# Create Claude Code ASCII Fix
cat > claude-code/prompts/ascii-fix.md << 'EOF'
# Claude Code ASCII Diagram Fix

## The Problem

Claude Code sometimes creates misaligned ASCII diagrams with:
- Misaligned vertical lines
- Inconsistent column widths
- Mixed separator styles
- Uneven spacing

## The Solution Prompt

When ASCII diagrams are misaligned, use this prompt:

```
Please fix this ASCII table/diagram using these rules:
- Count characters precisely for each column
- Use consistent box-drawing characters: └─┘├─┤┌─┐│
- Maintain equal padding in all cells
- Add separators between logical sections
- Ensure vertical lines form straight columns

Example of correct format:
┌───────┬───────┬───────┐
│ Col 1 │ Col 2 │ Col 3 │
├───────┼───────┼───────┤
│ Data  │ Data  │ Data  │
└───────┴───────┴───────┘
```

## Making it Permanent

Add this to every session where you need ASCII diagrams:

```
Remember for ALL ASCII diagrams in this session:
1. Count characters precisely
2. Use consistent box-drawing characters
3. Equal padding in all cells
4. Test that vertical lines align
```
EOF

# Create example files
cat > ascii-art/examples/good/simple-table.txt << 'EOF'
┌──────────┬────────┬─────────┐
│  Name    │  Age   │  City   │
├──────────┼────────┼─────────┤
│  Alice   │   25   │  NYC    │
│  Bob     │   30   │  LA     │
│  Charlie │   35   │  SF     │
└──────────┴────────┴─────────┘
EOF

cat > ascii-art/examples/bad/misaligned-table.txt << 'EOF'
+-------+------+--------+
| Name  | Age | City |
+-------+------+--------+
| Alice | 25  | NYC    |
| Bob   | 30    | LA  |
| Charlie | 35  | SF    |
+-------+------+--------+
EOF

# Create the airules command
cat > tools/bin/airules << 'EOF'
#!/bin/bash

# airules - AI Rules Quick Access Tool

RULES_DIR="$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")"

case "$1" in
    ascii)
        cat "$RULES_DIR/ascii-art/basics.md"
        ;;
    claude)
        cat "$RULES_DIR/claude-code/prompts/ascii-fix.md"
        ;;
    list)
        echo "Available rules:"
        find "$RULES_DIR" -name "*.md" -type f | grep -v README | sed "s|$RULES_DIR/||" | sort
        ;;
    "")
        echo "Usage: airules [command] [path]"
        echo ""
        echo "Commands:"
        echo "  ascii     - Show ASCII art basics"
        echo "  claude    - Show Claude Code rules"
        echo "  list      - List all available rules"
        echo "  [path]    - Show specific rule file"
        echo ""
        echo "Examples:"
        echo "  airules ascii"
        echo "  airules ascii-art/tables.md"
        ;;
    *)
        # Try to find and display the requested file
        if [ -f "$RULES_DIR/$1" ]; then
            cat "$RULES_DIR/$1"
        elif [ -f "$RULES_DIR/$1.md" ]; then
            cat "$RULES_DIR/$1.md"
        else
            echo "Rule not found: $1"
            echo "Use 'airules list' to see available rules"
        fi
        ;;
esac
EOF

chmod +x tools/bin/airules

# Create .gitignore
cat > .gitignore << 'EOF'
# OS Files
.DS_Store
Thumbs.db

# Editor Files
*.swp
*.swo
*~
.vscode/
.idea/

# Temporary Files
*.tmp
*.bak
EOF

echo "✅ airules repository structure created!"
echo ""
echo "Next steps:"
echo "1. Review the files created"
echo "2. Add tools/bin to your PATH: export PATH=\"\$PATH:$(pwd)/tools/bin\""
echo "3. Commit and push to GitHub"