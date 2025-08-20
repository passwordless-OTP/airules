# Securify Design System Documentation

**Version:** 1.0  
**Date:** August 20, 2025  
**Framework:** Shopify Polaris + Custom Securify Branding  
**Live Demo:** https://passwordless-otp.github.io/airules/frontend/smart-geofencing-demo.html

---

## 🎨 Brand Colors

### Primary Brand Colors
```css
/* Securify Purple - Primary Brand Color */
--securify-purple: #7c3aed;
--securify-purple-hover: #6d28d9;
--securify-purple-light: #a855f7;

/* Securify Yellow - Secondary Brand Color */
--securify-yellow: #fbbf24;
--securify-yellow-hover: #f59e0b;
--securify-yellow-light: #fde68a;
```

**Usage Guidelines:**
- **Purple**: Primary branding, headers, main CTAs, brand emphasis
- **Yellow**: Secondary actions, highlights, accents, badges
- **Light variants**: Backgrounds, subtle highlights, disabled states

### Shopify Polaris Integration
```css
/* Polaris Primary - For Shopify-native actions */
--polaris-primary: #008060;
--polaris-primary-hover: #006847;
```

**Usage Guidelines:**
- **Polaris Teal**: Primary actions, save buttons, confirmation actions
- **Why**: Maintains Shopify ecosystem familiarity and "Built for Shopify" compliance

### Status & Semantic Colors
```css
/* Success States */
--success-bg: #d1f7c4;
--success-text: #365314;
--success-border: #22c55e;

/* Critical/Error States */
--critical-bg: #fed7d7;
--critical-text: #b91c1c;
--critical-border: #ef4444;

/* Warning States */
--warning-bg: #fef3c7;
--warning-text: #92400e;
--warning-border: #f59e0b;

/* Info/Neutral */
--neutral-bg: #f6f6f7;
--neutral-text: #6d7175;
--neutral-border: #e1e3e5;
```

---

## 📝 Typography System

### Font Stack
```css
font-family: -apple-system, BlinkMacSystemFont, San Francisco, Segoe UI, Roboto, Helvetica Neue, sans-serif;
```

**Rationale**: Native system fonts for optimal performance and OS integration

### Typography Scale
```css
/* CSS Variables */
--font-size-xs: 12px;    /* Small labels, badges, timestamps */
--font-size-sm: 13px;    /* Subtitles, secondary text, captions */
--font-size-base: 14px;  /* Body text, buttons, form inputs */
--font-size-md: 16px;    /* Card titles, descriptions, prominent text */
--font-size-lg: 18px;    /* Section headings, card headers */
--font-size-xl: 20px;    /* Stage headings, page sections */
--font-size-2xl: 24px;   /* Callout titles, modal headers */
--font-size-3xl: 32px;   /* Main page titles, hero text */
--font-size-4xl: 36px;   /* Metrics, counters, emphasis numbers */
```

### Utility Classes
```css
.text-xs { font-size: var(--font-size-xs); line-height: 1.4; font-weight: 500; }
.text-sm { font-size: var(--font-size-sm); line-height: 1.5; font-weight: 400; }
.text-base { font-size: var(--font-size-base); line-height: 1.5; font-weight: 400; }
.text-md { font-size: var(--font-size-md); line-height: 1.5; font-weight: 500; }
.text-lg { font-size: var(--font-size-lg); line-height: 1.4; font-weight: 500; }
.text-xl { font-size: var(--font-size-xl); line-height: 1.4; font-weight: 600; }
.text-2xl { font-size: var(--font-size-2xl); line-height: 1.3; font-weight: 600; }
.text-3xl { font-size: var(--font-size-3xl); line-height: 1.2; font-weight: 600; }
.text-4xl { font-size: var(--font-size-4xl); line-height: 1.1; font-weight: 700; }
```

