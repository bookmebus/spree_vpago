<?php

  $merchant_id = "vtenh";
  $tran_id     = "POAUQRAV";
  $amount      = "12.00";

  // be2f9d0e9aaa3fceb64e5e6ed1efb808
  // vtenhPOAUQRAV12.00
  

  $key         = 'be2f9d0e9aaa3fceb64e5e6ed1efb808';

  $data = $merchant_id . $tran_id . $amount;

  print("data: $data, key: $key \n");
  $hmac = hash_hmac('sha512', $data, $key, true);

  echo "hashhmac data: ${hmac} \n";

  $hash = base64_encode($hmac);

// KxPclvYgReykTGWEL4fujhyBmQ59fSZV8ehV3z2biIdzflCG/ehyvifQF1Epq6YyIJAEccYnfdLPP0PZ670m/Q==
// KxPclvYgReykTGWEL4fujhyBmQ59fSZV8ehV3z2biIdzflCG/ehyvifQF1Ep\nq6YyIJAEccYnfdLPP0PZ670m/Q==



  echo ("base64_encode: $hash \n");

  $hmac = "KxPclvYgReykTGWEL4fujhyBmQ59fSZV8ehV3z2biIdzflCG/ehyvifQF1Ep\nq6YyIJAEccYnfdLPP0PZ670m/Q==\n";
  echo "base64_decode: " . base64_decode($hmac) . " \n";

  $abc = "MjYzMjAwNTkzNzY2MDE5ZmRkNTU1NjliNjYwZWIzM2U3OTdhMTg3YzdlOTVlZTg0ODZlNTY2MWViN2Q4MDk1YQ==";
  echo base64_decode($abc) . "\n"; 