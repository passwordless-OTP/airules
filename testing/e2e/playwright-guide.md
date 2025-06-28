# End-to-End Testing with Playwright

## Setup and Configuration

### Installation
```bash
# Install Playwright
npm init playwright@latest

# Install with specific browsers
npx playwright install chromium firefox webkit

# Install system dependencies
npx playwright install-deps
```

### Basic Configuration
```javascript
// playwright.config.js
module.exports = {
  testDir: './tests/e2e',
  timeout: 30000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'mobile',
      use: { ...devices['iPhone 12'] },
    },
  ],
  
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
};
```

## Persistent Authentication (CRITICAL FOR EFFICIENCY)

### Global Setup with Persistent Profiles
```javascript
// global-setup.js
import { chromium } from '@playwright/test';
import path from 'path';

async function globalSetup() {
  // Create persistent browser profile
  const userDataDir = path.join(__dirname, '.auth/user-data');
  const browser = await chromium.launchPersistentContext(userDataDir, {
    headless: false, // Set to true in CI
  });
  
  const page = await browser.newPage();
  
  // Check if already logged in
  await page.goto('/dashboard');
  
  if (page.url().includes('/login')) {
    // Perform login only if needed
    await page.goto('/login');
    await page.fill('input[name="email"]', process.env.TEST_USER_EMAIL);
    await page.fill('input[name="password"]', process.env.TEST_USER_PASSWORD);
    await page.click('button[type="submit"]');
    
    // Wait for successful login
    await page.waitForURL('/dashboard');
    
    // Save cookies and localStorage
    await page.context().storageState({ path: 'playwright/.auth/user.json' });
  }
  
  await browser.close();
}

export default globalSetup;
```

### Multiple User Profiles
```javascript
// auth.setup.js
import { test as setup } from '@playwright/test';

const users = [
  { role: 'admin', email: 'admin@example.com', file: 'admin.json' },
  { role: 'user', email: 'user@example.com', file: 'user.json' },
  { role: 'premium', email: 'premium@example.com', file: 'premium.json' }
];

for (const user of users) {
  setup(`authenticate as ${user.role}`, async ({ page }) => {
    const authFile = `playwright/.auth/${user.file}`;
    
    // Check if auth file exists and is recent (within 24 hours)
    const fs = require('fs');
    if (fs.existsSync(authFile)) {
      const stats = fs.statSync(authFile);
      const hoursSinceModified = (Date.now() - stats.mtime) / (1000 * 60 * 60);
      
      if (hoursSinceModified < 24) {
        console.log(`Using existing auth for ${user.role}`);
        return;
      }
    }
    
    // Perform fresh login
    await page.goto('/login');
    await page.fill('input[name="email"]', user.email);
    await page.fill('input[name="password"]', process.env[`${user.role.toUpperCase()}_PASSWORD`]);
    await page.click('button[type="submit"]');
    
    await page.waitForURL('/dashboard');
    await page.context().storageState({ path: authFile });
  });
}
```

### Using Persistent Auth in Tests
```javascript
// tests/admin-features.spec.js
import { test, expect } from '@playwright/test';

test.describe('Admin Features', () => {
  // Use admin auth for all tests in this file
  test.use({ storageState: 'playwright/.auth/admin.json' });
  
  test.beforeEach(async ({ page }) => {
    // Verify we're still logged in
    await page.goto('/dashboard');
    const isLoggedIn = await page.locator('[data-testid="user-menu"]').isVisible();
    
    if (!isLoggedIn) {
      throw new Error('Authentication expired - run auth setup again');
    }
  });
  
  test('can access admin panel', async ({ page }) => {
    await page.goto('/admin');
    await expect(page).toHaveURL('/admin');
    await expect(page.locator('h1')).toContainText('Admin Dashboard');
  });
});
```

## Page Object Model Pattern

