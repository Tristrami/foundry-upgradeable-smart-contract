# Upgradeable Smart Contract

## 相关资源

Proxy pattern: https://www.openzeppelin.com/news/proxy-patterns 🌟

Openzeppelin Proxy API: https://docs.openzeppelin.com/contracts/5.x/api/proxy

### Proxy Types

| 代理类型 | 核心特点 | 升级能力 | Gas 效率 | 复杂度 | 相关标准 | 典型应用 |
|:---------|:---------|:---------|:---------|:-------|:---------|:---------|
| **Transparent Proxy** | 基于调用者地址路由函数调用 | 单个逻辑合约 | 中等 | 低 | **ERC-1967** | 通用可升级合约场景 |
| **UUPS Proxy** | 升级逻辑放在逻辑合约中 | 单个逻辑合约 | **高** | 中 | **ERC-1822**<br>**ERC-1967** | Gas 敏感型应用 |
| **Diamond Proxy** | 多逻辑合约模块化架构 | 多个逻辑合约（Facets） | 低 | **极高** | **EIP-2535**<br>**Diamond Standard** | 大型复杂项目<br>Uniswap V3 |
| **Beacon Proxy** | 通过信标合约集中管理逻辑地址 | 批量升级代理群 | 中 | 中 | **ERC-1967**（信标槽） | NFT集合<br>批量部署场景 |
| **Minimal Proxy** | 极简字节码，不可升级克隆 | **不可升级** | **极高** | 低 | **EIP-1167** | 合约克隆工厂<br>Gnosis Safe |

## ERC-1967
ERC-1967 是一个为智能合约实现可升级代理模式而制定的标准，定义了代理合约（Proxy）和逻辑合约（Logic）之间如何安全、一致地进行交互

### 逻辑合约地址的存储位置 (Logic Contract Slot)

```solidity
// 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc 
bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
```

### 信标合约地址的存储位置 (Beacon Contract Slot)

适用于多个代理合约指向同一个逻辑合约的场景，信标合约可以统一查询和升级逻辑合约地址。需要注意，信标合约针对的是不使用 **Logic Contract Slot** 的代理合约

```solidity
// 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50 
bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
```

### 管理员地址的存储位置 (Admin address slot)

存储有权执行升级操作的管理员的地址

```solidity
// 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 
bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
```


## UUPS

EIP-1822: https://eips.ethereum.org/EIPS/eip-1822

UUPS 代理将升级逻辑都放到逻辑合约中，当通过代理合约调用逻辑合约中的升级函数时，会触发 delegatecall，升级逻辑将在代理合约的上下文中执行

### 与传统代理对比

#### 传统透明代理（Transparent Proxy）

- upgradeTo(address newImplementation) 函数在代理合约本身实现。
- 代理合约有一个管理员，只有管理员能调用这个函数。

#### UUPS 代理

- upgradeTo(address newImplementation) 函数在逻辑合约中实现和定义。
- 逻辑合约中通常还包含一个用来授权升级的 _authorizeUpgrade 内部函数（例如检查调用者是否是所有者）。

## 常见问题

### Storage Clashing

代理合约与逻辑合约的 Storage 存储是按照顺序一一对应的，并不是按照变量名对应，并且在代理合约中，并不需要去声明这些 Storage 变量。在这种情况下存在两个问题

- 升级后的逻辑合约与升级前的合约 Storage 变量可能存在冲突
- 逻辑合约与合约升级相关的 Storage 变量可能存在冲突

#### 升级合约与原合约 Storage 变量冲突

```solidity
// Logic V1
contract LogicV1 {
    uint256 public value;     // 存储槽 0
    address public owner;     // 存储槽 1
}

// Logic V2 - 错误的升级！
contract LogicV2 {
    address public newAdmin;  // 存储槽 0 - 冲突！覆盖了 value!
    uint256 public value;     // 存储槽 1 - 冲突！覆盖了 owner!
    address public owner;     // 存储槽 2
}
```

**解决方案：**

**继承链管理 (Inheritance Chain)**

让新版本合约继承旧版本合约，这样编译器会自动保持存储布局的兼容性。

```
solidity
// Logic V2 - 正确的升级
contract LogicV2 is LogicV1 {  // 继承 V1
    address public newAdmin;  // 存储槽 2 (自动追加在后面)
}
```

**存储间隙 (Storage Gaps)**

对于可扩展的合约，预留一些未使用的存储槽供未来使用

```solidity
contract Base {
    uint256 public value;     // 存储槽 0
    address public owner;     // 存储槽 1
    uint256[50] private __gap; // 预留 50 个存储槽
}

contract LogicV2 is Base {
    address public newAdmin;  // 使用预留的槽 2
}
```

#### 逻辑合约与升级相关 Storage 变量冲突

**解决方案：**

**ERC-1967**

代理相关的关键信息使用通过哈希计算得到的特定存储槽，避免与逻辑合约的存储冲突，下面是 Openzeppelin 中的实现方式

逻辑合约地址

```solidity
bytes32 internal constant _IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
```

初始化相关信息

```solidity
bytes32 internal constant INITIALIZABLE_STORAGE = keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
```

### Function Selector Clashing

函数选择器冲突发生在代理合约和逻辑合约具有相同函数选择器时，导致调用被错误的路由

**解决方案：**

**透明代理模式 (Transparent Proxy)**

核心思想是通过区分 `msg.sender` 来决定是调用代理合约的函数还是逻辑合约的函数

- 优点：简单可靠
- 缺点：管理员不能调用逻辑合约中与代理冲突的函数

```solidity
fallback() external payable {
    if (msg.sender == _admin()) {
        // 管理员：如果代理有该函数，自己处理
        return _fallback();
    } else {
        // 普通用户：总是委托给逻辑合约
        _delegate(_implementation());
    }
}
```

**UUPS 模式**

核心思想是，将升级相关的逻辑都放到逻辑合约中，代理合约只保留最简单的路由功能

- 优点：Gas 效率更高，无路由冲突
- 缺点：升级逻辑在逻辑合约中，如果新版本忘记包含会永久失去升级能力

```solidity
// UUPS Proxy - 极其简单
contract UUPSProxy {
    fallback() external payable {
        _delegate(_implementation()); // 总是委托调用
    }
}

// UUPS Logic - 包含升级逻辑
contract UUPSLogic {
    function upgradeTo(address newImplementation) external {
        require(msg.sender == owner, "Not authorized");
        _upgradeToAndCall(newImplementation, "");
    }
}
```