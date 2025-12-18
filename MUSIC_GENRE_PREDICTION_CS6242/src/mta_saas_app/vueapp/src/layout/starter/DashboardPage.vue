<template>
  <div class="row">
    <div class="row justify-content-around">
      <div class="col-7">
        <card title="Music Industry Visualizations & Tour Analytics">
          <template slot="footer">
            <a
              class="float-left"
              href="https://gtvault-my.sharepoint.com/:w:/g/personal/spothana3_gatech_edu/EfZYySIRKpNNooW23_n8l0QBnZYujNvZUxVip98bk2Za6A?e=wqKlJT"
              target="_blank"
              rel="noopener noreferrer"
              >Project Document</a
            >
            <a
              class="float-right"
              href="https://gtvault-my.sharepoint.com/:p:/g/personal/spothana3_gatech_edu/ER1o9vw8sF9Gt6oHTMxvtS4B4IG3-4lZOQuM59yJZae9Jg?e=8aX308"
              target="_blank"
              rel="noopener noreferrer"
              >Project Poster</a
            >
          </template>
          <div class="card-area">
            <p>
              <span class="font-weight-bold">Objective:</span>
              Create a cloud-based app predicting music tour success by merging
              diverse data sources for informed artist and location selection.
            </p>
            <p>
              <span class="font-weight-bold">Approach:</span>
              Utilize MusicBrainz & ListenBrainz data via Google Cloud for
              predictions, employing a similarity algorithm and ML models for
              revenue prediction. Visualize data using Azure & Google Cloud,
              create a VueJS frontend, and host on Azure.
            </p>
            <p>
              <span class="font-weight-bold">Value:</span>
              Assist music enthusiasts, entrepreneurs, and investors in choosing
              optimal tours while generating revenue through ads and artist
              registrations.
            </p>
            <p>
              <span class="font-weight-bold">Challenges:</span>
              Handling data accuracy, privacy, and legal concerns while
              integrating various data sources.
            </p>
            <p>
              <span class="font-weight-bold">Results:</span>
              A 96% accurate model predicting tour success, ready for
              integration with user inputs.
            </p>
          </div>
        </card>
      </div>
    </div>
    <div class="col-4" v-for="(dataSource, index) in dataInCards" :key="index">
      <card>
        <template slot="header">
          <h5 class="card-category">{{ dataSource.category }}</h5>
          <h3 class="card-title">{{ dataSource.title }}</h3>
        </template>
        <template slot="image">
          <div class="data-source-image-container">
            <img :src="dataSource.imageUrl" />
          </div>
        </template>
        <template slot="footer">
          <a :href="dataSource.link" target="_blank">Learn more</a>
        </template>
        <div class="card-area">
          <p>
            {{ dataSource.content }}
          </p>
        </div>
      </card>
    </div>
  </div>
</template>

<script>
export default {
  name: "dashboard-page",
  components: {},
  data() {
    return {
      dataInCards: [
        {
          category: "Datasource",
          title: "MusicBrainz",
          imageUrl: "https://static.metabrainz.org/MB/header-logo-1f7dc2a.svg",
          link: "https://musicbrainz.org/",
          content:
            "The MusicBrainz dataset serves as a vast music encyclopedia encompassing artists, albums, tracks, genres, and their intricate relationships. With detailed information on artists, recorded works, and interconnections between them, it contains album titles, track details, and lengths. Hosted through a PostgreSQL server due to its substantial size, it's not available on mainstream cloud platforms. Accessible via Python, Azure Data Studio, and a .NET library, it's invaluable for exploring music history, artist connections, and enhancing music recommendation systems.",
          content2:
            "A comprehensive music encyclopedia with artists, albums, tracks, and relationships. Captures extensive artist info, album details, and aids in music history exploration. Accessed via PostgreSQL, Python, Azure Data Studio, and .NET library.",
        },
        {
          category: "Datasource",
          title: "ListenBrainz",
          imageUrl: "https://listenbrainz.org/static/img/listenbrainz-logo.svg",
          link: "https://listenbrainz.org/",
          content:
            "ListenBrainz captures real-time music metadata, chronicling users' recent music listening habits. It records artist, album, recording, and timestamps of user-listened music, along with additional submitted data. This information streams directly to Google Cloud BigQuery, ensuring near-instant availability. Ideal for analyzing user music preferences and behavior, it's crucial for crafting efficient music recommendation systems, accessible via BigQuery, Python, Azure Data Studio, and a .NET library.",
          content2:
            "Real-time music metadata capturing user habits, artist, album, timestamp data. Streamed to Google BigQuery instantly for preference analysis. Essential for music recommendation systems, accessible via BigQuery, Python, Azure Data Studio, and .NET library.",
        },
        {
          category: "Datasource",
          title: "Pollstar",
          imageUrl:
            "https://seekvectorlogo.net/wp-content/uploads/2023/06/pollstar-vector-logo.png",
          link: "https://www.pollstar.com/",
          content:
            "Derived from a subset of top touring artists (150 entries) from Pollstar, this dataset aims to predict revenue and sales for music tours. As the full ticket and sales info from Pollstar was deemed costly for student projects, this subset serves as a valuable resource, offering insights into revenue estimation and sales forecasting for music tours.",
          content2:
            "Subset from Pollstar's top touring artists (150 entries) for revenue and sales prediction. Valuable insights for music tour revenue estimation, acquired freely from Pollstar for student projects.",
        },
      ],
    };
  },
};
</script>

<style>
.data-source-image-container {
  display: flex;
  justify-content: center;
  align-items: center;
  /* margin-top: 15px; */
  height: 200px;
  overflow: hidden;
}
.data-source-image-container img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}
</style>
