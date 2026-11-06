// Wing Mini App login (Wing Web JS Bridge SDK spec, Native API #1 getProfile).
//
// The bridge only exists inside Wing's WebView, so this only ever runs there —
// getProfile() asks the host app for the signed customer profile, we hand it to
// our own server to verify and mint a session, then hand the browser off to the
// storefront on the client host.
(function () {
  'use strict';

  // The page renders nothing, so failures only go to the console for debugging.
  function logError(message) {
    console.error('[Wing Mini App] ' + message);
  }

  var bridge = window.WebJSBridge && window.WebJSBridge.$bridge;

  if (!bridge || !bridge.isAvailable()) {
    logError('This page only works inside the Wing app.');
    return;
  }

  bridge
    .callHandler('getProfile', {})
    .then(function (profile) {
      return fetch('/mini_app/wing', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ profile: profile })
      });
    })
    .then(function (response) {
      return response.json().then(function (data) {
        return { ok: response.ok, data: data };
      });
    })
    .then(function (result) {
      if (!result.ok) {
        logError(result.data.error || 'Login failed.');
        return;
      }

      // Top frame, because window.location here was found to be intercepted by iOS
      // Universal Links / Android App Links and handed to the native BookMe+ app
      // instead of continuing inside Wing's WebView.
      //
      // replace, not href: this page has nothing to come back to, and assigning href
      // leaves it in the back stack — the customer pressing back on the home page lands
      // on this blank page and has to press back twice to leave the mini app.
      window.top.location.replace(result.data.miniAppUrl);
    })
    .catch(function (error) {
      logError('Error: ' + error.message);
    });
})();
