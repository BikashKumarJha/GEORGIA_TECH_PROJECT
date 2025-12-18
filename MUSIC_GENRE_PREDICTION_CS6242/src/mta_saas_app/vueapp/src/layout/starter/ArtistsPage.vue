<template>
  <div>
    <div class="row">
      <div class="col-12">
        <ArtistBarChartCard
          cardTitle="Artist"
          cardCategory="Release Count"
          :apiCallback="queryArtistReleasesCallback"
          :barColor="barColors.danger"
        />
      </div>
    </div>

    <div class="row justify-content-around">
      <div class="col-6">
        <ArtistBarChartCard
          cardTitle="Artist"
          cardCategory="Gross Revenue"
          :apiCallback="queryTopArtistsByRevenueCallback"
          :barColor="barColors.info"
        />
      </div>
      <div class="col-6">
        <ArtistBarChartCard
          cardTitle="Artist"
          cardCategory="Tickets Sold"
          :apiCallback="queryTopArtistsByTicketsCallback"
          :barColor="barColors.teal"
        />
      </div>
    </div>

    <div class="row justify-content-around">
      <div class="col-6">
        <ArtistLineChartCard
          cardTitle="Artist"
          cardCategory="Listen Count"
          :apiCallback="queryArtistListenersCallback"
          :lineColor="barColors.teal"
        />
      </div>
      <div class="col-6">
        <ArtistLineChartCard
          cardTitle="Artist"
          cardCategory="User Count"
          :apiCallback="queryArtistUsersCallback"
          :lineColor="barColors.info"
        />
      </div>
    </div>

    <div class="row justify-content-around">
      <div class="col-6">
        <ArtistLineChartCard
          cardTitle="Country"
          cardCategory="Artist"
          :apiCallback="queryCountryArtistCallback"
          :lineColor="barColors.danger"
        />
      </div>
      <div class="col-6">
        <ArtistLineChartCard
          cardTitle="Country"
          cardCategory="Release"
          :apiCallback="queryCountryReleaseCallback"
          :lineColor="barColors.default"
        />
      </div>
    </div>

    <div class="row justify-content-around">
      <div class="col-12">
        <ArtistCollabChart />
      </div>
    </div>
  </div>
</template>
<script>
import ArtistBarChartCard from "./ArtistBarChartCard.vue";
import ArtistLineChartCard from "./ArtistLineChartCard.vue";
import ArtistCollabChart from "./ArtistCollabChart.vue";
import * as DataService from "./dataService";
import config from "@/config";

export default {
  name: "artists-page",
  components: {
    ArtistBarChartCard,
    ArtistCollabChart,
    ArtistLineChartCard,
  },
  data() {
    return {
      barColors: config.colors,
    };
  },
  methods: {
    queryArtistReleasesCallback: DataService.queryArtistReleases,
    queryTopArtistsByRevenueCallback: DataService.queryTopArtistsByRevenue,
    queryTopArtistsByTicketsCallback: DataService.queryTopArtistsByTicketsSold,
    queryArtistListenersCallback: DataService.queryArtistListeners,
    queryArtistUsersCallback: DataService.queryArtistUsers,
    queryCountryArtistCallback: DataService.queryCountryArtist,
    queryCountryReleaseCallback: DataService.queryCountryReleases,
  },
};
</script>
<style></style>
