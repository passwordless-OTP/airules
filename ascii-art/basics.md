# ASCII Art Rules for Professional Diagrams

## Core Rules

1. **Count characters precisely** for each column
2. **Use consistent box-drawing characters**: └─┘├─┤┌─┐│
3. **Maintain equal padding** in all cells
4. **Add separators** between ALL logical sections
5. **Test alignment** by checking if vertical lines form straight columns
6. **CRITICAL: Every line must have EXACTLY the same character count**

## Character Counting Rule (NEW - June 2025)

### The Golden Rule
**EVERY line in an ASCII box diagram must have EXACTLY the same character count**

### Why This Matters
- Even one missing space breaks the alignment
- Inconsistent line lengths make right borders misalign
- Professional diagrams require perfect alignment

### How to Verify
```javascript
// Quick verification method
const lines = diagram.split('\n');
const lengths = lines.map(line => line.length);
const allSame = lengths.every(len => len === lengths[0]);
console.log(allSame ? "✅ Valid" : "❌ Invalid");
```

### Common Mistakes
```
WRONG (62 vs 63 chars):
┌─────────────┐  <- 63 chars
│ Content     │  <- 62 chars (missing space before │)
└─────────────┘  <- 63 chars

CORRECT (all 63 chars):
┌─────────────┐
│ Content     │  <- Added space to make 63
└─────────────┘
```

## Real Example from Practice

### Unit Economics Table Issue
We discovered this when debugging a unit economics table where content lines were 62 chars but borders were 63 chars.

### Before (Broken)
```
│  LTV (@ $95 ARPU):               $1,900                    │  <- 62 chars
│  LTV:CAC Ratio:                   76:1                     │  <- 62 chars
└─────────────────────────────────────────────────────────────┘  <- 63 chars
```

### After (Fixed)
```
│  LTV (@ $95 ARPU):                $1,900                    │  <- 63 chars
│  LTV:CAC Ratio:                   76:1                      │  <- 63 chars
└─────────────────────────────────────────────────────────────┘  <- 63 chars
```

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

## Alignment Checklist

- [ ] Count total width of your box
- [ ] Ensure ALL lines match this width exactly
- [ ] Check that vertical borders align perfectly
- [ ] Verify section separators span full width
- [ ] Test in a monospace font editor

## Never Use

- **Bold/italic/colors** (not ASCII)
- **Mixed character styles** in same diagram
- **Tabs** (use spaces only)
- **Trailing spaces** (except when needed for alignment)
- **Variable line lengths** (biggest mistake!)

## Testing

Always view in plain text editor to verify alignment. Use character counting to ensure consistency.