### Usage Guidelines
- **xs/sm**: Supporting information, metadata
- **base/md**: Primary content, readable text  
- **lg/xl**: Hierarchy markers, section organization
- **2xl+**: Attention-grabbing, metrics display

---

## 🧩 Component Patterns

### Buttons
```css
/* Primary Button (Polaris) */
.button {
    background-color: var(--polaris-primary);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 50px;
    font-size: var(--font-size-base);
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.button:hover {
    background-color: var(--polaris-primary-hover);
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 128, 96, 0.2);
}

/* Secondary Button (Securify Yellow) */
.button-secondary {
    background-color: var(--securify-yellow);
    color: #1f2937;
    /* ... same structure as primary */
}

/* Outline Button */
.button-outline {
    background-color: transparent;
    border: 1px solid var(--securify-yellow);
    color: var(--securify-yellow);
    /* ... rest of styling */
}
```

### Cards
```css
.card {
    background: white;
    border: 1px solid #e1e3e5;
    border-radius: 12px;
    margin-bottom: 20px;
    overflow: hidden;
    animation: slideInUp 0.6s ease-out;
}

.card-header {
    padding: 20px;
    border-bottom: 1px solid #e1e3e5;
}

.card-section {
    padding: 20px;
}

.card-title {
    font-size: var(--font-size-md);
    font-weight: 600;
    margin: 0 0 4px 0;
    color: #202223;
}
```

### Badges
```css
.badge {
    padding: 4px 8px;
    border-radius: 12px;
    font-size: var(--font-size-xs);
    font-weight: 500;
    text-transform: uppercase;
}

.badge-success {
    background-color: #d1f7c4;
    color: #365314;
}

.badge-critical {
    background-color: #fed7d7;
    color: #b91c1c;
}

.badge-warning {
    background-color: #fef3c7;
    color: #92400e;
}

.badge-recommended {
    background-color: var(--securify-yellow-light);
    color: #92400e;
}
```

### Callout Cards
```css
.callout-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 32px;
    border-radius: 12px;
    margin-bottom: 20px;
    text-align: center;
}

.callout-title {
    font-size: var(--font-size-2xl);
    font-weight: 600;
    margin-bottom: 12px;
}

.callout-description {
    font-size: var(--font-size-md);
    opacity: 0.9;
    margin-bottom: 24px;
    line-height: 1.5;
}
```

---

## 🚦 Color Coding Standards

### Geographic & Security Context
```css
/* Safe Countries (Customer Locations) */
.badge-success { /* Green - Safe to allow */ }

/* Threat Sources (Attack Origins) */
.badge-critical { /* Red - High risk, block immediately */ }
.badge-warning { /* Yellow - Medium risk, monitor */ }

/* System Status */
.test-success { /* Green background - System working */ }
.test-failure { /* Red background - System failed */ }
```

### Usage Examples
- **Green (Success)**: Countries with customers, successful tests, working features
- **Red (Critical)**: Attack sources, failed tests, broken functionality
- **Yellow (Warning)**: Medium-risk countries, needs attention items
- **Purple (Brand)**: Securify-specific features, brand emphasis
- **Teal (Action)**: Primary actions, Shopify-compliant buttons

---

## 📱 Responsive Design

### Breakpoints
```css
/* Mobile-first approach */
@media (max-width: 768px) {
    .two-column {
        grid-template-columns: 1fr;
    }
    
    .stage-indicator {
        flex-direction: column;
        text-align: center;
    }
    
    .progress-bar {
        margin: 12px 0;
    }
}
```

### Mobile Optimizations
- **Touch Targets**: Minimum 44px for interactive elements
- **Readable Text**: Minimum 16px font size for body text
- **Simplified Layouts**: Single column on mobile
- **Generous Padding**: 16px minimum for touch-friendly spacing

---

## ✨ Animations & Interactions

