# SpiderPOS Server Reporting API Endpoints

Base URL: `http://localhost:8080`

---

## 1. List Available Reports
Returns registry of all available reporting endpoints.

* **URL**: `/api/reports`
* **Method**: `GET`
* **Sample Call**:
  ```bash
  GET http://localhost:8080/api/reports
  ```

---

## 2. Product-Wise Profit & Loss (PnL) Report
Calculates item-level sales, returns, exchanges, purchase cost, profit, and summary totals with invoice discounts.

* **URL**: `/api/reports/product-pnl`
* **Method**: `GET`
* **Query Parameters**:
  | Param | Type | Required | Description | Example |
  | :--- | :--- | :--- | :--- | :--- |
  | `store_id` | `String` | No | Filter by store | `DPOmE2taGzQc2pjnE3E6kLJcQBp2` |
  | `warehouse_id` | `String` | No | Filter by warehouse | `YGnX1HuL4UqVC1KCUsWH` |
  | `category_id` | `String` | No | Filter by product category | `sECW0n4y5K8rXsxYdHfE` |
  | `product_id` | `String` | No | Filter by single product | `31s8szaq44NrFIaEDm1p` |
  | `from_date` | `String` | No | Start date (`YYYY-MM-DD`) | `2026-10-01` |
  | `to_date` | `String` | No | End date (`YYYY-MM-DD`) | `2026-11-05` |

* **Sample Calls**:
  ```bash
  # All time, all products
  GET http://localhost:8080/api/reports/product-pnl

  # Date range + store + warehouse
  GET http://localhost:8080/api/reports/product-pnl?store_id=DPOmE2taGzQc2pjnE3E6kLJcQBp2&warehouse_id=YGnX1HuL4UqVC1KCUsWH&from_date=2026-10-01&to_date=2026-11-05
  ```

* **Response Shape**:
  ```json
  {
    "filters": {
      "store_id": "...",
      "store_name": "Break Edge",
      "warehouse_id": "...",
      "warehouse_name": "Shop Glorious Mall",
      "from_date": "01 Oct 2026",
      "to_date": "05 Nov 2026"
    },
    "summary": {
      "gross_sale": 3897246.10,
      "total_returns": 220050.00,
      "total_discount": 8845.10,
      "net_sale": 3668351.00,
      "total_cost": 2445365.00,
      "net_profit": 1222986.00,
      "net_margin_percentage": 33.34,
      "total_sold_qty": 868.0,
      "total_return_qty": 33.0,
      "total_net_qty": 835.0,
      "total_products_count": 192
    },
    "products": [
      {
        "product_id": "31s8szaq44NrFIaEDm1p",
        "product_name": "TrackSuit [13]",
        "category_name": "Track Suit Gents",
        "purchase_price": 6500.00,
        "sale_price": 9638.89,
        "sold_qty": 18.0,
        "gross_sale": 173500.00,
        "return_qty": 1.0,
        "return_amount": 10000.00,
        "net_qty": 17.0,
        "quantity": 17.0,
        "net_sale": 163500.00,
        "total_cost": 110500.00,
        "gross_profit": 53000.00
      }
    ]
  }
  ```

---

## 3. Employee Commission Report
Calculates gross sales, returns, net sales, commission rate, and total commission payable per employee.

* **URL**: `/api/reports/employee-commission`
* **Method**: `GET`
* **Query Parameters**:
  | Param | Type | Required | Description | Example |
  | :--- | :--- | :--- | :--- | :--- |
  | `store_id` | `String` | No | Filter by store | `DPOmE2taGzQc2pjnE3E6kLJcQBp2` |
  | `warehouse_id` | `String` | No | Filter by warehouse | `YGnX1HuL4UqVC1KCUsWH` |
  | `employee_id` | `String` | No | Filter by specific staff | `vFYOIKWYT2xkxoEI7yBi` |
  | `from_date` | `String` | No | Start date (`YYYY-MM-DD`) | `2026-10-01` |
  | `to_date` | `String` | No | End date (`YYYY-MM-DD`) | `2026-11-05` |
  | `detailed` | `Boolean` | No | Return invoice list for employee | `true` |

* **Sample Calls**:
  ```bash
  # All employees summary
  GET http://localhost:8080/api/reports/employee-commission

  # Filtered by store and date range
  GET http://localhost:8080/api/reports/employee-commission?store_id=DPOmE2taGzQc2pjnE3E6kLJcQBp2&from_date=2026-10-01&to_date=2026-11-05

  # Detailed breakdown for single employee
  GET http://localhost:8080/api/reports/employee-commission?employee_id=vFYOIKWYT2xkxoEI7yBi&detailed=true
  ```

* **Response Shape**:
  ```json
  {
    "filters": {
      "store_id": "...",
      "store_name": "Break Edge",
      "from_date": "01 Oct 2026",
      "to_date": "05 Nov 2026"
    },
    "summary": {
      "total_employees": 18,
      "total_invoices": 1318,
      "gross_sales": 14786595.94,
      "total_returns": 51950.00,
      "net_sales": 14734645.94,
      "total_commission": 105643.66
    },
    "employees": [
      {
        "employee_id": "vFYOIKWYT2xkxoEI7yBi",
        "employee_name": "Faizan",
        "commission_percent": 1.0,
        "total_invoices": 146,
        "gross_sales": 2009875.00,
        "return_amount": 3600.00,
        "net_sales": 2006275.00,
        "total_commission": 20062.75
      }
    ],
    "invoices": [
      {
        "invoice_id": "...",
        "order_number": "SALE-00123",
        "order_type": "Sale",
        "created_at": "2026-10-15T14:32:00.000Z",
        "invoice_total": 4500.00,
        "commission_percent": 1.0,
        "commission_amount": 45.00
      }
    ]
  }
  ```

---

## 4. Frontend Dropdown & Filter Lookups
Use these endpoints to populate frontend filter dropdowns (stores, warehouses, employees, categories).

| Entity | Endpoint | Unpaginated Query |
| :--- | :--- | :--- |
| **Stores** | `/api/stores` | `GET /api/stores?limit=0` |
| **Warehouses** | `/api/warehouses` | `GET /api/warehouses?limit=0` |
| **Employees** | `/api/employees` | `GET /api/employees?limit=0` |
| **Categories** | `/api/categories` | `GET /api/categories?limit=0` |
| **Products** | `/api/products` | `GET /api/products?limit=100` |

---

## 5. Ready-to-Use Flutter API Client

```dart
class ReportingEndpoints {
  static const String baseUrl = 'http://localhost:8080';

  static String reportsList() => '$baseUrl/api/reports';

  static String productPnl({
    String? storeId,
    String? warehouseId,
    String? categoryId,
    String? productId,
    String? fromDate,
    String? toDate,
  }) {
    final query = <String, String>{
      if (storeId != null) 'store_id': storeId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (categoryId != null) 'category_id': categoryId,
      if (productId != null) 'product_id': productId,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
    };
    final uri = Uri.parse('$baseUrl/api/reports/product-pnl').replace(queryParameters: query);
    return uri.toString();
  }

  static String employeeCommission({
    String? storeId,
    String? warehouseId,
    String? employeeId,
    String? fromDate,
    String? toDate,
    bool detailed = false,
  }) {
    final query = <String, String>{
      if (storeId != null) 'store_id': storeId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (employeeId != null) 'employee_id': employeeId,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (detailed) 'detailed': 'true',
    };
    final uri = Uri.parse('$baseUrl/api/reports/employee-commission').replace(queryParameters: query);
    return uri.toString();
  }

  static String filterDropdown(String table) => '$baseUrl/api/$table?limit=0';
}
```
