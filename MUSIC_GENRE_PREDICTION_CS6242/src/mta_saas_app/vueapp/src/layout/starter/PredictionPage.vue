<template>
  <div>
    <div class="row justify-content-around">
      <div class="col-6">
        <card title="Confusion Matrix">
          <template slot="image">
            <div class="card-image-custom">
              <img src="../../../public/img/conf_matrix.png" alt="" />
            </div>
          </template>
          <div class="card-area"></div>
        </card>
      </div>
      <div class="col-6">
        <card title="Classification Report">
          <template slot="image">
            <div class="card-image-custom">
              <img src="../../../public/img/classification_report.png" alt="" />
            </div>
          </template>
          <div class="card-area"></div>
        </card>
      </div>
    </div>
    <div class="row">
      <div class="col-6">
        <card>
          <template slot="header">
            <div class="row">
              <div class="col-12">
                <h3 class="card-title">Search Artist</h3>
                <h5 class="card-category">
                  Search for an artist to use to run our model on
                </h5>
              </div>
            </div>
          </template>
          <div class="row mb-2">
            <div class="col-12">
              <p>
                <i
                  ><u>
                    Disclaimer: Not all artists are available due to data
                    acquisition limitations.
                  </u></i
                >
              </p>
            </div>
          </div>
          <div class="row">
            <div class="col-8">
              <input
                type="text"
                v-model="searchQuery"
                placeholder="Search for an artist"
                class="form-control"
              />
            </div>
            <div class="col-4">
              <button
                @click="searchArtist"
                class="btn-success form-control"
                type="button"
                :disabled="isLoading"
                fill
              >
                Search
              </button>
            </div>
          </div>
          <div class="row mt-3">
            <div class="col-12">
              <template v-if="isLoading">
                <p>Searching...</p>
              </template>
              <template v-else>
                <template v-if="resultsFound">
                  <div class="row">
                    <div class="col-8">
                      <select v-model="selectedArtist" class="form-control">
                        <option
                          v-for="artist in artistData"
                          :key="artist.id"
                          style="color: black"
                        >
                          {{ artist.name }}
                        </option>
                      </select>
                    </div>
                    <div class="col-4">
                      <button
                        @click="runModel"
                        class="btn-primary form-control"
                        type="button"
                        :disabled="isModelLoading || selectedArtist === null"
                        fill
                      >
                        Run Model
                      </button>
                    </div>
                  </div>
                </template>
                <template v-else
                  ><p>
                    No results found. Try a different search query.
                  </p></template
                >
              </template>
            </div>
          </div>
        </card>
      </div>
      <div class="col-6">
        <card>
          <template slot="header">
            <div class="row">
              <div class="col-12">
                <h3 class="card-title">Model Result</h3>
                <h5 class="card-category">
                  Based on the MIVTA model this is our prediction
                </h5>
              </div>
            </div>
          </template>
          <div class="row">
            <div class="col-12">
              <template v-if="modelResult">
                <pre v-html="displayModelJSON"></pre>
              </template>
              <template v-else>
                <p>Select and artist and run the model to see results.</p>
              </template>
            </div>
          </div>
        </card>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <card>
          <template slot="header">
            <div class="row">
              <div class="col-12">
                <h3 class="card-title">About the Artist</h3>
                <h5 class="card-category">Learn more about the artist</h5>
              </div>
            </div>
          </template>
          <div
            class="row"
            :class="{ 'd-block': selectedArtist, 'd-none': !selectedArtist }"
            style="color: white"
          >
            <div class="col-12">
              <iframe
                ref="wikiIframe"
                :src="wikipediaLink"
                frameborder="0"
                width="100%"
                height="600"
              ></iframe>
            </div>
            <p
              :class="{ 'd-block': !selectedArtist, 'd-none': selectedArtist }"
            >
              Select artist to see results.
            </p>
          </div>
        </card>
      </div>
    </div>
  </div>
</template>

<script>
import { queryArtists, runModel } from "./dataService";

export default {
  name: "prediction-page",
  data() {
    return {
      isLoading: false,
      searchQuery: "",
      artistData: null,
      selectedArtist: null,
      wikipediaLink: "",
      wikiIFrameRef: null,
      modelResult: null,
      isModelLoading: false,
    };
  },
  mounted() {
    this.wikiIFrameRef = this.$refs.wikiIframe;
  },
  computed: {
    resultsFound() {
      return (this.artistData?.length ?? 0) > 1;
    },
    displayModelJSON() {
      return JSON.stringify(this.modelResult, null, 2);
    },
  },
  watch: {
    selectedArtist: "constructWikipediaLink",
  },
  methods: {
    async searchArtist() {
      this.isLoading = true;
      this.selectedArtist = null;
      this.artistData = null;
      this.modelResult = null;

      const response = await queryArtists(this.searchQuery);

      this.artistData = response;
      this.isLoading = false;
    },
    async runModel() {
      this.isModelLoading = true;
      this.modelResult = null;

      const result = await runModel(
        this.artistData.find((a) => a.name === this.selectedArtist).id
      );

      this.modelResult = result;
      this.isModelLoading = false;
    },
    constructWikipediaLink() {
      // search for music artist {selected artist} wiki on google an read first link to use as wiki link
      const artistName = this.selectedArtist;
      const formattedName = artistName.replace(/\s+/g, "_");
      // this.wikipediaLink = `https://en.wikipedia.org/wiki/${formattedName}`;
      this.wikipediaLink = `https://en.wikipedia.org/wiki/Special:Search?search=${artistName}`;
    },
  },
};
</script>
<style scoped>
.card-image-custom {
  height: 520px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
