<template>
  <div>
    <div class="row">
      <div class="col-12">
        <card type="chart">
          <template slot="header">
            <h5 class="card-category">Artist</h5>
            <h3 class="card-title">Release Count</h3>
          </template>
          <div class="chart-area">
            <bar-chart
              style="height: 100%"
              ref="artistReleaseChart"
              chart-id="artist-bar-chart"
              :chart-data="artistReleaseChart.chartData"
              :gradient-stops="artistReleaseChart.gradientStops"
              :extra-options="artistReleaseChart.extraOptions"
            >
            </bar-chart>
          </div>
        </card>
      </div>
    </div>

    <div class="row">
      <div class="col-6">
        <card type="chart">
          <template slot="header">
            <h5 class="card-category">Country</h5>
            <h3 class="card-title">Artist Count</h3>
          </template>
          <div class="chart-area">
            <bar-chart
              style="height: 100%"
              ref="countryArtistChart"
              chart-id="country-artist-bar-chart"
              :chart-data="countryArtistChart.chartData"
              :gradient-stops="countryArtistChart.gradientStops"
              :extra-options="countryArtistChart.extraOptions"
            ></bar-chart>
          </div>
        </card>
      </div>
      <div class="col-6">
        <card type="chart">
          <template slot="header">
            <h5 class="card-category">Country</h5>
            <h3 class="card-title">Release Count</h3>
          </template>
          <div class="chart-area">
            <bar-chart
              style="height: 100%"
              ref="countryReleaseChart"
              chart-id="country-release-bar-chart"
              :chart-data="countryReleaseChart.chartData"
              :gradient-stops="countryReleaseChart.gradientStops"
              :extra-options="countryReleaseChart.extraOptions"
            ></bar-chart>
          </div>
        </card>
      </div>
    </div>

    <div class="row justify-content-around">
      <div class="col-8">
        <card type="chart">
          <template slot="header">
            <h5 class="card-category">Country</h5>
            <h3 class="card-title">Release Count</h3>
          </template>
          <div class="chart-area" style="height: 100%">
            <line-chart
              style="height: 100%"
              chart-id="green-line-chart"
              :chart-data="greenLineChart.chartData"
              :gradient-stops="greenLineChart.gradientStops"
              :extra-options="greenLineChart.extraOptions"
            >
            </line-chart>
          </div>
        </card>
      </div>
    </div>
  </div>
</template>
<script>
import * as chartConfigs from "@/components/Charts/config";
import config from "@/config";
import BarChart from "@/components/Charts/BarChart";
import LineChart from "@/components/Charts/LineChart";

import {
  ArtistReleaseCount,
  CountryArtistCount,
  CountryReleaseCount,
} from "@/assets/data/sample_data";

export default {
  name: "Testing Ground",
  components: {
    BarChart,
    LineChart,
  },
  data() {
    return {
      artistReleaseChart: {
        extraOptions: chartConfigs.barChartOptions,
        chartData: this.getChartDataObj(),
        gradientColors: config.colors.primaryGradient,
        gradientStops: [1, 0.4, 0],
      },
      countryArtistChart: {
        extraOptions: chartConfigs.barChartOptions,
        chartData: this.getChartDataObj(),
        gradientColors: config.colors.primaryGradient,
        gradientStops: [1, 0.4, 0],
      },
      countryReleaseChart: {
        extraOptions: chartConfigs.barChartOptions,
        chartData: this.getChartDataObj(),
        gradientColors: config.colors.primaryGradient,
        gradientStops: [1, 0.4, 0],
      },
      greenLineChart: {
        extraOptions: chartConfigs.greenChartOptions,
        chartData: {
          labels: ["JUL", "AUG", "SEP", "OCT", "NOV"],
          datasets: [
            {
              label: "My First dataset",
              fill: true,
              borderColor: config.colors.danger,
              borderWidth: 2,
              borderDash: [],
              borderDashOffset: 0.0,
              pointBackgroundColor: config.colors.danger,
              pointBorderColor: "rgba(255,255,255,0)",
              pointHoverBackgroundColor: config.colors.danger,
              pointBorderWidth: 20,
              pointHoverRadius: 4,
              pointHoverBorderWidth: 15,
              pointRadius: 4,
              data: [90, 27, 60, 12, 80],
            },
          ],
        },
        gradientColors: [
          "rgba(66,134,121,0.15)",
          "rgba(66,134,121,0.0)",
          "rgba(66,134,121,0)",
        ],
        gradientStops: [1, 0.4, 0],
      },
    };
  },
  mounted() {
    this.initializeData();
  },
  methods: {
    initializeData() {
      this.loadArtistReleaseData();
      this.loadCountryArtistData();
      this.loadCountryReleaseData();
    },
    loadArtistReleaseData() {
      const chartData = this.getChartDataObj(
        ArtistReleaseCount.map((item) => item?.name ?? ""),
        ArtistReleaseCount.map((item) => item?.release_count ?? 0)
      );
      this.artistReleaseChart.chartData = chartData;
      this.$refs.artistReleaseChart.updateGradients(chartData);
    },
    loadCountryArtistData() {
      const chartData = this.getChartDataObj(
        CountryArtistCount.map((item) => item?.country_name ?? ""),
        CountryArtistCount.map((item) => item?.artist_count ?? 0)
      );
      this.countryArtistChart.chartData = chartData;
      this.$refs.countryArtistChart.updateGradients(chartData);
    },
    loadCountryReleaseData() {
      const chartData = this.getChartDataObj(
        CountryReleaseCount.map((item) => item?.country_name ?? ""),
        CountryReleaseCount.map((item) => item?.release_count ?? 0)
      );
      this.countryReleaseChart.chartData = chartData;
      this.$refs.countryReleaseChart.updateGradients(chartData);

      const chartData2 = {
        labels: CountryReleaseCount.map((item) => item?.country_name ?? ""),
        datasets: [
          {
            label: "Country Release",
            fill: true,
            borderColor: config.colors.danger,
            borderWidth: 2,
            borderDash: [],
            borderDashOffset: 0.0,
            pointBackgroundColor: config.colors.danger,
            pointBorderColor: "rgba(255,255,255,0)",
            pointHoverBackgroundColor: config.colors.danger,
            pointBorderWidth: 20,
            pointHoverRadius: 4,
            pointHoverBorderWidth: 15,
            pointRadius: 4,
            data: CountryReleaseCount.map((item) => item?.release_count ?? 0),
          },
        ],
      };
      this.greenLineChart.chartData = chartData2;
    },
    getChartDataObj(labels = [], data = []) {
      const borderColors = [
        config.colors.default,
        config.colors.primary,
        config.colors.info,
        config.colors.danger,
        config.colors.teal,
      ];
      const randomIndex = Math.floor(Math.random() * borderColors.length);
      return {
        labels,
        datasets: [
          {
            label: "Releases",
            fill: true,
            borderColor: borderColors[randomIndex],
            borderWidth: 2,
            borderDash: [],
            borderDashOffset: 0.0,
            data,
          },
        ],
      };
    },
  },
};
</script>
<style></style>
