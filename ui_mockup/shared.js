// Splash -> welcome sequencing shared by every variation.
// The page has #splash and #welcome inside .phone; "Replay" restarts it,
// "Splash" / "Welcome" pin one screen for a closer look.
(function () {
  const phone = document.querySelector('.phone');
  const splash = document.getElementById('splash');
  const welcome = document.getElementById('welcome');
  const status = document.querySelector('.phone .status');
  const splashMs = Number(phone.dataset.splash || 2400);
  let timer;

  function restart(el) {
    // Re-trigger CSS animations by re-inserting the node.
    const clone = el.cloneNode(true);
    el.replaceWith(clone);
    return clone;
  }

  function show(which) {
    clearTimeout(timer);
    const s = document.getElementById('splash');
    const w = document.getElementById('welcome');
    if (which === 'splash') {
      w.hidden = true;
      s.hidden = false;
      restart(s);
      if (status) status.className = 'status ' + (phone.dataset.splashStatus || '');
    } else {
      s.hidden = true;
      w.hidden = false;
      restart(w);
      if (status) status.className = 'status ' + (phone.dataset.welcomeStatus || '');
    }
  }

  function play() {
    show('splash');
    timer = setTimeout(() => show('welcome'), splashMs);
  }

  document.getElementById('replay')?.addEventListener('click', play);
  document.getElementById('only-splash')?.addEventListener('click', () => show('splash'));
  document.getElementById('only-welcome')?.addEventListener('click', () => show('welcome'));
  // ?screen=splash or ?screen=welcome pins one screen (for screenshots).
  const pinned = new URLSearchParams(location.search).get('screen');
  pinned ? show(pinned) : play();
})();
