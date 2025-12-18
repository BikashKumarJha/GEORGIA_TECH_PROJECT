<template>
  <nav
    class="navbar navbar-expand-lg navbar-absolute"
    :class="{ 'bg-white': showMenu, 'navbar-transparent': !showMenu }"
  >
    <div class="container-fluid">
      <div class="navbar-wrapper">
        <div
          class="navbar-toggle d-inline"
          :class="{ toggled: $sidebar.showSidebar }"
        >
          <button type="button" class="navbar-toggler" @click="toggleSidebar">
            <span class="navbar-toggler-bar bar1"></span>
            <span class="navbar-toggler-bar bar2"></span>
            <span class="navbar-toggler-bar bar3"></span>
          </button>
        </div>
        <a class="navbar-brand" href="#">{{ routeName }}</a>
      </div>
      <button
        class="navbar-toggler"
        type="button"
        @click="toggleMenu"
        data-toggle="collapse"
        data-target="#navigation"
        aria-controls="navigation-index"
        aria-label="Toggle navigation"
      >
        <span class="navbar-toggler-bar navbar-kebab"></span>
        <span class="navbar-toggler-bar navbar-kebab"></span>
        <span class="navbar-toggler-bar navbar-kebab"></span>
      </button>

      <collapse-transition>
        <div class="collapse navbar-collapse show" v-show="showMenu">
          <ul class="navbar-nav" :class="$rtl.isRTL ? 'mr-auto' : 'ml-auto'">
            <div
              class="btn-group btn-group-toggle float-right"
              data-toggle="buttons"
            >
              <label
                v-for="(theme, index) in themeData.options"
                :key="index"
                class="btn btn-sm btn-primary btn-simple mt-auto"
                :class="{
                  active: themeData.selectedTheme === theme,
                }"
                :id="index"
              >
                <input
                  type="radio"
                  @click="() => changeTheme(theme)"
                  autocomplete="off"
                  :checked="themeData.selectedTheme === theme"
                />
                {{ theme }}
              </label>
            </div>
            <base-button round icon type="primary">
              <i class="tim-icons icon-single-02"></i>
            </base-button>
          </ul>
        </div>
      </collapse-transition>
    </div>
  </nav>
</template>
<script>
import { CollapseTransition } from "vue2-transitions";

export default {
  components: {
    CollapseTransition,
  },
  data() {
    return {
      showMenu: false,
      themeData: {
        options: ["light", "dark"],
        selectedTheme: "dark",
      },
    };
  },
  computed: {
    routeName() {
      const { name } = this.$route;
      return this.capitalizeFirstLetter(name);
    },
  },
  beforeMount() {
    const theme = document.body.classList.contains("white-content")
      ? "light"
      : "dark";
    this.themeData.selectedTheme = theme;
  },
  methods: {
    changeTheme(selectedTheme) {
      this.themeData.selectedTheme = selectedTheme;
      if (selectedTheme === "light") {
        document.body.classList.add("white-content");
      } else {
        document.body.classList.remove("white-content");
      }
    },
    capitalizeFirstLetter(string) {
      return string.charAt(0).toUpperCase() + string.slice(1);
    },
    toggleSidebar() {
      this.$sidebar.displaySidebar(!this.$sidebar.showSidebar);
    },
    hideSidebar() {
      this.$sidebar.displaySidebar(false);
    },
    toggleMenu() {
      this.showMenu = !this.showMenu;
    },
  },
};
</script>
<style></style>
