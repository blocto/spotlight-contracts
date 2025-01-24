## Spotlight Contracts

[![Actions Status](https://github.com/blocto/spotlight-contracts/workflows/CI/badge.svg)](https://github.com/blocto/spotlight-contracts/actions)

**Your Gateway to Establishing, Promoting, Connecting, and Monetizing IPs**

Spotlight is a platform offering powerful tools to help users build, promote, connect, and monetize their intellectual properties (IPs). Whether you’re an artist, creator, or entrepreneur, Spotlight provides everything you need to easily manage, grow, and unlock the value of your IP.

## Documentation

In-depth documentation on Spotlight Protocol is available at https://spotlight-protocol.gitbook.io/spotlight-protocol

## Development

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Deploy

- Deploy IPCollection contract
```shell
$ forge script script/DeployIPCollection.s.sol:Deploy --broadcast \
    --chain-id 1516 \
    --rpc-url https://odyssey.storyrpc.io \
    --verify \
    --verifier blockscout \
    --verifier-url 'https://odyssey.storyscan.xyz/api/' 
```

- Deploy IPRootCollection contract and mint the root ip
```shell
$ forge script script/DeployIPRootCollectionAndMint.s.sol:Deploy --broadcast \
    --chain-id 1516 \
    --rpc-url https://odyssey.storyrpc.io \
    --verify \
    --verifier blockscout \
    --verifier-url 'https://odyssey.storyscan.xyz/api/' 
```

- Deploy TokenFactory contract
```shell
forge script script/DeployTokenFactory.s.sol:Deploy  --broadcast \
    --chain-id 1516 \
    --rpc-url https://odyssey.storyrpc.io \
    --verify \
    --verifier blockscout \
    --verifier-url 'https://odyssey.storyscan.xyz/api/' 
```