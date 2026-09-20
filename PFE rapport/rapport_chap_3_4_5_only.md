# INWIN Report Guide For Chapters 3, 4, and 5 Only

This file is only for the parts of the report you want to revise:

- Chapter 3
- Chapter 4
- Chapter 5

It is based on the real implementation of the INWIN app.

## What The `.md` File Is

This `.md` file is just a simple text note.

It is for:

- organizing the corrections clearly
- keeping app-aligned wording
- helping you copy the right ideas into your report

It does not change your PDF automatically.

## Chapter 3: Functional Analysis, UML, and Technical Architecture

## 3.1 Actors

To align the report with the app, use these actors:

- Customer
- Business Client
- Admin

Important note:

You may mention `Service Provider` only as a future or conceptual actor, but not as a fully implemented actor in the current app.

### Why

The code really implements:

- `Customer` / `Business Client` through `clientType`
- `Admin` through `role`

This is visible in:

- [app_user.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/models/app_user.dart)
- [app_router.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/router/app_router.dart)

### Actor distinction

#### Customer

- individual user
- B2C flow
- can access event services only

#### Business Client

- company user
- B2B flow
- can access gifts and corporate events

#### Admin

- internal manager of the platform
- supervises requests, quotes, statuses, and communication

## 3.2 Functional Requirements

Only include features that are really implemented.

### Customer / Business Client

- Register
- Log in
- Verify email
- Edit profile
- Browse gifts
- Browse events
- Submit gift request
- Submit event request
- Upload files and logos
- Track project status
- Accept or reject a quote
- Exchange messages with admin
- Download the bon de commande PDF after quote acceptance

### Admin

- View all requests
- Filter requests by status
- View request details
- Mark a request as reviewing
- Set supplier price
- Send quote
- Update request status
- Mark delivery progress
- Cancel request
- Exchange messages with clients

## 3.3 Use Case Diagram Advice

Your professor said the roles were mixed. So in the use case diagram:

- separate `Customer`
- separate `Business Client`
- separate `Admin`

### Good use cases to show

#### Customer

- Register
- Log in
- Submit event request
- Track request
- Respond to quote
- Chat with admin

#### Business Client

- Register
- Log in
- Submit event request
- Submit gift request
- Upload logo
- Track request
- Respond to quote
- Chat with admin

#### Admin

- View requests
- Manage requests
- Prepare quote
- Update request status
- Chat with client

## 3.4 Class Diagram

Use classes that really exist in the app logic.

### User

- id
- fullName
- companyName
- email
- phone
- role
- clientType
- photoUrl
- fcmToken
- createdAt

Based on:
[app_user.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/models/app_user.dart)

### QuoteRequest

- id
- customerId
- customerName
- companyName
- type
- status
- details
- attachmentUrls
- supplierPrice
- quotedPrice
- adminNote
- customerNote
- createdAt
- updatedAt

Based on:
[quote_request.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/models/quote_request.dart)

### ChatMessage

- id
- requestId
- senderId
- senderName
- isAdmin
- text
- attachments
- createdAt
- isRead

Based on:
[message.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/models/message.dart)

### Important note for your diagram

Do not present these as fully implemented separate database classes unless you clearly mark them as conceptual only:

- Provider
- Quotation as a separate entity

In the real app:

- provider management is not implemented as its own user role
- quotation data is stored inside `QuoteRequest`

### Recommended relationships

- User 1..* QuoteRequest
- QuoteRequest 1..* ChatMessage
- Admin manages QuoteRequest

## 3.5 Sequence Diagrams

Your professor said the sequence diagrams were too UI-focused.

So rewrite them with backend steps too.

### Login sequence

User -> Flutter screen -> AuthService -> Firebase Authentication -> Firestore user data -> App router

### Submit request sequence

User -> Form screen -> RequestService -> Firestore `requests` collection -> Cloud Function -> Notification to admin

### Admin sends quote

Admin -> Admin detail screen -> RequestService -> Firestore update -> Cloud Function -> Notification to customer

### Messaging sequence

User/Admin -> MessageService -> Firestore `messages` subcollection -> Cloud Function -> Notification to the other side

### Quote response sequence

Customer -> Project detail screen -> RequestService -> Firestore update -> status update -> PDF generation

## 3.6 Software Architecture

This part should match the real technical stack.

### Architecture summary

The INWIN application follows a mobile client and cloud backend architecture. The frontend is developed with Flutter. The backend relies on Firebase services for authentication, database storage, file storage, notifications, and backend automation.

### Technologies actually used

- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Cloud Functions
- Riverpod
- GoRouter
- PDF and Printing packages

This is supported by:

- [pubspec.yaml](C:/apps/inwin_app_v3/inwin_app/pubspec.yaml)
- [index.ts](C:/apps/inwin_app_v3/inwin_app/functions/src/index.ts)

### Data structure

#### `users/{uid}`

- fullName
- companyName
- email
- phone
- role
- clientType
- photoUrl
- fcmToken
- createdAt

#### `requests/{requestId}`

- customerId
- customerName
- companyName
- type
- status
- details
- attachmentUrls
- supplierPrice
- quotedPrice
- adminNote
- customerNote
- createdAt
- updatedAt

#### `requests/{requestId}/messages/{messageId}`

- requestId
- senderId
- senderName
- isAdmin
- text
- attachments
- createdAt
- isRead

