# Unit Testing Patterns

## General Principles

1. **Test One Thing**
   - Each test should verify a single behavior
   - If a test fails, it should be immediately clear what broke

2. **Fast and Isolated**
   - No external dependencies (database, API, filesystem)
   - Mock all external services
   - Tests should run in milliseconds

3. **Descriptive Names**
   ```javascript
   // Bad
   test('user test', () => {});
   
   // Good
   test('should return user full name when first and last name are provided', () => {});
   ```

## JavaScript/TypeScript Patterns

### Basic Test Structure (Jest)
```javascript
describe('UserService', () => {
  let userService;
  let mockDatabase;
  
  beforeEach(() => {
    mockDatabase = {
      query: jest.fn()
    };
    userService = new UserService(mockDatabase);
  });
  
  afterEach(() => {
    jest.clearAllMocks();
  });
  
  describe('createUser', () => {
    it('should create a user with hashed password', async () => {
      // Arrange
      const userData = { email: 'test@example.com', password: 'password123' };
      mockDatabase.query.mockResolvedValue({ id: 1, ...userData });
      
      // Act
      const result = await userService.createUser(userData);
      
      // Assert
      expect(result).toHaveProperty('id');
      expect(result.password).not.toBe('password123');
      expect(mockDatabase.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT'),
        expect.any(Array)
      );
    });
  });
});
```

### Mocking Patterns
```javascript
// Mock modules
jest.mock('../emailService', () => ({
  sendEmail: jest.fn().mockResolvedValue(true)
}));

// Mock timers
jest.useFakeTimers();
jest.advanceTimersByTime(1000);

// Mock fetch
global.fetch = jest.fn(() =>
  Promise.resolve({
    json: () => Promise.resolve({ data: 'mocked' })
  })
);
```

## PHP Laravel Patterns

### Basic Test Structure (PHPUnit)
```php
class UserServiceTest extends TestCase
{
    private UserService $userService;
    private MockInterface $mockRepository;
    
    protected function setUp(): void
    {
        parent::setUp();
        
        $this->mockRepository = $this->mock(UserRepository::class);
        $this->userService = new UserService($this->mockRepository);
    }
    
    /** @test */
    public function it_creates_user_with_hashed_password()
    {
        // Arrange
        $userData = ['email' => 'test@example.com', 'password' => 'password123'];
        $this->mockRepository
            ->shouldReceive('create')
            ->once()
            ->andReturn(new User($userData));
        
        // Act
        $result = $this->userService->createUser($userData);
        
        // Assert
        $this->assertInstanceOf(User::class, $result);
        $this->assertTrue(Hash::check('password123', $result->password));
    }
}
```

### Laravel-Specific Patterns
```php
// Testing without hitting database
use Illuminate\Foundation\Testing\WithoutMiddleware;
use Illuminate\Foundation\Testing\DatabaseTransactions;

class ProductControllerTest extends TestCase
{
    use WithoutMiddleware;
    use DatabaseTransactions; // Rollback after each test
    
    /** @test */
    public function it_returns_paginated_products()
    {
        // Use factories for test data
        Product::factory()->count(25)->create();
        
        $response = $this->getJson('/api/products');
        
        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'price']
                ],
                'links',
                'meta'
            ])
            ->assertJsonCount(20, 'data'); // Default pagination
    }
}
```

## Testing Utilities

### Custom Assertions
```javascript
// JavaScript
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    return {
      pass,
      message: () =>
        `expected ${received} to be within range ${floor} - ${ceiling}`
    };
  }
});

// Usage
expect(result.score).toBeWithinRange(0, 100);
```

### Test Data Builders
```javascript
class UserBuilder {
  constructor() {
    this.user = {
      id: 1,
      email: 'default@example.com',
      name: 'Default User'
    };
  }
  
  withEmail(email) {
    this.user.email = email;
    return this;
  }
  
  withName(name) {
    this.user.name = name;
    return this;
  }
  
  build() {
    return { ...this.user };
  }
}

// Usage
const user = new UserBuilder()
  .withEmail('custom@example.com')
  .build();
```

## Common Pitfalls

1. **Testing Implementation Details**
   ```javascript
   // Bad - tests internal implementation
   expect(userService._hashPassword).toHaveBeenCalled();
   
   // Good - tests behavior
   expect(result.password).not.toBe(plainPassword);
   ```

2. **Not Resetting State**
   ```javascript
   // Always clean up
   afterEach(() => {
     jest.clearAllMocks();
     jest.restoreAllMocks();
   });
   ```

3. **Overmocking**
   ```javascript
   // Don't mock what you don't own
   // Mock the adapter, not the library
   ```

## Coverage Guidelines

- Aim for 80%+ coverage
- 100% coverage doesn't mean bug-free
- Focus on critical business logic
- Don't test:
  - Third-party libraries
  - Simple getters/setters
  - Framework code