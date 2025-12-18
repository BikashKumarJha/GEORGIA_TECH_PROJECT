## similarity_match_score_builder

The 2 input xlsx files in this are module are downloaded from our custom musicbrainz azure database's pta_mta and mta tables with 1000 entries to develop the similarity matching algorithm. The are also available in data directory.
This functionality is already integrated into ml_model_builder module. 

### Algorithm
**mta table looks like below**
<div>

<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>id</th>
      <th>gid</th>
      <th>name</th>
      <th>type</th>
      <th>area</th>
      <th>gender</th>
      <th>uc</th>
      <th>lc</th>
      <th>cc</th>
      <th>rc</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>4</td>
      <td>10adbe5e-a2c0-4bf3-8249-2b4cbf6e6ca8</td>
      <td>Massive Attack</td>
      <td>2.0</td>
      <td>3821.0</td>
      <td>NaN</td>
      <td>3699</td>
      <td>527460</td>
      <td>20</td>
      <td>1350</td>
    </tr>
    <tr>
      <th>1</th>
      <td>6</td>
      <td>ea738cc5-5b1a-44a4-94ab-ed0c1bd71ecf</td>
      <td>Apartment 26</td>
      <td>2.0</td>
      <td>221.0</td>
      <td>NaN</td>
      <td>129</td>
      <td>3546</td>
      <td>9</td>
      <td>24</td>
    </tr>
    <tr>
      <th>2</th>
      <td>9</td>
      <td>e83144dd-bb95-49fe-b1dd-00bab25cca9e</td>
      <td>Robert Miles</td>
      <td>1.0</td>
      <td>105.0</td>
      <td>1.0</td>
      <td>1260</td>
      <td>25392</td>
      <td>3</td>
      <td>243</td>
    </tr>
    <tr>
      <th>3</th>
      <td>10</td>
      <td>59e7ace7-3233-4f56-af78-4765957402cb</td>
      <td>Vincent Gallo</td>
      <td>1.0</td>
      <td>222.0</td>
      <td>1.0</td>
      <td>273</td>
      <td>6192</td>
      <td>6</td>
      <td>27</td>
    </tr>
  </tbody>
</table>
</div>

**pta_mta table has revenue and tickets sold. This table was created using a pdf file from [www.pollstar website ](https://data.pollstar.com/Chart/2022/07/072522_top.touring.artists_1020.pdf) which had top 150 successful music tours and using
others features from musicbrainz and listenbrainz for those top 150 touring artists. lc is listens count per artist, uc is users count per artist, rc is release count per artist and cc is collaboration count per artist**
<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>id</th>
      <th>gid</th>
      <th>name</th>
      <th>type</th>
      <th>area</th>
      <th>gender</th>
      <th>gross_revenue</th>
      <th>tickets_sold</th>
      <th>uc</th>
      <th>lc</th>
      <th>cc</th>
      <th>rc</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>17</td>
      <td>72c536dc-7137-4477-a521-567eeb840fa8</td>
      <td>Bob Dylan</td>
      <td>1</td>
      <td>222</td>
      <td>1</td>
      <td>391967919</td>
      <td>7252904</td>
      <td>11314</td>
      <td>712484</td>
      <td>560</td>
      <td>48776</td>
    </tr>
    <tr>
      <th>1</th>
      <td>71</td>
      <td>e01646f2-2a04-450d-8bf2-0d993082e058</td>
      <td>Phish</td>
      <td>2</td>
      <td>222</td>
      <td>0</td>
      <td>595859900</td>
      <td>13501959</td>
      <td>813</td>
      <td>132987</td>
      <td>15</td>
      <td>3138</td>
    </tr>
    <tr>
      <th>2</th>
      <td>89</td>
      <td>79239441-bfd5-4981-a70c-55c3f15c1287</td>
      <td>Madonna</td>
      <td>1</td>
      <td>222</td>
      <td>2</td>
      <td>1389746222</td>
      <td>11672443</td>
      <td>4319</td>
      <td>445371</td>
      <td>80</td>
      <td>8736</td>
    </tr>
    <tr>
      <th>3</th>
      <td>92</td>
      <td>9a2afb1e-504c-443e-acff-6c40ce75b1a1</td>
      <td>Yanni</td>
      <td>1</td>
      <td>84</td>
      <td>1</td>
      <td>190851725</td>
      <td>3643584</td>
      <td>516</td>
      <td>12381</td>
      <td>6</td>
      <td>291</td>
    </tr>
    <tr>
      <th>4</th>
      <td>93</td>
      <td>65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab</td>
      <td>Metallica</td>
      <td>2</td>
      <td>222</td>
      <td>0</td>
      <td>1219599179</td>
      <td>19468173</td>
      <td>3827</td>
      <td>836578</td>
      <td>203</td>
      <td>12572</td>
    </tr>
  </tbody>
</table>
</div>

**This modules uses revenue and ticket sold per artist to assign a success rate like high, medium and low and create a modified pta_mta table like below**

<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>type</th>
      <th>area</th>
      <th>gender</th>
      <th>uc</th>
      <th>lc</th>
      <th>cc</th>
      <th>rc</th>
      <th>success_rate</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>1</td>
      <td>222</td>
      <td>1</td>
      <td>11314</td>
      <td>712484</td>
      <td>560</td>
      <td>48776</td>
      <td>medium</td>
    </tr>
    <tr>
      <th>1</th>
      <td>2</td>
      <td>222</td>
      <td>0</td>
      <td>813</td>
      <td>132987</td>
      <td>15</td>
      <td>3138</td>
      <td>medium</td>
    </tr>
    <tr>
      <th>2</th>
      <td>1</td>
      <td>222</td>
      <td>2</td>
      <td>4319</td>
      <td>445371</td>
      <td>80</td>
      <td>8736</td>
      <td>medium</td>
    </tr>
    <tr>
      <th>3</th>
      <td>1</td>
      <td>84</td>
      <td>1</td>
      <td>516</td>
      <td>12381</td>
      <td>6</td>
      <td>291</td>
      <td>low</td>
    </tr>
    <tr>
      <th>4</th>
      <td>2</td>
      <td>222</td>
      <td>0</td>
      <td>3827</td>
      <td>836578</td>
      <td>203</td>
      <td>12572</td>
      <td>medium</td>
    </tr>
  </tbody>
</table>
</div>

**An entry like below would be passed by ml model builder to this module to get the success rate of a set of features per artist from the mta table which are similar to the above modified pta_mta table. This modules uses the euclidean distances to find out which entry in the modified pta_mta matches closely with the input entry and assigns that matched pta_mta entry's success rate to input entry's success rate**

<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>type</th>
      <th>area</th>
      <th>gender</th>
      <th>uc</th>
      <th>lc</th>
      <th>cc</th>
      <th>rc</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>2</td>
      <td>3821</td>
      <td>0</td>
      <td>3699</td>
      <td>527460</td>
      <td>20</td>
      <td>1350</td>
    </tr>
  </tbody>
</table>
</div>

**Output for each entry would be like below**
high, medium or low

**For 80% of the entries in the mta table, success rate is assigned using this module. pta table with success_rate column is used for training a classification model to 
predict the success of a music artist whose revenue and ticket sold features are not known**

