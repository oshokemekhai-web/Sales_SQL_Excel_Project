# End-to-End Sales Data Modeling & Analytics Project (SQL Server + Excel)

## 1. Project Overview
This project demonstrates a complete business intelligence workflow: taking raw, unlinked Excel tables (`Fact_sales$`, `Dim_products$`, and `Customers_id$`), cleaning duplicate records, building a normalized **Star Schema** in **SQL Server Management Studio (SSMS)**, running exploratory SQL analytics, and connecting the live relational data model to **Microsoft Excel** for interactive PivotTable and PivotChart reporting.

---

## 2. Database Schema & Data Cleaning (SQL Server)

### A. Identifying & Removing Duplicate Records
During data inspection, duplicate records were detected in the imported Excel tables (e.g., each product in `Dim_products$` appeared 4 times). Before enforcing Primary Keys, duplicate records were removed while preserving table schemas:

```sql
-- Check for duplicate Primary Keys
SELECT ProdID, COUNT(*) AS Record_Count
FROM Dim_products$
GROUP BY ProdID
HAVING COUNT(*) > 1

-- Deduplicate Dim_products$ using SELECT DISTINCT + TRUNCATE + INSERT
SELECT DISTINCT * INTO Temp_Products FROM Dim_products$
TRUNCATE TABLE Dim_products$
INSERT INTO Dim_products$ SELECT * FROM Temp_Products
DROP TABLE Temp_Products

-- Deduplicate Fact_sales$
SELECT DISTINCT * INTO Temp_Sales FROM Fact_sales$
TRUNCATE TABLE Fact_sales$
INSERT INTO Fact_sales$ SELECT * FROM Temp_Sales
DROP TABLE Temp_Sales

-- Deduplicate Customers_id$
SELECT DISTINCT * INTO temp_customer_id FROM Customers_id$
TRUNCATE TABLE Customers_id$
INSERT INTO Customers_id$ SELECT * FROM temp_customer_id
DROP TABLE temp_customer_id
```

### B. Star Schema Relationships (Primary & Foreign Keys)
To enable relational modeling across SQL Server and Excel's Data Model:
* **Dimension Tables (1-Side):**
  * `Dim_products$` — Primary Key set on `ProdID` (8 unique products).
  * `Customers_id$` — Primary Key set on `CustID`.
* **Fact Table (Many-Side):**
  * `Fact_sales$` — Linked to both dimension tables via Foreign Key constraints:

```sql
ALTER TABLE Fact_sales$
ADD 
    CONSTRAINT FK_Sales_Products FOREIGN KEY (ProdID) REFERENCES Dim_products$(ProdID),
    CONSTRAINT FK_Sales_Customer FOREIGN KEY (CustID) REFERENCES Customers_id$(CustID)
```

---

## 3. Core Business KPIs & Exploratory SQL Analysis

### A. Executive KPI Summary & Discount Impact
```sql
SELECT 
    COUNT(OrderID) AS Total_Orders, 
    SUM(Quantity) AS Total_Units_Sold, 
    SUM([Gross Revenue]) AS Total_Gross_Revenue, 
    SUM([Net Revenue]) AS Total_Net_Revenue,
    SUM([Gross Revenue] - [Net Revenue]) AS Total_Discount_Lost,
    ROUND((SUM([Gross Revenue] - [Net Revenue]) / SUM([Gross Revenue])) * 100, 2) AS Discount_Percentage
FROM Fact_sales$
```

#### Key Findings from the Data Model:
| KPI Metric | Value |
| :--- | :--- |
| **Total Orders** | **60** |
| **Total Units Sold** | **132** |
| **Total Gross Revenue** | **14,019.10** |
| **Total Net Revenue** | **13,495.88** |
| **Total Discount Lost** | **523.22** |
| **Overall Discount Rate** | **3.73%** |

### B. Product Performance (`JOIN` + `GROUP BY`)
```sql
SELECT 
    p.Product_Name, 
    SUM(f.[Net Revenue]) AS Revenue
FROM Fact_sales$ f
JOIN Dim_products$ p ON f.ProdID = p.ProdID
GROUP BY p.Product_Name
ORDER BY Revenue DESC
```
* **Top-Performing Product:** **DataMaster Pro** leads all products by a wide margin at **7,619.75** (~56.5% of total net revenue), followed by **SQL Studio Suite** (**1,732.38**) and **Dashboard Kit** (**1,257.75**).

