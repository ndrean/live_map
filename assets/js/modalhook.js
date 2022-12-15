// export const ModalHook = {
//   mounted() {
//     console.log("modals");
//   },
//   updated() {
//     let self = this;
//     const modal = document.getElementById("modal-window");

//     // S'assure que la fenêtre modale possède un contenu (lorsque socket.assigns.modal != nil)
//     if (modal !== null) {
//       const span = document.getElementsByClassName("close")[0];

//       // Un clique sur la croix: envoyer le signal closemodal à window_live.ex
//       span.onclick = function () {
//         self.pushEvent("closemodal", {});
//       };

//       // Un clique à l'extérieur de la fenêtre modale:
//       // envoyer le signal closemodal à window_live.ex
//       window.onclick = function (event) {
//         if (event.target == modal) {
//           self.pushEvent("closemodal", {});
//         }
//       };
//     }
//   },
// };
