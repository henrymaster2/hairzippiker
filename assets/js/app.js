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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/hair_zippiker"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}


const formatKes = amount => {
  const number = Number(amount || 0)
  return `KSh ${Math.round(number).toLocaleString("en-KE")}`
}

const sendStkPush = async payment => {
  const response = await fetch("/mpesa/stk_push", {
    method: "POST",
    headers: {
      "accept": "text/html",
      "content-type": "application/json",
      "x-csrf-token": csrfToken,
    },
    body: JSON.stringify({payment}),
  })
  const data = await response.json()
  return {response, data}
}

const initializeSalonHome = () => {
  const root = document.querySelector("[data-salon-home]")
  if (!root || root.dataset.salonHomeReady === "true") return

  root.dataset.salonHomeReady = "true"

  const drawer = root.querySelector("[data-profile-drawer]")
  const backdrop = root.querySelector("[data-drawer-backdrop]")
  const styleCards = Array.from(root.querySelectorAll("[data-style-card]"))
  const profileNavButton = root.querySelector("#salon-nav-profile")
  const selectedStyle = root.querySelector("[data-selected-style]")
  const selectedStyleEmpty = root.querySelector("[data-selected-style-empty]")
  const selectedStyleImg = root.querySelector("[data-selected-style-img]")
  const selectedStyleName = root.querySelector("[data-selected-style-name]")
  const selectedStylePrice = root.querySelector("[data-selected-style-price]")
  const stkPushButton = root.querySelector("[data-stk-push-button]")
  const stkPushStatus = root.querySelector("[data-stk-push-status]")
  const greeting = root.querySelector("[data-dynamic-greeting]")
  let activeStyle = Number(root.dataset.activeStyle || 0)
  let selectedStyleId = null
  let touchStartY = 0
  let touchStartedInSwipeZone = false
  let wheelLocked = false
  let wheelDelta = 0

  const setGreeting = () => {
    if (!greeting) return

    const hour = new Date().getHours()
    if (hour < 12) {
      greeting.textContent = "Good morning"
    } else if (hour < 17) {
      greeting.textContent = "Good afternoon"
    } else {
      greeting.textContent = "Good evening"
    }
  }

  const setActiveStyle = index => {
    activeStyle = Math.max(0, Math.min(index, styleCards.length - 1))
    root.dataset.activeStyle = activeStyle

    styleCards.forEach(card => {
      const cardIndex = Number(card.dataset.styleIndex || 0)
      card.style.transform = `translateY(${(cardIndex - activeStyle) * 100}%)`
    })
  }

  const openDrawer = () => {
    if (!drawer || !backdrop) return

    backdrop.hidden = false
    drawer.hidden = false
    drawer.setAttribute("aria-hidden", "false")
    profileNavButton?.classList.add("bg-white", "text-black")
    profileNavButton?.classList.remove("text-zinc-500")

    requestAnimationFrame(() => {
      backdrop.classList.remove("opacity-0")
      backdrop.classList.add("opacity-100")
      drawer.classList.remove("translate-x-full")
      drawer.classList.add("translate-x-0")
    })
  }

  const closeDrawer = () => {
    if (!drawer || !backdrop) return

    backdrop.classList.add("opacity-0")
    backdrop.classList.remove("opacity-100")
    drawer.classList.add("translate-x-full")
    drawer.classList.remove("translate-x-0")
    drawer.setAttribute("aria-hidden", "true")
    profileNavButton?.classList.remove("bg-white", "text-black")
    profileNavButton?.classList.add("text-zinc-500")

    window.setTimeout(() => {
      if (drawer.getAttribute("aria-hidden") === "true") {
        backdrop.hidden = true
        drawer.hidden = true
      }
    }, 700)
  }

  root.querySelectorAll("[data-drawer-open]").forEach(button => {
    button.addEventListener("click", openDrawer)
  })

  root.querySelectorAll("[data-drawer-close]").forEach(button => {
    button.addEventListener("click", closeDrawer)
  })

  backdrop?.addEventListener("click", closeDrawer)

  root.querySelector("[data-style-prev]")?.addEventListener("click", () => {
    setActiveStyle(activeStyle - 1)
  })

  root.querySelector("[data-style-next]")?.addEventListener("click", () => {
    setActiveStyle(activeStyle + 1)
  })

  root.addEventListener("wheel", event => {
    if (root.dataset.view !== "home") return
    if (!event.target.closest("[data-style-swipe-zone]")) return
    if (event.target.closest("details")) return

    event.preventDefault()
    if (wheelLocked || styleCards.length < 2) return

    wheelDelta += event.deltaY

    if (Math.abs(wheelDelta) < 42) return

    setActiveStyle(activeStyle + (wheelDelta > 0 ? 1 : -1))
    wheelDelta = 0
    wheelLocked = true

    window.setTimeout(() => {
      wheelLocked = false
    }, 520)
  }, {passive: false})

  root.querySelectorAll("[data-style-choose]").forEach(button => {
    button.addEventListener("click", () => {
      if (selectedStyle && selectedStyleEmpty) {
        selectedStyle.hidden = false
        selectedStyleEmpty.hidden = true
      }

      if (selectedStyleImg) {
        selectedStyleImg.src = button.dataset.styleImg || ""
        selectedStyleImg.alt = button.dataset.styleName || "Selected hairstyle"
      }

      if (selectedStyleName) selectedStyleName.textContent = button.dataset.styleName || ""
      if (selectedStylePrice) selectedStylePrice.textContent = `KSh ${button.dataset.stylePrice || ""}`
      if (stkPushButton) stkPushButton.disabled = false
      if (stkPushStatus) stkPushStatus.textContent = ""

      selectedStyleId = button.dataset.styleId || null

      openDrawer()
    })
  })

  stkPushButton?.addEventListener("click", async () => {
    if (!selectedStyleId) {
      if (stkPushStatus) stkPushStatus.textContent = "Choose a hairstyle first."
      return
    }

    stkPushButton.disabled = true
    stkPushButton.textContent = "Sending STK Push..."
    if (stkPushStatus) stkPushStatus.textContent = "Contacting Safaricom. Keep your phone nearby."

    try {
      const {response, data} = await sendStkPush({style_id: selectedStyleId})

      if (response.ok && data.ok) {
        stkPushButton.textContent = "STK Push Sent"
        if (stkPushStatus) stkPushStatus.textContent = data.message || "Check your phone to complete payment."
      } else {
        stkPushButton.disabled = false
        stkPushButton.textContent = "Send STK Push"
        if (stkPushStatus) stkPushStatus.textContent = data.message || "Could not send STK push."
      }
    } catch (_error) {
      stkPushButton.disabled = false
      stkPushButton.textContent = "Send STK Push"
      if (stkPushStatus) stkPushStatus.textContent = "Network error. Please try again."
    }
  })

  root.addEventListener("touchstart", event => {
    touchStartY = event.changedTouches[0].screenY
    touchStartedInSwipeZone = Boolean(event.target.closest("[data-style-swipe-zone]")) && !event.target.closest("details")
  }, {passive: true})

  root.addEventListener("touchend", event => {
    if (root.dataset.view !== "home") return
    if (!touchStartedInSwipeZone) return

    const touchEndY = event.changedTouches[0].screenY
    if (touchStartY - touchEndY > 50) {
      setActiveStyle(activeStyle + 1)
    } else if (touchEndY - touchStartY > 50) {
      setActiveStyle(activeStyle - 1)
    }
  }, {passive: true})

  window.addEventListener("keydown", event => {
    if (event.key === "Escape") closeDrawer()
  })

  setGreeting()
  setActiveStyle(activeStyle)
}

