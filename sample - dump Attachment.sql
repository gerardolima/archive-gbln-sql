DECLARE @template VARCHAR(400);
SET @template = 'BCP "SELECT Content FROM Blob WHERE Id = {id};" queryout "c:\temp\blob_{id}" -S "localhost" -d MyDatabase -N  >> d:\gbln\tmp\my.log'

SELECT Replace(@template, '{id}', blo.Id)
FROM Blob blo
WHERE (blo.Id = 123)
ORDER BY blo.Id;