USE ecommerce;

CREATE TABLE customers (
       customer_id VARCHAR(50),
       customer_unique_id VARCHAR(50),
       customer_zip_code_prefix INT,
       customer_city VARCHAR(100),
       customer_state VARCHAR(10)
);


SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM customers;

CREATE TABLE geolocation(
	geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,6),
    geolocation_lng DECIMAL(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)

);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM geolocation;

CREATE TABLE order_payments (
	order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(@id, @cat, @name_len, @desc_len, @photos, @weight, @len, @height, @width)

SET
product_id = @id,
product_category_name = NULLIF(TRIM(@cat),''),

product_name_length = CASE 
    WHEN TRIM(@name_len) REGEXP '^[0-9]+$' THEN @name_len 
    ELSE NULL 
END,

product_description_length = CASE 
    WHEN TRIM(@desc_len) REGEXP '^[0-9]+$' THEN @desc_len 
    ELSE NULL 
END,

product_photos_qty = CASE 
    WHEN TRIM(@photos) REGEXP '^[0-9]+$' THEN @photos 
    ELSE NULL 
END,

product_weight_g = CASE 
    WHEN TRIM(@weight) REGEXP '^[0-9]+$' THEN @weight 
    ELSE NULL 
END,

product_length_cm = CASE 
    WHEN TRIM(@len) REGEXP '^[0-9]+$' THEN @len 
    ELSE NULL 
END,

product_height_cm = CASE 
    WHEN TRIM(@height) REGEXP '^[0-9]+$' THEN @height 
    ELSE NULL 
END,

product_width_cm = CASE 
    WHEN TRIM(@width) REGEXP '^[0-9]+$' THEN @width 
    ELSE NULL 
END;

SELECT count(*) FROM products;

CREATE TABLE sellers(
	seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)

);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(@id, @zip, @city, @state)

SET
seller_id = @id,

-- ZIP fix (date -> number)
seller_zip_code_prefix = CASE 
    WHEN TRIM(@zip) REGEXP '^[0-9]+$' THEN @zip
    ELSE CAST(SUBSTRING_INDEX(@zip, '-', 1) AS UNSIGNED)
END,

seller_city = TRIM(@city),
seller_state = TRIM(@state);

CREATE TABLE category_translation(
	product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
    
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SELECT COUNT(*) FROM orders;

CREATE TABLE order_reviews (
	review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message LONGTEXT

);

SET GLOBAL local_infile = 1;

ALTER TABLE order_reviews
MODIFY review_comment_title LONGTEXT;

CREATE TABLE order_reviews (
	review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT

);

SELECT COUNT(*) FROM order_reviews;

ALTER TABLE customers
ADD PRIMARY KEY (customer_id);
DESCRIBE customers;

ALTER TABLE orders
ADD PRIMARY KEY (order_id);


ALTER TABLE orders
MODIFY order_id VARCHAR(50);

ALTER TABLE customers
MODIFY customer_id VARCHAR(50);

ALTER TABLE orders
MODIFY customer_id VARCHAR(50);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);


ALTER TABLE order_items
CHANGE COLUMN ï»¿order_id order_id VARCHAR(50);

DESCRIBE order_items;
ALTER TABLE order_items
MODIFY order_id VARCHAR(50),
MODIFY product_id VARCHAR(50),
MODIFY seller_id VARCHAR(50);

