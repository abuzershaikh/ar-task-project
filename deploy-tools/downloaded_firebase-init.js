// firebase-init.js

// 🔹 Firebase core (CDN se import)
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js"; // browser compatible

// 🔹 Auth (important)
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js"; // auth ke liye

// 🔹 Config (same as yours)
const firebaseConfig = {
  apiKey: "AIzaSyC1OOU-gFYTdRlLi_oZ-u6yOaNf2gEQGWM",
  authDomain: "review-gateway.firebaseapp.com",
  projectId: "review-gateway",
  storageBucket: "review-gateway.firebasestorage.app",
  messagingSenderId: "325905961629",
  appId: "1:325905961629:web:d5256bc163503bbc327a74",
  measurementId: "G-2820SK41Z7"
};

// 🔹 Initialize app
const app = initializeApp(firebaseConfig); // Firebase app start

// 🔹 Export auth (IMPORTANT)
export const auth = getAuth(app); // auth instance export