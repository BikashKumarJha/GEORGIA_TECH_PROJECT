SELECT a.name, COUNT(r.id) AS release_count
FROM musicbrainz.artist a
JOIN release_group rg ON a.id = rg.artist_credit  
JOIN musicbrainz.release r ON rg.id = r.release_group
WHERE a.name != 'Various Artists'
GROUP BY a.name
ORDER BY release_count DESC
LIMIT 25