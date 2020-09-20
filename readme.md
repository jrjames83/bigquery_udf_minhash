# Generating MinHash Signatures in BigQuery via a Javascript UDF

- ported from (thanks!) https://github.com/duhaime/minhash/blob/master/src/minhash.js


- <b>STEP</b> 1: Make a google cloud storage bucket

```gsutil mb gs://jjames-bq-udfs```

- <b>STEP</b> 2: Upload the .js file to the bucket 

```gsutil cp minhash_udf.js gs://jjames-bq-udfs```

- <b>STEP 3: </b>Use the function in a Bigquery statement

_Notice how we reference the resource in our cloud bucket._ 


```javascript
CREATE TEMP FUNCTION myMinHash(inputText STRING)
  RETURNS ARRAY<INT64>
  LANGUAGE js
  OPTIONS (
    library=["gs://jjames-bq-udfs/minhash_udf.js"]
  )
  AS
"""
//https://cloud.google.com/bigquery/docs/reference/standard-sql/user-defined-functions#including-javascript-libraries
  return generateMinHash(inputText);
""";

CREATE OR REPLACE TABLE minhash_testing.dbpedia_hashed AS 
SELECT URI, rdf_schema_comment, myMinHash( rdf_schema_comment ) as minhash
FROM `fh-bigquery.dbpedia.place`
```

The above runs in about 90 seconds on 800k or so documents. Not bad. 

# Other Notes
- Use the scratch.js file to play around with the number of hash functions to use, or whether you want to receive an array of precomputed tokens, or use JavaScript to tokenize your input. It's probably faster to tokenize the input in BigQuery, but you can modify it as you see fit. 

*REMEMBER* -- if you end up modifying the code in scratch.js, do not forget to change `minhash_udf.js`! Just make sure whatever you upload to your bucket and register with your function works :) 


# Reminder about Min-Hashes
- the degree to which 2 Min-Hash signatures "agree" is equal to the jaccard similarity of 2 documents. 
- if you run scratch.js, you'll see in the output:


```javascript
[
  'very',     'long',
  'document', 'that',
  'just',     'wrote',
  'down'
]
[
  'very',     'long',
  'document', 'that',
  'just',     'jotted',
  'down'
]
98 30 0.765625
```

Above, we have 2 documents. Their Jaccard similarity is equal to the length of the INTERSECTION of their tokens, divided by the length of the UNION of their tokens. 

INTERSECTION = `[very, document, just, down, long, that]`
UNION = `[very, document, just, down, long, that, jotted, wrote]`

6 items / 8 items = .75

The number of signatures the 2 documents match against eachothers MinHash signatures is .76. So there ya go. 

Here are the 128 signatures for each document. 76% of them are the same




```javascript

let m1 = generateMinHash('this is a very long document that I just wrote down')
let m2 = generateMinHash('this is a very long document that I just jotted down')

let trueCount = 0
let falseCount = 0

m1.forEach((el, idx) => {
    console.log(el, m2[idx])
    if (el == m2[idx]) {
        trueCount++;
    } else {
        falseCount++
    }
})

console.log(trueCount, falseCount, trueCount / (trueCount + falseCount))

// Output
207036724 207036724
50035553 50035553
521658094 521658094
914259898 914259898
1217887274 45156324
73454149 73454149
548814016 450133460
670980566 670980566
1161721474 1510302452
979107337 57245114
1246759432 291327271
677887205 677887205
169366307 169366307
510627711 510627711
873659246 873659246
31926488 31926488
269404464 269404464
274227871 274227871
235583499 235583499
451845872 451845872
415478898 415478898
1466306454 1466306454
631211406 631211406
685783922 685783922
684095366 682300320
293776320 293776320
900068028 900068028
402339630 402339630
16123413 16123413
1118264476 1118264476
119266201 119266201
430585981 430585981
20192908 782334812
1262545803 1262545803
106789705 232746283
25615993 25615993
811963414 811963414
3789815 44470038
1054803552 917324894
322211130 949292665
251598490 251598490
258304823 258304823
60087029 60087029
812955655 324638061
353711924 353711924
303468381 303468381
1004885016 1004885016
300379640 300379640
105438157 105438157
361809029 488455174
841190485 841190485
1305739719 1305739719
1062210317 1062210317
265733694 265733694
451345584 451345584
263007000 263007000
499286463 499286463
266988293 266988293
393324109 393324109
390973295 390973295
769354424 769354424
88679914 88679914
88138586 160960804
1475086642 1475086642
311675310 535272808
1471767711 1125249914
251738532 251738532
420966709 420966709
381607471 381607471
589159370 1076597994
220119620 28079468
52273725 52273725
120041257 120041257
1007022403 1007022403
524521821 524521821
82636433 82636433
464891289 464891289
141083686 141083686
79055256 79055256
79635042 79635042
59351941 59351941
92833519 92833519
581396550 581396550
428630076 359923296
497799367 497799367
1090421798 378435459
1006025902 1006025902
125358939 125358939
1306241764 1306241764
65708857 72475270
627210306 627210306
1032596199 820983179
62336615 62336615
432484431 463645145
249728907 249728907
319353799 319353799
464322796 464322796
1540564187 348000968
367994901 367994901
2388029 58011312
368395130 368395130
344051099 344051099
341534568 341534568
279826439 279826439
1114557515 1114557515
1431632739 1431632739
241831429 241831429
332892183 332892183
414062386 414062386
17414976 17414976
280059266 280059266
195618079 195618079
612270265 612270265
742130019 742130019
49160929 49160929
306923616 306923616
1682398574 688584622
167042850 167042850
714923044 714923044
277379269 277379269
437143693 244328066
86037289 2039529294
233266869 233266869
685556841 685556841
1704243243 691466603
184879758 184879758
381034149 215836752
1533808850 1533808850
```





