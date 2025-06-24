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
