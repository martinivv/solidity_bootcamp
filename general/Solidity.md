# Solidity

## VIA-IR COMPILATION

### Default Compilation

1. The compiler takes each Solidity smart contract source code as input and parses the source files;
2. The compiler then analyzes the source code and generates the **EVM assembly** directly using the legacy codegen;
3. It then runs the optimizer on the code until the code is considered sufficiently optimized;
4. Finally, the compiler generates bytecode for each contract.

### via IR Compilation

1. The compiler parses the Solidity source files;
2. Instead of compiling Solidity source code directly to **EVM assembly**, the new IR code generator will first transform the Solidity code into Yul code;
3. The **Yul optimizer** will repeatedly perform optimizations on the Yul code;
4. The optimized Yul code is then transformed into **EVM assembly** using **Yul → evmasm** code transform;
5. This code is very close to the actual bytecode, but is still suitable for further optimizations by the evmasm optimizer;
6. Finally, the EVM bytecode is generated.

![Compilation Pipelines](images/solidity/compilation-pipelines.png)

### Motivation

- Allow more powerful optimizations;
- Generate a more optimized bytecode;
- Reduce gas costs;
- Enable better security audits;
- Reduce stack too deep errors.

  #### Yul Advantages

  1. Enables more efficient manual inspection, formal verification, optimization of the code;
  2. Allows greater control over Solidity (e.g. retaining/allocating memory/storage knowledge);
  3. Ease of complex adjustments for various layer 2 extensions;
  4. Can serve as a backend for various compilers, for instance, for Fe;
  5. **EOF upgrade** compatibility.

### Disadvantages

- Longer compilation times;
- Unconditionally can generate code for every expression without codegen shortcuts → IR code becomes more verbose, inefficient. Yul optimizer compensates for this.

<br>
<br>

## TRANSIENT STORAGE

- Partially introduced in version 0.8.24;
- Behaves as a key-value store similar to storage;
- Scoped to the current transaction (not a function call!);
- As cheap as warm storage access - `TSTORE` are `TLOAD` are priced at 100 gas;
- [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153)

A canonical use case is implementing a cheaper reentrancy guard:

```solidity
modifier nonreentrant {
  assembly {
    if tload(0) { revert(0, 0) }
    tstore(0, 1)
  }
  _;
  // Unlocks the guard, making the pattern composable.
  // After the function exits, it can be called again, even in the same transaction.
  assembly {
    tstore(0, 0)
  }
}
```

### Composability in Computer Science & Solidity

- Composability concerns how **components interact**, **treating them as self-contained, stateless units**;
- The EVM do ensure composable behavior:
  - A sequence of calls to a contract within one transaction behaves identically to those same calls spread over multiple transactions;
- Use cases like batching calls across transactions focus on reducing gas costs. Transient storage **may** breaks such use cases since composability can no longer be taken for granted.

```solidity
contract MulService {
    function setMultiplier(uint multiplier) external {
        assembly {
            tstore(0, multiplier)
        }
    }

    function getMultiplier() private view returns (uint multiplier) {
        assembly {
            multiplier := tload(0)
        }
    }

    function multiply(uint value) external view returns (uint) {
        return value * getMultiplier();
    }
}
```

`setMultiplier(42)` ➜ `multiply(1)` ➜ `multiply(2)`.

➥ The transient storage is not cleared between calls!

> **The lack of composability is not an inherent property of transient storage!**

This _issue_ could be avoided if the rules for clearing transient storage were adjusted.

**Current behavior:**

- Transient storage is cleared for all contracts simultaneously at the end of a transaction.

**Proposed behavior:**

- Clear transient storage for a contract when no function belonging to it is active on the call stack.
- Means transient storage could reset multiple times within a transaction, resolving issues like the example above.

### Recommendations

1. **Clear transient storage completely at the end of each call!**

   - While it might seem tempting to use it as a replacement for in-memory mappings, this can be extremely risky❗

2. Adjust clearing rules to align with composable behavior to preserve compatibility across use cases.

<br>
<br>