### Base Page Object
```javascript
// pages/BasePage.js
export class BasePage {
  constructor(page) {
    this.page = page;
  }
  
  async navigate(path = '') {
    await this.page.goto(path);
  }
  
  async waitForLoadComplete() {
    await this.page.waitForLoadState('networkidle');
  }
  
  async takeScreenshot(name) {
    await this.page.screenshot({ 
      path: `screenshots/${name}.png`,
      fullPage: true 
    });
  }
  
  async fillForm(selectors) {
    for (const [selector, value] of Object.entries(selectors)) {
      await this.page.fill(selector, value);
    }
  }
}
```

### Specific Page Objects
```javascript
// pages/LoginPage.js
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  constructor(page) {
    super(page);
    this.emailInput = page.locator('input[name="email"]');
    this.passwordInput = page.locator('input[name="password"]');
    this.submitButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator('.error-message');
  }
  
  async login(email, password) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
  
  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }
}

// pages/DashboardPage.js
export class DashboardPage extends BasePage {
  constructor(page) {
    super(page);
    this.welcomeMessage = page.locator('h1');
    this.logoutButton = page.locator('button:has-text("Logout")');
    this.userMenu = page.locator('[data-testid="user-menu"]');
  }
  
  async isLoggedIn() {
    await this.page.waitForSelector('[data-testid="user-menu"]');
    return await this.userMenu.isVisible();
  }
  
  async logout() {
    await this.userMenu.click();
    await this.logoutButton.click();
  }
}
```

## Test Structure

### Basic Test Example
```javascript
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';

test.describe('Authentication Flow', () => {
  let loginPage;
  let dashboardPage;
  
  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.navigate('/login');
  });
  
  test('successful login redirects to dashboard', async ({ page }) => {
    // Act
    await loginPage.login('user@example.com', 'password123');
    
    // Assert
    await expect(page).toHaveURL('/dashboard');
    await expect(dashboardPage.welcomeMessage).toContainText('Welcome');
    expect(await dashboardPage.isLoggedIn()).toBeTruthy();
  });
  
  test('invalid credentials show error message', async () => {
    // Act
    await loginPage.login('invalid@example.com', 'wrongpassword');
    
    // Assert
    const error = await loginPage.getErrorMessage();
    expect(error).toBe('Invalid email or password');
    await expect(loginPage.errorMessage).toBeVisible();
  });
});
```

### Advanced Interactions
```javascript
test('shopping cart workflow', async ({ page }) => {
  const productPage = new ProductPage(page);
  const cartPage = new CartPage(page);
  
  // Add multiple products
  await productPage.navigate('/products');
  await productPage.addToCart('Product 1');
  await productPage.addToCart('Product 2');
  
  // Verify cart badge
  await expect(productPage.cartBadge).toHaveText('2');
  
  // Go to cart
  await productPage.goToCart();
  
  // Verify items
  const items = await cartPage.getCartItems();
  expect(items).toHaveLength(2);
  
  // Update quantity
  await cartPage.updateQuantity('Product 1', 3);
  
  // Verify total
  await expect(cartPage.totalPrice).toHaveText('$150.00');
  
  // Proceed to checkout
  await cartPage.proceedToCheckout();
  await expect(page).toHaveURL('/checkout');
});
```

## API Mocking

### Intercepting Requests
```javascript
test('handles API errors gracefully', async ({ page }) => {
  // Mock API failure
  await page.route('**/api/products', route => {
    route.fulfill({
      status: 500,
      body: JSON.stringify({ error: 'Server error' })
    });
  });
  
  await page.goto('/products');
  
  // Verify error handling
  await expect(page.locator('.error-banner')).toContainText('Unable to load products');
  await expect(page.locator('.retry-button')).toBeVisible();
});

test('displays loading state', async ({ page }) => {
  // Delay API response
  await page.route('**/api/products', async route => {
    await new Promise(resolve => setTimeout(resolve, 2000));
    await route.continue();
  });
  
  await page.goto('/products');
  
  // Verify loading state appears
  await expect(page.locator('.spinner')).toBeVisible();
  
  // Wait for content
  await expect(page.locator('.product-grid')).toBeVisible();
  await expect(page.locator('.spinner')).not.toBeVisible();
});
```

## Session Management Best Practices