const initializeBookingPayment = () => {
  const root = document.querySelector("[data-booking-payment-page]")
  if (!root || root.dataset.bookingPaymentReady === "true") return

  root.dataset.bookingPaymentReady = "true"

  const options = Array.from(root.querySelectorAll("[data-booking-style-option]"))
  const name = root.querySelector("[data-booking-payment-name]")
  const price = root.querySelector("[data-booking-payment-price]")
  const button = root.querySelector("[data-booking-stk-push-button]")
  const status = root.querySelector("[data-booking-stk-push-status]")

  const selectedOption = () => options.find(option => option.checked)

  const syncSummary = () => {
    const option = selectedOption()
    if (!option) return

    if (name) name.textContent = option.dataset.styleName || "Selected style"
    if (price) price.textContent = `KSh ${option.dataset.stylePrice || "0"}`
    if (status) status.textContent = ""
    if (button) {
      button.disabled = false
      button.textContent = "Pay With STK Push"
    }
  }

  options.forEach(option => option.addEventListener("change", syncSummary))

  button?.addEventListener("click", async () => {
    const option = selectedOption()

    if (!option) {
      if (status) status.textContent = "Choose a hairstyle first."
      return
    }

    button.disabled = true
    button.textContent = "Sending STK Push..."
    if (status) status.textContent = "Contacting Safaricom. Keep your phone nearby."

    try {
      const {response, data} = await sendStkPush({style_id: option.value})

      if (response.ok && data.ok) {
        button.textContent = "STK Push Sent"
        if (status) status.textContent = data.message || "Check your phone to complete payment."
      } else {
        button.disabled = false
        button.textContent = "Pay With STK Push"
        if (status) status.textContent = data.message || "Could not send STK push."
      }
    } catch (_error) {
      button.disabled = false
      button.textContent = "Pay With STK Push"
      if (status) status.textContent = "Network error. Please try again."
    }
  })

  syncSummary()
}

