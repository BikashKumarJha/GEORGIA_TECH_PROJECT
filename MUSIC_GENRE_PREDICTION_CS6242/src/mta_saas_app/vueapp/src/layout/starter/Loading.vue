<template>
  <div class="loading">
    <p :style="customStyles">{{ loadingText }}</p>
  </div>
</template>

<script>
export default {
  name: "loading",
  data() {
    return {
      loadingText: "Loading",
    };
  },
  props: {
    customStyles: {
      type: Object,
      required: false,
      default: () => {
        color: "white";
      },
    },
  },
  mounted() {
    this.animateLoading();
  },
  methods: {
    animateLoading() {
      const dots = [".", "..", "...", "...."];
      let index = 0;

      setInterval(() => {
        this.loadingText = "Loading" + dots[index];
        index = (index + 1) % dots.length;
      }, 500);
    },
  },
};
</script>

<style>
.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  height: inherit;
}
</style>
