/*
================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
================================================================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Transform, Load) process to 
  populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
  - Truncates Silver tables.
  - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  EXEC Silver.load_silver;
================================================================================
*/

create or alter procedure silver.load_silver as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	begin try

	set @batch_start_time = getdate();

		print '=====================================================================================';
		print 'loading Silver layer';
		print '=====================================================================================';

		print '-------------------------------------------------------------------------------------';
		print 'loading crm layer';
		print '-------------------------------------------------------------------------------------';



	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: silver.crm_cust_info'
	truncate table silver.crm_cust_info;
	print '>> inserting data into: silver.crm_cust_info'
	insert into silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname, 
	cst_lastname,
	cst_marital_status,
	cst_gndr, 
	cst_create_date
	)

	select 
	cst_id,
	cst_key,
	trim(cst_firstname) as cst_firstname,
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_marital_status)) = 'S' then 'Single'
		 when upper(trim(cst_marital_status)) = 'M' then 'Married'
		 else 'n/a' 
		 end cst_marital_status, -- normalize marital status values to readable format
	case when upper(trim(cst_gndr)) = 'M' then 'Male'
		 when upper(trim(cst_gndr)) = 'F' then 'Female'
		 else 'n/a' 
		 end cst_gndr, -- normalize gender status values to readable format
	cst_create_date
	from(
		select *, 
		row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info 
		where cst_id is not null
	) t
	WHERE t.flag_last = 1; -- select the most recent record per customer

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'

	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: silver.crm_prd_info'
	truncate table silver.crm_prd_info;
	print '>> inserting data into: silver.crm_prd_info'
	insert into silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)

	select 
	prd_id,
	replace(substring(prd_key, 1, 5), '-', '_') as cat_id, -- extract category ID
	substring(prd_key, 7, len(prd_key)) as prd_key, -- extract product key
	prd_nm,
	coalesce(prd_cost, 0) as prd_cost,
	case upper(trim(prd_line))
		 when 'M' then 'Mountain'
		 when 'R' then 'Road'
		 when 'S' then 'Other Sales'
		 when 'T' then 'Touring'
		 else 'n/a' 
		 end as prd_line, -- map product line to codes to descriptive values
	cast(prd_start_dt as date) as prd_start_dt,
	cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt asc) - 1 
		 as date) 
		 as prd_end_dt -- calculate end date as one day before the next start date
	from bronze.crm_prd_info

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'


	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: silver.crm_sales_details'
	truncate table silver.crm_sales_details;
	print '>> inserting data into: silver.crm_sales_details'
	insert into silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt, 
	sls_sales,
	sls_quantity,
	sls_price 
	)

	select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
			 else cast(cast(sls_order_dt as varchar) as date)
			 end as sls_order_dt,

		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
			 else cast(cast(sls_ship_dt as varchar) as date)
			 end as sls_ship_dt,

		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
			 else cast(cast(sls_due_dt as varchar) as date)
			 end as sls_due_dt,

		case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
			 then sls_quantity * abs(sls_price)
			 else sls_sales 
			 end as sls_sales, -- recalculate sales if original values is missing or incorrect

		sls_quantity,

		case when sls_price is null or sls_price <= 0 
			 then sls_sales / nullif(sls_quantity, 0)
			 else sls_price
			 end as sls_price -- derive price if original values is invalid

	from bronze.crm_sales_details

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'


		print '-------------------------------------------------------------------------------------';
		print 'loading erp layer';
		print '-------------------------------------------------------------------------------------';

	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: silver.erp_cust_az12'
	truncate table silver.erp_cust_az12;
	print '>> inserting data into: silver.erp_cust_az12'
	insert into silver.erp_cust_az12( cid, bdate, gen)

	select 
	case when cid like 'NAS%' then substring(cid, 4, len(cid))
		 else cid
		 end as cid, -- Remove 'NAS' prefix if present

	case when bdate > getdate() then null
		 else bdate end, -- Set future birthday to null

	case when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		 when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
		else 'n/a'
		end as gen -- Normalize gender values and unknown cases
	from bronze.erp_cust_az12

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'



	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: silver.erp_loc_a101'
	truncate table silver.erp_loc_a101;
	print '>> inserting data into: silver.erp_loc_a101'
	insert into silver.erp_loc_a101(cid, cntry)

	select  
	replace (cid, '-', '') as cid,
	case when trim(cntry) in ('USA', 'US') then 'United States'
		 when trim(cntry) = 'DE' then 'Germany'
		 when trim(cntry) = ' ' or cntry is null then 'n/a'
		 else trim(cntry) 
	end as cntry
	from bronze.erp_loc_a101 -- normalize and handle missing or blank country codes

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'


	/*-------------------------------------------------------------------------------------------------------------------*/
	set @start_time = getdate();
	print '>> Truncating table: erp_px_cat_g1v2'
	truncate table silver.erp_px_cat_g1v2;
	print '>> inserting data into: erp_px_cat_g1v2'
	insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)

	select id, cat, subcat, maintenance
	from bronze.erp_px_cat_g1v2

	set @end_time = getdate();
	print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
	print '----------------------------------'

		set @batch_end_time = getdate();
	print '======================================================'
	print 'Loading silver layer is completed'
	print '       - total duration: ' + cast(datediff(second, @batch_end_time, @batch_start_time) as nvarchar) + 'seconds';
	print '======================================================'

		end try
	begin catch
		print '================================================='
		print 'error occured during loading silver layer'
		print 'error message' + error_message();
		print 'error message' + cast (error_number() as nvarchar);
		print 'error message' + cast (error_state() as nvarchar);
		print '================================================='
	end catch
end
