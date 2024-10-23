CREATE PROCEDURE GetCurrencyRates
    @YearsAgo INT
AS
BEGIN
    DECLARE @DateThreshold DATE;
    SET @DateThreshold = DATEADD(YEAR, -@YearsAgo, GETDATE());

    SELECT 
        fcr.CurrencyKey,
        dc.CurrencyAlternateKey,
        fcr.Date,
        fcr.AverageRate,
        fcr.EndOfDayRate
    FROM dbo.FactCurrencyRate fcr
    INNER JOIN dbo.DimCurrency dc
        ON fcr.CurrencyKey = dc.CurrencyKey
    WHERE 
        fcr.Date <= @DateThreshold
        AND (dc.CurrencyAlternateKey = 'GBP' OR dc.CurrencyAlternateKey = 'EUR');
END;

-- Procedura sk�adowana w SQL umo�liwia szybkie uzyskanie wynik�w z tabel, gdy dane ju� znajduj� si� w bazie. 
-- Proces ETL natomiast jest bardziej elastyczny i pozwala na skomplikowane przetwarzanie danych z r�nych �r�de�, ich integracj� oraz automatyzacj�.