// ==UserScript==
// @name         LinkedIn Human-like Auto Connect
// @namespace    local.oshana.linkedin
// @version      1.0
// @description  Clicks "Connect" on LinkedIn suggestion pages with random, human-like delays. Start/Stop button + daily cap.
// @match        https://www.linkedin.com/mynetwork/*
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  // ---------- Settings ----------
  const CFG = {
    minDelay: 4000,        // min pause between connects (ms)
    maxDelay: 12000,       // max pause between connects (ms)
    longPauseEvery: [5, 9],// take a longer break after every N..M connects
    longPause: [25000, 60000],
    maxPerRun: 20,         // stop after this many in one run
    maxPerDay: 40,         // hard daily cap (stored in localStorage)
    scrollLoadMore: true,  // scroll down to load more suggestions
  };

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const rnd = (a, b) => a + Math.random() * (b - a);
  const rndInt = (a, b) => Math.floor(rnd(a, b + 1));

  let running = false;
  let stopFlag = false;

  // ---------- Daily counter ----------
  const todayKey = () => 'lac_count_' + new Date().toISOString().slice(0, 10);
  const getCount = () => { try { return +localStorage.getItem(todayKey()) || 0; } catch { return 0; } };
  const addCount = () => { try { localStorage.setItem(todayKey(), getCount() + 1); } catch {} };

  // ---------- UI ----------
  const panel = document.createElement('div');
  panel.style.cssText = 'position:fixed;bottom:20px;left:20px;z-index:99999;background:#0a66c2;color:#fff;padding:10px 14px;border-radius:10px;font:13px sans-serif;box-shadow:0 2px 10px rgba(0,0,0,.4);min-width:190px';
  const status = document.createElement('div');
  status.textContent = 'Idle';
  status.style.marginBottom = '6px';
  const btn = document.createElement('button');
  btn.textContent = 'Start auto-connect';
  btn.style.cssText = 'cursor:pointer;border:0;border-radius:6px;padding:6px 10px;font-weight:600;width:100%';
  panel.append(status, btn);
  document.body.appendChild(panel);

  const setStatus = (t) => { status.textContent = t; };

  btn.onclick = () => {
    if (running) { stopFlag = true; setStatus('Stopping...'); return; }
    run();
  };

  // ---------- Helpers ----------
  function getConnectButtons() {
    return [...document.querySelectorAll('button')].filter((b) =>
      /^invite .* to connect/i.test(b.getAttribute('aria-label') || '') &&
      !b.disabled && b.offsetParent !== null
    );
  }

  function humanClick(el) {
    const r = el.getBoundingClientRect();
    const x = r.left + r.width * rnd(0.25, 0.75);
    const y = r.top + r.height * rnd(0.25, 0.75);
    const opts = { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y };
    el.dispatchEvent(new MouseEvent('mouseover', opts));
    el.dispatchEvent(new MouseEvent('mousemove', opts));
    el.dispatchEvent(new MouseEvent('mousedown', opts));
    el.dispatchEvent(new MouseEvent('mouseup', opts));
    el.click();
  }

  function findModal() {
    return [...document.querySelectorAll('.artdeco-modal, [role=dialog]')].find(
      (d) => d.offsetParent && d.innerText.trim() && /connect|note|email|invitation|limit/i.test(d.innerText)
    );
  }

  // ---------- Main loop ----------
  async function run() {
    running = true; stopFlag = false;
    btn.textContent = 'Stop';
    let sent = 0;
    let untilLongPause = rndInt(...CFG.longPauseEvery);

    while (!stopFlag && sent < CFG.maxPerRun && getCount() < CFG.maxPerDay) {
      let buttons = getConnectButtons();
      if (!buttons.length) {
        if (CFG.scrollLoadMore) {
          setStatus('Looking for more...');
          window.scrollBy({ top: rnd(500, 900), behavior: 'smooth' });
          await sleep(rnd(2000, 4000));
          buttons = getConnectButtons();
        }
        if (!buttons.length) { setStatus('No more Connect buttons'); break; }
      }

      // Pick the first visible one most of the time, occasionally skip one (human-like)
      const idx = buttons.length > 2 && Math.random() < 0.25 ? 1 : 0;
      const b = buttons[idx];
      const name = (b.getAttribute('aria-label') || '').replace(/^Invite | to connect$/gi, '');

      b.scrollIntoView({ behavior: 'smooth', block: 'center' });
      await sleep(rnd(700, 2000));          // "look" at the card
      if (stopFlag) break;
      humanClick(b);
      await sleep(rnd(1200, 2400));

      const modal = findModal();
      if (modal) {
        const send = [...modal.querySelectorAll('button')].find((x) => /send without a note|^\s*send\s*$/i.test(x.innerText));
        if (send) { await sleep(rnd(500, 1200)); humanClick(send); await sleep(rnd(800, 1500)); }
        else {
          setStatus('Unexpected dialog - stopped');
          console.warn('[AutoConnect] Unexpected dialog:', modal.innerText.slice(0, 300));
          break;
        }
      }

      sent++; addCount();
      setStatus(`Sent ${sent} (today ${getCount()}/${CFG.maxPerDay}): ${name}`);

      untilLongPause--;
      if (untilLongPause <= 0) {
        const p = rnd(...CFG.longPause);
        setStatus(`Taking a break ${Math.round(p / 1000)}s...`);
        await sleep(p);
        untilLongPause = rndInt(...CFG.longPauseEvery);
      } else {
        await sleep(rnd(CFG.minDelay, CFG.maxDelay));
      }
    }

    running = false;
    btn.textContent = 'Start auto-connect';
    if (!/Unexpected|No more/.test(status.textContent)) setStatus(`Done. Sent ${sent} this run.`);
  }
})();
