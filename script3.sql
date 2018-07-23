1=>

INSERT OVERWRITE TABLE udm_p_customer

SELECT ${columns:customer::c.%1$s AS %1$S}
FROM (
	SELECT ${columns:customer:~c_timeZone:c.%1$s AS %1$s},
	CASE WHEN COALESCE(cs.Country,"") LIKE "us%"
		THEN CASE
			WHEN COALESCE(cs.state,"") IN ("CA","ID") THEN "PST"
			WHEN COALESCE(cs.state,"") IN ("TX","AL") THEN "CST" 
			WHEN COALESCE(cs.state,"") IN ("FL","DE") THEN "EST"
 			WHEN COALESCE(cs.state,"") IN ("WY","AZ") THEN "MST"
			ELSE NULL END
		ELSE NULL
	END AS c_timeZone
	FROM udm_p_customer c
		LEFT OUTER JOIN (
			SELECT CustomerID,MasterCustomerID
			FROM udm_pv_mastercustomer) mc 
			ON mc.CustomerID = c.ID

		LEFT OUTER JOIN (
			SELECT MasterCustomerID,State,Country
			FROM udm_pv_customersummery
		)cs ON cs.MasterCustomerID = mc.MasterCustomerID
)c;




2=>
INSERT OVERWRITE udm_p_customer
SELECT ${columns:customer::c.%1$s AS %1$S}
FROM (

	SELECT 
		${columns:customer::t1%1$s AS %1$S},
		ts.MasterCustomerID,
		o.Name AS c_PrimaryStore,
		ROW_NUMBER() OVER(PARTITION BY MasterCustomerID ORDER BY transactiontimestamp DESC) AS ROWNUM
	FROM(
		SELECT 
			sourceTransactionNumber,
			MasterCustomerID,
			OrganizationId,
			MIN(transactiontimestamp) as transactiontimestamp
		FROM udm_pv_transactionsummery
		GROUP BY sourceTransactionNumber,MasterCustomerID,OrganizationId
		)ts
	INNER JOIN (
		SELECT ID,Name
		FROM udm_pv_organization
		WHERE COALESCE(Type,"")<>"Digital"
		) o
	ON o.ID = ts.OrganizationId
	)t1
	WHERE COALESCE(ROWNUM,0) BETWEEN 1 AND 6
)c