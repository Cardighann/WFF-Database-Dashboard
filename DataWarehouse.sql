CREATE TABLE Carrier_Dimension (
        carrier_key                int                GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        carrier_id                int,
        carrier_name        varchar2(25),
        ship_mode                char(1),
        freight_rate        number(7, 2)
);


INSERT INTO Carrier_Dimension (
  carrier_id,
  carrier_name,
  ship_mode,
  freight_rate
)
Select
C_ID,
C_NAME,
C_SHIP_MODE,
C_FREIGHT_RATE
FROM WFF_CARRIER;


CREATE TABLE Customer_Dimension (
  customer_key        int                GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id        int,
  customer_name        varchar2(100),
  customer_bill_address        varchar2(200),
  customer_credit_limit        number(10, 2),
  customer_balance        number(10, 2)
);


INSERT INTO Customer_Dimension (
  customer_id,
  customer_name,
  customer_bill_address,
  customer_credit_limit,
  customer_balance
)
SELECT
CUST_NO,
CUST_NAME,
CUST_BILL_TO_ADDRESS,
CREDIT_LIMIT,
BALANCE
FROM WFF_CUSTOMER;


CREATE TABLE Calendar_Dimension (
  calendar_key        int        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_date                date,
  day_of_week        varchar2(20),
  day_of_month        int,
  calendar_month        varchar2(20),
  calendar_year        int
);


INSERT INTO Calendar_Dimension (
  full_date,
  day_of_week,
  day_of_month,
  calendar_month,
  calendar_year
)
SELECT DISTINCT
ORDER_DATE,
TRIM(TO_CHAR(ORDER_DATE, 'DAY')),
EXTRACT(DAY FROM ORDER_DATE),
TRIM(TO_CHAR(ORDER_DATE, 'Month')),
EXTRACT(YEAR FROM ORDER_DATE)
FROM WFF_ORDERS 
WHERE ORDER_DATE IS NOT NULL;


CREATE TABLE Product_Group_Dimension (
  product_group_key        int        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_group_number        int,
  product_group_name        varchar2(25),
  product_group_units_per_case        int,
  product_group_weight_per_case        int,
  product_group_freeze_time        int
);
INSERT INTO Product_Group_Dimension (
  product_group_number,
  product_group_name,
  product_group_units_per_case,
  product_group_weight_per_case,
  product_group_freeze_time
)
SELECT
GROUP_NO,
GROUP_DESC,
UNITS_PER_CASE,
WEIGHT_PER_CASE,
FREEZE_TIME
FROM WFF_PRODUCT_GROUP;


CREATE TABLE Product_Dimension (
  product_key        int        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_upc        int,
  product_name        varchar2(50),
  product_group        int        REFERENCES Product_Group_Dimension(product_group_key),
  product_msrp        number(18, 2),
  product_cost        number(18, 2)
);
INSERT INTO Product_Dimension (
  product_upc,
  product_name,
  product_group,
  product_msrp,
  product_cost
)
SELECT
  p.PROD_UPC,
  p.PROD_DESC,
  g.product_group_key,
  p.MSRP,
  p.COST
FROM WFF_PRODUCT p
JOIN Product_Group_Dimension g
  ON p.PROD_GROUP = g.product_group_number;


CREATE TABLE Order_Dimension (
  order_key        int        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_number        int,
  order_order_date                date,
  order_est_ship_date        date,
  order_act_ship_date        date,
  order_customer_key REFERENCES Customer_Dimension(customer_key),
  order_carrier_key REFERENCES Carrier_Dimension(carrier_key)
);
INSERT INTO Order_Dimension (
  order_number,
  order_order_date,
  order_est_ship_date,
  order_act_ship_date,
  order_customer_key,
  order_carrier_key
)
SELECT
o.ORDER_NO,
o.ORDER_DATE,
o.EST_SHIP_DATE,
o.ACTUAL_SHIP_DATE,
c.customer_key,
k.carrier_key
FROM WFF_ORDERS o
JOIN Customer_Dimension c
ON o.CUST_NO = c.customer_id
JOIN Carrier_Dimension k
ON o.C_ID = k.carrier_id;


CREATE TABLE Sales_Facts (
    sales_key      int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_key      int REFERENCES Order_Dimension(order_key),
    product_key    int REFERENCES Product_Dimension(product_key),
    customer_key   int REFERENCES Customer_Dimension(customer_key),
    calendar_key   int REFERENCES Calendar_Dimension(calendar_key),
    carrier_key    int REFERENCES Carrier_Dimension(carrier_key),
    quantity       int,
    sales_amount   number(18,2)
);
INSERT INTO Sales_Facts (
    order_key,
    product_key,
    customer_key,
    calendar_key,
    carrier_key,
    quantity,
    sales_amount
)
SELECT
    o.order_key,
    p.product_key,
    o.order_customer_key,
    d.calendar_key,
    o.order_carrier_key,
    ol.OL_QTY,
    ol.OL_QTY * p.product_msrp AS sales_amount
FROM WFF_ORDERLINE ol
JOIN Order_Dimension o
    ON ol.OL_ORDER_NO = o.order_number
JOIN Product_Dimension p
    ON ol.OL_UPC = p.product_upc
JOIN Calendar_Dimension d
    ON o.order_order_date = d.full_date; 
