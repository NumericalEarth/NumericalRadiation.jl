# Gate-2 fixed-dataset manifest

Status: **gate2_dataset_manifest_pending_eval2**

inventory only; no aggregation choice, no metric evaluation, no candidate acceptance; eval2 entries pending G2c/G2d honestly.

Counts: LW 20/20, SW-rgb 16/16, eval2 0/2

| Label | Present | Size | sha256 (16) |
|---|---|---|---|
| lw_rel-180 | true | 450863 | dde735608e57af93 |
| lw_rel-280 | true | 450863 | b0932f2648f720af |
| lw_rel-415 | true | 450863 | 01836becbc96e7da |
| lw_rel-560 | true | 450863 | c8aa819b9e7ea7ed |
| lw_rel-1120 | true | 450873 | cfbda1d66decc14e |
| lw_rel-2240 | true | 450873 | 75239df6dbf578b3 |
| lw_present | true | 469175 | 98ccb738a2cc9fe7 |
| lw_ch4-350 | true | 469174 | 67e386755139d062 |
| lw_ch4-700 | true | 469174 | 5097a2044a6cc471 |
| lw_ch4-1200 | true | 469184 | 0db74ee83f804a82 |
| lw_ch4-2600 | true | 469184 | 6560283bebe8696b |
| lw_ch4-3500 | true | 469184 | f601efa7c37f58b5 |
| lw_n2o-190 | true | 469175 | eee1cad7a4cc3c01 |
| lw_n2o-270 | true | 469175 | 34048c6aacd36276 |
| lw_n2o-405 | true | 469175 | ed6f69658fa5e4c8 |
| lw_n2o-540 | true | 469175 | e670a3f7a5e7e591 |
| lw_cfc11-0 | true | 469173 | f80167edd631b12b |
| lw_cfc11-2000 | true | 469203 | 557b0e96e1c591b6 |
| lw_cfc12-0 | true | 469173 | d71cc1697a645320 |
| lw_cfc12-550 | true | 469193 | 9d8ea06d70a374a8 |
| sw_rgb_rel-180 | true | 1817472 | 19016e05da9586e5 |
| sw_rgb_rel-280 | true | 1817472 | 01c5326f5f4d4c9f |
| sw_rgb_rel-415 | true | 1817472 | 55cf6fffba18d950 |
| sw_rgb_rel-560 | true | 1817472 | 19c801655f5a594e |
| sw_rgb_rel-1120 | true | 1817482 | dddeeb6b97fdaae2 |
| sw_rgb_rel-2240 | true | 1817482 | 944c5957c33cf5d2 |
| sw_rgb_present | true | 1839369 | ceb5872dd4ac3928 |
| sw_rgb_ch4-350 | true | 1839368 | d15967da2873b4a4 |
| sw_rgb_ch4-700 | true | 1839368 | 9c355b0ca2597388 |
| sw_rgb_ch4-1200 | true | 1839378 | f31d7c5628bfb17c |
| sw_rgb_ch4-2600 | true | 1839378 | c22671d43a0ca055 |
| sw_rgb_ch4-3500 | true | 1839378 | 300adb48f0feb928 |
| sw_rgb_n2o-190 | true | 1839369 | d7bac1bcf8a09497 |
| sw_rgb_n2o-270 | true | 1839369 | 551c532d0661025f |
| sw_rgb_n2o-405 | true | 1839369 | d76927da116d65d0 |
| sw_rgb_n2o-540 | true | 1839369 | aac07193510b1fcc |
| eval2_lw_rel-415 | false | 0 | PENDING |
| eval2_sw_rgb_rel-415 | false | 0 | PENDING |

Unresolved: BINDING dataset choice (this optimizer-training union is the candidate per design note rev 2; not yet ruled); aggregation: worst-case vs pooled log-RMSE across scenarios
