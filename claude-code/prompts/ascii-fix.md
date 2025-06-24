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
