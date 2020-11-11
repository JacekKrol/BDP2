CREATE OR ALTER PROCEDURE procedura_cw3 @YearsAgo INT
AS
SELECT factCur.* , dimCur.CurrencyAlternateKey 
FROM dbo.FactCurrencyRate as factCur
JOIN dbo.DimCurrency as dimCur on factCur.CurrencyKey=dimCur.CurrencyKey
WHERE (dimCur.CurrencyAlternateKey = 'GBP' or dimCur.CurrencyAlternateKey = 'EUR')
AND DATEDIFF(year, factCur.Date, GETDATE()) = @YearsAgo
GO

EXEC procedura_cw3 @YearsAgo = 8