# Solidity Delegate Call Patterns

_Disclaimer: all code here is incomplete and probably unsafe, do not use it._

This repository highlights different delegate calls patterns in Solidity for education purposes.

# Introduction - Delegatecall and Storage

### What is delegatecall?

EVM exposes and opcode `delegatecall` which allows to execute code from another contract in the context of the caller contract. This means that the code executed by `delegatecall` has access to the caller's storage, balance, etc.

```solidity

contract implem {
    uint256 public a;

    function increment() public {
        a += 1;
    }
}

contract caller {
    uint256 public a = 2;

    function callIncrement(address _addr) public {
        _addr.delegatecall(abi.encodeWithSignature("increment()"));
    }
}
```

In the example above, calling the `callIncrement` function of the `caller` contract will increment the `a` variable of the `caller` contract (2 -> 3 on first call), not the `implem` contract.

This allows usecases like proxies and upgradability patterns that we will explore below.

### Storage layout

In order to understand the patterns below, it is important to understand how Solidity stores variables in storage.

Solidity stores variables in storage in a slot-based manner. Each slot is 32 bytes long and can store a single variable. The first variable of a contract is stored in the first slot, the second variable in the second slot, etc.

```solidity

contract implem {
    uint256 public a;
    uint256 public c;
    uint256 public b;

    function increment() public {
        a += 1;
    }

    function setB(uint256 _b) public {
        b = _b;
    }
}

contract caller {
    uint256 public a = 2;
    uint256 public b;
    uint256 public c;

    function callIncrement(address _addr) public {
        _addr.delegatecall(abi.encodeWithSignature("increment()"));
    }

    function callSetB(address _addr, uint256 _b) public {
        _addr.delegatecall(abi.encodeWithSignature("setB(uint256)", _b));
    }
}
```

In the above example, calling the `callIncrement` function will update the a variable of the caller contract (first slot). But calling the `callSetB` function will update the third slot of the caller contract (c variable) and not the b variable, because the variable are not declared in the same order in the two contracts.

Here is an ascii representation of the storage layout of the `caller` and `implem` contracts step by step:

```solidity

SLOT #0     caller.a = 2     implem.a
SLOT #1     caller.b = 0     implem.c
SLOT #2     caller.c = 0     implem.b

=> caller.callIncrement(implem)

SLOT #0     caller.a = 3     implem.a
SLOT #1     caller.b = 0     implem.c
SLOT #2     caller.c = 0     implem.b

=> caller.callSetB(implem, 42)

SLOT #0     caller.a = 3     implem.a
SLOT #1     caller.b = 0     implem.c
SLOT #2     caller.c = 42    implem.b
```

To prevent this, we use a storage layout that is compatible between the two contracts by encoding variables name to slot numbers. This is done in the [Storage Library](./contracts/Storage.sol).

# Proxy pattern

A proxy contract uses `delegatecall` to execute the code of another contract in the storage context of the proxy contract.

```
                +-----------------+             +-----------------+
                | Proxy           |             | TargetedImplem  |
                |                 |             |                 |
      calls     |                 |  delegate   |                 |
   -------->    |                 | ----------> |                 |
                |  +-----------+  |   calls     |  +-----------+  |
                |  |  Storage  |  |             |  |  Logic    |  |
                |  +-----------+  |             |  +-----------+  |
                +-----------------+             +-----------------+
```

### Proxy

The first pattern we will explore is the proxy pattern. The proxy pattern allows to have a single contract that can execute the code of another contract.

👉 See [Proxy.sol](./contracts/Proxy.sol) for the implementation.

### UpgradeableProxy

The upgradeable proxy pattern is an extension of the proxy pattern that allows to upgrade the implementation address of the proxy. This is managed by a dedicated `admin` address.

👉 See [UpgradeableProxy.sol](./contracts/UpgradeableProxy.sol) for the implementation.

### TransparentUpgradeableProxy

The issue with the UpgradeableProxy is that if the admin functions are also declared on the implementation contract (like the `upgradeTo` function). This creates ambiguity on which contract should be called when calling these functions.

To solve this, we can use the TransparentUpgradeableProxy pattern. This pattern only forwards calls to the implementation contract if msg.sender is not the registered admin address. This way, the admin functions are always called on the proxy contract.

👉 See [TransparentUpgradeableProxy.sol](./contracts/TransparentUpgradeableProxy.sol) for the implementation.

# Beacon pattern
