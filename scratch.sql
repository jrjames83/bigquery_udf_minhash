CREATE TEMP
FUNCTION myMinHash
(inputText STRING)
  RETURNS ARRAY<INT64>
  LANGUAGE js
  OPTIONS
(
    library=["gs://jjames-bq-udfs/minhash_udf.js"]
  )
  AS
"""
//https://cloud.google.com/bigquery/docs/reference/standard-sql/user-defined-functions#including-javascript-libraries
  return generateMinHash(inputText);
""";

CREATE OR REPLACE TABLE minhash_testing.dbpedia_hashed AS
SELECT URI, rdf_schema_comment, myMinHash( rdf_schema_comment ) as minhash
FROM `fh
-bigquery.dbpedia.place`

-- 

CREATE OR REPLACE TABLE minhash_testing.dbpedia_bands AS
SELECT URI, element, index,
    CASE 
    WHEN index < 5 THEN 'band1'
    WHEN index < 10 THEN 'band2'
    WHEN index < 15 THEN 'band3'
    WHEN index < 20 THEN 'band4'
    WHEN index < 25 THEN 'band5'
    WHEN index < 30 THEN 'band6'
    WHEN index < 35 THEN 'band7'
    WHEN index < 40 THEN 'band8'
    WHEN index < 45 THEN 'band9'
    WHEN index < 50 THEN 'band10'
    WHEN index < 55 THEN 'band11'
    WHEN index < 60 THEN 'band12'
    WHEN index < 65 THEN 'band13'
    WHEN index < 70 THEN 'band14'
    WHEN index < 75 THEN 'band15'
    WHEN index < 80 THEN 'band16'
    WHEN index < 85 THEN 'band17'
    WHEN index < 90 THEN 'band18'
    WHEN index < 95 THEN 'band19'
    WHEN index < 100 THEN 'band20'
    WHEN index < 105 THEN 'band21'
    WHEN index < 110 THEN 'band22'
    WHEN index < 115 THEN 'band23'
    WHEN index < 120 THEN 'band24'
    WHEN index < 125 THEN 'band25'
    WHEN index < 130 THEN 'band26'
ELSE 'other' END as band
FROM `minhash_testing
.dbpedia_hashed`, UNNEST
(minhash) element
WITH offset as index


-- 

CREATE OR REPLACE TABLE minhash_testing.grouped_candidates AS

WITH
    base_table
    AS
    (
        SELECT URI, band, ARRAY_TO_STRING(ARRAY_AGG(CAST(element as STRING)
        ORDER BY index
    ), '|') as band_key
  FROM minhash_testing.dbpedia_bands
  GROUP BY 1,2
)

SELECT band_key, band, array_agg(URI) as documents
FROM base_table
GROUP BY 1,2

-- If 2 documents appear together in any band, they're near duplicate candidates
-- Round up all documents which appear clustered in the table

-- filter down the table to where the length of the array is not 1
CREATE OR REPLACE TABLE minhash_testing.grouped_candidates_pairs AS
SELECT *
FROM minhash_testing.grouped_candidates
WHERE array_length(documents) > 1

-- Think about probabilities, is 2 bands the minimum for a pair of documents?
-- Would that eliminate false positives?