## 3.7 Security / Access Logic

If you mention app security, say it simply and correctly:

- Firebase Authentication controls account access
- role and client type influence navigation and permissions
- B2C users cannot access gift routes
- admin has dedicated request-management screens

This is visible in:

- [app_router.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/router/app_router.dart)

## Chapter 4: System Architecture and Workflow

This chapter should explain how the system works, not repeat theory.

## 4.1 Main Workflow

Use this real workflow:

1. The user creates an account and logs in.
2. The user chooses event services or gift services depending on profile type.
3. The user submits a request with details and optional files.
4. The request is stored in Firestore.
5. The admin reviews the request.
6. The admin prepares a quote and updates the status.
7. The customer receives a notification.
8. The customer accepts or rejects the quote.
9. If accepted, the project continues with tracking, messaging, and bon de commande generation.

## 4.2 Request Lifecycle

You can describe the request states like this:

- `pending`
- `reviewing`
- `quoted`
- `accepted`
- `rejected`
- `inProduction`
- `delivered`
- `cancelled`

This is based on:
[quote_request.dart](C:/apps/inwin_app_v3/inwin_app/lib/core/models/quote_request.dart)

## 4.3 Notification Workflow

The app supports automatic notifications through Firebase Cloud Messaging and Cloud Functions.

### Real notification logic

- when a new request is created, admins are notified
- when a request status changes, the customer is notified
- when a new message is sent, the other party is notified

Based on:
[index.ts](C:/apps/inwin_app_v3/inwin_app/functions/src/index.ts)

## 4.4 Messaging Workflow

Each project contains a message thread linked to the request.

This allows:

- customer-admin communication
- message history
- project follow-up inside the same request context

## 4.5 PDF Workflow

After quote acceptance, the app can generate a bon de commande PDF.

This is an important implemented feature, so it should appear clearly in Chapters 4 and 5.

Based on:

- [project_detail_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/projects/presentation/screens/project_detail_screen.dart)
- [bon_commande_service.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/bon_commande/services/bon_commande_service.dart)

## Chapter 5: Execution and Interfaces

This chapter must describe the interfaces and features that really exist in the app.

## 5.1 Authentication Module

You can present:

- registration interface
- login interface
- email verification
- role-based redirection

Based on:

- [register_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/auth/presentation/screens/register_screen.dart)
- [login_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/auth/presentation/screens/login_screen.dart)
- [email_verification_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/auth/presentation/screens/email_verification_screen.dart)

## 5.2 Customer Features

### Home interface

The home screen adapts to the user type:

- B2B users see gifts and corporate events
- B2C users see event flow only

Based on:
[home_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/home/presentation/screens/home_screen.dart)

### Gifts module

For B2B users, the app includes:

- gift category browsing
- gift customization request
- logo upload
- logo positioning

Based on:

- [gifts_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/gifts/presentation/screens/gifts_screen.dart)
- [gift_configurator_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/gifts/presentation/screens/gift_configurator_screen.dart)
- [logo_positioner.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/gifts/presentation/widgets/logo_positioner.dart)

### Events module

The app includes:

- B2B event request flow
- B2C event request flow

Based on:

- [events_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/events/presentation/screens/events_screen.dart)
- [event_form_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/events/presentation/screens/event_form_screen.dart)
- [b2c_event_form_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/events/presentation/screens/b2c_event_form_screen.dart)

### Project tracking

The user can:

- see project status
- see request details
- accept or reject a quote
- download the bon de commande
- exchange messages

Based on:

- [projects_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/projects/presentation/screens/projects_screen.dart)
- [project_detail_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/projects/presentation/screens/project_detail_screen.dart)

### Profile management

The user can manage profile information from the profile screen.

Based on:
[profile_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/profile/presentation/screens/profile_screen.dart)

## 5.3 Admin Features

The admin side should be described clearly because it is one of the strongest implemented parts of the app.

### Admin request list

The admin can:

- see all requests
- filter by status
- access details

Based on:
[admin_requests_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/admin/presentation/screens/admin_requests_screen.dart)

### Admin request detail

The admin can:

- review customer data
- inspect attachments
- set supplier price
- prepare quote
- update request status
- chat with the customer

Based on:
[admin_request_detail_screen.dart](C:/apps/inwin_app_v3/inwin_app/lib/features/admin/presentation/screens/admin_request_detail_screen.dart)

## 5.4 Backend Integration

This section should stay practical and concise.

### Firebase Authentication

Used for:

- account creation
- login
- email verification

### Cloud Firestore

Used for:

- storing users
- storing requests
- storing messages

### Firebase Storage

Used for:

- logo upload
- attachment upload

### Firebase Cloud Messaging and Cloud Functions

Used for:

- sending notifications
- reacting automatically to request creation
- reacting automatically to status changes
- reacting automatically to new messages

## 5.5 Claims To Avoid

Do not write that the app already has:

- integrated online payment
- separate provider accounts
- advanced logistics management
- AI recommendation engine
- fully implemented review/rating system

If needed, call them:

- future improvements
- possible extensions

## 5.6 Safe Final Summary Sentence

You can use this sentence in Chapter 5:

> The implementation of INWIN resulted in a Flutter and Firebase mobile application that supports user authentication, event and corporate gift request submission, quotation management, real-time messaging, notification handling, and project tracking through a centralized digital workflow.

