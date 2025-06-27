# Professional Database Schema Templates

## Entity Relationship Diagrams

### Basic One-to-Many
```
┌─────────────┐       ┌─────────────┐
│   USERS     │       │   POSTS     │
├─────────────┤       ├─────────────┤
│ PK  id      │───┐   │ PK  id      │
│     name    │   └──▶│ FK  user_id │
│     email   │       │     title   │
│     created │       │     content │
└─────────────┘       └─────────────┘
```

### Many-to-Many with Junction Table
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  STUDENTS   │     │ ENROLLMENTS │     │  COURSES    │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ PK  id      │◀───┤ FK  stud_id │───▶│ PK  id      │
│     name    │     │ FK  crs_id  │     │     name    │
│     email   │     │     grade   │     │     credits │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Complex Schema with Indices
```
┌───────────────────────────────────┐
│           ORDERS                  │
├───────────────────────────────────┤
│ PK    id         BIGINT          │
│ FK    user_id    → users.id      │
│ FK    product_id → products.id   │
│       quantity   INT             │
│       total      DECIMAL(10,2)   │
│       status     ENUM            │
│       created_at TIMESTAMP       │
├───────────────────────────────────┤
│ IDX   idx_user_created (user_id, │
│                        created_at)│
│ IDX   idx_status (status)        │
└───────────────────────────────────┘
```

## Inheritance Patterns

### Single Table Inheritance
```
┌─────────────────────────┐
│       VEHICLES          │
├─────────────────────────┤
│ PK  id                  │
│     type    [CAR|TRUCK] │
│     make               │
│     model              │
│     doors   (nullable) │ ← Car only
│     payload (nullable) │ ← Truck only
└─────────────────────────┘
```

### Class Table Inheritance
```
        ┌──────────────┐
        │   VEHICLES   │
        ├──────────────┤
        │ PK  id       │
        │     make     │
        │     model    │
        └──────┬───────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌──────────────┐ ┌──────────────┐
│     CARS     │ │    TRUCKS    │
├──────────────┤ ├──────────────┤
│ FK  veh_id   │ │ FK  veh_id   │
│     doors    │ │     payload  │
│     sunroof  │ │     axles    │
└──────────────┘ └──────────────┘
```

## NoSQL Document Structure
```
┌─ USERS Collection ──────────────┐
│ {                               │
│   _id: ObjectId("..."),        │
│   name: "John Doe",            │
│   profile: {                   │
│     avatar: "url",             │
│     bio: "text"                │
│   },                           │
│   posts: [                     │
│     { ref: "posts", id: "..." }│
│   ]                            │
│ }                              │
└─────────────────────────────────┘
```

## Redis Data Structure
```
┌─── Redis Keys ─────────────────┐
│                                │
│ user:1001      → Hash          │
│ ├─ name       → "Alice"        │
│ ├─ email      → "a@ex.com"     │
│ └─ last_login → "2024-01-15"   │
│                                │
│ sessions:active → Set          │
│ ├─ "sess:abc123"               │
│ └─ "sess:def456"               │
│                                │
│ queue:tasks    → List          │
│ ├─ [0] → "task:process"        │
│ └─ [1] → "task:email"          │
└────────────────────────────────┘
```

## Migration Schema
```
     Version 1.0              Version 2.0
┌──────────────┐         ┌──────────────────┐
│    USERS     │   ───▶  │      USERS       │
├──────────────┤         ├──────────────────┤
│ id           │         │ id               │
│ name         │         │ first_name  NEW  │
│ email        │         │ last_name   NEW  │
└──────────────┘         │ email            │
                         │ created_at  NEW  │
                         └──────────────────┘
```

## Best Practices

1. **Naming**: Use consistent naming (snake_case or camelCase)
2. **Keys**: Always mark PK (Primary Key) and FK (Foreign Key)
3. **Types**: Include data types for clarity
4. **Relationships**: Use clear arrows showing direction
5. **Indices**: Document important indices for performance