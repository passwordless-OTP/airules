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
