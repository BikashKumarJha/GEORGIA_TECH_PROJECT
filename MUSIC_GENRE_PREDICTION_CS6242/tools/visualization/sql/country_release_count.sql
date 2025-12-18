SELECT 
    a.name AS country_name, 
    COUNT(rc.release) AS release_count
FROM 
    release_country rc
JOIN 
    country_area ca ON rc.country = ca.area
JOIN 
    area a ON ca.area = a.id
JOIN 
    area_type at ON a.type = at.id
WHERE 
    at.name = 'Country'
GROUP BY 
    a.name
ORDER BY 
    release_count DESC
limit 25