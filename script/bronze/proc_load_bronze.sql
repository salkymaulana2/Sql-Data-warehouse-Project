/*
====================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
====================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
====================================================================================
*/


create or alter procedure bronze.load_bronze as 
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	begin try

	set @batch_start_time = getdate();

		print '=====================================================================================';
		print 'loading bronze layer';
		print '=====================================================================================';

		print '-------------------------------------------------------------------------------------';
		print 'loading crm layer';
		print '-------------------------------------------------------------------------------------';


		set @start_time = getdate();
		print '>> truncating table: bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;

		print '>> inserting data into: bronze.crm_cust_info';
		bulk insert bronze.crm_cust_info
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'

		set @start_time = getdate();
		print '>> truncating table: bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;

		print '>> inserting data into: bronze.crm_prd_info';
		bulk insert bronze.crm_prd_info
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'


		set @start_time = getdate();
		print '>> truncating table: bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;

		print '>> inserting data into: bronze.crm_sales_details';
		bulk insert bronze.crm_sales_details
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'


		print '-------------------------------------------------------------------------------------';
		print 'loading erp layer';
		print '-------------------------------------------------------------------------------------';

		set @start_time = getdate();
		print '>> truncating table: bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;

		print '>> inserting data into: bronze.erp_loc_a101';
		bulk insert bronze.erp_loc_a101
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_erp\loc_a101.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'


		set @start_time = getdate();
		print '>> truncating table: bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;

		print '>> inserting data into: bronze.erp_cust_az12';
		bulk insert bronze.erp_cust_az12
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_erp\cust_az12.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'


		set @start_time = getdate();
		print '>> truncating table: bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;

		print '>> inserting data into: bronze.erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\User\Documents\project data\data warehousing\1\sql-data-warehouse-project-main\datasets\source_erp\px_cat_g1v2.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print 'load duration: ' + cast(datediff(second, @end_time, @start_time) as nvarchar) + 'seconds';
		print '----------------------------------'

	set @batch_end_time = getdate();
	print '======================================================'
	print 'Loading bronze layer is completed'
	print '       - total duration: ' + cast(datediff(second, @batch_end_time, @batch_start_time) as nvarchar) + 'seconds';
	print '======================================================'

		end try
	begin catch
		print '================================================='
		print 'error occured during loading bronze layer'
		print 'error message' + error_message();
		print 'error message' + cast (error_number() as nvarchar);
		print 'error message' + cast (error_state() as nvarchar);
		print '================================================='
	end catch
end


