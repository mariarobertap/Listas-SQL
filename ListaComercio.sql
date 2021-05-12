USE COMERCIO
GO

/*
1) Apresente os dados do cliente (código, nome completo, 
e-mail, sexo (masculino ou feminino) e sua idade). 
Utilize uma subconsulta para apresentar a data da 
primeira e última compra de cada cliente, 
e em uma única coluna apresente seu endereço completo, 
também por subconsulta.
*/
SELECT
	C.IDCLIENTE,
	CONCAT(C.NOME, ' ', C.SOBRENOME) AS CLIENTE,
	C.EMAIL,
	CASE C.SEXO
		WHEN 'M' THEN 'Masculino'
		ELSE 'Feminino'
	END AS SEXO,
	FLOOR(DATEDIFF(DAY, C.NASCIMENTO, GETDATE()) / 365.25) AS IDADE,
	DT_PRIMEIRA_COMPRA = (
		SELECT
			CONVERT(VARCHAR(10), MIN(NF.DATA), 103)
		FROM
			NOTA_FISCAL NF
		WHERE
			NF.ID_CLIENTE = C.IDCLIENTE
	),
	DT_ULTIMA_COMPRA = (
		SELECT
			CONVERT(VARCHAR(10), MAX(NF.DATA), 103)
		FROM
			NOTA_FISCAL NF
		WHERE
			NF.ID_CLIENTE = C.IDCLIENTE
	),
	ENDERECO = (
		SELECT 
			CONCAT(RUA, ', ', CIDADE, ', ', ESTADO, ', ', REGIAO)
		FROM 
			ENDERECO E
		WHERE
			E.ID_CLIENTE = C.IDCLIENTE
	)
FROM
	CLIENTE C

/*
2) Apresente os dados do produto (código, descrição e valor). 
Utilize subconsulta para apresentar o nome dacategoria e do 
fornecedor de cada produto.
*/
SELECT
	P.IDPRODUTO,
	P.PRODUTO,
	P.VALOR,
	CATEGORIA = (
		SELECT	
			NOME
		FROM
			CATEGORIA C
		WHERE
			C.IDCATEGORIA = P.ID_CATEGORIA
	),
	FORNECEDOR = (
		SELECT	
			NOME
		FROM
			FORNECEDOR F
		WHERE
			F.IDFORNECEDOR = P.ID_FORNECEDOR
	)
FROM
	PRODUTO P

/*
3) Encontre os produtos mais caros por categoria de produto.
*/
SELECT
	TAB.ID_CATEGORIA,
	CATEGORIA = (
		SELECT	
			NOME
		FROM
			CATEGORIA C
		WHERE
			C.IDCATEGORIA = TAB.ID_CATEGORIA	
	),
	ID_PRODUTO = (
		SELECT 
			IDPRODUTO
		FROM 
			PRODUTO P
		WHERE
			P.VALOR = TAB.VALOR
			AND P.ID_CATEGORIA = TAB.ID_CATEGORIA
	),
	PRODUTO = (
		SELECT 
			PRODUTO
		FROM 
			PRODUTO P
		WHERE
			P.VALOR = TAB.VALOR
			AND P.ID_CATEGORIA = TAB.ID_CATEGORIA
	),
	TAB.VALOR
FROM
(
	SELECT
		P.ID_CATEGORIA,
		MAX(P.VALOR) AS VALOR
	FROM
		PRODUTO P
	GROUP BY
		P.ID_CATEGORIA
) AS TAB

/*
4) Encontre os melhores vendedores de cada produto.
*/
SELECT
	TAB2.ID_PRODUTO,
	(
		SELECT TOP 1
			TAB.ID_VENDEDOR
		FROM
		(
			SELECT
				NF.ID_VENDEDOR,
				I.ID_PRODUTO,
				SUM(I.QUANTIDADE) AS QTDE_TOTAL_ITEN
			FROM
				NOTA_FISCAL NF
				JOIN ITEM_NOTA I
					ON I.ID_NOTA_FISCAL = NF.IDNOTA
			GROUP BY
				NF.ID_VENDEDOR,
				I.ID_PRODUTO
		) AS TAB
		WHERE
			TAB.ID_PRODUTO = TAB2.ID_PRODUTO
			AND TAB.QTDE_TOTAL_ITEN = TAB2.MAX_QTDE
	) AS ID_VENDEDOR,
	TAB2.MAX_QTDE
