# Gadget.dev - Coding Rules for Claude Code

This file provides specific guidance for Claude Code when working with Gadget.dev applications.

## Gadget.dev Overview

Gadget is a full-stack development platform that handles infrastructure, databases, and APIs automatically. When working with Gadget apps, remember:
- No direct database access - use Gadget's model APIs
- No manual migrations - Gadget handles schema changes
- Built-in authentication and permissions
- Automatic GraphQL and REST APIs
- Serverless backend with auto-scaling

## Key Commands

### Development
```bash
# Install Gadget CLI
npm install -g @gadget-client/cli

# Login to Gadget
gadget login

# Pull latest changes
gadget pull

# Push local changes
gadget push

# Open app in browser
gadget open

# View logs
gadget logs
```

## Architecture Patterns

### Directory Structure
```
api/
├── models/         # Data models and actions
│   ├── user/
│   │   ├── schema.gadget.ts
│   │   └── actions/
│   │       ├── create.js
│   │       ├── update.js
│   │       └── delete.js
│   └── product/
├── routes/         # HTTP routes
├── auth/           # Authentication config
└── jobs/           # Background jobs

frontend/
├── components/     # React components
├── hooks/          # Custom React hooks
├── pages/          # Route pages
└── api.ts          # Generated API client
```

### Model Definition Patterns

```javascript
// api/models/product/schema.gadget.ts
export const schema = {
  fields: {
    title: {
      type: "string",
      required: true,
      validations: {
        length: { max: 255 }
      }
    },
    price: {
      type: "number",
      validations: {
        numberRange: { min: 0 }
      }
    },
    shop: {
      type: "belongsTo",
      model: "shopifyShop"
    }
  }
};
```

### Action Patterns

#### 1. Model Actions
```javascript
// api/models/product/actions/create.js
export async function run({ params, record, logger, api }) {
  // Validations
  if (!params.product.title) {
    throw new Error("Title is required");
  }
  
  // Set computed fields
  record.slug = params.product.title
    .toLowerCase()
    .replace(/\s+/g, '-');
  
  // Save record (Gadget handles the database)
  await record.save();
  
  // Trigger side effects
  await api.internal.email.send({
    to: record.shop.owner.email,
    template: "new-product",
    data: { product: record }
  });
}

export const options = {
  actionType: "create",
  triggers: {
    api: true,
    webhook: true
  }
};
```

#### 2. Global Actions
```javascript
// api/actions/syncInventory.js
export async function run({ params, logger, api, connections }) {
  const shop = await api.shopifyShop.findOne(params.shopId);
  
  // Use Gadget's built-in Shopify connection
  const products = await connections.shopify.product.list({
    shop: shop.domain
  });
  
  // Bulk operations
  await api.product.bulkCreate(
    products.map(p => ({
      shopifyId: p.id,
      title: p.title,
      shop: { _link: shop.id }
    }))
  );
}

export const options = {
  triggers: {
    api: true,
    scheduler: "0 */6 * * *" // Every 6 hours
  }
};
```

### Frontend Patterns

#### 1. Using the Generated API Client
```javascript
// frontend/components/ProductList.jsx
import { useFindMany } from "@gadgetinc/react";
import { api } from "../api";

export function ProductList() {
  const [{ data, loading, error }] = useFindMany(api.product, {
    select: {
      id: true,
      title: true,
      price: true,
      shop: {
        id: true,
        domain: true
      }
    },
    filter: {
      published: { equals: true }
    },
    sort: { createdAt: "desc" },
    first: 20
  });
  
  if (loading) return <Spinner />;
  if (error) return <Error error={error} />;
  
  return (
    <div>
      {data.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

#### 2. Mutations
```javascript
// frontend/components/ProductForm.jsx
import { useAction } from "@gadgetinc/react";
import { api } from "../api";

