# Foundry Lottery

This repository contains the Foundry Lottery project, which includes smart contracts, scripts, and tests for deploying and interacting with the Raffle contract.

## Project Structure

```
foundry-lottery/
    .gas-snapshot
    .gitignore
    .gitmodules
    .vscode/
        settings.json
    coverage.txt
    foundry.toml
    foundryup-zksync
    lib/
        chainlink-brownie-contracts/
        forge-std/
        foundry-devops/
        solmate/
    Makefile
    README.md
    remappings.txt
    script/
        DeployRaffle.s.sol
        HelperConfig.s.sol
        Interactions.s.sol
    src/
        Raffle.sol
    test/
        mocks/
            LinkToken.sol
        unit/
            RaffleTest.t.sol
```

## Files and Directories

- **.vscode/**: Contains Visual Studio Code settings.
  - **settings.json**: VSCode settings for the project.
- **lib/**: Contains external libraries and dependencies.
  - **chainlink-brownie-contracts/**: Chainlink contracts.
  - **forge-std/**: Forge standard library.
  - **foundry-devops/**: Foundry DevOps scripts.
  - **solmate/**: Solmate library.
- **script/**: Contains deployment and interaction scripts.
  - **DeployRaffle.s.sol**: Script to deploy the Raffle contract.
  - **HelperConfig.s.sol**: Helper configuration script.
  - **Interactions.s.sol**: Script for interacting with deployed contracts.
- **src/**: Contains the main smart contracts.
  - **Raffle.sol**: Main Raffle contract.
- **test/**: Contains test files.
  - **mocks/LinkToken.sol**: Mock contract for testing.
  - **unit/RaffleTest.t.sol**: Unit tests for the Raffle contract.

## Getting Started

### Prerequisites

- [Foundry](https://github.com/gakonst/foundry) - A blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/foundry-lottery.git
    cd foundry-lottery
    ```

2. Install dependencies:
    ```sh
    forge install
    ```

### Building the Project

To build the project, run:
```sh
forge build
```

### Running Tests

To run the tests, execute:
```sh
forge test
```

## Contributing

If you wish to contribute to this project, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.
