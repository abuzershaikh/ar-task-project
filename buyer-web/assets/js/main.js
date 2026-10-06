document.addEventListener('DOMContentLoaded', () => {
    // Screenshot Lightbox functionality
    const screenshots = [
        './assets/images/screenshot-1.jpeg',
        './assets/images/screenshot-2.jpeg',
        './assets/images/screenshot-3.jpeg',
        './assets/images/screenshot-4.jpeg'
    ];

    let currentScreenshotIdx = 0;
    const modal = document.getElementById('previewModal');
    const modalImg = document.getElementById('modalPreviewImg');
    const prevBtn = document.getElementById('modalPrev');
    const nextBtn = document.getElementById('modalNext');
    const closeBtn = document.getElementById('modalClose');
    const fullPreviewBtn = document.getElementById('fullPreviewBtn');

    function openModal(idx) {
        currentScreenshotIdx = idx;
        modalImg.src = screenshots[currentScreenshotIdx];
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    function closeModal() {
        modal.classList.remove('active');
        document.body.style.overflow = '';
    }

    function nextScreenshot() {
        currentScreenshotIdx = (currentScreenshotIdx + 1) % screenshots.length;
        modalImg.src = screenshots[currentScreenshotIdx];
    }

    function prevScreenshot() {
        currentScreenshotIdx = (currentScreenshotIdx - 1 + screenshots.length) % screenshots.length;
        modalImg.src = screenshots[currentScreenshotIdx];
    }

    // Attach click listeners to screenshot cards
    document.querySelectorAll('.screenshot-card').forEach((card, idx) => {
        card.addEventListener('click', () => openModal(idx));
    });

    if (fullPreviewBtn) {
        fullPreviewBtn.addEventListener('click', () => openModal(0));
    }

    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (nextBtn) nextBtn.addEventListener('click', nextScreenshot);
    if (prevBtn) prevBtn.addEventListener('click', prevScreenshot);

    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal || e.target.classList.contains('modal-container')) {
                closeModal();
            }
        });
    }

    // Mobile Touch Swipe Gesture for Lightbox
    let touchStartX = 0;
    let touchEndX = 0;

    if (modal) {
        modal.addEventListener('touchstart', (e) => {
            touchStartX = e.changedTouches[0].screenX;
        }, { passive: true });

        modal.addEventListener('touchend', (e) => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipeGesture();
        }, { passive: true });
    }

    function handleSwipeGesture() {
        const diff = touchEndX - touchStartX;
        const minSwipeDistance = 45;
        if (Math.abs(diff) > minSwipeDistance) {
            if (diff < 0) {
                // Swiped Left -> Next
                nextScreenshot();
            } else {
                // Swiped Right -> Prev
                prevScreenshot();
            }
        }
    }

    // Keyboard support for modal
    document.addEventListener('keydown', (e) => {
        if (!modal || !modal.classList.contains('active')) return;
        if (e.key === 'Escape') closeModal();
        if (e.key === 'ArrowRight') nextScreenshot();
        if (e.key === 'ArrowLeft') prevScreenshot();
    });

    // Toast notification utility
    const toast = document.getElementById('toastNotice');
    let toastTimeout;
    function showToast(message) {
        if (!toast) return;
        toast.textContent = message;
        toast.classList.add('show');
        clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => {
            toast.classList.remove('show');
        }, 2800);
    }

    // Share button logic
    const shareBtns = document.querySelectorAll('.share-action-btn');
    shareBtns.forEach(btn => {
        btn.addEventListener('click', async () => {
            const shareData = {
                title: 'Reviews Gateway - Official App',
                text: 'Download Reviews Gateway Buyer App to get real Google 5★ reviews, YouTube watch time & Play Store installs!',
                url: window.location.href
            };

            if (navigator.share && navigator.canShare && navigator.canShare(shareData)) {
                try {
                    await navigator.share(shareData);
                } catch (err) {
                    if (err.name !== 'AbortError') {
                        copyToClipboard(window.location.href);
                    }
                }
            } else {
                copyToClipboard(window.location.href);
            }
        });
    });

    function copyToClipboard(text) {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(text).then(() => {
                showToast('Link copied to clipboard!');
            }).catch(() => {
                showToast('Share link: ' + text);
            });
        } else {
            showToast('Share link: ' + text);
        }
    }

    // Smart Mobile Sticky Bar Trigger on Scroll
    const mobileBottomBar = document.querySelector('.mobile-bottom-bar');
    const heroInstallSection = document.getElementById('heroInstallSection');

    if (mobileBottomBar && heroInstallSection) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (!entry.isIntersecting) {
                    mobileBottomBar.classList.add('visible');
                } else {
                    mobileBottomBar.classList.remove('visible');
                }
            });
        }, {
            threshold: 0.1
        });

        observer.observe(heroInstallSection);
    }

    // Download notification
    const downloadBtns = document.querySelectorAll('a[download], a[href$=".apk"]');
    downloadBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            showToast('Starting Review Gateway APK download...');
        });
    });
});
