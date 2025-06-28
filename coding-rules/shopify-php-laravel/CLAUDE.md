# Shopify PHP Laravel MySQL - Coding Rules for Claude Code

This file provides specific guidance for Claude Code when working with Shopify apps built with PHP Laravel and MySQL.

## Project Setup & Commands

### Initial Setup
```bash
# Install dependencies
composer install
npm install

# Setup environment
cp .env.example .env
php artisan key:generate

# Database setup
php artisan migrate
php artisan db:seed

# Shopify app setup
php artisan shopify:install
```

### Development Commands
```bash
# Start development server
php artisan serve
npm run dev

# Run tests
php artisan test
php artisan test --parallel

# Code quality checks
./vendor/bin/phpstan analyse
./vendor/bin/pint --test
php artisan insights

# Database operations
php artisan migrate:fresh --seed
php artisan tinker
```

## Architecture Guidelines

### Directory Structure
```
app/
├── Http/
│   ├── Controllers/
│   │   ├── Api/           # API endpoints
│   │   └── Shopify/       # Shopify-specific controllers
│   └── Middleware/
│       └── VerifyWebhook.php
├── Models/
│   ├── Shop.php           # Shopify shop model
│   └── Product.php        # Local product cache
├── Services/
│   ├── Shopify/           # Shopify API services
│   └── Webhook/           # Webhook handlers
└── Jobs/
    └── Shopify/           # Background jobs
```

### Shopify Integration Patterns

#### 1. Authentication Flow
```php
// Always use the Shopify package's built-in auth
use Osiset\ShopifyApp\Http\Controllers\AuthController;

// Custom auth checks
if (!auth()->user()->shopify_active) {
    return redirect()->route('shopify.auth');
}
```

#### 2. API Rate Limiting
```php
// Use Laravel's built-in rate limiting with Shopify's limits
use Illuminate\Support\Facades\RateLimiter;

RateLimiter::for('shopify-api', function ($request) {
    return Limit::perSecond(2)->by($request->user()->id);
});
```

#### 3. Webhook Handling
```php
// Always verify webhooks
class ProductUpdateJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;
    
    public function handle()
    {
        // Process webhook data
        // Always use transactions for data consistency
        DB::transaction(function () {
            // Update logic
        });
    }
}
```

### Database Patterns

#### 1. Migrations
```php
// Always include proper indexes for Shopify IDs
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('shopify_id')->index();
    $table->unsignedBigInteger('shop_id');
    $table->json('data'); // Store Shopify API response
    $table->timestamps();
    
    $table->foreign('shop_id')->references('id')->on('shops');
    $table->unique(['shopify_id', 'shop_id']);
});
```

#### 2. Model Relationships
```php
// Shop.php
public function products()
{
    return $this->hasMany(Product::class);
}

// Always use eager loading to prevent N+1
$shops = Shop::with(['products', 'settings'])->get();
```

### API Design Patterns

#### 1. Resource Controllers
```php
// Use API resources for consistent responses
class ProductController extends Controller
{
    public function index(Request $request)
    {
        $products = $request->user()
            ->shop
            ->products()
            ->paginate(20);
            
        return ProductResource::collection($products);
    }
}
```

#### 2. Error Handling
```php
// Consistent error responses
try {
    $response = $shop->api()->rest('GET', '/admin/api/2024-01/products.json');
} catch (ApiException $e) {
    Log::error('Shopify API Error', [
        'shop' => $shop->domain,
        'error' => $e->getMessage()
    ]);
    
    return response()->json([
        'error' => 'Unable to fetch products',
        'message' => 'Please try again later'
    ], 503);
}
```

### Security Best Practices

1. **Environment Variables**
   ```php
   // Never hardcode Shopify credentials
   SHOPIFY_APP_NAME=
   SHOPIFY_API_KEY=
   SHOPIFY_API_SECRET=
   SHOPIFY_API_SCOPES=
   ```

2. **Webhook Verification**
   ```php
   // Always verify webhook signatures
   public function handle(Request $request)
   {
       $verified = $this->verifyWebhook(
           $request->getContent(),
           $request->header('X-Shopify-Hmac-Sha256')
       );
       
       if (!$verified) {
           abort(401);
       }
   }
   ```

3. **Session Security**
   ```php
   // Use database sessions for multi-server setups
   SESSION_DRIVER=database
   SESSION_SECURE_COOKIE=true
   ```

### Testing Guidelines

#### 1. Feature Tests
```php
class ShopifyAuthTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_shop_can_install_app()
    {
        $response = $this->get('/auth?shop=test-shop.myshopify.com');
        
        $response->assertRedirect();
        $this->assertStringContains('oauth/authorize', $response->headers->get('Location'));
    }
}
```

