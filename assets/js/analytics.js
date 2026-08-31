(function () {
  "use strict";

  var script = document.currentScript;
  var endpoint = script && script.dataset ? String(script.dataset.endpoint || "").replace(/\/$/, "") : "";
  var productionHost = script && script.dataset ? String(script.dataset.host || "") : "";

  if (!endpoint || endpoint.indexOf("REPLACE_") !== -1) return;
  if (productionHost && location.hostname !== productionHost) return;
  if (navigator.doNotTrack === "1") return;
  if (/bot|crawler|spider|preview|headless/i.test(navigator.userAgent)) return;

  function randomId() {
    if (crypto && typeof crypto.randomUUID === "function") return crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (character) {
      var random = Math.random() * 16 | 0;
      var value = character === "x" ? random : (random & 3 | 8);
      return value.toString(16);
    });
  }

  function getStoredId(storage, key) {
    try {
      var value = storage.getItem(key);
      if (!value) {
        value = randomId();
        storage.setItem(key, value);
      }
      return value;
    } catch (_) {
      return randomId();
    }
  }

  function deviceType() {
    var width = Math.min(screen.width || innerWidth, innerWidth || screen.width);
    if (width <= 640) return "mobile";
    if (width <= 1024) return "tablet";
    return "desktop";
  }

  var visitorId = getStoredId(localStorage, "kevinPortfolioVisitor");
  var sessionId = getStoredId(sessionStorage, "kevinPortfolioSession");
  var lastPath = "";

  function track() {
    var path = location.pathname + location.hash;
    if (path === lastPath) return;
    lastPath = path;

    var payload = {
      visitorId: visitorId,
      sessionId: sessionId,
      path: path,
      referrer: document.referrer,
      device: deviceType(),
      language: navigator.language || "",
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "",
      screen: String(screen.width || 0) + "x" + String(screen.height || 0)
    };

    fetch(endpoint + "/api/track", {
      method: "POST",
      mode: "cors",
      cache: "no-store",
      keepalive: true,
      headers: { "content-type": "text/plain;charset=UTF-8" },
      body: JSON.stringify(payload)
    }).catch(function () {});
  }

  track();
  window.addEventListener("hashchange", function () {
    window.setTimeout(track, 120);
  }, { passive: true });
})();
