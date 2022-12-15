// export const TransitionHook = {
//   mounted() {
//     this.from = this.el.getAttribute("data-transition-from").split(" ");
//     this.to = this.el.getAttribute("data-transition-to").split(" ");
//     this.el.classList.add(...this.from);

//     setTimeout(() => {
//       this.el.classList.remove(...this.from);
//       this.el.classList.add(...this.to);
//     }, 10);
//   },
//   updated() {
//     this.el.classList.remove("transition");
//     this.el.classList.remove(...this.from);
//   },
// };