export function ProductForm() {
  const [{ loading, error }, createProduct] = useAction(api.product.create);
  
  const handleSubmit = async (formData) => {
    const result = await createProduct({
      product: {
        title: formData.title,
        price: formData.price,
        shop: { _link: shopId }
      }
    });
    
    if (result.success) {
      router.push(`/products/${result.data.id}`);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
    </form>
  );
}
```

### Authentication & Permissions

#### 1. Access Control
```javascript
// api/models/product/accessControl.gadget.ts
export const accessControl = {
  read: {
    filter: ({ session }) => {
      // Users can only see their shop's products
      return {
        shop: { equals: session?.shopId }
      };
    }
  },
  create: {
    check: ({ session }) => {
      // Only authenticated users can create
      return session?.userId != null;
    }
  }
};
```

#### 2. Frontend Auth
```javascript
// frontend/components/AuthGuard.jsx
import { useUser } from "@gadgetinc/react";
import { api } from "../api";

export function AuthGuard({ children }) {
  const [{ data: user, loading }] = useUser(api);
  
  if (loading) return <Loading />;
  if (!user) return <Redirect to="/login" />;
  
  return children;
}
```

### Background Jobs

```javascript
// api/jobs/cleanupOldRecords.js
export async function run({ api, logger }) {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const deleted = await api.internal.tempData.deleteMany({
    filter: {
      createdAt: { lessThan: thirtyDaysAgo }
    }
  });
  
  logger.info(`Deleted ${deleted.count} old records`);
}

export const options = {
  schedule: {
    cron: "0 0 * * *" // Daily at midnight
  },
  retries: 3
};
```

### Shopify Integration

```javascript
// Gadget automatically syncs Shopify webhooks
// api/models/shopifyProduct/actions/sync.js
export async function onSuccess({ record, api }) {
  // Create or update local product record
  await api.internal.product.upsert({
    shopifyId: record.id,
    title: record.title,
    shop: { _link: record.shop.id }
  });
}

// Frontend Shopify components
import { Provider } from "@gadgetinc/react-shopify-app-bridge";

export function App() {
  return (
    <Provider api={api}>
      <AuthenticatedApp />
    </Provider>
  );
}
```

### Testing Patterns

```javascript
// test/api/models/product.test.js
import { api } from "@gadget-client/my-app";

describe("Product model", () => {
  it("should create a product", async () => {
    const result = await api.product.create({
      product: {
        title: "Test Product",
        price: 99.99
      }
    });
    
    expect(result.success).toBe(true);
    expect(result.data.title).toBe("Test Product");
  });
});
```

### Performance Best Practices

1. **Use Select to Limit Fields**
   ```javascript
   const products = await api.product.findMany({
     select: {
       id: true,
       title: true,
       // Don't select large fields unless needed
     }
   });
   ```

2. **Batch Operations**
   ```javascript
   // Use bulkCreate/bulkUpdate for multiple records
   await api.product.bulkCreate(products);
   ```

3. **Pagination**
   ```javascript
   const { data, hasNextPage, endCursor } = await api.product.findMany({
     first: 50,
     after: cursor
   });
   ```

### Common Patterns

1. **File Uploads**
   ```javascript
   // Models automatically handle file storage
   const result = await api.document.create({
     document: {
       name: "Report",
       file: {
         base64: fileData,
         fileName: "report.pdf"
       }
     }
   });
   ```

2. **Computed Fields**
   ```javascript
   // api/models/order/actions/create.js
   export async function run({ params, record }) {
     record.total = params.order.items.reduce(
       (sum, item) => sum + (item.price * item.quantity), 
       0
     );
   }
   ```

3. **Email Sending**
   ```javascript
   await api.internal.email.send({
     to: user.email,
     subject: "Welcome!",
     html: template
   });
   ```

### Debugging

```javascript
// Use logger in actions
export async function run({ logger, params }) {
  logger.info("Processing order", { orderId: params.id });
  
  try {
    // ... action logic
  } catch (error) {
    logger.error("Order processing failed", { error });
    throw error;
  }
}

// View logs
// gadget logs --tail
```

### Common Pitfalls to Avoid

1. **Don't try to access the database directly**
2. **Don't modify schema files manually - use the Gadget editor**
3. **Always use the generated API client**
4. **Don't store sensitive data in frontend code**
5. **Use Gadget's built-in auth instead of custom solutions**
6. **Leverage Gadget's automatic API generation**
7. **Use internal APIs for server-side only operations**