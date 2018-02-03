#!/usr/bin/env bats

@test "list empty accounts" {
  run vault list ethereum/accounts
    [ "$status" -eq 2 ]
}

@test "create test account" {
  results="$(vault write -format=json ethereum/accounts/test chain_id=1977 | jq .data)"
  list_results="$(vault list -format=json ethereum/accounts | jq '. | length')"
  blacklist="$(echo $results | jq .blacklist)"
  whitelist="$(echo $results | jq .whitelist)"
  rpc_url="$(echo $results | jq .rpc_url | tr -d '"')"
  address="$(echo $results | jq .address | tr -d '"')"
  chain_id="$(echo $results | jq .chain_id | tr -d '"')"
    [ "$list_results" -eq 1 ]
    [ "$chain_id" = "1977" ]
    [ "$rpc_url" = "http://localhost:8545" ]
    [ "$blacklist" = "null" ]
    [ "$whitelist" = "null" ]
    [ "$address" != "" ]
}

@test "read test account" {
  results="$(vault read -format=json ethereum/accounts/test | jq .data)"
  blacklist="$(echo $results | jq .blacklist)"
  whitelist="$(echo $results | jq .whitelist)"
  rpc_url="$(echo $results | jq .rpc_url | tr -d '"')"
  address="$(echo $results | jq .address | tr -d '"')"
  chain_id="$(echo $results | jq .chain_id | tr -d '"')"
    [ "$chain_id" = "1977" ]
    [ "$rpc_url" = "http://localhost:8545" ]
    [ "$blacklist" = "null" ]
    [ "$whitelist" = "null" ]
    [ "$address" != "" ]
}

@test "update test account no changes" {
  read_results="$(vault read -format=json ethereum/accounts/test | jq .data)"
  update_results="$(vault write -format=json ethereum/accounts/test chain_id=1977 | jq .data)"
    [ "$read_results" = "$update_results" ]
}

@test "update test account blacklist" {
  read_results="$(vault read -format=json ethereum/accounts/test | jq .data)"
  blacklist_entry_1="0x0acfF30349F2DCcE288dB75150A588262D6C247a"
  blacklist_entry_2="0x0acfF30349F2DCcE288dB75150A588262D6C247b"
  update_results="$(vault write -format=json ethereum/accounts/test chain_id=1977 blacklist="$blacklist_entry_1,$blacklist_entry_2"| jq .data)"
  test_blacklist_entry_1="$(echo $update_results | jq '.blacklist[0]' | tr -d '"')"
  test_blacklist_entry_2="$(echo $update_results | jq '.blacklist[1]' | tr -d '"')"
    [ "$blacklist_entry_1" = "$test_blacklist_entry_1" ]
    [ "$blacklist_entry_2" = "$test_blacklist_entry_2" ]
}


@test "update test account whitelist" {
  read_results="$(vault read -format=json ethereum/accounts/test | jq .data)"
  whitelist_entry_1="0x0acfF30349F2DCcE288dB75150A588262D6C247a"
  whitelist_entry_2="0x0acfF30349F2DCcE288dB75150A588262D6C247b"
  update_results="$(vault write -format=json ethereum/accounts/test chain_id=1977 whitelist="$whitelist_entry_1,$whitelist_entry_2"| jq .data)"
  test_whitelist_entry_1="$(echo $update_results | jq '.whitelist[0]' | tr -d '"')"
  test_whitelist_entry_2="$(echo $update_results | jq '.whitelist[1]' | tr -d '"')"
    [ "$whitelist_entry_1" = "$test_whitelist_entry_1" ]
    [ "$whitelist_entry_2" = "$test_whitelist_entry_2" ]
}

@test "delete test account" {
  run vault delete ethereum/accounts/test
    [ "$status" -eq 0 ]
}

@test "export test account" {
  results="$(vault write -format=json ethereum/accounts/test chain_id=1977 | jq .data)"
  export_results="$(vault write -format=json ethereum/accounts/test/export path=$(pwd) | jq .data)"
  passphrase="$(echo $export_results | jq .passphrase | tr -d '"')"
  path="$(echo $export_results | jq .path | tr -d '"')"
  echo $passphrase > passphrase.txt
  echo $path > path.txt
  filename="$(echo $export_results | jq .path | tr -d '"')"
    [ -e "$filename" ]
    [ "$passphrase" != "" ]
}

@test "test sign and verify" {
  signature="$(vault write -format=json ethereum/accounts/test/sign data=@accounts.bats | jq .data.signature | tr -d '"')"
  verified="$(vault write -format=json ethereum/accounts/test/verify data=@accounts.bats signature=$signature | jq .data.verified)"
    [ "$verified" = "true" ]
}