### Animation Principles
```css
/* Smooth transitions */
transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

/* Hover elevation */
transform: translateY(-2px);
box-shadow: 0 4px 12px rgba(0, 128, 96, 0.2);

/* Entrance animations */
@keyframes slideInUp {
    0% { 
        opacity: 0;
        transform: translateY(30px);
    }
    100% { 
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Accessibility
```css
/* Respect user motion preferences */
@media (prefers-reduced-motion: reduce) {
    * {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
    }
}
```

### Interactive States
- **Hover**: Elevation + color change + subtle scale
- **Focus**: Clear focus rings for keyboard navigation
- **Active**: Pressed state with slight scale reduction
- **Disabled**: Reduced opacity + no pointer events

---

## 🛠️ Shopify Polaris Requirements

### Required Dependencies
```json
{
  "@shopify/polaris": "^12.0.0",
  "@shopify/polaris-icons": "^7.0.0", 
  "@shopify/app-bridge": "^4.0.0",
  "@shopify/app-bridge-react": "^4.0.0"
}
```

### Component Usage
```jsx
import {
  Page,
  Card,
  Layout,
  Stack,
  TextContainer,
  DisplayText,
  Button,
  Badge,
  Banner,
  ProgressBar,
  ResourceList,
  Avatar,
  Icon
} from '@shopify/polaris';
```

### Polaris Compliance Checklist
- [ ] Use Polaris components as base layer
- [ ] Apply Securify brand colors as overlay
- [ ] Maintain Polaris spacing (4px grid system)
- [ ] Use Polaris typography scale where possible
- [ ] Follow Polaris accessibility guidelines
- [ ] Test on mobile devices for touch interactions

---

## 📊 Layout System

### Grid System
```css
/* Two-column layout */
.two-column {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-bottom: 20px;
}

/* Container */
.demo-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}
```

### Spacing Scale
- **4px**: Micro spacing (internal padding)
- **8px**: Small spacing (between related elements)
- **12px**: Medium spacing (component internal)
- **16px**: Default spacing (general padding)
- **20px**: Large spacing (between sections)
- **32px**: Extra large spacing (major sections)

---

## 🎯 Usage Examples

### Smart Geofencing Demo Implementation
The complete implementation can be seen in:
- **File**: `frontend/smart-geofencing-demo.html`
- **Live Demo**: https://passwordless-otp.github.io/airules/frontend/smart-geofencing-demo.html

### Key Features Implemented
1. **4-Stage User Journey**: Store analysis → Geography report → Recommendations → Testing
2. **Progressive Enhancement**: Works without JavaScript, enhanced with interactions
3. **Real-time Feedback**: Progress bars, status updates, threat counters
4. **Mobile Optimization**: Responsive design with touch-friendly interactions
5. **Accessibility**: Screen reader support, keyboard navigation, motion preferences

---

## 📋 Implementation Checklist for UI Designer

### Brand Consistency
- [ ] Use Securify purple for primary branding
- [ ] Use Securify yellow for secondary elements
- [ ] Apply Polaris teal for primary actions only
- [ ] Maintain color coding standards (green=safe, red=threat)

### Typography
- [ ] Use system font stack for performance
- [ ] Apply consistent font scale via CSS variables
- [ ] Use utility classes for standardized sizing
- [ ] Ensure minimum 16px for mobile body text

### Components
- [ ] Build on Polaris base components
- [ ] Apply Securify color overlays
- [ ] Use standardized border radius (12px cards, 50px buttons)
- [ ] Include hover states and transitions

### Responsive Design
- [ ] Mobile-first approach
- [ ] Test on iOS Safari and Chrome
- [ ] Ensure touch targets ≥44px
- [ ] Single-column mobile layouts

### Performance
- [ ] Use CSS variables for consistency
- [ ] Minimize custom CSS (leverage Polaris)
- [ ] Optimize for fast loading
- [ ] Test with slow connections

---

**Need Help?** Reference the complete implementation in `frontend/smart-geofencing-demo.html` or the live demo for visual examples of every component and interaction.