# Database Integration Testing

## Core Principles

1. **Test Real Database Interactions**
   - Use actual database engine (not in-memory substitutes)
   - Test transactions, constraints, and triggers
   - Verify data integrity

2. **Isolation Between Tests**
   - Each test starts with clean state
   - No test depends on another test's data
   - Rollback or clean up after each test

3. **Performance Considerations**
   - Use smaller datasets than production
   - Consider parallel test execution
   - Optimize slow queries in tests

## PostgreSQL Testing Patterns

### Test Database Setup
```javascript
// test/setup/database.js
const { Pool } = require('pg');

const testPool = new Pool({
  connectionString: process.env.TEST_DATABASE_URL,
  max: 5
});

beforeAll(async () => {
  // Create test schema
  await testPool.query('CREATE SCHEMA IF NOT EXISTS test');
  await testPool.query('SET search_path TO test');
  
  // Run migrations
  await runMigrations(testPool);
});

afterAll(async () => {
  // Clean up
  await testPool.query('DROP SCHEMA test CASCADE');
  await testPool.end();
});
```

### Transaction Rollback Pattern
```javascript
describe('OrderService Integration', () => {
  let client;
  
  beforeEach(async () => {
    client = await testPool.connect();
    await client.query('BEGIN');
  });
  
  afterEach(async () => {
    await client.query('ROLLBACK');
    client.release();
  });
  
  it('should create order with items', async () => {
    const orderService = new OrderService(client);
    
    const order = await orderService.createOrder({
      userId: 1,
      items: [
        { productId: 1, quantity: 2 },
        { productId: 2, quantity: 1 }
      ]
    });
    
    // Verify in same transaction
    const result = await client.query(
      'SELECT * FROM orders WHERE id = $1',
      [order.id]
    );
    
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0].total).toBe(150.00);
  });
});
```

## MySQL/Laravel Testing Patterns

### Database Transactions
```php
use Illuminate\Foundation\Testing\DatabaseTransactions;

class OrderRepositoryTest extends TestCase
{
    use DatabaseTransactions; // Auto rollback after each test
    
    private OrderRepository $repository;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = app(OrderRepository::class);
    }
    
    /** @test */
    public function it_creates_order_with_relationships()
    {
        // Arrange
        $user = User::factory()->create();
        $products = Product::factory()->count(3)->create();
        
        // Act
        $order = $this->repository->createWithItems($user->id, [
            ['product_id' => $products[0]->id, 'quantity' => 2],
            ['product_id' => $products[1]->id, 'quantity' => 1]
        ]);
        
        // Assert
        $this->assertDatabaseHas('orders', [
            'user_id' => $user->id,
            'status' => 'pending'
        ]);
        
        $this->assertCount(2, $order->items);
        $this->assertEquals(
            $products[0]->price * 2 + $products[1]->price,
            $order->total
        );
    }
}
```

### Testing Database Constraints
```php
/** @test */
public function it_enforces_unique_email_constraint()
{
    // Create first user
    User::factory()->create(['email' => 'test@example.com']);
    
    // Attempt duplicate
    $this->expectException(\Illuminate\Database\QueryException::class);
    
    User::factory()->create(['email' => 'test@example.com']);
}

/** @test */
public function it_cascades_delete_to_related_records()
{
    $user = User::factory()->has(Order::factory()->count(3))->create();
    
    $this->assertDatabaseCount('orders', 3);
    
    $user->delete();
    
    $this->assertDatabaseCount('orders', 0);
}
```

## Test Data Management

### Fixtures Pattern
```javascript
// fixtures/users.js
module.exports = {
  activeUser: {
    email: 'active@example.com',
    status: 'active',
    created_at: new Date('2023-01-01')
  },
  inactiveUser: {
    email: 'inactive@example.com',
    status: 'inactive',
    created_at: new Date('2023-01-01')
  }
};

// In tests
const fixtures = require('./fixtures/users');

beforeEach(async () => {
  await db.query(
    'INSERT INTO users (email, status, created_at) VALUES ($1, $2, $3)',
    [fixtures.activeUser.email, fixtures.activeUser.status, fixtures.activeUser.created_at]
  );
});
```

### Factory Pattern (Laravel)
```php
// database/factories/OrderFactory.php
class OrderFactory extends Factory
{
    public function definition()
    {
        return [
            'user_id' => User::factory(),
            'total' => $this->faker->randomFloat(2, 10, 1000),
            'status' => $this->faker->randomElement(['pending', 'completed', 'cancelled']),
        ];
    }
    
    public function completed()
    {
        return $this->state(function (array $attributes) {
            return [
                'status' => 'completed',
                'completed_at' => now(),
            ];
        });
    }
}

// Usage in tests
$completedOrders = Order::factory()
    ->count(5)
    ->completed()
    ->for($user)
    ->create();
```

## Performance Testing Queries

### Testing Query Performance
```javascript
it('should efficiently query orders with pagination', async () => {
  // Insert test data
  await seedLargeDataset(1000); // 1000 orders
  
  const start = Date.now();
  
  const result = await db.query(`
    SELECT o.*, u.name as user_name
    FROM orders o
    JOIN users u ON o.user_id = u.id
    WHERE o.created_at > $1
    ORDER BY o.created_at DESC
    LIMIT 20 OFFSET 0
  `, [thirtyDaysAgo]);
  
  const duration = Date.now() - start;
  
  expect(duration).toBeLessThan(100); // Should complete in 100ms
  expect(result.rows).toHaveLength(20);
});
```

### Testing with EXPLAIN
```javascript
it('should use index for user email lookup', async () => {
  const explainResult = await db.query(
    'EXPLAIN (FORMAT JSON) SELECT * FROM users WHERE email = $1',
    ['test@example.com']
  );
  
  const plan = explainResult.rows[0]['QUERY PLAN'][0]['Plan'];
  
  // Verify index scan is used
  expect(plan['Node Type']).toContain('Index Scan');
  expect(plan['Index Name']).toBe('idx_users_email');
});
```

## Seeding Strategies

### Hierarchical Data Seeding
```javascript
async function seedTestData() {
  const users = await seedUsers(10);
  
  for (const user of users) {
    const orders = await seedOrders(user.id, 5);
    
    for (const order of orders) {
      await seedOrderItems(order.id, 3);
    }
  }
}
```

### Bulk Insert Optimization
```php
// Efficient bulk insert for large datasets
$chunks = array_chunk($testData, 1000);

foreach ($chunks as $chunk) {
    DB::table('products')->insert($chunk);
}
```

## Common Pitfalls

1. **Shared State Between Tests**
   - Always clean up or use transactions
   - Don't rely on test execution order

2. **Testing with Production Data**
   - Never use production database
   - Create minimal test datasets

3. **Ignoring Database-Specific Features**
   - Test constraints, triggers, stored procedures
   - Verify cascade deletes work correctly

4. **Not Testing Edge Cases**
   - NULL values
   - Empty strings vs NULL
   - Maximum field lengths
   - Concurrent access scenarios