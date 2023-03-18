# SwapAndDeposit
The contract can take any token as input and swap it on [Uniswap](https://app.uniswap.org) it to a token that can be deposited in [Compound v2](https://docs.compound.finance/v2/). 
The sender will receive the respective cTokens in return. Examples how to interact with the contract can be found in the [tests](/tests) folder.
## Requirements
- Python >= 3.x
- [Brownie](https://eth-brownie.readthedocs.io/en/stable/install.html)
- You need an Infura API key to connect to the Ethereum Network: add `export WEB3_INFURA_PROJECT_ID = ...`
