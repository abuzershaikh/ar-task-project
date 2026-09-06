/* =============================================
   MAIN.JS — ReviewsGateway
   ============================================= */


/* ── 1. LAYOUT LOADER ── */

async function loadLayout() {

    /* header */
    const headerEl = document.getElementById('header');
    if (headerEl) {
        const res = await fetch('/components/header.html');
        headerEl.innerHTML = await res.text();
    }

    /* footer */
    const footerEl = document.getElementById('footer');
    if (footerEl) {
        const res = await fetch('/components/footer.html');
        footerEl.innerHTML = await res.text();
    }

    /* cookie banner */
    if (!document.getElementById('cookie-banner')) {
        const res = await fetch('/components/cookie-banner.html');
        const div = document.createElement('div');
        div.innerHTML = await res.text();
        document.body.appendChild(div);

        const script = document.createElement('script');
        script.src = '/assetes/js/cookie-banner.js';
        document.body.appendChild(script);
    }

    initNavbar();       // navbar + hamburger
    initAnnouncement(); // announcement bar height
    initFaq();          // FAQ accordion
    initDropdowns();    // navbar dropdowns
    waitForLucide();    // icons render after header inject
    initProfileDropdown(); // ✅ add this line
}


/* ── 2. NAVBAR ── */

function initNavbar() {
    const toggle = document.getElementById('menu-toggle');
    const nav    = document.getElementById('nav-menu');

    if (!toggle || !nav) return;

    toggle.addEventListener('click', function (e) {
        e.stopPropagation();
        nav.classList.toggle('active');
        toggle.classList.toggle('active');
    });

    document.addEventListener('click', function () {
        nav.classList.remove('active');
        toggle.classList.remove('active');
    });

    window.addEventListener('resize', function () {
        if (window.innerWidth > 768) {
            nav.classList.remove('active');
            toggle.classList.remove('active');
        }
    });
}


/* ── 3. ANNOUNCEMENT BAR ── */

function initAnnouncement() {
    const announcement = document.querySelector('.announcement-section');
    const navbar       = document.querySelector('.navbar');

    if (!announcement || !navbar) return;

    function setNavbarTop() {
        navbar.style.top = announcement.offsetHeight + 'px';
    }

    setNavbarTop();
    window.addEventListener('resize', setNavbarTop);
}


/* ── 4. TRUST TRACK — infinite scroll ── */

document.addEventListener('DOMContentLoaded', function () {
    const track = document.querySelector('.trust-track');
    if (track) track.innerHTML += track.innerHTML;
});


/* ── 5. FAQ ACCORDION ── */

function initFaq() {
    const faqItems = document.querySelectorAll('.faq-item');
    if (!faqItems.length) return;

    faqItems.forEach(function (item) {
        const btn = item.querySelector('.faq-question');
        if (!btn) return;

        btn.addEventListener('click', function () {
            const isOpen = item.classList.contains('open');

            faqItems.forEach(function (el) {
                el.classList.remove('open');
                el.querySelector('.faq-question')
                  .setAttribute('aria-expanded', 'false');
            });

            if (!isOpen) {
                item.classList.add('open');
                btn.setAttribute('aria-expanded', 'true');
            }
        });
    });
}


/* ── 6. DROPDOWN HELPERS ── */

function openDropdown(d) {
    const t = d.querySelector('.dropdown-trigger');
    d.classList.add('open');
    if (t) { t.classList.add('active'); t.setAttribute('aria-expanded', 'true'); }
}

function closeDropdown(d) {
    const t = d.querySelector('.dropdown-trigger');
    d.classList.remove('open');
    if (t) { t.classList.remove('active'); t.setAttribute('aria-expanded', 'false'); }
}

function closeAllDropdowns() {
    document.querySelectorAll('.nav-dropdown').forEach(closeDropdown);
}

function initProfileDropdown() {

    const profileBtn = document.getElementById("profile-btn");      // profile icon
    const dropdown   = document.getElementById("profile-dropdown"); // dropdown box

    if (!profileBtn || !dropdown) return; // safety

    // toggle dropdown
    profileBtn.addEventListener("click", function (e) {
        e.stopPropagation(); // important
        dropdown.classList.toggle("active");
    });

    // close on outside click
    document.addEventListener("click", function (e) {
        if (!profileBtn.contains(e.target) && !dropdown.contains(e.target)) {
            dropdown.classList.remove("active");
        }
    });

    // ESC key close
    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") {
            dropdown.classList.remove("active");
        }
    });
}

/* ── 7. DROPDOWNS INIT ── */

function initDropdowns() {
    const dropdowns = document.querySelectorAll('.nav-dropdown');
    if (!dropdowns.length) return;

    dropdowns.forEach(function (d) {
        const t = d.querySelector('.dropdown-trigger');
        if (!t) return;

        /* desktop — hover */
        d.addEventListener('mouseenter', function () {
            if (window.innerWidth > 768) { closeAllDropdowns(); openDropdown(d); }
        });
        d.addEventListener('mouseleave', function () {
            if (window.innerWidth > 768) closeDropdown(d);
        });

        /* mobile + desktop — click toggle */
        t.addEventListener('click', function (e) {
            e.stopPropagation();
            const isOpen = d.classList.contains('open');
            closeAllDropdowns();
            if (!isOpen) openDropdown(d);
        });
    });

    document.addEventListener('click', closeAllDropdowns);
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeAllDropdowns();
    });
    window.addEventListener('resize', function () {
        if (window.innerWidth > 768) closeAllDropdowns();
    });
}


/* ── 8. LUCIDE ICONS — wait for load ── */

function waitForLucide() {
    if (window.lucide) {
        lucide.createIcons();          // ready — render karo
    } else {
        setTimeout(waitForLucide, 50); // 50ms baad dobara check
    }
}


/* ── START ── */
loadLayout();
// ── 9. TOOL CLICK TRACKING ──

function trackAndRedirect(e, toolName, url) {
    e.preventDefault(); // redirect rok

    if (typeof gtag === "function") {
        gtag('event', 'tool_click', {
            tool_name: toolName,
            event_callback: function () {
                window.location.href = url;
            }
        });
    } else {
        // agar gtag load nahi hua
        window.location.href = url;
    }

    // fallback (safety)
    setTimeout(() => {
        window.location.href = url;
    }, 500);
}