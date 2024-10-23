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

-- Procedura sk³adowana w SQL umo¿liwia szybkie uzyskanie wyników z tabel, gdy dane ju¿ znajduj¹ siê w bazie. 
-- Proces ETL natomiast jest bardziej elastyczny i pozwala na skomplikowane przetwarzanie danych z ró¿nych Ÿróde³, ich integracjê oraz automatyzacjê.