### C. Regional & Segment Breakdown
* **Top Region:** **Asia-Pacific** generates the highest net revenue (**6,753.45**, ~50.0% of total revenue), followed by **Europe** (**3,999.19**), **North America** (**1,931.82**), and **LATAM** (**811.42**).
* **Top Customer Segment:** **SME** leads net revenue at **5,677.48**, followed by **Corporate** (**4,231.22**) and **Individual** (**3,587.18**).

### D. Monthly Trend Analysis (`MONTH()` + `ORDER BY`)
```sql
SELECT 
    MONTH(OrderDate) AS MonthNo, 
    SUM([Net Revenue]) AS Monthly_Revenue
FROM Fact_sales$
GROUP BY MONTH(OrderDate)
ORDER BY MonthNo ASC;
```
* **Peak Revenue Month:** **November** recorded the highest net revenue (**2,266.40**), followed by **May** (**1,631.90**) and **June** (**1,528.41**).

---

## 4. Excel Dashboard (Final Output)

The finished dashboard is built in Excel and connected live to the SQL Server star schema (`(local)\SQLEXPRESS` → `Merge` database) through the Excel Data Model. The PivotTables read directly from the database, so a refresh pulls the latest data with no copying or pasting.
<img width="1542" height="555" alt="Screenshot 2026-11-22 154607" src="https://github.com/user-attachments/assets/3a6181a9-6306-4b24-ad95-ccbb0e4de213" />


### A. KPI Summary
| KPI | Value |
| :--- | :--- |
| **Total Orders** | **60** |
| **Total Units Sold** | **132** |
| **Gross Revenue** | **14,019.10** |
| **Net Revenue** | **13,495.88** |
| **Discount Lost** | **523.22 (3.73%)** |

### B. Dashboard Visuals
| Chart | Type | What it shows |
| :--- | :--- | :--- |
| Revenue by Month | Line | Net revenue trend from January to December |
| Revenue by Location | Column | Net revenue by region |
| Revenue by Product | Bar | Net revenue for each of the 8 products |
| Revenue by Audience | Doughnut | Share of net revenue by customer segment |
| No of Order per Month | Line | Number of orders placed each month |
| Quantity Sold per Month | Line | Units sold each month |

### C. Interactivity
* A **Segment slicer** (Corporate, Individual, SME) is linked through **Report Connections** to the dashboard PivotTables, so one click filters the charts and KPIs by customer segment.
* All visuals come from PivotTables built on the related SQL tables, so product, customer and region fields filter each other correctly through the foreign keys.

### D. Key Insights
* **Product concentration:** DataMaster Pro brings in **7,619.75**, about **56%** of net revenue. The business depends heavily on one product.
* **Regional strength:** Asia-Pacific produces **6,753.45** (about **50%**), more than Europe, North America and LATAM. LATAM is the weakest region at **811.42**.
* **Segment mix:** SME customers lead with **5,677.48**, ahead of Corporate (**4,231.22**) and Individual (**3,587.18**).
* **Seasonality:** November is the peak month (**2,266.40**). January is the lowest (**361.48**).
* **Volume vs value:** July sold the most units (**23**) but not the most revenue, because most of those sales were lower-priced products.
* **Discounts:** Discounts cost **523.22**, or **3.73%** of gross revenue. That is a modest amount, but worth tracking as volume grows.

### E. Recommendations
1. Reduce dependence on DataMaster Pro by bundling or cross-selling SQL Studio Suite and Dashboard Kit with it.
2. Investigate LATAM and North America performance with targeted campaigns, using Asia-Pacific as the benchmark.
3. Plan promotions and stock around the November peak, and test early-year offers to lift January sales.
4. Review discount rules so that discounts go to orders that grow volume rather than to orders that would sell anyway.

### F. Skills Demonstrated
* **SQL Server:** duplicate detection (`GROUP BY` / `HAVING`), deduplication (`SELECT DISTINCT INTO`, `TRUNCATE`, `INSERT`), primary and foreign key constraints, `JOIN`, aggregate and date functions.
* **Data modelling:** turning unlinked flat tables into a star schema with one fact table and two dimension tables.
* **Excel:** live connection to SQL Server, Data Model, PivotTables, PivotCharts, slicers with report connections, dashboard layout.
