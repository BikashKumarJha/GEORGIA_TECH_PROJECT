SELECT artist_name, COUNT(DISTINCT user_name) as unique_users_count
FROM  `listenbrainz.listenbrainz.listen`
GROUP BY artist_name
ORDER BY unique_users_count DESC