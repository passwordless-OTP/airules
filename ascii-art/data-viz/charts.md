# ASCII Data Visualization

## Progress Bars

### Basic Progress
```
[████████████████████░░░░░░░░░░] 67%
[■■■■■■■■■■■□□□□□□□□□] 55%
[▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱] 50%
```

### Compact Progress
```
▕████████▏ 80%
◖██████  ◗ 75%
⟦▓▓▓▓▓░░░⟧ 62%
```

## Sparklines

### Line Sparklines
```
Revenue: ▁▂▄▅▇█▆▄▃▁ (+12%)
Users:   ▁▁▂▃▅▆▇████ (+45%)
CPU:     █▇▅▃▂▁▂▄▆▇█ (avg: 73%)
```

### Bar Sparklines
```
Daily Sales: ▁▃▅▇█▆▄▂ 
Weekly:      ▄█▆▃▁▂▅█
Monthly:     ▂▄▆████▇▅
```

## Heat Maps

### Density Matrix
```
Activity Heatmap (Mon-Sun, 00:00-23:00)
     M  T  W  T  F  S  S
00  ░░ ░░ ░░ ░░ ░░ ▒▒ ▒▒
06  ▒▒ ▒▒ ▒▒ ▒▒ ▒▒ ░░ ░░
12  ▓▓ ▓▓ ▓▓ ▓▓ ▓▓ ▒▒ ▒▒
18  ██ ██ ██ ██ ▓▓ ▓▓ ▓▓
```

### Intensity Scale
```
Low    ░░░░░░░░░░░░░░░░    High
       ░░▒▒▒▒▓▓▓▓████
```

## Mini Charts

### Inline Bar Charts
```
Q1: ▇▇▇▇▇▇▇▇ 80%
Q2: ▇▇▇▇▇▇   60%
Q3: ▇▇▇▇▇▇▇▇▇ 90%
Q4: ▇▇▇▇▇    50%
```

### Vertical Bars
```
Sales by Region
     10 ┤ ██    
      8 ┤ ██ ██ 
      6 ┤ ██ ██ ██
      4 ┤ ██ ██ ██ ██
      2 ┤ ██ ██ ██ ██
      0 └─────────────
         US EU AS OC
```

## Gauges & Meters

### Circular Gauge
```
    ╭──────╮
   ╱ ◉75%  ╲
  │ ███████ │
   ╲        ╱
    ╰──────╯
```

### Linear Gauge
```
CPU: ◀▓▓▓▓▓▓▓▓░░▶ 80%
MEM: ◀▓▓▓▓▓░░░░░▶ 50%
DSK: ◀▓▓░░░░░░░░▶ 20%
```

## Scatter Plots

### Simple Scatter
```
10│     ×
  │   × ×  ×
 5│ ×   × ×
  │× × ×
 0└──────────▶
  0    5    10
```

### Multi-Series
```
Y │  ○ = Series A
  │○ • × = Series B
  │ ○×•
  │×○•×
  └────────▶ X
```

## Best Practices

1. **Consistent Scales**: Always show units and ranges
2. **Clear Labels**: Use legends for multi-series data
3. **Appropriate Density**: Match character density to data values
4. **Accessibility**: Include numeric values where possible