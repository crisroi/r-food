# 📱 R-Foods: University Food Delivery Platform
## Comprehensive Project Documentation

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [System Architecture](#system-architecture)
4. [User Roles & Flows](#user-roles--flows)
5. [Core Features](#core-features)
6. [Screen-by-Screen Guide](#screen-by-screen-guide)
7. [Database Schema](#database-schema)
8. [Security & Permissions](#security--permissions)
9. [Implementation Status](#implementation-status)
10. [Future Improvements](#future-improvements)
11. [Setup & Deployment](#setup--deployment)

---

## 1. Project Overview

### Vision
R-Foods is a university campus food delivery platform that connects students (customers), campus restaurants, and delivery partners in a seamless ecosystem. The platform enables students to order food from multiple restaurants in a single transaction, track their orders in real-time, and have meals delivered to their hostel or faculty location.

### Target Audience
- **Primary:** University students (customers)
- **Secondary:** Campus restaurant owners
- **Tertiary:** Student delivery partners earning income
- **Administrative:** Platform administrators

### Unique Selling Points
1. **Multi-Order System** - Order from multiple restaurants in one transaction (unique feature)
2. **Campus-Specific** - Delivery locations tailored to university geography
3. **Student Economy** - Empowers students to earn as delivery partners
4. **Category-by-Category Ordering** - Intuitive ordering process (Food → Drinks → Desserts)
5. **Pack System** - Eco-friendly packaging options with pricing

---

## 2. Tech Stack

### Frontend
- **Framework:** Flutter (Web & Mobile support)
- **State Management:** Riverpod (Provider pattern)
- **UI Components:** Material Design 3
- **Responsive Design:** LayoutBuilder, MediaQuery
- **Image Handling:** image_picker (web-compatible with XFile + Uint8List)

### Backend & Services
- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore (NoSQL, real-time)
- **File Storage:** Cloudinary (images: profile pictures, menu items, documents)
- **Cloud Functions:** (Planned for notifications)

### Development Tools
- **IDE:** VS Code / Android Studio
- **Version Control:** Git
- **Testing:** Flutter Test (planned)
- **Deployment:** Firebase Hosting (web), Play Store/App Store (mobile)

### Key Packages
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  image_picker: ^1.0.0
  intl: ^0.18.0
  http: ^1.1.0  # For Cloudinary uploads
```

---

## 3. System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APPLICATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Customer   │  │  Restaurant  │  │   Delivery   │      │
│  │     Flow     │  │     Flow     │  │  Partner Flow│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              RIVERPOD STATE MANAGEMENT                │   │
│  │  - Auth Providers  - Order Providers                  │   │
│  │  - Cart Providers  - Restaurant Providers             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼────────┐           ┌─────────▼──────────┐
│    FIREBASE    │           │     CLOUDINARY     │
│  AUTHENTICATION│           │   IMAGE STORAGE    │
└───────┬────────┘           └────────────────────┘
        │
┌───────▼────────────────────────────────────────┐
│         CLOUD FIRESTORE DATABASE               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  users   │  │  orders  │  │menuItems │    │
│  └──────────┘  └──────────┘  └──────────┘    │
└────────────────────────────────────────────────┘
```

### Data Flow Example: Placing an Order

```
1. Customer adds items to cart → Cart Provider (local state)
2. Customer proceeds to checkout → Multi-Order Checkout Screen
3. Customer reviews & places order → OrderModel created
4. Order saved to Firestore → Real-time listener triggers
5. Restaurant sees new order → Restaurant Orders Screen (Pending)
6. Restaurant confirms → Order status: pending → confirmed
7. Restaurant marks ready → Order status: confirmed → ready
8. Delivery partner sees order → Available Deliveries Screen
9. Partner accepts → deliveryPartnerId assigned, status: picked_up
10. Partner delivers → Order status: picked_up → delivered
11. Customer rates → restaurantRating & deliveryPartnerRating saved
```

---

## 4. User Roles & Flows

### 4.1 Customer Flow

**Journey:** Browse → Order → Track → Receive → Rate

#### Step 1: Registration & Login
- Sign up with email/password
- Provide: Name, Email, Password, Phone, Hostel
- Email verification (optional)
- Automatic role assignment: `customer`

#### Step 2: Browse Restaurants
- View all restaurants on campus
- See open/closed status (based on operating hours)
- Filter by availability
- View restaurant details (location, hours, logo)

#### Step 3: Multi-Order Placement
**Unique Feature: Order from Multiple Restaurants**

**Stage 1: Order Count Selection**
- Choose number of orders (1 to N)
- Each order can be from same/different categories

**Stage 2: Category-by-Category Ordering**
- Progress through: Food → Drinks → Desserts
- Only shows categories restaurant actually offers
- Select items per category
- **Pack Selection** (under Food category):
  - Small Foam Pack (₦100)
  - Big Foam Pack (₦150)
  - Small Plastic Pack (₦150)
  - Medium Plastic Pack (₦200)
  - Big Plastic Pack (₦250)
  - Limit: 1 pack per order
- View running subtotal
- Navigate: Previous/Next Category
- Complete all N orders

**Stage 3: Review & Checkout**
- Review all individual orders
- **Actions per order:**
  - Duplicate (clone entire order)
  - Edit (return to ordering stage)
  - Delete (minimum 1 order enforced)
- **Minimum Order Validation:** ₦500 (excluding pack)
- Select delivery type:
  - **Pickup:** Free (customer collects from restaurant)
  - **Delivery:** ₦200 flat fee (33 campus locations)
- Payment method: Wallet (default)
- Place Order

#### Step 4: Order Tracking
- View order status in "My Orders"
- **Status progression:**
  - Pending (awaiting restaurant confirmation)
  - Confirmed (restaurant accepted)
  - Ready (food prepared, awaiting pickup)
  - Picked Up (delivery partner collected)
  - Delivered (order complete)
- **Actions:**
  - Cancel (if pending/confirmed)
  - Rate (after delivery)
  - View details

#### Step 5: Rating & Review
- Rate restaurant (1-5 stars)
- Write review (optional)
- Rate delivery partner (1-5 stars)
- Review saved to order record

---

### 4.2 Restaurant Flow

**Journey:** Setup → Accept Orders → Prepare → Mark Ready

#### Step 1: Registration
- Sign up with restaurant credentials
- Provide: Restaurant Name, Location, Phone, Operating Hours
- Upload restaurant logo (optional, Cloudinary)
- Automatic role: `restaurant`
- Account created immediately (no approval needed)

#### Step 2: Menu Management
**Screen: Menu Management**

**Add Menu Items:**
- Item name, description
- Category: Food, Drink, or Dessert
- Subcategory:
  - Food: Rice, Swallow, Soup, Chicken, Beef, Egg, Pack, Others
  - Drink: Water, Soft Drinks, Others
  - Dessert: Ice Cream, Others
- Price (₦)
- Upload image (Cloudinary, required)
- Set availability (toggle)

**Manage Items:**
- Edit: Update details, price, availability
- Delete: Remove from menu
- Toggle availability: Show/hide from customers
- Responsive grid: 3 cols (desktop) → 2 (tablet) → 1 (mobile)

#### Step 3: Order Management
**Screen: Restaurant Orders**

**3 Tabs:**

**Tab 1: Pending Orders**
- New orders awaiting confirmation
- Order details: Customer, items, total
- **Actions:**
  - Confirm (→ confirmed)
  - Reject with reason (→ cancelled)
- Auto-refresh with badge notification

**Tab 2: Active Orders**
- Confirmed orders being prepared
- Estimated ready time input
- **Actions:**
  - Mark as Ready (→ ready)
  - View order details
  - Update ready time

**Tab 3: Order History**
- All completed/cancelled orders
- Filter by status
- Revenue tracking (planned)

#### Step 4: Restaurant Settings
**Screen: Restaurant Settings**

**Editable Fields:**
- Restaurant name
- Location
- Operating hours (time pickers)
- Restaurant logo (upload/update)
- Phone number

**Toggle Open/Close:**
- Green toggle = Open (visible to customers)
- Red toggle = Closed (hidden from customers)
- Real-time update on customer dashboard

---

### 4.3 Delivery Partner Flow

**Journey:** Signup → Approval → Accept Deliveries → Earn

#### Step 1: Registration (6-Step Wizard)
**Multi-step form with validation:**

**Step 1: Personal Info**
- Full name
- Email
- Password
- Phone

**Step 2: Student Verification**
- Student ID
- Department
- Level (100-500)

**Step 3: Vehicle Info**
- Vehicle type: Bicycle, Motorcycle, Car, On Foot
- Vehicle registration (if applicable)

**Step 4: Document Upload (Cloudinary)**
- Student ID card photo
- Passport photograph
- Valid ID (National ID/Driver's License)

**Step 5: Hostel Allocation**
- Upload hostel allocation document
- Verify campus residence

**Step 6: Review & Submit**
- Review all information
- Terms & conditions
- Submit for admin approval

**Initial Status:** `approvalStatus: 'pending'`, `isApproved: false`

#### Step 2: Admin Approval
**Admin dashboard:**
- View pending applications
- Review documents (zoomable)
- **Actions:**
  - Approve (→ `approved`, `isApproved: true`)
  - Reject with reason (→ `rejected`)
- Approved partners can start accepting deliveries

#### Step 3: Accept Deliveries
**Screen: Available Deliveries**

**Availability Toggle:**
- Green = Available (can see orders)
- Grey = Offline (no orders shown)

**View Available Orders:**
- Orders with status: `ready`
- Order type: `delivery`
- No delivery partner assigned
- Display: Restaurant, customer, location, earnings (₦200)

**Accept Order:**
- Click "Accept Delivery"
- Confirmation dialog
- Order assigned: `deliveryPartnerId` = current user
- Status updated: ready → picked_up
- Moves to "My Deliveries"

#### Step 4: Manage Active Deliveries
**Screen: My Deliveries**

**View Active Deliveries:**
- Orders with status: `picked_up`
- Assigned to current delivery partner
- Customer details, delivery location
- Order items, total

**Mark as Delivered:**
- Click "Mark as Delivered"
- Status updated: picked_up → delivered
- Earnings credited (₦200)
- Move to "Delivery History"

#### Step 5: Track Earnings
**Screen: Delivery Earnings**

**Dashboard Stats:**
- Total earnings (₦)
- Wallet balance (₦)
- Total deliveries count
- Completion rate (%)

**Delivery History:**
- All completed deliveries
- Date, restaurant, customer
- Earnings per delivery
- Customer rating (if provided)

**Withdraw Earnings (Planned):**
- Bank account linking
- Withdrawal requests
- Transaction history

---

### 4.4 Admin Flow

**Journey:** Monitor → Approve → Manage

#### Screen: Admin Dashboard

**3 Tabs:**

**Tab 1: Pending Applications**
- All delivery partner applications awaiting review
- Sort by: Date submitted (newest first)
- View: Name, email, student ID, department
- Click to view full application

**Application Review Modal:**
- All personal information
- Document viewer (zoomable images):
  - Student ID card
  - Passport photo
  - Valid ID
  - Hostel allocation
- **Actions:**
  - Approve → Grant delivery partner access
  - Reject → Provide rejection reason
- Updates applicant's status in Firestore

**Tab 2: Approved Partners**
- All active delivery partners
- Stats: Total deliveries, earnings, rating
- **Actions (Planned):**
  - Suspend account
  - View activity log
  - Adjust commission

**Tab 3: Rejected Applications**
- All rejected applications
- Rejection reason displayed
- Re-review option (planned)

**Admin Creation:**
- No signup flow (security)
- Created manually in Firestore:
  ```javascript
  {
    uid: "admin-uid",
    email: "admin@rfood.com",
    role: "admin",
    name: "Admin Name"
  }
  ```

---

## 5. Core Features

### 5.1 Multi-Order System (★ Unique Feature)

**Problem Solved:**
Students often want to order different items from the same restaurant (e.g., lunch + snacks for later), or need to order for roommates.

**How It Works:**

**Data Model:**
```dart
class OrderModel {
  // Traditional fields
  String orderId;
  String customerId;
  String restaurantId;
  String status;
  double total;
  
  // Multi-order specific
  List<IndividualOrder> individualOrders;  // Array of orders
  int orderCount;  // Number of orders (1 to N)
}

class IndividualOrder {
  List<OrderItem> foodItems;
  List<OrderItem> drinkItems;
  List<OrderItem> dessertItems;
  OrderItem? packItem;  // Optional, max 1
  String? specialInstructions;
}
```

**User Flow:**
1. Select order count: "I want to make 3 orders"
2. Order 1: Add food, drinks, desserts, pack
3. Order 2: Add food, drinks, desserts, pack
4. Order 3: Add food, drinks, desserts, pack
5. Review all 3 orders together
6. Pay once, get one delivery

**Benefits:**
- Single transaction (one payment, one delivery fee)
- Organized by category (easy to review)
- Duplicate feature (quickly copy orders)
- Edit individual orders before checkout

---

### 5.2 Pack System

**Environmental Consideration:**
Restaurants charge for food packaging to reduce waste and cover costs.

**Pack Types & Pricing:**
| Pack Type | Size | Price |
|-----------|------|-------|
| Small Foam Pack | Small | ₦100 |
| Big Foam Pack | Large | ₦150 |
| Small Plastic Pack | Small | ₦150 |
| Medium Plastic Pack | Medium | ₦200 |
| Big Plastic Pack | Large | ₦250 |

**Rules:**
- 1 pack per individual order
- Pack is a menu item (category: Food, subcategory: Pack)
- Selected during Food category ordering
- **Pack cost excluded from ₦500 minimum validation**

**Implementation:**
- Restaurant adds packs as regular menu items
- Customer selects during ordering
- Stored in `packItem` field of IndividualOrder
- Displayed separately in order review

---

### 5.3 Delivery Location System

**Campus-Specific Locations (33 total):**

**Hostels:**
- Engineering Hostel (Boys)
- Engineering Hostel (Girls)
- SUB Hostel (Boys)
- SUB Hostel (Girls)
- Awolowo Hall
- Kuti Hall
- Queen Elizabeth Hall
- Queen Idia Hall

**Faculties:**
- Faculty of Agriculture
- Faculty of Arts
- Faculty of Science
- Faculty of Education
- Faculty of Technology
- Faculty of Law
- Faculty of Social Sciences
- Faculty of Pharmacy
- Faculty of Basic Medical Sciences
- Faculty of Clinical Sciences

**Key Locations:**
- SUB (Student Union Building)
- Amphitheatre
- Sports Complex
- Main Gate
- New Buka
- Car Park C

**Plus:** Multiple specific departments and buildings

**Delivery Fee:** Flat ₦200 to any location (no distance calculation)

---

### 5.4 Order Status Lifecycle

```
┌──────────┐
│ PENDING  │  ← Customer places order
└────┬─────┘
     │
     ├─→ [CANCELLED]  ← Customer/Restaurant cancels
     │
     ▼
┌──────────┐
│CONFIRMED │  ← Restaurant accepts order
└────┬─────┘
     │
     ├─→ [CANCELLED]  ← Customer cancels (before preparation)
     │
     ▼
┌──────────┐
│  READY   │  ← Restaurant finishes preparation
└────┬─────┘
     │
     │   (For Pickup Orders)
     ├─────────────────────→ [COMPLETED]  ← Customer collects
     │
     │   (For Delivery Orders)
     ▼
┌──────────┐
│PICKED_UP │  ← Delivery partner collects from restaurant
└────┬─────┘
     │
     ▼
┌──────────┐
│DELIVERED │  ← Delivery partner delivers to customer
└────┬─────┘
     │
     ▼
┌──────────┐
│ [RATED]  │  ← Customer rates restaurant & partner
└──────────┘
```

**Status Permissions:**
- `pending` → `confirmed`: Restaurant only
- `pending` → `cancelled`: Customer or Restaurant
- `confirmed` → `ready`: Restaurant only
- `confirmed` → `cancelled`: Customer only
- `ready` → `picked_up`: Delivery Partner only
- `picked_up` → `delivered`: Delivery Partner only

---

### 5.5 Real-Time Updates

**Firestore Stream Listeners:**

**Customer:**
```dart
// Watch own orders in real-time
final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return firestore
      .collection('orders')
      .where('customerId', isEqualTo: currentUserId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => parseOrders(snapshot));
});
```

**Restaurant:**
```dart
// Watch restaurant's orders
final restaurantOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return firestore
      .collection('orders')
      .where('restaurantId', isEqualTo: currentUserId)
      .snapshots();
});
```

**Delivery Partner:**
```dart
// Watch available deliveries
final availableDeliveriesProvider = StreamProvider<List<OrderModel>>((ref) {
  return firestore
      .collection('orders')
      .where('status', isEqualTo: 'ready')
      .where('orderType', isEqualTo: 'delivery')
      .snapshots()
      .map((snapshot) => filterUnassigned(snapshot));
});
```

**Benefits:**
- No manual refresh needed
- Instant notifications of status changes
- Real-time badge updates
- Smooth user experience

---

### 5.6 Image Upload System (Cloudinary)

**Why Cloudinary (not Firebase Storage):**
- Automatic image optimization
- CDN delivery (fast loading)
- Transformation API (resize, crop, format)
- Generous free tier
- Direct URL access (no signed URLs needed)

**Configuration:**
- Cloud Name: `di037vgjc`
- Upload Preset: `r_foods_uploads` (unsigned)
- Allowed formats: jpg, png, jpeg, webp

**Folder Structure:**
```
r_foods_uploads/
├── profile_pictures/        # Customer/Restaurant profile photos
├── menu_items/             # Food item images
├── id_cards/               # Delivery partner student IDs
├── hostel_allocations/     # Hostel verification documents
└── restaurant_logos/       # Restaurant branding
```

**Upload Flow:**
```dart
// 1. User selects image
final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);

// 2. Read as bytes (web-compatible)
final Uint8List imageBytes = await image.readAsBytes();

// 3. Upload to Cloudinary
final String imageUrl = await CloudinaryService.uploadImage(
  imageBytes: imageBytes,
  fileName: 'menu_item_${DateTime.now().millisecondsSinceEpoch}',
  folder: 'menu_items',
);

// 4. Save URL to Firestore
await firestore.collection('menuItems').add({
  'imageUrl': imageUrl,
  // ... other fields
});
```

**Image Display:**
```dart
// Use Image.network for Cloudinary URLs
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

---

### 5.7 Dark Mode Support

**Implementation:**
Every screen detects system theme and adapts colors dynamically.

**Color Palette:**

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | White | System Dark |
| Card Background | White | `#2C2C2C` |
| Section Background | `grey[100]` | `#1E1E1E` |
| Primary Text | Black | White |
| Secondary Text | `grey[600]` | `grey[400]` |
| Borders | `grey[300]` | `grey[700]` |
| Accent | Orange | Orange |

**Pattern Used:**
```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
  final textColor = isDark ? Colors.white : Colors.black;
  final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
  
  return Card(
    color: cardColor,
    child: Text('Hello', style: TextStyle(color: textColor)),
  );
}
```

**Screens with Dark Mode:**
- ✅ All customer screens (6)
- ✅ All restaurant screens (4)
- ✅ All delivery partner screens (4)
- ✅ Auth screens (login, signup, etc.)

---

## 6. Screen-by-Screen Guide

### 6.1 Authentication Screens

#### Role Selection Screen
**Purpose:** Choose user type before signup

**UI:**
- App logo/branding
- 4 role cards:
  - Customer (Students)
  - Restaurant Owner
  - Delivery Partner
  - Admin (hidden/disabled)
- Each card shows icon, title, description
- Tap to proceed to respective signup

**Navigation:**
- Customer → Customer Signup
- Restaurant → Restaurant Signup
- Delivery Partner → Delivery Partner Signup (6-step wizard)

---

#### Login Screen
**Fields:**
- Email
- Password
- "Forgot Password?" link

**Actions:**
- Login button
- "Don't have an account? Sign up" link

**Logic:**
- Firebase Authentication
- Fetch user role from Firestore
- Route based on role:
  - customer → CustomerDashboard
  - restaurant → RestaurantDashboard
  - delivery-partner → DeliveryPartnerDashboard
  - admin → AdminDashboard

**Error Handling:**
- Invalid credentials
- Email not verified (optional)
- Account disabled

---

#### Customer Signup
**Fields:**
- Full Name
- Email
- Password
- Phone Number
- Hostel/Residence

**Validation:**
- Email format
- Password strength (min 6 chars)
- Phone number format
- Required fields

**Flow:**
1. Create Firebase Auth account
2. Create Firestore user document:
   ```javascript
   {
     uid: authUser.uid,
     email: email,
     fullName: name,
     phone: phone,
     hostel: hostel,
     role: 'customer',
     createdAt: serverTimestamp()
   }
   ```
3. Auto-login
4. Navigate to CustomerDashboard

---

#### Restaurant Signup
**Fields:**
- Restaurant Name
- Email
- Password
- Phone Number
- Location (campus address)
- Operating Hours (open time, close time)

**Additional:**
- Restaurant Logo (optional, Cloudinary upload)

**Flow:**
1. Create Firebase Auth account
2. Create Firestore user document with role: 'restaurant'
3. Auto-login
4. Navigate to RestaurantDashboard

**Default State:**
- isOpen: false (restaurant must manually toggle open)
- No menu items (must add via Menu Management)

---

#### Delivery Partner Signup (6-Step Wizard)
**Most complex signup flow**

**Step 1: Personal Information**
- Full Name
- Email
- Password
- Phone Number
- Validation + "Next" button

**Step 2: Student Information**
- Student ID Number
- Department (dropdown)
- Level: 100, 200, 300, 400, 500
- Validation + "Next"

**Step 3: Vehicle Information**
- Vehicle Type: Bicycle, Motorcycle, Car, On Foot
- Vehicle Registration Number (if applicable)
- "Next"

**Step 4: Document Upload**
- Student ID Card Photo (Cloudinary → id_cards/)
- Passport Photograph (Cloudinary → profile_pictures/)
- Valid ID (National ID or Driver's License) (Cloudinary → id_cards/)
- Image preview before upload
- "Next"

**Step 5: Hostel Allocation**
- Upload hostel allocation document (Cloudinary → hostel_allocations/)
- Confirms student is campus resident
- "Next"

**Step 6: Review & Submit**
- Display all entered information
- Display uploaded documents (thumbnails)
- Edit buttons for each section
- Terms & Conditions checkbox
- "Submit Application" button

**Backend Flow:**
1. Create Firebase Auth account
2. Upload all images to Cloudinary (parallel uploads)
3. Create Firestore user document:
   ```javascript
   {
     uid: authUser.uid,
     role: 'delivery-partner',
     approvalStatus: 'pending',
     isApproved: false,
     studentIdCardUrl: url1,
     passportPhotoUrl: url2,
     validIdUrl: url3,
     hostelAllocationUrl: url4,
     // ... other fields
   }
   ```
4. Show success message: "Application submitted! Please wait for admin approval."
5. Logout automatically
6. User must wait for admin approval before accessing dashboard

---

### 6.2 Customer Screens

#### Customer Dashboard
**Layout:** Restaurant grid + app bar

**App Bar:**
- Title: "R-Foods"
- Cart icon (with badge if items exist)
- "My Orders" button
- Logout icon

**Main Content:**
- Search bar (planned)
- Restaurant grid:
  - Responsive: 3 cols (desktop) → 2 (tablet) → 1 (mobile)
  - Each card shows:
    - Restaurant logo (background image if set)
    - Restaurant name
    - Location
    - Operating hours
    - Open/Closed badge (green/red)
  - Closed restaurants: Grey overlay, non-clickable
  - Open restaurants: Clickable → MultiOrderFlowScreen

**Data Source:**
```dart
final restaurantsProvider = StreamProvider<List<UserModel>>((ref) {
  return firestore
      .collection('users')
      .where('role', isEqualTo: 'restaurant')
      .snapshots();
});
```

**Empty State:**
- "No restaurants available"
- Icon + message

---

#### Multi-Order Flow Screen
**3-Stage Process**

**Stage 1: Order Count Selection**
- Center screen with order counter
- "-" and "+" buttons
- Large number display
- "Start Ordering" button
- Min: 1, Max: unlimited

**Stage 2: Category-by-Category Ordering**
**Header:**
- Progress: "Order X of Y"
- Current category badge
- Progress bar

**Category Tabs:**
- Horizontal scroll chips: Food, Drinks, Desserts
- Only shows categories with available items
- Active category highlighted (orange)

**Item Grid:**
- Responsive: 3 → 2 → 1 columns
- Each card:
  - Item image (Cloudinary)
  - Item name
  - Price
  - Add/Remove buttons (- 0 +)
  - Quantity display
- Empty state: "No items in this category"

**Pack Selection (Food Category Only):**
- Special section below food items
- Radio buttons for pack types
- Price shown for each
- Max 1 selection per order

**Current Order Summary Bar:**
- Sticky bottom bar
- Shows: "X items - ₦Y"
- "View Order" button → details modal

**Navigation:**
- "Previous Category" button
- "Next Category" button
- On last category: "Complete Order X" → Next order or Stage 3

**Data Persistence:**
- Orders stored in local state
- Can go back and edit
- Not saved to Firestore until checkout

**Stage 3: Proceed to Checkout**
- Automatically navigates to MultiOrderCheckoutScreen
- Passes all orders data

---

#### Multi-Order Checkout Screen
**Header:**
- Title: "Review Order"
- Restaurant name subtitle
- Order count: "X Orders"

**Individual Order Cards:**
Each card shows:
- Order number: "Order 1", "Order 2", etc.
- Action buttons:
  - Duplicate (copy icon)
  - Edit (pencil icon)
  - Delete (trash icon, disabled if only 1 order)
- Categorized items:
  - **Food:** List with quantities and prices
  - **Drinks:** List with quantities and prices
  - **Desserts:** List with quantities and prices
  - **Pack:** Single item (if selected)
- Order subtotal

**Actions:**
- **Duplicate:** Clone entire order → adds new order
- **Edit:** Returns to MultiOrderFlowScreen at that order index
- **Delete:** Removes order (min 1 enforced)

**Order Type Selection:**
- Radio buttons:
  - Pickup (Free)
  - Delivery (₦200)
- If delivery selected → Location dropdown appears

**Delivery Location Dropdown:**
- 33 campus locations
- Required if delivery selected
- Alphabetically sorted

**Minimum Order Validation:**
- ₦500 minimum (excluding pack)
- Red warning if not met
- Shows deficit: "Add ₦X more to proceed"
- "Place Order" button disabled

**Summary Section:**
- Subtotal (with pack): ₦X
- Delivery Fee: ₦0 or ₦200
- Divider
- **Total:** ₦X (bold, green)

**Place Order Button:**
- Disabled if:
  - Minimum not met
  - Delivery selected but no location
  - Already placing order (loading state)
- Enabled: Green, prominent
- Loading state: Shows spinner

**Backend Flow:**
```dart
final order = OrderModel(
  orderId: generatedId,
  customerId: currentUser.uid,
  customerName: currentUser.name,
  restaurantId: widget.restaurantId,
  restaurantName: widget.restaurantName,
  individualOrders: allOrders,
  orderCount: allOrders.length,
  status: 'pending',
  orderType: selectedType, // 'pickup' or 'delivery'
  deliveryLocation: selectedLocation,
  subtotal: subtotalWithPack,
  deliveryFee: deliveryFee,
  total: grandTotal,
  paymentMethod: 'wallet',
  paymentStatus: 'pending',
  createdAt: Timestamp.now(),
);

await firestore.collection('orders').add(order.toFirestore());
```

**Success:**
- SnackBar: "Order placed successfully!"
- Navigate to MyOrdersScreen
- Clear cart

---

#### My Orders Screen
**App Bar:**
- Title: "My Orders"
- Back button
- Filter icon (planned)

**Order List:**
- Reverse chronological (newest first)
- Each card:
  - Order date & time
  - Restaurant name
  - Status badge (color-coded):
    - Pending: Orange
    - Confirmed: Blue
    - Ready: Purple
    - Picked Up: Teal
    - Delivered: Green
    - Cancelled: Red
  - Order count: "X orders"
  - Total amount: ₦Y
  - Action buttons (conditional)

**Actions by Status:**
- **Pending:**
  - "Cancel Order" button
- **Confirmed:**
  - "Cancel Order" button
  - "View Details" button
- **Ready/Picked Up:**
  - "View Details" button
  - "Track Order" (planned)
- **Delivered:**
  - "View Details" button
  - "Rate Order" button (if not rated)
- **Cancelled:**
  - "View Details" button
  - "Reorder" button (planned)

**Order Details Modal:**
- Full order information
- All individual orders
- Itemized breakdown
- Delivery address (if applicable)
- Tracking timeline (visual)

**Rating Dialog:**
- Star rating (1-5) for restaurant
- Text review (optional, max 500 chars)
- Star rating (1-5) for delivery partner (if applicable)
- Submit button
- Saved to order document

**Empty State:**
- "No orders yet"
- "Browse restaurants" button → Dashboard

---

#### Cart Screen (Legacy/Backward Compatible)
**Note:** Mostly replaced by multi-order flow, but still accessible

**App Bar:**
- Title: "Cart"
- Back button
- Clear cart icon

**Cart Items:**
- List view
- Each item:
  - Image, name, price
  - Quantity controls (- X +)
  - Remove button
- Subtotal shown

**Actions:**
- "Proceed to Checkout" → Creates single IndividualOrder
- Same checkout flow as multi-order

**Empty State:**
- Shopping cart icon
- "Your cart is empty"
- "Browse restaurants" button

---

### 6.3 Restaurant Screens

#### Restaurant Dashboard
**Tab Bar:** 3 tabs (Overview, Menu, Orders)

**App Bar:**
- Restaurant name as title
- Open/Close toggle (switch)
  - Green = Open (visible to customers)
  - Red = Closed (hidden from customers)
- Logout icon

**Overview Tab:**
**Stats Cards (Responsive Grid: 4 → 2 → 1):**
1. **Pending Orders**
   - Icon: Clock
   - Count badge
   - "Needs Confirmation"
   
2. **Active Orders**
   - Icon: Cooking
   - Count badge
   - "In Progress"
   
3. **Menu Items**
   - Icon: Restaurant menu
   - Total count
   - "Items Available"
   
4. **Total Revenue** (Planned)
   - Icon: Money
   - ₦X earned
   - "This Month"

**Quick Actions:**
- "Add Menu Item" → Menu tab
- "View Pending Orders" → Orders tab
- "View Settings" → Settings screen

**Recent Orders:**
- Last 5 orders
- Quick view with status
- Tap to see details

**Menu Tab:**
- Directly shows MenuManagementScreen

**Orders Tab:**
- Directly shows RestaurantOrdersScreen

---

#### Menu Management Screen
**App Bar:**
- Title: "Menu Management"
- "+ Add Item" button (floating or app bar)

**Menu Items Grid:**
- Responsive: 3 → 2 → 1 columns
- Each card:
  - Item image (Cloudinary)
  - Item name
  - Category & subcategory
  - Price (₦)
  - Availability toggle (green = available)
  - Edit icon button
  - Delete icon button

**Add/Edit Item Form:**
**Fields:**
- Item Name (text)
- Description (multiline)
- Category (dropdown): Food, Drink, Dessert
- Subcategory (dropdown, changes based on category):
  - Food: Rice, Swallow, Soup, Chicken, Beef, Egg, Pack, Others
  - Drink: Water, Soft Drinks, Others
  - Dessert: Ice Cream, Others
- Price (number, ₦)
- Image Upload:
  - "Choose Image" button
  - Image preview (if selected)
  - Upload to Cloudinary → menu_items/
  - Required field
- Available (checkbox, default: true)

**Actions:**
- "Save" → Create/update Firestore
- "Cancel" → Close form

**Delete Confirmation:**
- Dialog: "Delete [Item Name]?"
- Warning: "This action cannot be undone"
- "Cancel" / "Delete" buttons

**Availability Toggle:**
- In-line toggle on each card
- Updates Firestore immediately
- No confirmation needed
- Available = shows to customers
- Unavailable = hidden but not deleted

**Empty State:**
- "No menu items yet"
- "Add your first item" button

---

#### Restaurant Orders Screen
**3 Sub-Tabs:**

**Tab 1: Pending Orders**
- Orders with status: 'pending'
- Awaiting restaurant confirmation
- Sorted: Oldest first (FIFO)

**Each Order Card:**
- Order number/ID
- Customer name & phone
- Order time (relative: "5 mins ago")
- Order type: Pickup/Delivery
- Delivery location (if delivery)
- Item count: "X items"
- Total amount: ₦Y
- "View Details" button
- **Action buttons:**
  - "Confirm" (green) → status: confirmed
  - "Reject" (red) → shows reason dialog

**Confirm Action:**
- Updates status to 'confirmed'
- Moves to Active tab
- (Planned: Send notification to customer)

**Reject Action:**
- Dialog: "Reason for rejection?"
- Text input (required)
- Updates status to 'cancelled'
- Saves rejection reason
- (Planned: Notify customer)

**Tab 2: Active Orders**
- Orders with status: 'confirmed' or 'preparing'
- Currently being prepared
- Sorted: Oldest first

**Each Order Card:**
- Same info as pending
- Estimated ready time input
- **Action button:**
  - "Mark as Ready" (orange) → status: ready
  - (Planned: Update estimated time)

**Mark as Ready Action:**
- Updates status to 'ready'
- Triggers notification to delivery partners
- Moves to History tab
- (For pickup: Customer can collect)
- (For delivery: Shows in Available Deliveries)

**Tab 3: History**
- Orders with status: 'ready', 'picked_up', 'delivered', 'cancelled'
- All past orders
- Sorted: Newest first

**Each Order Card:**
- Read-only
- Shows final status
- Customer rating (if delivered & rated)
- "View Details" only

**Order Details Modal:**
- Full order breakdown
- All individual orders
- Customer information
- Timestamps (created, updated, delivered)
- Status history (planned)

**Empty States:**
- Pending: "No pending orders"
- Active: "No active orders"
- History: "No order history"

**Real-time Badge:**
- Pending tab shows badge with count
- Updates automatically via Firestore listener

---

#### Restaurant Settings Screen
**Layout:** Centered form (max-width: 800px)

**Sections:**

**1. Restaurant Information**
- Restaurant Name (text field)
- Location/Address (text field)
- Phone Number (text field)
- All editable

**2. Restaurant Logo**
- Current logo display (if exists)
- "Upload Logo" button
- Image picker → Cloudinary upload → restaurant_logos/
- Preview before save
- Optional field

**3. Operating Hours**
- Open Time (time picker)
- Close Time (time picker)
- Responsive: Side-by-side (desktop) → Stacked (mobile)
- 12-hour format with AM/PM

**4. Account Settings**
- Email (read-only, from Firebase Auth)
- "Change Password" button (planned)
- "Delete Account" button (planned, with confirmation)

**Save Button:**
- Bottom of form
- Validates all fields
- Updates Firestore user document
- Shows loading spinner
- Success: SnackBar + auto-navigate back
- Error: Shows error message

**Implementation Note:**
- Logo URL stored in `restaurantLogoUrl` field
- Operating hours stored as map:
  ```javascript
  operatingHours: {
    openTime: "8:00 AM",
    closeTime: "10:00 PM"
  }
  ```

---

### 6.4 Delivery Partner Screens

#### Delivery Partner Dashboard
**Tab Bar:** 4 tabs (Overview, Available, My Deliveries, Earnings)

**App Bar:**
- Title: "Delivery Partner"
- Availability toggle (switch)
  - Green = Available (can accept orders)
  - Grey = Offline (hidden from system)
- Logout icon

**Overview Tab:**
**Stats Cards (Grid: 4 → 2 → 1):**
1. **Wallet Balance**
   - Icon: Wallet
   - ₦X available
   - "Withdraw" button (planned)

2. **Total Deliveries**
   - Icon: Delivery truck
   - Count of completed deliveries
   - "View History"

3. **Today's Earnings**
   - Icon: Money
   - ₦X earned today
   - Progress bar to daily goal (planned)

4. **Average Rating**
   - Icon: Star
   - X.X / 5.0
   - Based on customer ratings

**Quick Stats:**
- Pending deliveries count
- Completion rate (%)
- Response time average (planned)

**Recent Activity:**
- Last 5 deliveries
- Quick view: Restaurant, amount, time
- Tap for details

**Available Tab:**
- Shows AvailableDeliveriesScreen

**My Deliveries Tab:**
- Shows MyDeliveriesScreen

**Earnings Tab:**
- Shows DeliveryEarningsScreen

---

#### Available Deliveries Screen
**Conditional Rendering:**

**If Offline (toggle = grey):**
- Empty state with message
- "You are currently offline"
- "Turn on availability to see orders"
- Toggle reminder

**If Available (toggle = green):**

**Order List:**
- Orders with status: 'ready'
- Order type: 'delivery'
- deliveryPartnerId: null
- Sorted: Oldest first (FIFO)

**Each Order Card:**
- Restaurant name & logo
- Customer name
- Delivery location (prominent)
- Order time (relative: "Ready 10 mins ago")
- Item count: "X items"
- Order value: ₦Y
- **Earnings display:** "Earn ₦200" (prominent, green)
- "View Details" button
- **"Accept Delivery" button** (orange, full-width)

**Accept Delivery Action:**
- Confirmation dialog:
  - "Accept this delivery?"
  - Restaurant: [Name]
  - Customer: [Name]
  - Location: [Address]
  - Earnings: ₦200
  - "Cancel" / "Confirm" buttons
- On confirm:
  - Updates order:
    ```javascript
    {
      deliveryPartnerId: currentUser.uid,
      deliveryPartnerName: currentUser.name,
      status: 'picked_up',
      acceptedAt: serverTimestamp()
    }
    ```
  - Shows success SnackBar
  - Moves to "My Deliveries" tab
  - Removes from Available list

**Order Details Modal:**
- Full order information
- Restaurant details (name, location, phone)
- Customer details (name, phone)
- Delivery address (full)
- All ordered items (categorized)
- Order total
- Delivery fee (₦200)
- **"Accept" button** at bottom

**Empty State:**
- "No available deliveries"
- Delivery truck icon
- "Check back soon for new orders"

**Real-Time Updates:**
- New orders appear automatically
- Accepted orders disappear immediately
- Badge on tab updates

---

#### My Deliveries Screen
**Active Deliveries:**
- Orders with status: 'picked_up'
- Assigned to current delivery partner
- Sorted: Oldest first (urgent first)

**Each Delivery Card:**
- **Urgent Indicator:** (if > 30 mins old)
  - Red border or badge
  - "Deliver ASAP"
- Restaurant name
- Customer name & phone (tap to call - planned)
- Delivery location (large, bold)
- Order items (expandable)
- Order total
- Time since pickup (e.g., "Picked up 15 mins ago")
- **"Mark as Delivered" button** (green, prominent)
- "View Details" button
- "Get Directions" button (planned - Google Maps integration)

**Mark as Delivered Action:**
- Confirmation dialog:
  - "Confirm delivery?"
  - Customer: [Name]
  - Location: [Address]
  - "Cancel" / "Confirm" buttons
- On confirm:
  - Updates order:
    ```javascript
    {
      status: 'delivered',
      deliveredAt: serverTimestamp(),
      actualDeliveryTime: serverTimestamp()
    }
    ```
  - Credits ₦200 to wallet
  - Shows success: "Delivery completed! ₦200 earned"
  - Moves to Earnings history
  - Removes from active list

**Call Customer Feature (Planned):**
- Tap phone number
- Opens device dialer
- Privacy: Uses masked number (future enhancement)

**Navigation Features (Planned):**
- "Get Directions" opens Google Maps
- Shows route from current location to delivery address
- Turn-by-turn navigation

**Empty State:**
- "No active deliveries"
- "Accept orders from Available tab"
- Quick link to Available tab

---

#### Delivery Earnings Screen
**Summary Cards:**
**Grid: 3 → 1 column**

1. **Total Earnings**
   - ₦X lifetime earnings
   - Progress bar (to next milestone - planned)

2. **Wallet Balance**
   - ₦Y available for withdrawal
   - "Withdraw" button (planned)

3. **This Month**
   - ₦Z earned this month
   - Comparison to last month (planned)

**Delivery History:**
**Filter Bar (Planned):**
- All Time / This Month / This Week / Today
- Status filter: All / Completed / Cancelled

**History List:**
- All completed deliveries
- Sorted: Newest first

**Each Entry:**
- Date & time
- Restaurant name
- Customer name
- Delivery location
- Earnings: ₦200 (or actual amount)
- Customer rating (if provided)
  - Star rating (1-5)
  - Review text (if any)
- Order value (for reference)
- "View Details" button

**Withdrawal Section (Planned):**
- "Withdraw Earnings" button
- Minimum withdrawal: ₦1,000
- Bank account linking
- Withdrawal history
- Processing time: 1-3 business days

**Stats & Insights (Planned):**
- Average delivery time
- Peak earning hours
- Most common delivery locations
- Monthly earnings chart
- Completion rate trend

**Empty State:**
- "No delivery history yet"
- "Complete your first delivery to start earning"
- Link to Available Deliveries

---

### 6.5 Admin Screen

#### Admin Dashboard
**3 Tabs:** Pending, Approved, Rejected

**Tab 1: Pending Applications**
**List View:**
- All delivery partner applications with approvalStatus: 'pending'
- Sorted: Newest first

**Each Application Card:**
- Applicant name
- Email
- Student ID
- Department & Level
- Application date
- "Review Application" button

**Application Review Modal:**
**Full-screen or large dialog**

**Sections:**
1. **Personal Information**
   - Full Name
   - Email
   - Phone Number
   - Student ID

2. **Academic Details**
   - Department
   - Level (100-500)

3. **Vehicle Information**
   - Vehicle Type
   - Registration Number (if applicable)

4. **Uploaded Documents**
   - Student ID Card (zoomable image viewer)
   - Passport Photograph (zoomable)
   - Valid ID (zoomable)
   - Hostel Allocation (zoomable)
   - Each image:
     - Click to zoom/fullscreen
     - Download option
     - Verify authenticity

**Image Viewer:**
- Pinch to zoom
- Pan to move
- Fullscreen mode
- Next/Previous buttons
- Close button

**Action Buttons:**
**Bottom of modal:**
1. **Approve** (green)
   - Confirmation: "Approve [Name] as delivery partner?"
   - On confirm:
     ```javascript
     await firestore.collection('users').doc(userId).update({
       approvalStatus: 'approved',
       isApproved: true,
       approvedBy: currentAdminUid,
       approvedAt: serverTimestamp()
     });
     ```
   - Send email notification (planned)
   - Move to Approved tab

2. **Reject** (red)
   - Shows reason dialog
   - Text input: "Reason for rejection" (required)
   - On submit:
     ```javascript
     await firestore.collection('users').doc(userId).update({
       approvalStatus: 'rejected',
       isApproved: false,
       rejectedBy: currentAdminUid,
       rejectedAt: serverTimestamp(),
       rejectionReason: reason
     });
     ```
   - Send email notification (planned)
   - Move to Rejected tab

3. **Cancel** (grey)
   - Close modal without action

**Tab 2: Approved Delivery Partners**
**List View:**
- All delivery partners with approvalStatus: 'approved'
- Sorted: Most recent approval first

**Each Partner Card:**
- Name & photo
- Student ID
- Department
- Approval date
- Stats (planned):
  - Total deliveries
  - Current earnings
  - Average rating
- **Actions:**
  - "View Profile" → Full details
  - "Suspend" (planned) → Temporarily disable
  - "View Activity" (planned) → Delivery history

**Tab 3: Rejected Applications**
**List View:**
- All applications with approvalStatus: 'rejected'
- Sorted: Most recent rejection first

**Each Card:**
- Applicant name
- Email
- Rejection date
- Rejected by (admin name)
- Rejection reason (visible)
- **Actions:**
  - "View Application" → Same review modal
  - "Re-review" (planned) → Allow reconsideration
  - "Delete" (planned) → Permanently remove

**Empty States:**
- Pending: "No pending applications"
- Approved: "No approved partners"
- Rejected: "No rejected applications"

**Admin Tools (Planned):**
- Search applicants
- Filter by department
- Bulk actions
- Export to CSV
- Statistics dashboard

---

## 7. Database Schema

### 7.1 Firestore Collections

#### Collection: `users`
**Purpose:** Store all user types (customer, restaurant, delivery-partner, admin)

**Common Fields:**
```javascript
{
  uid: string (Firebase Auth UID),
  email: string,
  role: string ('customer' | 'restaurant' | 'delivery-partner' | 'admin'),
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Customer-Specific Fields:**
```javascript
{
  fullName: string,
  phone: string,
  hostel: string,
  // Optional:
  profilePictureUrl: string
}
```

**Restaurant-Specific Fields:**
```javascript
{
  restaurantName: string,
  location: string,
  phone: string,
  operatingHours: {
    openTime: string,
    closeTime: string
  },
  isOpen: boolean,
  restaurantLogoUrl: string (optional)
}
```

**Delivery Partner-Specific Fields:**
```javascript
{
  fullName: string,
  phone: string,
  studentId: string,
  department: string,
  level: string,
  vehicleType: string,
  vehicleRegistration: string (optional),
  
  // Documents
  studentIdCardUrl: string,
  passportPhotoUrl: string,
  validIdUrl: string,
  hostelAllocationUrl: string,
  
  // Approval
  approvalStatus: string ('pending' | 'approved' | 'rejected'),
  isApproved: boolean,
  approvedBy: string (admin UID, optional),
  approvedAt: timestamp (optional),
  rejectedBy: string (admin UID, optional),
  rejectedAt: timestamp (optional),
  rejectionReason: string (optional),
  
  // Status
  isAvailable: boolean,
  
  // Stats (updated via cloud functions or computed)
  totalDeliveries: number,
  totalEarnings: number,
  walletBalance: number,
  averageRating: number
}
```

**Admin-Specific Fields:**
```javascript
{
  fullName: string,
  // Minimal fields - admins are created manually
}
```

**Indexes:**
```javascript
// For admin dashboard
users: [role (Asc), approvalStatus (Asc), createdAt (Desc)]

// For restaurant listing
users: [role (Asc), isOpen (Asc)]
```

---

#### Collection: `menuItems`
**Purpose:** Store all restaurant menu items

**Document Structure:**
```javascript
{
  menuItemId: string (auto-generated),
  restaurantId: string (ref to users.uid),
  restaurantName: string (denormalized for quick access),
  
  name: string,
  description: string,
  category: string ('Food' | 'Drink' | 'Dessert'),
  subcategory: string (varies by category),
  price: number,
  imageUrl: string (Cloudinary URL),
  
  isAvailable: boolean,
  
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Subcategory Values:**
```javascript
// Food
['Rice', 'Swallow', 'Soup', 'Chicken', 'Beef', 'Egg', 'Pack', 'Others']

// Drink
['Water', 'Soft Drinks', 'Others']

// Dessert
['Ice Cream', 'Others']
```

**Indexes:**
```javascript
// For menu queries
menuItems: [restaurantId (Asc), category (Asc), isAvailable (Asc)]
```

---

#### Collection: `orders`
**Purpose:** Store all customer orders

**Document Structure:**
```javascript
{
  orderId: string (auto-generated),
  
  // Participants
  customerId: string (ref to users.uid),
  customerName: string,
  customerPhone: string,
  restaurantId: string (ref to users.uid),
  restaurantName: string,
  deliveryPartnerId: string (optional, ref to users.uid),
  deliveryPartnerName: string (optional),
  
  // Order Data
  individualOrders: [
    {
      foodItems: [
        {
          menuItemId: string,
          name: string,
          price: number,
          quantity: number,
          notes: string (optional)
        }
      ],
      drinkItems: [ /* same structure */ ],
      dessertItems: [ /* same structure */ ],
      packItem: {
        menuItemId: string,
        name: string,
        price: number,
        quantity: number (always 1)
      } (optional),
      specialInstructions: string (optional)
    }
  ],
  orderCount: number,
  
  // Legacy (for backward compatibility)
  items: [ /* flattened all items */ ],
  
  // Pricing
  subtotal: number,
  deliveryFee: number,
  total: number,
  
  // Delivery
  orderType: string ('pickup' | 'delivery'),
  deliveryLocation: string (required if delivery),
  
  // Payment
  paymentMethod: string ('wallet'),
  paymentStatus: string ('pending' | 'completed' | 'failed'),
  
  // Status & Tracking
  status: string ('pending' | 'confirmed' | 'ready' | 'picked_up' | 'delivered' | 'cancelled'),
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
  confirmedAt: timestamp (optional),
  readyAt: timestamp (optional),
  pickedUpAt: timestamp (optional),
  deliveredAt: timestamp (optional),
  estimatedReadyTime: timestamp (optional),
  actualDeliveryTime: timestamp (optional),
  
  // Ratings
  restaurantRating: number (optional, 1-5),
  restaurantReview: string (optional),
  deliveryPartnerRating: number (optional, 1-5),
  deliveryPartnerReview: string (optional),
  
  // Cancellation
  cancellationReason: string (optional)
}
```

**Indexes:**
```javascript
// Customer orders
orders: [customerId (Asc), createdAt (Desc)]

// Restaurant orders
orders: [restaurantId (Asc), status (Asc), createdAt (Desc)]

// Delivery partner orders
orders: [deliveryPartnerId (Asc), createdAt (Desc)]

// Available deliveries
orders: [status (Asc), orderType (Asc), createdAt (Asc)]

// Active customer orders
orders: [customerId (Asc), status (Asc), createdAt (Desc)]
```

---

### 7.2 Firestore Security Rules

**Current State:** Using simplified permissive rules for development

**Recommended Production Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getUserRole() {
      return getUserData().role;
    }
    
    function isCustomer() {
      return getUserRole() == 'customer';
    }
    
    function isRestaurant() {
      return getUserRole() == 'restaurant';
    }
    
    function isDeliveryPartner() {
      return getUserRole() == 'delivery-partner';
    }
    
    function isApprovedDeliveryPartner() {
      return isDeliveryPartner() && getUserData().isApproved == true;
    }
    
    function isAdmin() {
      return getUserRole() == 'admin';
    }
    
    // USERS
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    // MENU ITEMS
    match /menuItems/{itemId} {
      allow read: if isSignedIn();
      allow create: if isRestaurant() && request.resource.data.restaurantId == request.auth.uid;
      allow update, delete: if isRestaurant() && resource.data.restaurantId == request.auth.uid;
    }
    
    // ORDERS
    match /orders/{orderId} {
      // Read
      allow read: if isSignedIn() && (
        isOwner(resource.data.customerId) ||
        isOwner(resource.data.restaurantId) ||
        (resource.data.deliveryPartnerId != null && isOwner(resource.data.deliveryPartnerId)) ||
        (isDeliveryPartner() && resource.data.status == 'ready' && resource.data.orderType == 'delivery' && resource.data.deliveryPartnerId == null) ||
        isAdmin()
      );
      
      // Create
      allow create: if isCustomer() && isOwner(request.resource.data.customerId);
      
      // Update
      allow update: if isSignedIn() && (
        // Customer actions
        (isCustomer() && isOwner(resource.data.customerId)) ||
        // Restaurant actions
        (isRestaurant() && isOwner(resource.data.restaurantId)) ||
        // Delivery partner actions
        (isApprovedDeliveryPartner() && (
          // Accept order
          (resource.data.status == 'ready' && request.resource.data.deliveryPartnerId == request.auth.uid) ||
          // Mark delivered
          (isOwner(resource.data.deliveryPartnerId))
        ))
      );
      
      // Delete
      allow delete: if (isCustomer() && isOwner(resource.data.customerId) && resource.data.status == 'cancelled') || isAdmin();
    }
  }
}
```

---

## 8. Implementation Status

### 8.1 Completed Features ✅

**Core System:**
- ✅ Multi-user authentication (4 roles)
- ✅ Role-based routing
- ✅ Real-time Firestore integration
- ✅ Cloudinary image uploads
- ✅ Responsive design (all screens)
- ✅ Dark mode (all screens)

**Customer Features:**
- ✅ Multi-order system (1-N orders per transaction)
- ✅ Category-by-category ordering
- ✅ Pack selection (5 types)
- ✅ ₦500 minimum validation
- ✅ Duplicate/Edit/Delete orders
- ✅ Pickup vs Delivery selection
- ✅ 33 campus delivery locations
- ✅ Order tracking
- ✅ Restaurant/delivery partner rating

**Restaurant Features:**
- ✅ Menu management (CRUD)
- ✅ Image uploads for menu items
- ✅ Category & subcategory system
- ✅ Availability toggle per item
- ✅ Order management (3 tabs)
- ✅ Confirm/Reject orders
- ✅ Mark orders as ready
- ✅ Restaurant settings (hours, logo)
- ✅ Open/Close toggle

**Delivery Partner Features:**
- ✅ 6-step registration wizard
- ✅ Document upload (4 docs)
- ✅ Admin approval system
- ✅ Available deliveries list
- ✅ Accept deliveries
- ✅ Active delivery tracking
- ✅ Mark as delivered
- ✅ Earnings tracking
- ✅ Delivery history

**Admin Features:**
- ✅ Application review dashboard
- ✅ Approve/Reject workflow
- ✅ Document verification (zoomable)
- ✅ Rejection reasons

**Technical:**
- ✅ Firestore indexes configured
- ✅ Security rules (permissive for development)
- ✅ Riverpod state management
- ✅ Error handling
- ✅ Loading states
- ✅ Empty states

---

### 8.2 Partially Implemented ⚠️

**Delivery Partner Rating:**
- ✅ Rating dialog exists
- ✅ Restaurant rating works
- ⚠️ Delivery partner rating saved but not displayed
- ⚠️ No average rating calculation
- ⚠️ Not shown on partner profile

**Restaurant Logo:**
- ✅ Upload functionality exists
- ✅ Stored in Firestore
- ⚠️ Not displayed as background on customer cards

**Security Rules:**
- ✅ Comprehensive rules written
- ⚠️ Currently using permissive rules for development
- ⚠️ Need testing and activation

---

### 8.3 Not Implemented ❌

**High Priority:**
- ❌ Order notifications (in-app alerts when status changes)
- ❌ Restaurant earnings dashboard
- ❌ Order history filters

**Medium Priority:**
- ❌ Push notifications (FCM)
- ❌ Payment integration
- ❌ Wallet top-up system
- ❌ Withdrawal system for delivery partners
- ❌ Search functionality (restaurants, menu items)
- ❌ Order reordering
- ❌ Favorite restaurants

**Nice to Have:**
- ❌ Chat system (customer ↔ restaurant ↔ delivery partner)
- ❌ Real-time GPS tracking
- ❌ ETA calculations
- ❌ Analytics dashboard
- ❌ Promotional codes/discounts
- ❌ Scheduled orders
- ❌ Group orders
- ❌ Loyalty points

---

## 9. Future Improvements

### 9.1 Phase 1: Essential Polish (1-2 weeks)

#### 1. Order Notifications
**Estimated:** 2-3 hours

**Implementation:**
```dart
// Add to pubspec.yaml
firebase_messaging: ^14.0.0
flutter_local_notifications: ^16.0.0

// Create notification service
class NotificationService {
  static Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();
    
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }
  
  static void _showLocalNotification(RemoteMessage message) {
    // Show in-app notification
  }
}

// Listen to order status changes
ref.listen(myOrdersProvider, (previous, next) {
  next.whenData((orders) {
    for (var order in orders) {
      if (order.status == 'confirmed') {
        _showNotification('Order Confirmed!', 'Your order is being prepared');
      } else if (order.status == 'ready') {
        _showNotification('Order Ready!', 'Your order is ready for pickup/delivery');
      }
    }
  });
});
```

**Features:**
- In-app banner when order confirmed
- In-app banner when order ready
- Sound/vibration alerts
- Clickable (opens My Orders screen)

---

#### 2. Restaurant Logo Display
**Estimated:** 30 minutes

**Implementation:**
```dart
// In customer_dashboard.dart restaurant card
class _RestaurantCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background: Restaurant logo
          if (restaurant.restaurantLogoUrl != null)
            Positioned.fill(
              child: Image.network(
                restaurant.restaurantLogoUrl!,
                fit: BoxFit.cover,
              ),
            ),
          
          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Content (name, location, etc.)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.restaurantName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
                // ... location, hours
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### 3. Activate Proper Security Rules
**Estimated:** 1-2 hours

**Tasks:**
1. Deploy production security rules
2. Test all user flows:
   - Customer: Browse, order, track
   - Restaurant: Manage menu, orders
   - Delivery: Accept, deliver
   - Admin: Approve partners
3. Fix any permission errors
4. Add error handling for permission denied

---

### 9.2 Phase 2: Enhanced Features (2-3 weeks)

#### 1. Restaurant Earnings Dashboard
**Estimated:** 3-4 hours

**Features:**
- Total revenue (all-time, this month, this week)
- Order statistics (completed, cancelled, pending)
- Revenue chart (line graph, last 30 days)
- Top-selling items
- Peak hours analysis
- Average order value

**Implementation:**
```dart
// Add to restaurant_dashboard.dart Overview tab
class EarningsSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(restaurantStatsProvider);
    
    return statsAsync.when(
      data: (stats) => Column(
        children: [
          // Revenue cards
          Row(
            children: [
              _StatCard(
                title: 'Total Revenue',
                value: '₦${stats.totalRevenue}',
                icon: Icons.account_balance_wallet,
              ),
              _StatCard(
                title: 'This Month',
                value: '₦${stats.monthlyRevenue}',
                icon: Icons.trending_up,
              ),
            ],
          ),
          
          // Chart
          RevenueChart(data: stats.dailyRevenue),
          
          // Top items
          TopSellingItems(items: stats.topItems),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error loading stats'),
    );
  }
}

// Provider
final restaurantStatsProvider = FutureProvider<RestaurantStats>((ref) async {
  final restaurantId = ref.watch(authStateProvider).value!.uid;
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getRestaurantOrderStats(restaurantId);
});
```

---

#### 2. Order History Filters
**Estimated:** 2-3 hours

**Features:**
- Filter by status (All, Pending, Delivered, Cancelled)
- Filter by date range (Today, This Week, This Month, Custom)
- Search by restaurant name
- Sort by: Date, Total, Status

**Implementation:**
```dart
// Add to my_orders_screen.dart
class OrderFilters extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status chips
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text('All'),
              selected: selectedStatus == null,
              onSelected: (selected) => setState(() => selectedStatus = null),
            ),
            FilterChip(
              label: Text('Pending'),
              selected: selectedStatus == 'pending',
              onSelected: (selected) => setState(() => selectedStatus = 'pending'),
            ),
            // ... other statuses
          ],
        ),
        
        // Date range
        DropdownButton<DateRange>(
          value: selectedRange,
          items: [
            DropdownMenuItem(value: DateRange.today, child: Text('Today')),
            DropdownMenuItem(value: DateRange.week, child: Text('This Week')),
            DropdownMenuItem(value: DateRange.month, child: Text('This Month')),
            DropdownMenuItem(value: DateRange.custom, child: Text('Custom')),
          ],
          onChanged: (range) => setState(() => selectedRange = range),
        ),
        
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by restaurant...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (query) => setState(() => searchQuery = query),
        ),
      ],
    );
  }
}

// Filter orders
List<OrderModel> filterOrders(List<OrderModel> orders) {
  return orders.where((order) {
    // Status filter
    if (selectedStatus != null && order.status != selectedStatus) return false;
    
    // Date filter
    if (!isInDateRange(order.createdAt, selectedRange)) return false;
    
    // Search query
    if (searchQuery.isNotEmpty && 
        !order.restaurantName.toLowerCase().contains(searchQuery.toLowerCase())) {
      return false;
    }
    
    return true;
  }).toList();
}
```

---

#### 3. Enhanced Delivery Partner Ratings
**Estimated:** 2 hours

**Features:**
- Separate restaurant and delivery partner rating
- Display average ratings on profiles
- Calculate ratings automatically (Cloud Function)
- Show rating breakdown (5★: X, 4★: Y, etc.)
- Display reviews on profile

**Implementation:**
```dart
// Update rating dialog in my_orders_screen.dart
void _showRatingDialog(BuildContext context, WidgetRef ref, OrderModel order) {
  int restaurantRating = 5;
  int deliveryRating = 5;
  String restaurantReview = '';
  String deliveryReview = '';
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Rate Your Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restaurant rating
          Text('Rate Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
          StarRating(
            rating: restaurantRating,
            onRatingChanged: (rating) => setState(() => restaurantRating = rating),
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Review (optional)'),
            onChanged: (text) => restaurantReview = text,
          ),
          
          SizedBox(height: 16),
          
          // Delivery partner rating (if applicable)
          if (order.deliveryPartnerId != null) ...[
            Text('Rate Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold)),
            StarRating(
              rating: deliveryRating,
              onRatingChanged: (rating) => setState(() => deliveryRating = rating),
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Review (optional)'),
              onChanged: (text) => deliveryReview = text,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            await ref.read(orderServiceProvider).addRatingAndReview(
              orderId: order.orderId,
              restaurantRating: restaurantRating,
              restaurantReview: restaurantReview.isNotEmpty ? restaurantReview : null,
              deliveryPartnerRating: order.deliveryPartnerId != null ? deliveryRating : null,
              deliveryPartnerReview: order.deliveryPartnerId != null && deliveryReview.isNotEmpty ? deliveryReview : null,
            );
            Navigator.pop(context);
          },
          child: Text('Submit'),
        ),
      ],
    ),
  );
}

// Cloud Function to update average ratings
exports.updateAverageRatings = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    
    // Update restaurant average rating
    if (newData.restaurantRating) {
      const restaurantOrders = await admin.firestore()
        .collection('orders')
        .where('restaurantId', '==', newData.restaurantId)
        .where('restaurantRating', '>=', 1)
        .get();
      
      const avgRating = restaurantOrders.docs.reduce((sum, doc) => 
        sum + doc.data().restaurantRating, 0) / restaurantOrders.size;
      
      await admin.firestore()
        .collection('users')
        .doc(newData.restaurantId)
        .update({ averageRating: avgRating });
    }
    
    // Update delivery partner average rating
    if (newData.deliveryPartnerRating && newData.deliveryPartnerId) {
      // Similar logic for delivery partner
    }
  });
```

---

### 9.3 Phase 3: Advanced Features (4-6 weeks)

#### 1. Push Notifications
**Estimated:** 4-6 hours

**Requirements:**
- Firebase Cloud Messaging setup
- Device token management
- Server-side notification triggers (Cloud Functions)
- Notification permission handling
- Background notification handling

**Triggers:**
- Customer: Order confirmed, Order ready, Delivery partner assigned, Order delivered
- Restaurant: New order received
- Delivery Partner: New order available

---

#### 2. Payment Integration
**Estimated:** 12-16 hours

**Options for Nigeria:**
- Paystack (recommended)
- Flutterwave
- Stripe (international)

**Features:**
- Wallet top-up (card, bank transfer)
- Order payment from wallet
- Transaction history
- Refund processing
- Payment verification
- Webhook handling

**Implementation:**
```dart
// Paystack integration
class PaystackService {
  static const String publicKey = 'pk_test_xxx';
  
  Future<bool> topUpWallet(double amount) async {
    final charge = Charge()
      ..amount = (amount * 100).toInt() // Convert to kobo
      ..email = currentUser.email
      ..reference = _generateReference();
    
    final response = await PaystackPlugin.checkout(
      context,
      method: CheckoutMethod.card,
      charge: charge,
    );
    
    if (response.status == true) {
      // Verify payment on backend
      await _verifyPayment(response.reference);
      // Update wallet balance
      await _updateWalletBalance(amount);
      return true;
    }
    return false;
  }
}
```

---

#### 3. Chat System
**Estimated:** 8-12 hours

**Features:**
- Customer ↔ Restaurant chat
- Customer ↔ Delivery Partner chat
- Real-time messaging (Firestore)
- Read receipts
- Typing indicators
- Image sharing
- Message history

**Data Model:**
```javascript
// Collection: chats
{
  chatId: string,
  participants: [customerId, restaurantId/deliveryPartnerId],
  orderId: string (ref),
  lastMessage: {
    text: string,
    senderId: string,
    timestamp: timestamp
  },
  unreadCount: {
    [userId]: number
  }
}

// Collection: messages (subcollection of chats)
{
  messageId: string,
  senderId: string,
  senderName: string,
  text: string,
  imageUrl: string (optional),
  timestamp: timestamp,
  read: boolean
}
```

---

#### 4. Real-time GPS Tracking
**Estimated:** 10-15 hours

**Features:**
- Live delivery partner location
- Customer map view
- ETA calculation
- Route optimization
- Location permission handling
- Background location tracking

**Requirements:**
- google_maps_flutter package
- geolocator package
- Location services enabled
- Battery optimization considerations

**Implementation:**
```dart
// Delivery partner app
class LocationService {
  StreamSubscription<Position>? _positionStream;
  
  void startTracking(String orderId) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _updateLocationInFirestore(orderId, position);
    });
  }
  
  Future<void> _updateLocationInFirestore(String orderId, Position position) async {
    await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .update({
        'deliveryPartnerLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
  }
}

// Customer app
class OrderTrackingMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots(),
      builder: (context, snapshot) {
        final location = snapshot.data?.get('deliveryPartnerLocation');
        
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(location['latitude'], location['longitude']),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId('delivery_partner'),
              position: LatLng(location['latitude'], location['longitude']),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
            Marker(
              markerId: MarkerId('destination'),
              position: LatLng(destinationLat, destinationLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          },
        );
      },
    );
  }
}
```

---

## 10. Setup & Deployment

### 10.1 Development Setup

**Prerequisites:**
- Flutter SDK (3.0+)
- Firebase account
- Cloudinary account
- IDE (VS Code / Android Studio)

**Step 1: Clone & Install**
```bash
git clone https://github.com/yourusername/r_foods.git
cd r_foods
flutter pub get
```

**Step 2: Firebase Configuration**
1. Create Firebase project: https://console.firebase.google.com
2. Add web app (for Flutter web)
3. Enable Authentication (Email/Password)
4. Create Firestore database
5. Download `firebase_options.dart` or run:
   ```bash
   flutterfire configure
   ```

**Step 3: Firestore Setup**
1. Create composite indexes (see section 7.2)
2. Deploy security rules (firestore.rules)
3. Create admin user manually:
   ```javascript
   // In Firestore Console → users collection → Add Document
   {
     uid: "your-auth-uid",
     email: "admin@rfood.com",
     role: "admin",
     fullName: "Admin Name",
     createdAt: [server timestamp]
   }
   ```

**Step 4: Cloudinary Configuration**
1. Sign up: https://cloudinary.com
2. Get credentials from dashboard
3. Update in `cloudinary_service.dart`:
   ```dart
   static const String cloudName = 'your_cloud_name';
   static const String uploadPreset = 'your_upload_preset';
   ```
4. Create upload preset (Settings → Upload → Add upload preset)
   - Signing Mode: Unsigned
   - Folder: r_foods_uploads

**Step 5: Run App**
```bash
# Web
flutter run -d chrome

# Android
flutter run

# iOS
flutter run
```

---

### 10.2 Production Deployment

#### Web Deployment (Firebase Hosting)

**Step 1: Build**
```bash
flutter build web --release
```

**Step 2: Deploy**
```bash
firebase init hosting
# Select build/web as public directory
# Configure as single-page app: Yes
# Set up automatic builds: No

firebase deploy --only hosting
```

**Custom Domain:**
```bash
firebase hosting:channel:deploy production
# Follow instructions to add custom domain in Firebase Console
```

---

#### Android Deployment (Play Store)

**Step 1: Prepare**
1. Create keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Update `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. Update `android/app/build.gradle`:
   ```gradle
   android {
     signingConfigs {
       release {
         keyAlias keystoreProperties['keyAlias']
         keyPassword keystoreProperties['keyPassword']
         storeFile file(keystoreProperties['storeFile'])
         storePassword keystoreProperties['storePassword']
       }
     }
     buildTypes {
       release {
         signingConfig signingConfigs.release
       }
     }
   }
   ```

**Step 2: Build**
```bash
flutter build appbundle --release
```

**Step 3: Upload**
1. Go to Google Play Console
2. Create app
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. Fill app details, screenshots, etc.
5. Submit for review

---

#### iOS Deployment (App Store)

**Step 1: Prepare**
1. Enroll in Apple Developer Program ($99/year)
2. Configure signing in Xcode
3. Update `ios/Runner/Info.plist` with required permissions

**Step 2: Build**
```bash
flutter build ipa --release
```

**Step 3: Upload**
1. Open Xcode
2. Archive → Upload to App Store Connect
3. Fill metadata in App Store Connect
4. Submit for review

---

### 10.3 Environment Variables

**Create `.env` file:**
```env
# Firebase
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset

# Environment
ENV=production
```

**Load in app:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

---

### 10.4 Monitoring & Analytics

**Firebase Analytics:**
```dart
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// Log events
await analytics.logEvent(
  name: 'order_placed',
  parameters: {
    'restaurant_id': restaurantId,
    'order_value': total,
    'order_count': orderCount,
  },
);
```

**Crashlytics:**
```dart
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Order placement failed',
);
```

---

## 11. Conclusion

R-Foods is a comprehensive university food delivery platform with a unique multi-order system that sets it apart from traditional food delivery apps. The platform successfully connects students, restaurants, and delivery partners in a seamless ecosystem.

**Current State:**
- ✅ ~80% feature complete
- ✅ All core flows working
- ✅ Production-ready for MVP launch
- ✅ Scalable architecture

**Next Steps:**
1. Implement order notifications (2-3 hours)
2. Activate production security rules (1-2 hours)
3. Deploy to production (web + mobile)
4. Gather user feedback
5. Iterate on Phase 2 features

**Key Strengths:**
- Unique multi-order system
- Comprehensive user flows for all roles
- Real-time updates throughout
- Beautiful, responsive UI with dark mode
- Solid technical foundation

The platform is ready for launch and can be enhanced incrementally based on user feedback and business priorities.

---

**Document Version:** 1.0  
**Last Updated:** March 11, 2026  
**Authors:** Development Team  
**License:** Proprietary
