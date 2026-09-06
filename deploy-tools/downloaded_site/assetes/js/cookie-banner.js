/* =============================================
   COOKIE BANNER JS
   File: /assetes/js/cookie-banner.js
   ============================================= */

// ── STEP 1: GA ID yahan change karo ──
var GA_ID = 'G-HGE9GWLDPM'; 

// ── STEP 2: GA script load karne ka function ──
function loadGoogleAnalytics() {

    // agar pehle se load ho chuka hai toh dobara mat load karo
    if (window._gaLoaded) return;
    window._gaLoaded = true;

    // GA script dynamically inject karo
    var script = document.createElement('script');        // script tag banao
    script.async = true;                                   // non-blocking load
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID; // GA CDN
    document.head.appendChild(script);                    // head mein add karo

    // gtag function setup karo
    window.dataLayer = window.dataLayer || [];            // dataLayer initialize
    function gtag() { dataLayer.push(arguments); }        // gtag helper
    window.gtag = gtag;                                   // globally available

    gtag('js', new Date());                               // current timestamp

    // consent granted ke saath initialize karo
    gtag('consent', 'update', {
        analytics_storage: 'granted',                     // analytics allow
        ad_storage: 'denied',                             // ads block (GDPR safe)
        functionality_storage: 'granted',                 // functional cookies
        personalization_storage: 'denied',                // personalization block
    });

    gtag('config', GA_ID, {
        anonymize_ip: true,                               // IP anonymize — GDPR
        cookie_flags: 'SameSite=None;Secure',             // secure cookie flags
    });
}

// ── STEP 3: GA default consent deny karo (page load pe) ──
// Yeh script se PEHLE hona chahiye — isliye yahan hai
window.dataLayer = window.dataLayer || [];               // dataLayer ready karo
function gtag() { dataLayer.push(arguments); }           // gtag define karo
window.gtag = gtag;

gtag('consent', 'default', {
    analytics_storage: 'denied',                         // default: tracking band
    ad_storage: 'denied',                                // default: ads band
    wait_for_update: 500,                                // 500ms wait for update
});

// ── STEP 4: agar pehle accept kiya hua hai toh directly GA load karo ──
(function () {

    var COOKIE_KEY = 'rg_cookie_consent';  // localStorage key
    var SHOW_DELAY = 3000;                 // 3 seconds baad banner dikhao

    // pehle se accepted hai toh GA abhi load karo
    var existing = localStorage.getItem(COOKIE_KEY); // localStorage check karo

    if (existing === 'accepted') {
        loadGoogleAnalytics(); // pehle se consent tha — GA load karo
        return;                // banner mat dikhao
    }

    if (existing === 'declined') return; // decline kiya tha — kuch mat karo

    // ── DOM elements ──
    var banner     = document.getElementById('cookie-banner');   // banner div
    var acceptBtn  = document.getElementById('cookie-accept');   // accept button
    var declineBtn = document.getElementById('cookie-decline');  // decline button

    // ── elements nahi mile toh stop ──
    if (!banner || !acceptBtn || !declineBtn) return;

    // ── 3 seconds baad banner show karo ──
    setTimeout(function () {
        banner.setAttribute('aria-hidden', 'false'); // accessibility
        banner.classList.add('show');                // slide-up animation
    }, SHOW_DELAY);

    // ── banner hide karne ka function ──
    function hideBanner() {
        banner.classList.remove('show');  // show class hato
        banner.classList.add('hide');     // hide animation

        setTimeout(function () {
            banner.setAttribute('aria-hidden', 'true'); // accessibility reset
        }, 400); // CSS transition duration ke barabar
    }

    // ── Accept button ──
    acceptBtn.addEventListener('click', function () {
        localStorage.setItem(COOKIE_KEY, 'accepted'); // consent save karo
        hideBanner();                                  // banner hatao
        loadGoogleAnalytics(); 
        setTimeout(function () {
        if (typeof gtag === "function") {
            gtag('event', 'cookie_accept');
        }
    }, 300);                        
    });

    // ── Decline button ──
    declineBtn.addEventListener('click', function () {
        localStorage.setItem(COOKIE_KEY, 'declined'); // decline save karo
        hideBanner();                                  // banner hatao
        // GA load nahi hoga — tracking band rahega
    });

    // ── ESC key ──
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && banner.classList.contains('show')) {
            localStorage.setItem(COOKIE_KEY, 'declined'); // ESC = decline
            hideBanner();
        }
    });

})();