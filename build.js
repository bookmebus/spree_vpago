const esbuild = require("esbuild");

esbuild.build({
  entryPoints: ["app/javascripts/vpago/vpago_payments/user_informers/firebase.js"],
  outfile: "app/assets/javascripts/vpago/vpago_payments/user_informers/firebase.js",
  bundle: true,
  minify: false,
  globalName: "VpagoPayments",
}).catch(() => process.exit(1));