### Refresh Auth Tokens
```javascript
// helpers/auth.js
export async function ensureAuthenticated(page) {
  // Check if token is expired
  const token = await page.evaluate(() => localStorage.getItem('authToken'));
  
  if (!token || isTokenExpired(token)) {
    // Refresh token
    const response = await page.request.post('/api/auth/refresh', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (response.ok()) {
      const { newToken } = await response.json();
      await page.evaluate((token) => {
        localStorage.setItem('authToken', token);
      }, newToken);
    } else {
      // Re-login if refresh fails
      throw new Error('Session expired - please run auth setup');
    }
  }
}

// Use in tests
test.beforeEach(async ({ page }) => {
  await ensureAuthenticated(page);
});
```

### Cookie Management
```javascript
// Save cookies after login
const cookies = await page.context().cookies();
await fs.writeFile('cookies.json', JSON.stringify(cookies));

// Restore cookies in new context
const cookies = JSON.parse(await fs.readFile('cookies.json'));
await context.addCookies(cookies);
```

## Visual Testing

### Screenshot Comparisons
```javascript
test('visual regression - homepage', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  
  // Hide dynamic content
  await page.evaluate(() => {
    document.querySelectorAll('.timestamp').forEach(el => {
      el.textContent = '2024-01-01';
    });
  });
  
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    animations: 'disabled',
    mask: [page.locator('.dynamic-banner')],
  });
});
```

## Mobile Testing

```javascript
test.describe('Mobile Experience', () => {
  test.use({ ...devices['iPhone 12'] });
  
  test('mobile navigation works', async ({ page }) => {
    await page.goto('/');
    
    // Open mobile menu
    await page.click('[data-testid="mobile-menu-toggle"]');
    
    // Verify menu is visible
    await expect(page.locator('.mobile-menu')).toBeVisible();
    
    // Navigate via mobile menu
    await page.click('.mobile-menu a:has-text("Products")');
    await expect(page).toHaveURL('/products');
    
    // Verify mobile layout
    const viewport = page.viewportSize();
    expect(viewport.width).toBeLessThan(768);
  });
});
```

## Debugging Tips

### Debug Mode
```bash
# Run in debug mode
npx playwright test --debug

# Run specific test in headed mode
npx playwright test test-file.spec.js --headed

# Preserve browser on failure
npx playwright test --headed --no-exit
```

### Using Playwright Inspector
```javascript
test('debug example', async ({ page }) => {
  // Pause execution
  await page.pause();
  
  // Or use inspector
  await page.goto('/');
  
  // Record actions in browser
  await page.click('text=Get Started');
});
```

## CI/CD Integration

### GitHub Actions with Caching
```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      
      - name: Cache Playwright browsers
        uses: actions/cache@v3
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
          
      - name: Cache auth state
        uses: actions/cache@v3
        with:
          path: playwright/.auth
          key: playwright-auth-${{ github.sha }}
          restore-keys: |
            playwright-auth-
      
      - name: Install dependencies
        run: npm ci
        
      - name: Install Playwright
        run: npx playwright install --with-deps
        
      - name: Setup auth
        run: npm run test:auth:setup
        env:
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
        
      - name: Run tests
        run: npm run test:e2e
        
      - name: Upload artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: |
            playwright-report/
            test-results/
```

## Best Practices

1. **Use Data Attributes**
   ```html
   <button data-testid="submit-order">Submit Order</button>
   ```

2. **Wait for Specific Conditions**
   ```javascript
   // Don't use arbitrary waits
   // await page.waitForTimeout(5000); ❌
   
   // Wait for specific elements/states
   await page.waitForSelector('.loading', { state: 'hidden' });
   await page.waitForResponse(resp => resp.url().includes('/api/data'));
   ```

3. **Handle Flaky Tests**
   ```javascript
   test.describe.configure({ retries: 2 });
   
   // Or use test.step for better reporting
   await test.step('Submit form', async () => {
     await page.click('button[type="submit"]');
   });
   ```

4. **Persistent Profile Management**
   ```javascript
   // Clean up old profiles periodically
   const profileAge = Date.now() - fs.statSync(authFile).mtime;
   if (profileAge > 7 * 24 * 60 * 60 * 1000) { // 7 days
     fs.unlinkSync(authFile);
   }
   ```