ALTER TABLE order_items
ADD CONSTRAINT fk_orders_items_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE products
ADD PRIMARY KEY (product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE sellers
ADD PRIMARY KEY (seller_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_item_sellers
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

ALTER TABLE order_payments
ADD CONSTRAINT fk_payments_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_reviews
MODIFY order_id VARCHAR(50);

ALTER TABLE order_reviews
ADD CONSTRAINT fk_reviews_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

SHOW CREATE TABLE orders;
SHOW CREATE TABLE order_items;
SHOW CREATE TABLE order_reviews;
SHOW CREATE TABLE order_payments;

desc orders;

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Weekday vs Weekend total Sales
SELECT
	CASE
		WHEN
			dayofweek(o.order_purchase_timestamp) IN (1,7) THEN "Weekend"
            ELSE "Weekday"
	END AS day_type,
    SUM(p.payment_value) AS total_sales,
    COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o JOIN order_payments p
    ON o.order_id = p.order_id
    GROUP BY day_type;
    
        -- Weekday	12367988.08	76593
        -- Weekend	3640884.04	22847



-- 2) How many order have review score = 5 AND payment_type = credit card
SELECT COUNT(DISTINCT r.order_id) AS total_orders
FROM order_reviews r
JOIN order_payments p
ON r.order_id = p.order_id
WHERE r.review_score = 5
AND p.payment_type = 'credit_card';

-- 43981

-- 3) Average delivery day for pet shop 
SELECT
	AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_days
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_category_name = 'pet_shop';
    
    -- 11.1653

-- 4) Average product_price and average_payment value for Sao Paulo city

SELECT
	AVG(oi.price) AS avg_price,
    AVG(op.payment_value) AS avg_payment
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN order_payments op ON op.order_id = o.order_id
    WHERE c.customer_city = 'sao paulo';
    
    -- avg_price             avg_payment
    -- 108.02874610003946	152.765114
    
    
-- 5) Relation between review_score and delivery_days
SELECT 
r.review_score,
AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) as avg_shipping_days
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;

/* 1	21.2519
2	    16.6059
3	    14.2043
4	    12.2531
5	    10.6254
*/

SELECT
c.customer_city,
SUM(oi.price) AS total_revenue FROM customers c        
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_city
ORDER BY total_revenue DESC
LIMIT 5;

-- Top Cities by Revenue
/* Sao Paulo	1914924.5399997574
Rio De Janeiro	992538.8600000334
Belo Horizonte	355611.13000000076
Brasilia	    301920.24999999773
Curitiba	    211738.05999999685 */


SELECT
p.product_category_name,
COUNT(*) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_orders DESC;

-- Best selling Categories
/* cama_mesa_banho	11115
beleza_saude	9670
esporte_lazer	8641
moveis_decoracao	8334
informatica_acessorios	7827
utilidades_domesticas	6964
relogios_presentes	5991
telefonia	4545
ferramentas_jardim	4347
automotivo	4235
brinquedos	4117
cool_stuff	3796
perfumaria	3419
bebes	3065
eletronicos	2767
papelaria	2517
fashion_bolsas_e_acessorios	2031
pet_shop	1947
moveis_escritorio	1691
Unknown	1603
consoles_games	1137
malas_acessorios	1092
construcao_ferramentas_construcao	929
eletrodomesticos	771
instrumentos_musicais	680
eletroportateis	679
casa_construcao	604
livros_interesse_geral	553
alimentos	510
moveis_sala	503
casa_conforto	434
bebidas	379
audio	364
market_place	311
construcao_ferramentas_iluminacao	304
climatizacao	297
moveis_cozinha_area_de_servico_jantar_e_jardim	281
alimentos_bebidas	278
industria_comercio_e_negocios	268
livros_tecnicos	267
telefonia_fixa	264
fashion_calcados	262
eletrodomesticos_2	238
construcao_ferramentas_jardim	238
agro_industria_e_comercio	212
artes	209
pcs	203
sinalizacao_e_seguranca	199
construcao_ferramentas_seguranca	194
artigos_de_natal	153
fashion_roupa_masculina	132
fashion_underwear_e_moda_praia	131
moveis_quarto	109
construcao_ferramentas_ferramentas	103
tablets_impressao_imagem	83
portateis_casa_forno_e_cafe	76
cine_foto	72
dvds_blu_ray	64
livros_importados	60
fashion_roupa_feminina	48
artigos_de_festas	43
fraldas_higiene	39
musica	38
moveis_colchao_e_estofado	38
flores	33
fashion_esporte	30
casa_conforto_2	30
artes_e_artesanato	24
portateis_cozinha_e_preparadores_de_alimentos	15
la_cuisine	14
cds_dvds_musicais	14
pc_gamer	9
fashion_roupa_infanto_juvenil	8
seguros_e_servicos	2 */













