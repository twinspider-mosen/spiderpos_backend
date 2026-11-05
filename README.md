# SpiderPOS Server

High-performance Dart reporting server migrating Firebase operational data into PostgreSQL for fast aggregations and analytical queries.

---

## 1. Prerequisites

- **Dart SDK**: `^3.8.1`
- **PostgreSQL**: `16` (Running on port `5432`)
- **Firebase Service Account**: Service account JSON at `lib/credentials/break-edge.json`

---

## 2. Configuration (`.env`)

Create or update `.env` in root:

```env
# Firebase
GOOGLE_APPLICATION_CREDENTIALS=lib/credentials/break-edge.json
FIREBASE_PROJECT_ID=break-edge

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=spiderpos
DB_USER=postgres
DB_PASSWORD=postgres
PORT=8080
```

---

## 3. Database Setup

### Create Database
```bash
createdb -U postgres spiderpos
```

*If password forgotten on macOS:*
```bash
sudo -u postgres /Library/PostgreSQL/16/bin/psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
sudo -u postgres /Library/PostgreSQL/16/bin/psql -c "CREATE DATABASE spiderpos;"
```

### Run Migrations
Executes all SQL schemas in `database/` sequentially:
```bash
dart run bin/migrate.dart
```

---

## 4. Run Server

```bash
dart run bin/server.dart
```
Default URL: `http://localhost:8080`

---

## 5. API Reference

### PostgreSQL Table Endpoints (`/api/<table_name>`)
Full CRUD for all 15 relational tables:

| Resource | List / Create | Get / Update / Delete |
|---|---|---|
| Invoices | `GET/POST /api/invoices` | `GET/PUT/DELETE /api/invoices/<id>` |
| Invoice Items | `GET/POST /api/invoice-items` | `GET/PUT/DELETE /api/invoice-items/<id>` |
| Products | `GET/POST /api/products` | `GET/PUT/DELETE /api/products/<id>` |
| Customers | `GET/POST /api/customers` | `GET/PUT/DELETE /api/customers/<id>` |
| Payments | `GET/POST /api/payments` | `GET/PUT/DELETE /api/payments/<id>` |
| Categories | `GET/POST /api/categories` | `GET/PUT/DELETE /api/categories/<id>` |
| Warehouses | `GET/POST /api/warehouses` | `GET/PUT/DELETE /api/warehouses/<id>` |
| Employees | `GET/POST /api/employees` | `GET/PUT/DELETE /api/employees/<id>` |
| Salaries | `GET/POST /api/salaries` | `GET/PUT/DELETE /api/salaries/<id>` |
| Reports | `GET/POST /api/invoice-reports` | `GET/PUT/DELETE /api/invoice-reports/<id>` |
| Stock Transfers | `GET/POST /api/stock-transfers`| `GET/PUT/DELETE /api/stock-transfers/<id>` |
| Product Stocks | `GET/POST /api/product-stocks` | `GET/PUT/DELETE /api/product-stocks/<id>` |
| Stores | `GET/POST /api/stores` | `GET/PUT/DELETE /api/stores/<id>` |
| Users | `GET/POST /api/users` | `GET/PUT/DELETE /api/users/<id>` |
| App Configs | `GET/POST /api/app-configs` | `GET/PUT/DELETE /api/app-configs/<id>` |

**Query Parameters (`GET` List):**
- `limit`: Max records (e.g. `?limit=50`, default 100).
- `offset`: Pagination offset (e.g. `?offset=100`).
- `store_id`: Multi-tenant filtering (e.g. `?store_id=DPOmE2taGzQc2pjnE3E6kLJcQBp2`).
- `order_by`: Sort column (e.g. `?order_by=product_price`).
- `desc`: Descending sort boolean (e.g. `?desc=true`).

*List all tables metadata:*
```bash
curl http://localhost:8080/api/tables
```

---

### Firebase Endpoints (`/api/collections`)
Direct Firestore reads during transition:

- `GET /api/collections`: List all Firestore collection names.
- `GET /api/collections/<name>?limit=20`: Fetch raw collection documents.
- `GET /api/collections/<name>/<id>`: Fetch single document.

---

## 6. Utilities & Testing

- **Export Firestore data to JSON**:
  ```bash
  dart run bin/export_samples.dart
  ```
- **Import JSON data into PostgreSQL tables**:
  ```bash
  dart run bin/import_samples.dart
  ```
- **Run tests**:
  ```bash
  dart test
  ```
- **Code validation**:
  ```bash
  dart analyze
  ```

---

## 7. Architecture Rules

Strict project limits enforced in `AGENTS.md`:
- Max 140–160 lines per file.
- Zero dummy data & zero fallback objects.
- All heavy analytical reports query PostgreSQL directly.
