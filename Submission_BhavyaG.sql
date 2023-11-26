/*

-- ----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-- ----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-- ----------------------------------------------------------------------------------------------------------------------------------

                                                         Queries
                                               
-- ----------------------------------------------------------------------------------------------------------------------------------

/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     
     Hint: For each state, count the number of customers.*/


USE vehdb;
	
SELECT
    State,
    COUNT(DISTINCT Customer_id) AS CustomerCount
FROM
    Customer_t
GROUP BY
    State
ORDER BY
    CustomerCount DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is quarter_number the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

WITH RatingNumbers AS (
    SELECT
        Customer_feedback,
        CASE
            WHEN Customer_feedback = 'Very Bad' THEN 1
            WHEN Customer_feedback = 'Bad' THEN 2
            WHEN Customer_feedback = 'Okay' THEN 3
            WHEN Customer_feedback = 'Good' THEN 4
            WHEN Customer_feedback = 'Very Good' THEN 5
            ELSE 0
        END AS RatingValue,
        QUARTER(Order_date) AS Quarter
    FROM
        Order_t
)
SELECT
    Quarter,
    AVG(RatingValue) AS AverageRating
FROM
    RatingNumbers
GROUP BY
    Quarter
ORDER BY
    Quarter;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
      
WITH cust_feed AS 
(
	SELECT 
		quarter_number,
		ROUND(SUM(CASE WHEN customer_feedback = 'very good' THEN 1 ELSE 0 END), 2) AS very_good,
		ROUND(SUM(CASE WHEN customer_feedback = 'good' THEN 1 ELSE 0 END), 2) AS good,
		ROUND(SUM(CASE WHEN customer_feedback = 'okay' THEN 1 ELSE 0 END), 2) AS okay,
		ROUND(SUM(CASE WHEN customer_feedback = 'bad' THEN 1 ELSE 0 END), 2) AS bad,
		ROUND(SUM(CASE WHEN customer_feedback = 'very bad' THEN 1 ELSE 0 END), 2) AS very_bad,
		ROUND(COUNT(customer_feedback), 2) AS total_feedback
	FROM 
		order_t
	GROUP BY 
		quarter_number
    ORDER BY 
		quarter_number DESC
)
   
SELECT 
	quarter_number,
    ROUND((very_good/total_feedback)*100, 2) AS very_good,
    ROUND((good/total_feedback)*100, 2) AS good,
    ROUND((okay/total_feedback)*100, 2) AS okay,
    ROUND((bad/total_feedback)*100, 2) AS bad,
    ROUND((very_bad/total_feedback)*100, 2) AS very_bad
FROM 
	cust_feed
GROUP BY 
	quarter_number
ORDER BY 
	quarter_number DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------

SELECT
	Quarter(Order_Date) AS Quarter,
	SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS VeryGood,
	SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Good,
	SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Okay,
	SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Bad,
	SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS VeryBad
FROM
	order_t
GROUP BY
	Quarter
ORDER BY
	Quarter DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT
	Vehicle_maker,
    COUNT(DISTINCT Product_id) AS ProductCount
FROM
    Product_t
GROUP BY
    Vehicle_maker
ORDER BY
    ProductCount DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

SELECT * FROM (
	SELECT 
		state, 
		vehicle_maker,
		COUNT(customer_id) AS total_customers,
    RANK() OVER (PARTITION BY state ORDER BY COUNT(customer_id) DESC) AS ranking
    FROM 
		product_t 
    JOIN order_t USING(product_id)
    JOIN customer_t USING(customer_id)
	GROUP BY 
		state, 
		vehicle_maker 
) AS preferred_vehicle
WHERE 
	ranking = 1
ORDER BY 
	total_customers DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT
    Quarter(Order_Date) AS Quarter,
    COUNT(Order_id) AS OrderCount
FROM
    Order_t
GROUP BY
    Quarter(Order_Date)
ORDER BY
    Quarter;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      
WITH QoQ AS 
(
	SELECT 
		quarter_number, 
        ROUND(SUM(quantity * (vehicle_price - ((discount / 100) * vehicle_price))), 0) AS revenue
	FROM 
		order_t
	GROUP BY 
		quarter_number)

SELECT 
	quarter_number, 
    revenue,
	ROUND(LAG(revenue) OVER(ORDER BY quarter_number), 2) AS previous_revenue,
	ROUND((revenue - LAG(revenue) OVER(ORDER BY quarter_number))/LAG(revenue) OVER(ORDER BY quarter_number), 2) AS qoq_perc_change
FROM QoQ;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT 
	quarter_number,
	ROUND(SUM(quantity*vehicle_price), 0) AS revenue,
    COUNT(order_id) AS total_order
FROM 
	order_t
GROUP BY 
	quarter_number
ORDER BY 
	quarter_number;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT 
	credit_card_type,
	ROUND(AVG(discount) * 100, 2) AS average_discount
FROM 
	order_t t1
INNER JOIN customer_t t2
	ON t1.customer_id = t2.customer_id
GROUP BY 
	credit_card_type
ORDER BY 
	average_discount DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

SELECT 
	quarter_number,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 0) AS average_shipping_time
FROM 
	order_t
GROUP BY 
	quarter_number
ORDER BY 
	quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
