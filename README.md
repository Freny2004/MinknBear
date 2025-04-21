MinknBear is a feature-rich, cross-platform e-commerce mobile application built with Flutter. It offers a seamless shopping experience, integrating the Shopify Storefront API for product management, Razorpay for secure payments, and Firebase for authentication and data storage. The app uses the BLoC pattern for efficient state management, ensuring scalability and maintainability.

# Features:
 User Authentication: Secure login and registration using Firebase Authentication with email/password validation.<br/>
 Product Browsing: Dynamic product catalog with category filters, keyword search, and sorting options (price, popularity).<br/>
 Wishlist: Save favorite products for future purchase, with easy transfer to the cart.<br/>
 Cart Management: Real-time price computation, quantity updates, and discount application.<br/>
 Secure Checkout: Integrated Razorpay payment gateway with Cash on Delivery (COD) fallback and webhook synchronization.<br/>
 Order Tracking: View order history and track shipment status via Shopify’s order pipeline.<br/>
 User Profiles: Manage addresses, past orders, and account settings with session persistence.<br/>
 Cross-Platform: Consistent UI/UX on Android and iOS, built with a single Flutter codebase.<br/>



# Prerequisites:
Flutter SDK (v3.0 or higher)<br/>
Dart<br/>
Android Studio/Xcode for emulator/simulator<br/>
Shopify Storefront API access token<br/>



# Testing:
The app has been thoroughly tested for:

Functional Testing: Authentication, product listing, cart, checkout, and order tracking.
UI/UX: Responsiveness across screen sizes and platform-specific guidelines.
API: Shopify GraphQL queries, mutations, and error handling.
Performance: Fast API responses and low-latency UI updates.
Security: Encrypted data storage, secure login, and HTTPS API calls.
Payment: End-to-end checkout with success/failure scenarios.
See the  section for details.


# License
This project is licensed under the MIT License. See the  file for details.

# Contact
For issues or inquiries, reach out via GitHub Issues or email at frenybhadiyadra.fb@gmail.com
