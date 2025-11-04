# Build From Scratch

A learning journey documenting the implementation of classic DeFi protocols from first principles.

## 🎯 Purpose

This repo serves as a hands-on educational resource for understanding how Defi protocols work by building them from scratch. Each project includes detailed documentation, incremental commits showing the thought process, and explanations of key concepts.

## 📚 Projects

### 1. Simple DEX (Decentralized Exchange)
**Status:** 🚧 In Progress

A basic automated market maker (AMM) implementing:
- Constant product formula (x * y = k)
- Liquidity provision and removal
- Token swapping
- Fee mechanics

[View Project →](./projects/01-simple-dex/)

### Coming Soon
- Lending Protocol
- Stablecoin System
- Yield Aggregator
- Options Protocol

## 🏗️ Repository Structure

```
build-from-scratch/
├── projects/
│   ├── 01-simple-dex/
│   │   ├── README.md           # Project-specific documentation
│   │   ├── contracts/          # Smart contracts
│   │   ├── test/               # Test files
│   │   ├── scripts/            # Deployment and interaction scripts
│   │   └── research/           # Uniswap V2 code study
│   │       └── doc.md          # Uniswap V2 key mechanism
│   └── 02-lending-protocol/
│       └── ...
```

## 🛠️ Tech Stack

- **Smart Contracts:** Solidity
- **Development Framework:** Foundry
- **Testing:** Foundry tests
- **Language:** TypeScript for scripts


## 📖 Learning Approach

Each project follows this structure:

1. **Concept Overview** - Understanding what we're building and why
2. **Design Phase** - Planning the architecture and key components
3. **Implementation** - Building incrementally with detailed commits
4. **Testing** - Comprehensive test coverage with edge cases
5. **Reflection** - Documenting learnings and potential improvements

## 🎓 Educational Philosophy

- **Build to understand:** Theory is important, but implementation reveals the details
- **Document the journey:** Capture thought process, not just final code
- **Embrace mistakes:** Failed attempts and fixes are valuable learning moments
- **Keep it simple:** Start with core functionality, add complexity gradually
- **Test thoroughly:** Understanding edge cases deepens comprehension

## 🤝 Contributing

This is primarily a personal learning repository, but suggestions and corrections are welcome! Please open an issue to discuss any changes.

## 📝 License

MIT License - Feel free to use this code for learning purposes.

## 🔗 Connect

- Twitter: [@chloe_zhuX](https://x.com/Chloe_zhuX)
- Blog: [ChloeisCoding](https://hackmd.io/@ChloeIsCoding)

---

**Note:** This repository is for educational purposes. Code has not been audited and should not be used in production.
