# Project Requirements Document (PRD): BlissFruitz

## 1. Project Overview
**BlissFruitz** is a premium fresh fruits e-commerce ecosystem designed to provide a seamless "farm-to-table" experience. The project consists of a multi-platform mobile application (Flutter) for customers, a vendor management system, a delivery tracking interface, and a comprehensive administrative dashboard.

### 1.1 Mission
To deliver the freshest fruits to customers while empowering local vendors with modern digital tools for inventory and order management.

---

## 2. Product Ecosystem
The BlissFruitz ecosystem is composed of several key components:

### 2.1 BlissFruitz Customer App (Flutter)
- **Status**: Primary Mobile Application
- **Key Features**:
  - Fruit selection and category browsing.
  - Subscription models for regular fruit delivery.
  - Real-time order tracking.
  - Secure payments via Razorpay.
  - Multi-location support (Geolocator/Google Maps).

### 2.2 Online Market Monorepo
- **Backend**: Node.js/TypeScript server handling authentication, business logic, and real-time updates via Socket.io.
- **Admin Panel**: Web-based dashboard for global oversight and analytics.
- **Vendor App**: Specialized interface for sellers to manage products and orders.
- **Delivery App**: Interface for delivery partners to manage routes and status updates.

---

## 3. Technical Stack
- **Mobile**: Flutter (Dart) with Riverpod for state management and GoRouter for navigation.
- **Backend**: Node.js, Express, TypeScript.
- **Real-time**: Socket.io for live order tracking and notifications.
- **Database**: Supabase (PostgreSQL) and Firebase (Messaging/Auth).
- **Payments**: Razorpay integration.
- **Infrastructure**: Railway (Deployment), GitHub Actions (CI/CD).

---

## 4. Full Project Tree Structure

### 4.1 BlissFruitz (Flutter Mobile App)
```text
blissfruitz/
├── android/                # Android native configuration
├── ios/                    # iOS native configuration
├── lib/                    # Flutter source code
│   ├── config/             # App configuration and constants
│   ├── models/             # Data models (Product, User, Order)
│   ├── providers/          # Riverpod state management
│   ├── screens/            # UI Screens (Home, Cart, Profile, etc.)
│   ├── services/           # API and Supabase service wrappers
│   ├── utils/              # Helper functions and extensions
│   ├── widgets/            # Reusable UI components
│   ├── app.dart            # Main application widget
│   └── main.dart           # Application entry point
├── assets/                 # Images, fonts, and config files
├── test/                   # Unit and widget tests
├── design_ref/             # UI/UX design mockups and screenshots
└── pubspec.yaml            # Project dependencies
```

### 4.2 Online Market (Monorepo - Backend & Web)
```text
online-market/
├── admin-panel/            # Admin dashboard (Next.js/React)
├── backend/                # Node.js TypeScript Server
│   ├── src/
│   │   ├── middleware/     # Auth, logging, and error handling
│   │   ├── routes/         # Express API routes
│   │   ├── services/       # Business logic (Order, User, Vendor)
│   │   ├── socket/         # Socket.io real-time handlers
│   │   ├── utils/          # Shared utilities
│   │   └── server.ts       # Server entry point
│   └── package.json
├── customer-app/           # Legacy/Alternative React Native App
├── delivery-app/           # Delivery partner interface
├── vendor-app/             # Vendor management interface
├── shared/                 # Shared types and logic across apps
└── package.json            # Monorepo configuration
```

---

## 5. Core Functionalities

### 5.1 User Roles & Permissions
- **Customer**: Browse, Order, Pay, Rate.
- **Vendor**: Manage Stock, Process Orders, View Earnings.
- **Delivery**: Accept Task, Update Status (Picked/Delivered), Navigate.
- **Admin**: User Management, Analytics, Conflict Resolution, System Config.

### 5.2 Key Workflows
1. **Ordering**: Customer picks fruit -> Payment -> Vendor notified.
2. **Fulfillment**: Vendor packs -> Assigns to Delivery -> Delivery picks up.
3. **Tracking**: Customer sees real-time location update via Socket.io.
4. **Completion**: Delivery confirmed -> Payment released to Vendor.

---

## 6. Milestones & Future Roadmap
- [x] Backend Infrastructure Setup (Supabase + Node.js)
- [x] Customer App UI/UX Design
- [ ] Vendor Registration Flow Optimization (In Progress)
- [ ] Real-time Tracking Integration
- [ ] Analytics Dashboard Implementation
- [ ] Multi-region Expansion
