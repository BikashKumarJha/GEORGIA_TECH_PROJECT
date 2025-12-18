<template>
  <card type="chart">
    <template slot="header">
      <div class="row">
        <div class="col-6">
          <h5 class="card-category">Artist</h5>
          <h3 class="card-title">
            Top {{ limitData.selectedLimit }} Music Artist Collaboration Count
          </h3>
        </div>
        <div class="col-6">
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
    <div class="card-area">
      <Loading
        :class="{ 'd-block': isLoading, 'd-none': !isLoading }"
        :customStyles="customStyle"
      />
      <svg
        id="svgContainer"
        ref="graphContainer"
        :class="{ 'd-block': !isLoading, 'd-none': isLoading }"
      ></svg>
    </div>
  </card>
</template>

<script>
import * as d3 from "d3";
import { queryArtistCollaboration } from "./dataService";
import Loading from "./Loading.vue";

export default {
  name: "artist-collaboration-chart",
  components: {
    Loading,
  },
  data() {
    return {
      customStyle: { color: "black", textAlign: "center" },
      isLoading: true,
      limitData: {
        limitOptions: [25, 35, 45, 55, 65],
        selectedLimit: 25,
      },
      dataset: [],
      graphContainerRef: null,
    };
  },
  mounted() {
    this.graphContainerRef = this.$refs.graphContainer;
    this.loadData();
  },
  watch: {
    "limitData.selectedLimit": "loadData",
  },
  methods: {
    async loadData() {
      this.isLoading = true;
      const data = await queryArtistCollaboration(this.limitData.selectedLimit);
      this.dataset = data;
      this.setupGraph();
      this.isLoading = false;
    },
    setupGraph() {
      this.graphContainerRef.innerHTML = "";

      var links = this.dataset.slice().map((item) => {
        return {
          source: item.source.name,
          target: item.target.name,
          value: item.value,
        };
      });

      var nodes = {};
      // compute the distinct nodes from the links.
      links.forEach((link) => {
        link.source =
          nodes[link.source] || (nodes[link.source] = { name: link.source });
        link.target =
          nodes[link.target] || (nodes[link.target] = { name: link.target });
      });

      var degrees = {};
      for (var i = 0; i < d3.values(nodes).length; i++) {
        degrees[i] = 0;
      }
      for (var i = 0; i < d3.values(nodes).length; i++) {
        degrees[i] = links.filter(
          (link) => link.source === d3.values(nodes)[i]
        ).length;
        degrees[i] += links.filter(
          (link) => link.target === d3.values(nodes)[i]
        ).length;
      }

      var radiusScale = d3
        .scaleLinear()
        .domain([0, d3.max(d3.values(degrees))])
        .range([5, 30]);

      var width = 1470;
      var height = 1470;

      var force = d3
        .forceSimulation()
        .nodes(d3.values(nodes))
        .force("link", d3.forceLink(links).distance(100))
        .force("center", d3.forceCenter(width / 2, height / 2))
        .force("x", d3.forceX())
        .force("y", d3.forceY())
        .force("charge", d3.forceManyBody().strength(-250))
        .alphaTarget(1)
        .on("tick", tick);

      var svg = d3
        .select("#svgContainer")
        .attr("width", width - 30)
        .attr("height", height - 30);
      // .attr("transform", "translate(" + 30 + "," + 30 + ")");

      // add the links
      var path = svg
        .append("g")
        .selectAll("path")
        .data(links)
        .enter()
        .append("path")
        .attr("class", "link")
        .attr("fill", "none")
        .attr("stroke", "green")
        .attr("stroke-dasharray", "2")
        .attr("stroke-width", "2");
      // define the nodes stroke-dasharray

      var node = svg
        .selectAll(".node")
        .data(force.nodes())
        .enter()
        .append("g")
        .attr("class", "node")
        .call(
          d3
            .drag()
            .on("start", dragStarted)
            .on("drag", dragged)
            .on("end", dragEnded)
        )
        .on("dblclick", doubleClick);

      // add labels
      node
        .append("text")
        .attr("class", "label")
        .text((d) => d.name)
        .attr("text-anchor", "start")
        .attr("dy", (d) => -radiusScale(degrees[d.index]))
        .style("font-weight", "bold");

      var colorScale = d3
        .scaleSequential(d3.interpolateViridis)
        .domain([d3.max(d3.values(degrees)), 0]);

      // add the nodes
      node
        .append("circle")
        .attr("id", function (d) {
          return d.name.replace(/\s+/g, "").toLowerCase();
        })
        .style("fill", (d) => colorScale(degrees[d.index]))
        .attr("r", (d) => radiusScale(degrees[d.index]));

      function tick() {
        path.attr("d", function (d) {
          var dx = d.target.x - d.source.x,
            dy = d.target.y - d.source.y,
            dr = Math.sqrt(dx * dx + dy * dy);
          return (
            "M" +
            d.source.x +
            "," +
            d.source.y +
            "A" +
            dr +
            "," +
            dr +
            " 0 0,1 " +
            d.target.x +
            "," +
            d.target.y
          );
        });
        node.attr("transform", function (d) {
          return "translate(" + d.x + "," + d.y + ")";
        });
      }

      function dragStarted(d) {
        if (!d3.event.active) force.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
        d.fixed = true;
      }

      function dragged(d) {
        d.fixed = true;
        d.fx = d3.event.x;
        d.fy = d3.event.y;
      }

      function dragEnded(d) {
        if (!d3.event.active) force.alphaTarget(0);
        if (d.fixed == true) {
          d.fx = d.x;
          d.fy = d.y;
          var cid = "#" + d.name.replace(/\s+/g, "").toLowerCase();
          d3.select(cid).style("fill", "black");
        } else {
          d.fx = null;
          d.fy = null;
          var cid = "#" + d.name.replace(/\s+/g, "").toLowerCase();
          d3.select(cid).style("fill", colorScale(degrees[d.index]));
        }
      }

      function doubleClick(d) {
        d.fixed = false;
        d.fx = null;
        d.fy = null;
        var cid = "#" + d.name.replace(/\s+/g, "").toLowerCase();
        d3.select(cid).style("fill", colorScale(degrees[d.index]));
      }
    },
  },
};
</script>

<style scoped>
.card-area {
  background-color: white;
  color: black;
}
.link {
  fill: none;
  stroke: #666;
  stroke-width: 1px;
}
/* circle {
  fill: #ccc !important;
  stroke: #fff;
  stroke: black;
  stroke-width: 1px;
} */
text {
  fill: #000;
  font: 10px sans-serif;
  pointer-events: none;
}
</style>
