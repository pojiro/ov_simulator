// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// assets/js/app.js
import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let hooks = {};
hooks.canvases = {
  mounted() {
    let canvas1 = document.getElementById("canvas1")
    let canvas2 = document.getElementById("canvas2")
    let ctx1 = canvas1.getContext("2d")
    let ctx2 = canvas2.getContext("2d")

    Object.assign(this, {canvas1, ctx1, canvas2, ctx2})
  },
  updated(){
    let {canvas1, ctx1, canvas2, ctx2} = this
    let particles = JSON.parse(this.el.dataset.particles)
    let spaceSize = Number(this.el.dataset.spaceSize)

    let circuitRadius = 150
    let particleRadius = 10

    ctx1.clearRect(0, 0, canvas1.width, canvas1.height)
    ctx2.clearRect(0, 0, canvas2.width, canvas2.height)
    particles.forEach(particle => {
      let color_value = Math.round(particle.velocity / 2.0 * 200)
      // Draw Circuit
      ctx1.fillStyle = `rgba(${color_value}, 0, ${255 - color_value}, 1)`
      ctx1.beginPath()
      ctx1.arc(
        particleRadius + circuitRadius + circuitRadius * Math.cos(2 * Math.PI/spaceSize * particle.position),
        particleRadius + circuitRadius + circuitRadius * Math.sin(2 * Math.PI/spaceSize * particle.position),
        particleRadius, 0, 2 * Math.PI);
      ctx1.fill();

      // Draw limit cycle
      ctx2.fillStyle = `rgba(${color_value}, 0, ${255 - color_value}, 1)`
      ctx2.beginPath()
      ctx2.arc(
        particle.headway / 4.0 * 320,
        320 - particle.velocity / 2.0 * 320,
        particleRadius, 0, 2 * Math.PI);
      ctx2.fill();
    })
  }
};


let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: hooks});
liveSocket.connect()

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
