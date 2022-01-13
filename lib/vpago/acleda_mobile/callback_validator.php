<?php
  $data = array(
    "TransactionId" => "REF0361472663",
    "PaymentTokenId" => "16de81d4-b5ef-ef59-16de-81d4b5efef59",
    "TxnAmount" => "30",
    "SenderName" => "Test User"
  );

  // will be provided
  $secret_key = 'VTenhSecret';

  // signed request fields
  $hash_data = $data['TransactionId'] . ' ' . $data['PaymentTokenId'] . ' ' . $data['TxnAmount'];
  $binary_output = false;

  // calculate the signed input hash
  echo "hash data: ${hash_data}";
  $hash_value = hash_hmac('sha256', $hash_data, $secret_key, $binary_output);


  $vtenh_request = $data;

  // request payload with signed for vtenh callback
  $vtenh_request["SignedHash"] = $hash_value;

  print_r($vtenh_request);
  // output
  // Array
  // (
  //     [TransactionId] => REF0361472663
  //     [PaymentTokenId] => 16de81d4-b5ef-ef59-16de-81d4b5efef59
  //     [TxnAmount] => 30
  //     [SenderName] => Test User
  //     [SignedHash] => c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79
  // )
