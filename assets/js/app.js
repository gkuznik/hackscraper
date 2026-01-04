// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.formatDate = {
  mounted() {
    const dateString = this.el.textContent.trim();
    const date = new Date(dateString);
    if (this.el.getAttribute("data-format") === "short") {
      this.el.textContent = date.toLocaleDateString([], {
        hour: "2-digit",
        minute: "2-digit",
      });
    } else {
      this.el.textContent = date.toLocaleDateString([], {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    }
  },
}
Hooks.AutoTimezone = {
  mounted() {
    this.el.addEventListener("click", e => {
      let locale = Intl.DateTimeFormat().resolvedOptions().timeZone
      document.getElementById("timezone-input").value = locale
    })
  }
}

Hooks.TimezoneSelector = {
  mounted() {
    const ua = navigator.userAgent.toLowerCase()
    const needsFallback = (ua.includes('android') && ua.includes('firefox')) || ua.includes('opera mini')

    if (needsFallback) {
      this.enableFallback()
    }
  },

  enableFallback() {
    const input = this.el.querySelector('#timezone-input')
    const fallbackList = this.el.querySelector('#timezone-fallback')

    // Set up input filtering
    input.addEventListener('input', (e) => {
      this.filterOptions(e.target.value.toLowerCase(), fallbackList)
    })

    // Set up option click handlers
    this.setupOptionHandlers(input, fallbackList)

    // Show/hide list on focus/blur
    input.addEventListener('focus', () => {
      this.filterOptions(input.value.toLowerCase(), fallbackList)
    })

    // Delay blur to allow clicks to register
    input.addEventListener('blur', () => {
      setTimeout(() => {
        fallbackList.style.display = 'none'
      }, 200)
    })
  },

  filterOptions(query, fallbackList) {
    fallbackList.style.display = 'block'
    const options = this.el.querySelectorAll('.timezone-option')
    let visibleCount = 0

    options.forEach(option => {
      const text = option.textContent.toLowerCase()
      const matches = text.includes(query)

      option.style.display = matches ? 'block' : 'none'
      if (matches) visibleCount++
    })

    // Show "no results" message if needed
    const noResults = this.el.querySelector('#no-results')
    if (noResults) {
      noResults.style.display = visibleCount === 0 ? 'block' : 'none'
    }
  },

  setupOptionHandlers(input, fallbackList) {
    const options = this.el.querySelectorAll('.timezone-option')

    options.forEach(option => {
      option.addEventListener('click', (e) => {
        e.preventDefault()
        const value = option.dataset.value
        input.value = value

        input.dispatchEvent(new Event('input', { bubbles: true }))

        fallbackList.style.display = 'none'
      })
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
