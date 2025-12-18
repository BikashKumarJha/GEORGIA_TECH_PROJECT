import Vue from "vue";
import Router from "vue-router";
import DashboardLayout from "../layout/starter/SampleLayout.vue";
import ArtistsPage from "../layout/starter/ArtistsPage.vue";
import PredictionPage from "../layout/starter/PredictionPage.vue";
import DashboardPage from "../layout/starter/DashboardPage.vue";

Vue.use(Router);

export default new Router({
  linkExactActiveClass: "active",
  routes: [
    {
      path: "/",
      name: "home",
      redirect: "/about",
      component: DashboardLayout,
      children: [
        {
          path: "about",
          name: "about",
          components: { default: DashboardPage },
        },
        {
          path: "visualizations",
          name: "visualizations",
          components: { default: ArtistsPage },
        },
        {
          path: "model",
          name: "model",
          components: { default: PredictionPage },
        },
      ],
    },
  ],
});
