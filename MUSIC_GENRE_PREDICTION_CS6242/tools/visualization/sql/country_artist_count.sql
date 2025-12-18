SELECT 
    a1.name AS country_name, 
    COUNT(distinct ar.id) AS artist_count
FROM 
    artist ar
JOIN 
    area a1 ON ar.area = a1.id  
  
GROUP BY 
    a1.name
ORDER BY 
    artist_count DESC
limit 25;