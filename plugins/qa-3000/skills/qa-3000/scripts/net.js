// In-page network harness for a running Flutter web app.
//
// Paste this whole function as the function argument of chrome-devtools
// evaluate_script on the app's page, AFTER the app has loaded (a reload wipes
// it — and in-memory caches with it). Idempotent: running it twice keeps
// one patch.
//
// It gives you:
//   window.__qa.block = true / false   cut / restore the network for every host
//                                      except 127.0.0.1 / localhost, so the
//                                      driver and DWDS keep working. XHR goes to
//                                      a closed port (real network error), fetch
//                                      rejects. DevTools "Offline" would also
//                                      kill the driver connection.
//   window.__qa.log                    [{t, via, blocked, u}] for every
//                                      non-local request — what the app asked
//                                      for, and when.
//   window.__qa.amp                    [{t, type, props}] decoded Amplitude
//                                      events (event_type + event_properties).
//   window.__qa.delay = {match: 'collections/', ms: 6000}
//                                      hold matching XHRs before sending them —
//                                      a slow network for one endpoint, enough
//                                      to tap Back mid-load. null turns it off.
//                                      An abort while held cancels the send —
//                                      the request never leaves, and the log
//                                      gets {aborted: true}.
//
// Keep this file free of backticks and of await inside expressions:
// evaluate_script rejects both with "missing ) after argument list".
() => {
  if (window.__qa) return { installed: 'already', now: new Date().toISOString().slice(11, 19) };
  const qa = { block: false, delay: null, log: [], amp: [] };
  window.__qa = qa;
  const now = () => new Date().toISOString().slice(11, 19);
  const isLocal = (u) => {
    try {
      const h = new URL(u, location.href).hostname;
      return h === '127.0.0.1' || h === 'localhost';
    } catch (e) {
      return true;
    }
  };
  const recordAmplitude = (u, body) => {
    if (!/amplitude/.test(u) || typeof body !== 'string') return;
    try {
      const events = JSON.parse(body).events || [];
      events.forEach((e) => qa.amp.push({ t: now(), type: e.event_type, props: e.event_properties }));
    } catch (e) {}
  };

  const origOpen = XMLHttpRequest.prototype.open;
  const origSend = XMLHttpRequest.prototype.send;
  const origAbort = XMLHttpRequest.prototype.abort;
  XMLHttpRequest.prototype.open = function (method, url, ...rest) {
    const u = String(url);
    this.__qaUrl = u;
    if (!isLocal(u)) {
      qa.log.push({ t: now(), via: 'xhr', blocked: qa.block, u: u.split('?')[0] });
      if (qa.block) return origOpen.call(this, method, 'http://127.0.0.1:9/blocked', ...rest);
    }
    return origOpen.call(this, method, url, ...rest);
  };
  XMLHttpRequest.prototype.send = function (body) {
    const u = this.__qaUrl || '';
    recordAmplitude(u, body);
    if (qa.delay && u.indexOf(qa.delay.match) >= 0) {
      this.__qaHeld = setTimeout(() => {
        this.__qaHeld = null;
        origSend.call(this, body);
      }, qa.delay.ms);
      return undefined;
    }
    return origSend.call(this, body);
  };
  XMLHttpRequest.prototype.abort = function () {
    if (this.__qaHeld) {
      clearTimeout(this.__qaHeld);
      this.__qaHeld = null;
      qa.log.push({ t: now(), via: 'xhr', aborted: true, u: (this.__qaUrl || '').split('?')[0] });
    }
    return origAbort.call(this);
  };

  const origFetch = window.fetch;
  window.fetch = function (input, init) {
    const u = typeof input === 'string' ? input : (input && input.url) || String(input);
    if (!isLocal(u)) {
      qa.log.push({ t: now(), via: 'fetch', blocked: qa.block, u: u.split('?')[0] });
      if (qa.block) return Promise.reject(new TypeError('Failed to fetch (qa offline)'));
      recordAmplitude(u, init && init.body);
    }
    return origFetch.call(this, input, init);
  };
  return { installed: true, now: now() };
}
