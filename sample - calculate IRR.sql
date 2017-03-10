

	-- TABLE WITH SAMPLE DATA FOR FLOW OF PAYMENTS
	-- ===========================================================================

	DECLARE @payments TABLE (
		num		SMALLINT,
		valor	FLOAT
	)

	INSERT @payments(num, valor)
	SELECT 0, -100000				-- this is the loan (negative value)
	UNION ALL SELECT 1, 20000		-- 1st payment
	UNION ALL SELECT 2, 20000		-- 2nd payment
	UNION ALL SELECT 3, 20000		-- 3rd payment
	UNION ALL SELECT 4, 20000		-- 4th payment
	UNION ALL SELECT 5, 20000		-- 5th payment
	UNION ALL SELECT 6, 20000;		-- 6th payment


	-- IRR
	-- ===========================================================================

	-- SQL SERVER specific settings	
	SET ARITHABORT OFF;			-- prevents error when overflow happens
	SET ARITHIGNORE ON;			-- prevents warning when overflow happens
	SET ANSI_WARNINGS OFF;		-- prevents warning when overflow happens
	SET NOCOUNT ON;				-- prevents error for some database drivers

	-- PARAMETERS 
	DECLARE @ERROR_PVL	FLOAT (53);	SET @ERROR_PVL = 1.0E-2;	-- acceptable error/precision for PVL (= 0.01 money)
	DECLARE @GUESS_UPP	FLOAT (53);	SET @GUESS_UPP = 1.0E-2;	-- initial guess for upper value for IRR (= 1%)
	DECLARE @GUESS_LOW	FLOAT (53);	SET @GUESS_LOW = 0.0E;		-- initial guess for lower value for IRR (= 0%)
	DECLARE @COUNT_MAX	INT;		SET @COUNT_MAX = 30;		-- limit for the loop iteration
	DECLARE @LIMIT_UPP	FLOAT (53);	SET @LIMIT_UPP = 1.0E-1;	-- upper limit for interpolation
	DECLARE @LIMIT_LOW	FLOAT (53);	SET @LIMIT_LOW = 1.0E-20;	-- lower limit for interpolation

	-- VARIABLES
	DECLARE @irr_next	FLOAT (53);	-- interest rate: next
	DECLARE @irr_prev	FLOAT (53);	-- interest rate: previous
	DECLARE @irr_curr	FLOAT (53);	-- interest rate: current
	DECLARE @irr_diff	FLOAT (53);	-- interest rate: delta

	DECLARE @pvl_next	FLOAT (53);	-- present value: next
	DECLARE @pvl_prev	FLOAT (53);	-- present value: previous
	DECLARE @pvl_curr	FLOAT (53);	-- present value: current
	DECLARE @pvl_diff	FLOAT (53);	-- present value: delta

	DECLARE @count_cur	INT;	-- loop counter

	-- INITIALIZE VARIABLES FROM PARAMETERS
	SET @irr_prev = @GUESS_LOW;
	SET @irr_curr = @GUESS_UPP;
	SET @pvl_prev = (SELECT SUM (valor) FROM @payments );
	SET @pvl_curr = (SELECT SUM (valor / POWER (@irr_curr, num)) FROM @payments );

	-- CALCULATION
	-- ===========================================================================
	SET @count_cur = 0;
	WHILE (@count_cur < @COUNT_MAX) AND (ABS(@pvl_curr) >= @ERROR_PVL)
	BEGIN

		SET @count_cur = @count_cur +1;

		SET @irr_diff = ABS( @irr_prev - @irr_curr);
		SET @pvl_diff = ABS( @pvl_prev - @pvl_curr);

		IF (@irr_diff < @LIMIT_LOW )
		BEGIN -- BINARY SEARCH - irr difference is too small to interpolate
			SET @irr_next = (@irr_prev + @irr_curr) / 2.0E0;
		END
		ELSE IF (@irr_diff > @LIMIT_UPP) AND (@pvl_prev > 0)
		BEGIN -- EXTRAPOLATE - up
			SET @irr_next = @irr_prev * 9.0E0;
		END
		ELSE IF (@irr_diff > @LIMIT_UPP) AND (@pvl_prev < 0)
		BEGIN -- EXTRAPOLATE - down
			SET @irr_next = @irr_prev / 7.0E0;
		END
		ELSE BEGIN
			-- LINEAR INTERPOLATION - good enough aproximation for the range
			SET @irr_next = @irr_diff * (@pvl_curr / @pvl_diff) + @irr_curr;
		END;

		SET @pvl_next = ( SELECT SUM (valor / POWER (1.0E0 + @irr_next, num)) FROM @payments );	-- [1.0E0 == CONVERT(FLOAT, 1)]

		-- set previous values
		SET @irr_prev = @irr_curr;
		SET @pvl_prev = @pvl_curr;

		-- set current values
		SET @irr_curr = @irr_next;
		SET @pvl_curr = @pvl_next;
	END;


	-- INTERPRETATION
	-- ===========================================================================
	PRINT 'END OF CALCULATION';
	PRINT ' number of iterations [' + CONVERT(VARCHAR, @count_cur) + '].';
	PRINT ' calculated internal interet rate (IRR) [' + CONVERT(VARCHAR, @irr_curr) + '].';
	PRINT ' calculated present value (PVL) from the calculated IRR [' + CONVERT(VARCHAR, @pvl_curr) + '].';
