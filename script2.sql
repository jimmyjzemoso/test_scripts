
INSERT INT0 udm_product

SELECT ${:udm_s_product::s.%1$s AS %1&S},
	SELECT ${columns:udm_s_product:~Availability: COALESCE(dw.%1&s,sparse.%1&s AS %1&s},
	CASE 
		WHEN COALESCE(sparse.Availability,0) > 0 
		THEN "Available" 
		ELSE "No" 
		END AS Availability,
	CASE 
		WHEN (CASE 
				WHEN COALESCE(sparse.Availability,0) > 0 
				THEN "Available" 
				ELSE "No" 
				END AS Availability)<>COALESCE(dw.Availability,"") 
				AND
		 		COALESCE(dw.Availability,"")<>"" 
		THEN COALESCE(sparse.RowModified,dw.RowModified)+1 
	 	ELSE COALESCE(sparse.RowModified,dw.RowModified) 
	 	END AS RowModified
	FROM udm_product dw 
	FULL OUTER JOIN
		((SELECT ${:udm_s_product:~SourceProductNumber,c_colorname,productUrl: p.%1$s AS %1&S},
		  	SUBSTRING(SourceProductNumber,4) AS SourceProductNumber,
		  	t1.c_colorname as c_colorname,
		  	CONCAT(t1.ProductUrl,"_",t1.c_colorname)
		FROM udm_s_product) p
		LEFT OUTER JOIN(
			SELECT SourceProductColorNumber, 
				CASE
			    WHEN map_values (collect_max (COALESCE(c_colorname,''),CASE WHEN c_colorname IS NULL then 0L else RowModified END))[0]= 0L THEN NULL
			    ELSE map_keys (collect_max (COALESCE(c_colorname,''),CASE WHEN c_colorname IS NULL then 0L else RowModified END))[0]
			    END AS c_colorname
			FROM (
				SELECT SourceProductColorNumber,c_colorname,RowModified
				FROM udm_s_c_productColor
				UNION ALL
				SELECT SourceProductColorNumber,c_colorname,RowModified
				FROM udm_c_productColor)
			GROUP BY SourceProductNumber) t1
		ON p.SourceProductNumber = t1.SourceProductColorNumber)sparse
	ON dw.SourceProductNumber = sparse.SourceProductNumber
)s
; 
