# SpiderPOS Server Architecture & Coding Rules

## 1. Strict File Size Limit
- Hard limit: **140–160 lines per file**.
- When logic expands, decompose into dedicated handlers, services, or helpers. Never let a file bloat.

## 2. No Dummy Data & No Fallbacks
- Strictly forbidden: mock arrays (e.g., mock users/products), hardcoded mock payloads, fake fallback objects.
- Real database/service data only. Fail fast or return precise error responses.

## 3. Pure Logic Only (Zero Bloat)
- Write only code required for actual business and reporting requirements.
- Avoid speculative abstractions, unnecessary wrapper classes, and unused boilerplate.

## 4. Heavy Reporting Project Structure
- Architecture must support heavy aggregations, filtering, and streaming:
  - `lib/config/`: Runtime configurations, DB connections.
  - `lib/modules/<feature>/`: Feature-specific logic (e.g. sales, inventory, accounting).
    - `<feature>_controller.dart`: HTTP request/response parsing (Shelf).
    - `<feature>_service.dart`: Aggregations, calculations, heavy data processing.
    - `<feature>_repository.dart`: Direct Firestore/Postgres query logic.
  - `lib/services/`: Shared cross-cutting services (Firebase, Postgres, Cache).

## 5. Comment Hygiene
- No redundant, obvious, or decorative comments.
- Code must be self-documenting. Comments permitted only for non-obvious algorithmic decisions.

## 6. System Mission: Firebase -> PostgreSQL Migration
- **Core Objective**: Migrate operational reporting off Firestore into PostgreSQL for high-speed aggregations and analytical queries.
- **Reporting Rule**: All heavy reports query PostgreSQL directly. Do not run heavy analytical aggregations against Firestore.
- **Schema Discovery Pattern**:
  - Sample 10 real documents per collection into JSON for schema analysis before writing PostgreSQL DDL migrations.
  - Design relational normalization, JSONB fields where appropriate, and index strategy based on real document structures.
