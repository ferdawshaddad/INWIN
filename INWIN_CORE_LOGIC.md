# INWIN Core Logic & Architecture

This document serves as the high-level knowledge base for the INWIN Flutter application.

## 1. Project Overview
INWIN is a "From Idea to Realization" platform for Corporate Gifts (B2B) and Events (B2B/B2C).
- **Primary Tech**: Flutter, Firebase (Auth, Firestore, Storage), Riverpod (State Mgmt), GoRouter.
- **Brand Identity**: Navy Blue (`0xFF1A237E`), Gold (`0xFFD4A853`), and Premium UI (Rounded corners, interactive chips).

## 2. User Roles & Logic
- **Admin**: Accesses `/admin`. Can view all requests, send quotes (set prices), and chat with clients.
- **Customer (B2B)**: Accesses `/gifts` and `/events`. clientType: `b2b`.
- **Customer (B2C)**: Accesses `/events` ONLY. clientType: `b2c`. Restricted from `/gifts` via `app_router.dart` redirects.

## 3. Key Navigation (GoRouter)
- `/home`: Main gateway with "Cadeaux d'entreprise" and "Événements" cards.
- `/gifts/:category`: Interactive 3D/Visual configurator for items (Pens, Tech, etc.).
- `/events/b2c`: Premium event form with interactive chips for "Vibes" and Color Palettes.
- `/events/:type`: B2B Corporate event form.
- `/projects/:id`: Real-time chat, status tracking, and PDF "Bon de Commande" generation.

## 4. Firestore Data Schema
### `requests` collection
- `userId`: UID of the creator.
- `type`: `gift` | `event`.
- `status`: `pending`, `reviewing`, `quoted`, `accepted`, `inProduction`, `delivered`, `cancelled`.
- `details`: Map containing form data.
  - *B2C Events*: `ambiance`, `services`, `colors` (int list), `venueType`.
  - *Gifts*: `category`, `material`, `logoPosition`.
- `quotedPrice`: Double (set by Admin).
- `attachmentUrls`: List of strings (images/logos).

## 5. Quote to Order Flow
1. **Request**: User submits form -> status: `pending`.
2. **Review**: Admin reviews -> status: `reviewing`.
3. **Quote**: Admin sets `quotedPrice` -> status: `quoted`.
4. **Acceptance**: User accepts + Terms & Conditions -> status: `accepted`.
5. **PDF**: `BonCommandeService` generates a legal PDF (50% deposit logic) for the user to print/sign.

## 6. Theme & UI Components
- **Colors**: Defined in `lib/core/constants/app_theme.dart`.
- **Status Badges**: `lib/core/widgets/status_badge.dart` maps Firestore status to UI colors.
- **Form UI**: Uses `ChoiceChip` and `FilterChip` instead of dropdowns for a premium feel.