FROM
(
	SELECT
		TAB.ID_PRODUTO,
		MAX(TAB.QTDE_TOTAL_ITEN) AS MAX_QTDE
	FROM
	(
		SELECT
			NF.ID_VENDEDOR,
			I.ID_PRODUTO,
			SUM(I.QUANTIDADE) AS QTDE_TOTAL_ITEN
		FROM
			NOTA_FISCAL NF
			JOIN ITEM_NOTA I
				ON I.ID_NOTA_FISCAL = NF.IDNOTA
		GROUP BY
			NF.ID_VENDEDOR,
			I.ID_PRODUTO
	) AS TAB
	GROUP BY
		TAB.ID_PRODUTO
) AS TAB2
ORDER BY
	ID_PRODUTO
/*
5) Crie um relatório que apresente o volume e o faturamento de 
compras por ano, e utilize subconsulta para exibir 
os respectivos valores para cada mês do ano de Jan e Dez.
*/
SELECT
	TAB.ANO,
	SUM(TAB.JAN_VOL) AS JAN_VOL,
	FORMAT(SUM(TAB.JAN_FAT), 'C', 'PT-BR') AS JAN_FAT,
	SUM(TAB.DEZ_VOL) AS DEZ_VOL,
	FORMAT(SUM(TAB.DEZ_FAT), 'C', 'PT-BR') AS DEZ_FAT
FROM
(
	SELECT
		YEAR(NF.DATA) AS ANO,
		IIF(MONTH(NF.DATA) = 1, 1, 0) AS JAN_VOL,
		IIF(MONTH(NF.DATA) = 1, NF.TOTAL, 0) AS JAN_FAT,
		IIF(MONTH(NF.DATA) = 12, 1, 0) AS DEZ_VOL,
		IIF(MONTH(NF.DATA) = 12, NF.TOTAL, 0) AS DEZ_FAT
	FROM
		NOTA_FISCAL NF
	WHERE
		MONTH(NF.DATA) IN(1, 12)
) AS TAB
GROUP BY
	TAB.ANO
ORDER BY
	TAB.ANO

/*
6) Crie um relatório que apresente o volume e faturamento 
por forma de pagamento. Utilize subconsulta.
*/
SELECT
	PG.FORMA,
	VOLUME = (
		SELECT
			COUNT(NF.IDNOTA)
		FROM
			NOTA_FISCAL NF
		WHERE
			NF.ID_FORMA = PG.IDFORMA
	),
	FATURAMENTO = FORMAT((
		SELECT
			SUM(NF.TOTAL)
		FROM
			NOTA_FISCAL NF
		WHERE
			NF.ID_FORMA = PG.IDFORMA
	), 'C', 'PT-BR')
FROM
	FORMA_PAGAMENTO PG
ORDER BY
	3 DESC

/*
7) DESAFIO: Crie um relatório que apresente o faturamento 
e o faturamento acumulado por ano, conforme imagem abaixo:
*/
SELECT
	YEAR(NF.DATA) AS ANO,
	FORMAT(SUM(NF.TOTAL), 'C', 'PT-BR') AS FATURAMENTO,
	FAT_ACUMULADO = (
		SELECT
			FORMAT(SUM(SNF.TOTAL), 'C', 'PT-BR')
		FROM
			NOTA_FISCAL SNF
		WHERE
			YEAR(SNF.DATA) <= YEAR(NF.DATA)
	)
FROM
	NOTA_FISCAL NF
GROUP BY
	YEAR(NF.DATA)
ORDER BY
	YEAR(NF.DATA)