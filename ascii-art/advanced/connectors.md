# Advanced ASCII Connectors & Junctions

## Connector Types

### Basic Lines
```
Horizontal: ─ ━ ═ ≡
Vertical:   │ ┃ ║ ‖
```

### Corner Styles
```
Standard:  ┌─┐  ┏━┓  ╔═╗  ╭─╮
           └─┘  ┗━┛  ╚═╝  ╰─╯
```

### T-Junctions
```
├─ ┣━ ╟─ ╠═    (left)
─┤ ━┫ ─╢ ═╣    (right)
┬─ ┳━ ╦═ ╥─    (top)
┴─ ┻━ ╩═ ╨─    (bottom)
```

### Cross Junctions
```
┼─ ╋━ ╬═ ╫─ ╪═
```

### Arrow Connectors
```
Direct:        ────▶   ◀────   ◀───▶
Emphasized:    ════▶   ◀════   ◀═══▶
Dashed:        ----▶   ◀----   ◀---▶
Dotted:        ····▶   ◀····   ◀···▶
```

### Special Connectors
```
Fork/Merge:    ─┬─     ─┴─
               ╱ ╲     ╲ ╱
              ─   ─     ─
```

## Usage Examples

### Decision Flow
```
         ┌─────────┐
         │ Start   │
         └────┬────┘
              │
         ┌────▼────┐
         │Decision?│
         └─┬────┬──┘
     Yes ╱      ╲ No
        ▼        ▼
   ┌────────┐ ┌────────┐
   │ Path A │ │ Path B │
   └────────┘ └────────┘
```

### Complex Junction
```
     ━━━━━━━━┳━━━━━━━━━
             ┃
    ─────────╫─────────
             ┃
     ════════╬═════════
             ┃
     ········╫·········
```

## Best Practices

1. **Consistency**: Use one line style per diagram
2. **Hierarchy**: Thicker lines for main flows
3. **Spacing**: Maintain clear gaps at junctions
4. **Alignment**: Ensure perfect vertical/horizontal alignment