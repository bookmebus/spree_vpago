<?php

  $merchant_id = "bookmebus";
  $tran_id     = "12124257";
  $amount      = "10.00";

  $key         = '7866ceb0b796eda95e1cc597e9f62e5e';

  $data = $merchant_id . $tran_id . $amount;

  print("data: $data, key: $key \n");

  $hash = base64_encode(hash_hmac('sha512', $data, $key, true));

  echo ("base64_encode: $hash \n");
