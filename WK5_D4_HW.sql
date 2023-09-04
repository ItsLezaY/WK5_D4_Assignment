------------------------SQL Procedures and Functions Assignment------------------------

-- 1. EXTRA CREDIT: Create a procedure that adds a late fee to any customer who returned 
-- their rental after 7 days.
-- Use the payment and rental tables. Create a stored function that you call inside your procedure. 
-- The function will calculate the late fee amount based on how many days late they returned 
-- their rental.

CREATE OR REPLACE PROCEDURE late_fee(
    customer_id INT,
    late_payment INT,
    late_fee_amount DECIMAL(5,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE payment
    SET amount = amount + late_fee_amount
    WHERE customer_id = customer_id AND payment_id = late_payment;
    COMMIT;
END;
$$;

-- ALTER TABLE payment
-- DROP COLUMN late_fee;

-- DROP PROCEDURE IF EXISTS late_fee(integer, integer, numeric);


CREATE OR REPLACE PROCEDURE apply_late_fee(
    late_fee_amount DECIMAL(5,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    ALTER TABLE payment
    ADD COLUMN late_fee NUMERIC(6,2),
    ADD COLUMN late_total NUMERIC(6,2);
    UPDATE payment
    SET late_fee = CASE
        WHEN rental.return_date < current_date - 7 THEN late_fee_amount * (current_date - rental.return_date)
        ELSE 0.00
    END
    FROM rental
    WHERE payment.rental_id = rental.rental_id
    AND rental.return_date < current_date - 7;
    UPDATE payment
    SET late_total = amount + late_fee
    WHERE rental_id IN (
        SELECT rental_id
        FROM rental
        WHERE return_date - rental_date > INTERVAL '7 Days'
    );

    COMMIT;
END;
$$;


CALL apply_late_fee(5.00);


-- 2. Add a new column in the customer table for Platinum Member. This can be a boolean.
-- Platinum Members are any customers who have spent over $200. 
-- Create a procedure that updates the Platinum Member column to True for any customer 
-- who has spent over $200 and False for any customer who has spent less than $200.
-- Use the payment and customer table.

ALTER TABLE customer
ADD COLUMN platinum_member BOOLEAN;

-- ALTER TABLE customer
-- DROP COLUMN platinum_member;

CREATE OR REPLACE PROCEDURE platinum_member_check()
AS $$
BEGIN
    UPDATE customer
    SET platinum_member = TRUE
    WHERE customer.customer_id IN (
        SELECT DISTINCT customer.customer_id
        FROM customer
        JOIN payment ON customer.customer_id = payment.customer_id
        GROUP BY customer.customer_id
        HAVING SUM(payment.amount) > 200
    );

    UPDATE customer
    SET platinum_member = FALSE
    WHERE platinum_member IS NULL;

    COMMIT;
END;
$$ 
LANGUAGE plpgsql;


CALL platinum_member_check();


SELECT * 
FROM customer
WHERE platinum_member = TRUE;



