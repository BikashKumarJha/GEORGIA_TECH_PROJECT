WITH 
pta_lar_table AS (
   SELECT pta.id, pta.gid, pta.name, pta.type, 
          pta.area, pta.gender,lar.entity1 as release_id
    FROM artist AS pta
    JOIN l_artist_release AS lar ON lar.entity0 = pta.id
),  
artist_release_count AS (
SELECT a.id as artist_id, COUNT(r.id) AS release_count
FROM musicbrainz.artist a
JOIN musicbrainz.release r ON a.id = r.artist_credit
WHERE a.name != 'Various Artists'
GROUP BY a.id
),
artist_collab_count as (
SELECT artist_id, COUNT(*) as collab_count
FROM (
    SELECT entity0 as artist_id FROM l_artist_artist
    UNION ALL
    SELECT entity1 FROM l_artist_artist
) as combined
GROUP BY 
combined.artist_id
),
pta_credit_id_table AS (
    SELECT plt.id, plt.gid, plt.name, plt.type, 
           plt.area, plt.gender, plt.release_id, r.artist_credit
    FROM  pta_lar_table AS plt JOIN  release AS r ON  plt.release_id = r.id
), pta_msid_table AS (
 SELECT DISTINCT pcit.id, pcit.gid, pcit.name, pcit.type,
        pcit.area, pcit.gender, 
        mmm.msb_artist_msid
  FROM pta_credit_id_table as pcit JOIN msid_mbid_map as mmm ON pcit.artist_credit = mmm.mb_artist_credit_id 
),
pta_listen_count_table AS (
SELECT  pmt.id, pmt.gid, pmt.name, pmt.type,
        pmt.area, pmt.gender,
        pmt.msb_artist_msid, alc.listen_count
  FROM pta_msid_table as pmt JOIN artist_listen_count as alc ON alc.artist_msid = pmt.msb_artist_msid  
), 
pta_listen_user_count_table AS (
    SELECT  plct.id, plct.gid, plct.name, plct.type,
        plct.area, plct.gender,
        plct.msb_artist_msid, plct.listen_count,auc.user_count
  FROM pta_listen_count_table as plct JOIN artist_user_count as auc ON auc.artist_msid = plct.msb_artist_msid   
), 
pta_listen_user_collab_count_table AS (
         SELECT  pluct.id, pluct.gid, pluct.name, pluct.type,
        pluct.area, pluct.gender,
        pluct.msb_artist_msid, 
        pluct.listen_count,pluct.user_count, acc.collab_count
  FROM pta_listen_user_count_table as pluct JOIN artist_collab_count as acc ON acc.artist_id = pluct.id   
), 
pta_listen_user_collab_release_count_table AS (
         SELECT  plucct.id, plucct.gid, plucct.name, plucct.type,
        plucct.area, plucct.gender,
        plucct.listen_count,plucct.user_count, plucct.collab_count, arc.release_count 
  FROM pta_listen_user_collab_count_table as plucct JOIN artist_release_count as arc ON arc.artist_id = plucct.id   
), 
pta_listen_user_collab_release_count_group_table AS(
SELECT plucrct.id, plucrct.gid, plucrct.name, plucrct.type,
        plucrct.area, plucrct.gender,         
        SUM(plucrct.user_count) as uc, 
        SUM(plucrct.listen_count) as lc,
        SUM(plucrct.collab_count) as cc, 
        SUM (plucrct.release_count) as rc
  FROM pta_listen_user_collab_release_count_table as plucrct
  GROUP BY  plucrct.id, plucrct.gid, plucrct.name, plucrct.type,
        plucrct.area, plucrct.gender        
) select * into musicbrainz.mta from pta_listen_user_collab_release_count_group_table