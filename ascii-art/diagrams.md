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
