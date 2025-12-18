WITH Collaborations AS (
    SELECT
        acn.artist_credit
    FROM 
        artist_credit_name acn
    GROUP BY 
        acn.artist_credit
    HAVING 
        COUNT(acn.artist) > 1
),

Pairs AS (
    SELECT
        a1.name AS artist1_name, a1.id as id1, a2.id as id2,
        a2.name AS artist2_name
    FROM 
        Collaborations c
    JOIN 
        artist_credit_name acn1 ON acn1.artist_credit = c.artist_credit
    JOIN 
        artist_credit_name acn2 ON acn2.artist_credit = c.artist_credit AND acn1.artist < acn2.artist
    JOIN 
        artist a1 ON acn1.artist = a1.id
    JOIN 
        artist a2 ON acn2.artist = a2.id
)

SELECT 
    id1, id2, artist1_name, artist2_name, COUNT(*) as collaboration_count
FROM 
    Pairs
GROUP BY 
    artist1_name, artist2_name, id1, id2
ORDER BY 
    collaboration_count DESC, artist1_name, artist2_name
LIMIT 25;
