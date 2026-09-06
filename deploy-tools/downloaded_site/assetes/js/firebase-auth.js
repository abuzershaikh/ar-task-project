// 🔹 Firebase core
import { auth } from "./firebase-init.js";

// 🔹 Firebase auth functions
import {
  GoogleAuthProvider,
  signInWithPopup,
  signInWithRedirect, // ✅ fallback added
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendEmailVerification,
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";


// ======================================================
// 🔥 ELEMENTS
// ======================================================

const errorBox = document.getElementById("error-box")
const errorText = document.getElementById("error-text")
const errorClose = document.getElementById("error-close")

const email = document.getElementById("email")
const password = document.getElementById("password")


// ======================================================
// 🔥 GLOBAL ERROR BOX
// ======================================================

function showError(message) {
  if (!errorBox || !errorText) return

  errorText.innerText = message
  errorBox.classList.remove("hidden")
}

function hideError() {
  if (!errorBox) return
  errorBox.classList.add("hidden")
}


// ======================================================
// 🔥 FIELD ERROR
// ======================================================

function setFieldError(input, message) {
  input.classList.add("error")

  const errorEl = input.parentElement.querySelector(".error-msg")
  if (errorEl) errorEl.innerText = message
}

function clearFieldError(input) {
  input.classList.remove("error")

  const errorEl = input.parentElement.querySelector(".error-msg")
  if (errorEl) errorEl.innerText = ""
}

function clearAllErrors() {
  clearFieldError(email)
  clearFieldError(password)
}


// ======================================================
// 🔥 VALIDATION
// ======================================================

function validate() {
  let ok = true

  clearAllErrors()
  hideError()

  if (!email?.value.trim()) {
    setFieldError(email, "Email required")
    ok = false
  }

  if (!password?.value.trim()) {
    setFieldError(password, "Password required")
    ok = false
  }

  return ok
}


// ======================================================
// 🔥 BACKEND / FIREBASE ERROR HANDLER
// ======================================================

function handleError(message) {

  showError(message)

  const msg = message.toLowerCase()

  if (msg.includes("email")) {
    setFieldError(email, message)
  }

  if (msg.includes("password")) {
    setFieldError(password, message)
  }
}


// ======================================================
// 🔥 PUBLIC IP
// ======================================================

async function getPublicIP() {
  try {
    const res = await fetch("https://api.ipify.org?format=json")
    const data = await res.json()
    return data.ip
  } catch {
    return null
  }
}


// ======================================================
// 🔥 SEND TOKEN (BACKEND CONNECT)
// ======================================================

async function sendToken(user) {
  try {
    const token = await user.getIdToken(true)
    const ip = await getPublicIP()

    const response = await fetch("https://api.reviewsgateway.in/auth/api/login", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-Forwarded-For": ip || "",
      },
      body: JSON.stringify({
        name: user.displayName,
        picture: user.photoURL,
      }),
      credentials: "include",
    })

    const data = await response.json()

    if (!response.ok) {
      handleError(data.error || "Login failed")

      if (data.error === "Please verify your email first") {
        setTimeout(() => {
          window.location.href = "/account/verify_email/"
        }, 1500)
      }

      return
    }

    window.location.href = "/redirect/"

  } catch {
    showError("Server error. Try again.")
  }
}


// ======================================================
// 🔥 GOOGLE LOGIN
// ======================================================

async function googleLogin() {
  hideError()
  clearAllErrors()

  try {
    const provider = new GoogleAuthProvider()

    let result

    try {
      result = await signInWithPopup(auth, provider) // primary
    } catch (err) {
      // ✅ fallback if popup blocked
      await signInWithRedirect(auth, provider)
      return
    }

    await sendToken(result.user)

  } catch (err) {
    handleError(err.message)
  }
}


// ======================================================
// 🔥 SIGNUP
// ======================================================

async function signup() {
  if (!validate()) return

  try {
    const userCred = await createUserWithEmailAndPassword(
      auth,
      email.value,
      password.value
    )

    await sendEmailVerification(userCred.user, {
      url: "https://www.reviewsgateway.in/account/verify_email/",
      handleCodeInApp: false,
    })

    window.location.href = "/account/verify_email/"

  } catch (err) {

    if (err.code === "auth/email-already-in-use") {
      handleError("Email already exists")
    }
    else if (err.code === "auth/weak-password") {
      handleError("Password too weak")
    }
    else if (err.code === "auth/invalid-email") {
      handleError("Invalid email format")
    }
    else {
      handleError(err.message)
    }
  }
}


// ======================================================
// 🔥 LOGIN
// ======================================================

async function login() {
  if (!validate()) return

  try {
    const userCred = await signInWithEmailAndPassword(
      auth,
      email.value,
      password.value
    )

    await userCred.user.reload()

    if (!userCred.user.emailVerified) {
      window.location.href = "/account/verify_email/"
      return
    }

    await sendToken(userCred.user)

  } catch (err) {

    if (err.code === "auth/user-not-found") {
      handleError("Email not registered")
    }
    else if (err.code === "auth/wrong-password") {
      handleError("Incorrect password")
    }
    else if (err.code === "auth/invalid-email") {
      handleError("Invalid email format")
    }
    else {
      handleError(err.message)
    }
  }
}


// ======================================================
// 🔥 EVENTS
// ======================================================

document.addEventListener("DOMContentLoaded", () => {

  if (errorClose) {
    errorClose.addEventListener("click", hideError)
  }

  if (email) {
    email.addEventListener("input", () => clearFieldError(email))
  }

  if (password) {
    password.addEventListener("input", () => clearFieldError(password))
  }

  // ✅ GOOGLE BUTTON FIX (MAIN ISSUE)
  const googleBtn = document.getElementById("googleBtn")
  if (googleBtn) {
    googleBtn.addEventListener("click", (e) => {
      e.preventDefault()
      googleLogin()
    })
  }

})


// ======================================================
// 🔥 GLOBAL ACCESS
// ======================================================

window.signup = signup
window.login = login
window.googleLogin = googleLogin