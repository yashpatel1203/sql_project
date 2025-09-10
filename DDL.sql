/*
  Housing Rental Database Management System
*/

/* Create the database */
DROP SCHEMA IF EXISTS housingrentalsystem;
CREATE SCHEMA housingrentalsystem;

/* Switch to the RentalManagementSystem database */
USE housingrentalsystem;

-- Create Tables
CREATE TABLE landlord (
    landlord_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tenant (
    tenant_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    income DECIMAL(10,2) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE property (
    property_id INT AUTO_INCREMENT PRIMARY KEY,
    landlord_id INT NOT NULL,
    rental_price DECIMAL(10,2) NOT NULL,
    is_affordable_housing BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (landlord_id) REFERENCES Landlord(landlord_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE location (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    province VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE lease_Agreement (
    lease_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    property_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    FOREIGN KEY (tenant_id) REFERENCES Tenant(tenant_id),
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    lease_id INT NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    FOREIGN KEY (lease_id) REFERENCES Lease_Agreement(lease_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rental_application (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    property_id INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    application_date DATE NOT NULL,
    FOREIGN KEY (tenant_id) REFERENCES Tenant(tenant_id),
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inspection (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    inspector_name VARCHAR(100) NOT NULL,
    inspection_date DATE NOT NULL,
    comments TEXT,
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE government_subsidy (
    subsidy_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    approval_date DATE NOT NULL,
    FOREIGN KEY (tenant_id) REFERENCES Tenant(tenant_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE property_Manager (
    manager_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE maintenance_request (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    tenant_id INT NOT NULL,
    request_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (property_id) REFERENCES Property(property_id),
    FOREIGN KEY (tenant_id) REFERENCES Tenant(tenant_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE maintenance_issues (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    issue_description TEXT NOT NULL,
    FOREIGN KEY (request_id) REFERENCES Maintenance_Request(request_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-------------------- Views --------------------------------------------

CREATE VIEW LeasePaymentSummary AS
WITH PaymentSummary AS (
    SELECT
        lease_id,
        COUNT(payment_id) AS payments_made,
        COALESCE(SUM(amount_paid), 0) AS total_paid,
        MAX(payment_date) AS last_payment_date
    FROM Payment
    GROUP BY lease_id
)
SELECT
    l.lease_id,
    l.property_id,
    l.tenant_id,
    l.start_date,
    CONCAT(t.first_name, ' ', t.last_name) AS tenant_name,
    l.monthly_rent,
    COALESCE(ps.payments_made, 0) AS payments_made,
    COALESCE(ps.total_paid, 0) AS total_paid,
    ps.last_payment_date,
    COALESCE(
        ROUND(ps.total_paid / NULLIF(l.monthly_rent, 0), 0),
        0
    ) AS months_covered
FROM Lease_Agreement l
JOIN Tenant t ON l.tenant_id = t.tenant_id
LEFT JOIN PaymentSummary ps ON l.lease_id = ps.lease_id;

-------------------- Functions --------------------------------------------
DELIMITER //
CREATE FUNCTION CalculateTotalRentPaid(tenant_id INT) 
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC
DETERMINISTIC SQL SECURITY INVOKER
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT IFNULL(SUM(p.amount_paid),0) INTO total
    FROM Payment p
    JOIN Lease_Agreement la ON p.lease_id = la.lease_id
    WHERE la.tenant_id = tenant_id;
    RETURN total;
END;
// DELIMITER ;

DELIMITER //
CREATE FUNCTION IsConsistentPayer(tenant_id INT) 
RETURNS VARCHAR(3)
NOT DETERMINISTIC
DETERMINISTIC SQL SECURITY INVOKER
BEGIN
    DECLARE result VARCHAR(3);
    SELECT IF(COUNT(DISTINCT MONTH(payment_date)) = TIMESTAMPDIFF(MONTH, MIN(payment_date), MAX(payment_date))+ 1, 'Yes', 'No') INTO result
    FROM Payment p
    JOIN Lease_Agreement la ON p.lease_id = la.lease_id
    WHERE la.tenant_id = tenant_id;
    RETURN result;
END;
// DELIMITER ;