const initializeShopPayment = () => {
  const root = document.querySelector("[data-shop-payment-page]")
  if (!root || root.dataset.shopPaymentReady === "true") return

  root.dataset.shopPaymentReady = "true"

  root.querySelectorAll("[data-shop-product]").forEach(product => {
    const quantityInput = product.querySelector("[data-product-quantity]")
    const total = product.querySelector("[data-product-total]")
    const minus = product.querySelector("[data-quantity-minus]")
    const plus = product.querySelector("[data-quantity-plus]")
    const buyButton = product.querySelector("[data-product-buy-button]")
    const status = product.querySelector("[data-product-payment-status]")
    const unitPrice = Number(product.dataset.productPrice || 0)
    const stock = Number(product.dataset.productStock || 0)

    const clampQuantity = value => Math.max(1, Math.min(Number(value || 1), Math.max(stock, 1)))

    const syncTotal = () => {
      const quantity = clampQuantity(quantityInput?.value)
      if (quantityInput) quantityInput.value = quantity
      if (total) total.textContent = formatKes(unitPrice * quantity)
      if (minus) minus.disabled = stock <= 0 || quantity <= 1
      if (plus) plus.disabled = stock <= 0 || quantity >= stock
      if (status) status.textContent = ""
      if (buyButton && stock > 0) {
        buyButton.disabled = false
        buyButton.textContent = "Buy With STK Push"
      }
    }

    minus?.addEventListener("click", () => {
      if (!quantityInput) return
      quantityInput.value = clampQuantity(Number(quantityInput.value) - 1)
      syncTotal()
    })

    plus?.addEventListener("click", () => {
      if (!quantityInput) return
      quantityInput.value = clampQuantity(Number(quantityInput.value) + 1)
      syncTotal()
    })

    quantityInput?.addEventListener("input", syncTotal)
    quantityInput?.addEventListener("blur", syncTotal)

    buyButton?.addEventListener("click", async () => {
      const quantity = clampQuantity(quantityInput?.value)

      buyButton.disabled = true
      buyButton.textContent = "Sending STK Push..."
      if (status) status.textContent = `Sending ${formatKes(unitPrice * quantity)} prompt.`

      try {
        const {response, data} = await sendStkPush({
          product_id: product.dataset.productId,
          quantity: String(quantity),
        })

        if (response.ok && data.ok) {
          buyButton.textContent = "STK Push Sent"
          if (status) status.textContent = data.message || "Check your phone to complete payment."
        } else {
          buyButton.disabled = false
          buyButton.textContent = "Buy With STK Push"
          if (status) status.textContent = data.message || "Could not send STK push."
        }
      } catch (_error) {
        buyButton.disabled = false
        buyButton.textContent = "Buy With STK Push"
        if (status) status.textContent = "Network error. Please try again."
      }
    })

    syncTotal()
  })
}

window.addEventListener("DOMContentLoaded", initializeSalonHome)
window.addEventListener("phx:page-loading-stop", initializeSalonHome)
window.addEventListener("DOMContentLoaded", initializeBookingPayment)
window.addEventListener("phx:page-loading-stop", initializeBookingPayment)
window.addEventListener("DOMContentLoaded", initializeShopPayment)
window.addEventListener("phx:page-loading-stop", initializeShopPayment)
