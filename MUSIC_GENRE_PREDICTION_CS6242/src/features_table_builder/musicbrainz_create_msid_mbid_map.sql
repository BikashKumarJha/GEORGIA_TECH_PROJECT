INSERT INTO musicbrainz.msid_mbid_map (
    msb_recording_msid,
    mb_recording_mbid,
    msb_artist_msid,
    mb_artist_credit_mbids,
    mb_artist_credit_id,
    msb_release_msid,
    mb_release_mbid
)
SELECT 
    (data ->> 'msb_recording_msid')::UUID,
    (data ->> 'mb_recording_mbid')::UUID,
    (data ->> 'msb_artist_msid')::UUID,
    ARRAY(SELECT json_array_elements_text(data -> 'mb_artist_credit_mbids'))::UUID[],
    (data ->> 'mb_artist_credit_id')::INTEGER,
    (data ->> 'msb_release_msid')::UUID,
    (data ->> 'mb_release_mbid')::UUID
FROM 
    musicbrainz.import.msid_mbid_mapping;