#### 2. Mocking Shopify API
```php
// Use Laravel's Http::fake() for API mocking
Http::fake([
    'test-shop.myshopify.com/admin/api/*/products.json' => Http::response([
        'products' => [
            ['id' => 1, 'title' => 'Test Product']
        ]
    ], 200)
]);
```

### Performance Optimization

1. **Caching Strategy**
   ```php
   // Cache Shopify API responses
   $products = Cache::remember("shop.{$shopId}.products", 3600, function () use ($shop) {
       return $shop->api()->rest('GET', '/admin/api/2024-01/products.json');
   });
   ```

2. **Queue Configuration**
   ```php
   // Use Redis for queue management
   QUEUE_CONNECTION=redis
   
   // Separate queues for different priorities
   php artisan queue:work --queue=webhooks,default
   ```

3. **Database Optimization**
   ```php
   // Use chunking for large datasets
   Shop::chunk(100, function ($shops) {
       foreach ($shops as $shop) {
           ProcessShopJob::dispatch($shop);
       }
   });
   ```

### Common Pitfalls to Avoid

1. **Don't store sensitive data in logs**
2. **Always paginate Shopify API requests**
3. **Handle Shopify's 429 rate limit responses**
4. **Use background jobs for heavy operations**
5. **Implement proper webhook replay protection**
6. **Always use HTTPS in production**
7. **Validate shop domains against Shopify's format**

### Debugging Tools

```bash
# Telescope for local debugging
php artisan telescope:install

# Debug Shopify API calls
\Log::channel('shopify')->info('API Call', [
    'endpoint' => $endpoint,
    'response' => $response
]);

# Use Laravel Debugbar in development
composer require barryvdh/laravel-debugbar --dev
```

## Cloudways Deployment

### Deployment Commands
```bash
# Access server via SSH
ssh [username]@[server-ip] -p [port]

# Navigate to application
cd applications/[app-name]/public_html

# Pull latest changes
git pull origin main

# Run deployment tasks
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan migrate --force
php artisan queue:restart

# Clear Cloudways cache
php artisan cloudways:cache:clear
```

### Cloudways-Specific Configuration

1. **Environment Setup**
   ```bash
   # Use Cloudways environment variables
   DB_CONNECTION=mysql
   DB_HOST=localhost
   DB_PORT=3306
   DB_DATABASE=[cloudways_db_name]
   DB_USERNAME=[cloudways_db_user]
   DB_PASSWORD=[cloudways_db_pass]
   
   # Redis configuration
   REDIS_HOST=localhost
   REDIS_PASSWORD=null
   REDIS_PORT=6379
   
   # Use Cloudways SMTP
   MAIL_MAILER=smtp
   MAIL_HOST=[cloudways_smtp_host]
   MAIL_PORT=587
   ```

2. **Supervisor Configuration for Queues**
   ```ini
   # /etc/supervisor/conf.d/laravel-worker.conf
   [program:laravel-worker]
   process_name=%(program_name)s_%(process_num)02d
   command=php /home/[app]/applications/[app-name]/public_html/artisan queue:work --sleep=3 --tries=3
   autostart=true
   autorestart=true
   user=[username]
   numprocs=8
   redirect_stderr=true
   stdout_logfile=/home/[app]/applications/[app-name]/public_html/storage/logs/worker.log
   ```

3. **Cron Jobs**
   ```bash
   # Add to Cloudways cron job manager
   * * * * * cd /home/[app]/applications/[app-name]/public_html && php artisan schedule:run >> /dev/null 2>&1
   ```

### Performance Optimization for Cloudways

1. **Varnish Cache**
   ```php
   // Clear Varnish cache after deployments
   Route::get('/deploy/cache-clear', function () {
       if (request()->header('X-Deploy-Token') !== env('DEPLOY_TOKEN')) {
           abort(403);
       }
       
       Artisan::call('cache:clear');
       // Cloudways Varnish purge endpoint
       Http::post('http://localhost:8080/purge-all');
       
       return 'Cache cleared';
   });
   ```

2. **Object Cache with Redis**
   ```php
   // config/cache.php
   'default' => env('CACHE_DRIVER', 'redis'),
   
   // Use Redis for sessions
   SESSION_DRIVER=redis
   ```

3. **CDN Integration**
   ```php
   // config/app.php
   'asset_url' => env('CLOUDWAYS_CDN_URL', null),
   ```

### Monitoring & Logs

```bash
# View application logs
tail -f /home/[app]/applications/[app-name]/public_html/storage/logs/laravel.log

# View server logs
tail -f /var/log/nginx/[app-name]-access.log
tail -f /var/log/nginx/[app-name]-error.log

# Monitor PHP-FPM
sudo service php7.4-fpm status

# Check MySQL slow queries
tail -f /var/log/mysql/mysql-slow.log
```