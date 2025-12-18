<template>
  <card type="chart">
    <template slot="header">
      <div class="row">
        <div class="col-sm-6">
          <h5 class="card-category">{{ cardTitle }}</h5>
          <h3 class="card-title">{{ cardCategory }}</h3>
        </div>
        <div class="col-sm-6">
          <div
            class="btn-group btn-group-toggle float-right"
            data-toggle="buttons"
          >
            <label
              v-for="(limit, index) in limitData.limitOptions"
              :key="limit"
              class="btn btn-sm btn-primary btn-simple"
              :class="{
                active: limitData.selectedLimit === limit,
              }"
              :id="index"
            >
              <input
                type="radio"
                @click="limitData.selectedLimit = limit"
                name="options"
                autocomplete="off"
                :disabled="isLoading"
                :checked="limitData.selectedLimit === limit"
              />
              {{ limit }}
            </label>
          </div>
        </div>
      </div>
    </template>
    <div class="chart-area">
      <Loading v-if="isLoading" />
      <template v-else>
        <line-chart
          style="height: 100%"
          :chart-data="chartDataObject.chartData"
          :gradient-stops="chartDataObject.gradientStops"
          :extra-options="chartDataObject.extraOptions"
        >
        </line-chart>
      </template>
    </div>
  </card>
</template>
<script>
import config from "@/config";
import LineChart from "@/components/Charts/LineChart";
import Loading from "./Loading.vue";

export default {
  name: "ArtistLineChart",
  components: {
    LineChart,
    Loading,
  },
  props: {
    cardCategory: {
      type: String,
      required: true,
    },
    cardTitle: {
      type: String,
      required: true,
    },
    apiCallback: {
      type: Function,
      required: true,
    },
    lineColor: {
      type: String,
      required: false,
      default: config.colors.default,
    },
  },
  data() {
    return {
      isLoading: true,
      limitData: {
        limitOptions: [10, 20, 30, 40, 50],
        selectedLimit: 10,
      },
      dataset: [],
      chartDataObject: {},
    };
  },
  computed: {
    labels() {
      return this.dataset?.map((item) => item.name) ?? [];
    },
    values() {
      return this.dataset?.map((item) => item.count) ?? [];
    },
  },
  mounted() {
    this.loadData();
  },
  watch: {
    isLoading: "setupChart",
    "limitData.selectedLimit": "loadData",
  },
  methods: {
    setupChart() {
      const chartData = this.getLineChartData(
        this.cardCategory,
        this.labels,
        this.values
      );
      this.chartDataObject = chartData;
    },
    async loadData() {
      this.isLoading = true;
      const data = await this.apiCallback(this.limitData.selectedLimit);
      this.dataset = data;
      this.isLoading = false;
    },
    getLineChartData(label, labels, data) {
      return {
        extraOptions: {
          maintainAspectRatio: false,
          legend: {
            display: false,
          },
          responsive: true,
          tooltips: {
            backgroundColor: "#f5f5f5",
            titleFontColor: "#333",
            bodyFontColor: "#666",
            bodySpacing: 4,
            xPadding: 12,
            mode: "nearest",
            intersect: 0,
            position: "nearest",
          },
          scales: {
            yAxes: [
              {
                barPercentage: 1.6,
                gridLines: {
                  drawBorder: false,
                  color: "rgba(29,140,248,0.0)",
                  zeroLineColor: "transparent",
                },
                ticks: {
                  suggestedMin: 60,
                  suggestedMax: 125,
                  padding: 20,
                  fontColor: "#9a9a9a",
                },
              },
            ],

            xAxes: [
              {
                barPercentage: 1.6,
                gridLines: {
                  drawBorder: false,
                  color: "rgba(225,78,202,0.1)",
                  zeroLineColor: "transparent",
                },
                ticks: {
                  padding: 20,
                  fontColor: "#9a9a9a",
                },
              },
            ],
          },
        },
        chartData: {
          labels,
          datasets: [
            {
              label,
              fill: true,
              borderColor: config.colors.primary,
              borderWidth: 2,
              borderDash: [],
              borderDashOffset: 0.0,
              pointBackgroundColor: config.colors.primary,
              pointBorderColor: "rgba(255,255,255,0)",
              pointHoverBackgroundColor: config.colors.primary,
              pointBorderWidth: 20,
              pointHoverRadius: 4,
              pointHoverBorderWidth: 15,
              pointRadius: 4,
              data,
            },
          ],
        },
        gradientColors: config.colors.primaryGradient,
        gradientStops: [1, 0.2, 0],
      };
    },
  },
};
</script>
<style scoped>
.chart-area {
  height: auto;
}
</style>
