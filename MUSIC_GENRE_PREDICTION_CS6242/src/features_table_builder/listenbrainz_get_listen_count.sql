SELECT artist_msid, COUNT(*) as listen_count
FROM listenbrainz.listenbrainz.listen
GROUP BY artist_msid
ORDER BY listen_count DESC