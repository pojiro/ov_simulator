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
hooks.canvas = {
  mounted() {
    let canvas = this.el
    let ctx = canvas.getContext("2d")

    Object.assign(this, {canvas, ctx})
    console.log("mounted", this)
  },
  updated(){
    let {canvas, ctx} = this
    let particles = JSON.parse(canvas.dataset.particles)
    let L = 50

    let circuitRadius = 150
    let particleRadius = 10

    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.fillStyle = "rgba(128, 0, 255, 1)"
    particles.forEach(particle => {
      ctx.beginPath()
      ctx.arc(
        particleRadius + circuitRadius + circuitRadius * Math.cos(2 * Math.PI/L * particle.position),
        particleRadius + circuitRadius + circuitRadius * Math.sin(2 * Math.PI/L * particle.position),
        particleRadius, 0, 2 * Math.PI);
      ctx.fill();
    })

    console.log("updated")
  }
};


let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: hooks});
liveSocket.connect()

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
