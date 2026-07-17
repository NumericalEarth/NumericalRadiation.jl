# Reduced ecCKD Size Scan

Status: **only_full_32_sw_passes**

This scan evaluates simple official-gpoint reduction strategies against the clean ecCKD hard gate. It is diagnostic evidence only; passing the reduced-model goal still requires a reduced 16-term method that meets the hard thresholds.

| Method | ng_lw | ng_sw | Passed | Worst TOA forcing error | Worst surface forcing error | Worst SW up RMSE | Worst SW down RMSE |
|---|---:|---:|---:|---:|---:|---:|---:|
| even_select | 32 | 16 | false | 15.148939416 W m^-2 | 66.5675113805 W m^-2 | 5.08694719079 W m^-2 | 26.1526617172 W m^-2 |
| even_select | 32 | 20 | false | 38.6134677745 W m^-2 | 148.23330804 W m^-2 | 15.679920506 W m^-2 | 57.598469212 W m^-2 |
| even_select | 32 | 24 | false | 12.7081975005 W m^-2 | 41.4690150351 W m^-2 | 8.58980889537 W m^-2 | 19.0409736902 W m^-2 |
| even_select | 32 | 28 | false | 18.9036496529 W m^-2 | 25.7081655144 W m^-2 | 8.27161340502 W m^-2 | 8.5430438144 W m^-2 |
| even_select | 32 | 30 | false | 6.66278545205 W m^-2 | 13.4314515542 W m^-2 | 1.92381964664 W m^-2 | 6.44667209161 W m^-2 |
| even_select | 32 | 32 | true | 0.00806408713652 W m^-2 | 0.0140335470379 W m^-2 | 0.00547013027554 W m^-2 | 0.00430073465525 W m^-2 |
| weighted_bins | 32 | 16 | false | 66.0484885039 W m^-2 | 164.983235003 W m^-2 | 29.1953020718 W m^-2 | 55.9597378585 W m^-2 |
| weighted_bins | 32 | 20 | false | 48.0895560605 W m^-2 | 140.70601047 W m^-2 | 21.8125648821 W m^-2 | 47.8605511273 W m^-2 |
| weighted_bins | 32 | 24 | false | 16.8469606458 W m^-2 | 48.4833107922 W m^-2 | 7.80715869254 W m^-2 | 15.3363041658 W m^-2 |
| weighted_bins | 32 | 28 | false | 6.55301535626 W m^-2 | 25.1907870764 W m^-2 | 2.92552522792 W m^-2 | 9.4910962291 W m^-2 |
| weighted_bins | 32 | 30 | false | 4.48326703925 W m^-2 | 13.7910030177 W m^-2 | 1.55253309467 W m^-2 | 6.1614997309 W m^-2 |
| weighted_bins | 32 | 32 | true | 0.00806408713652 W m^-2 | 0.0140335470379 W m^-2 | 0.00547013027554 W m^-2 | 0.00430073465525 W m^-2 |
