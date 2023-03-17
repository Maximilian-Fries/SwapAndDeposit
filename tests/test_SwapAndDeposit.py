import pytest
import json
from brownie import Contract, SwapAndDeposit, accounts, interface, Wei


@pytest.fixture(scope="session")
def deploy_SwapAndDeposit():
  yield SwapAndDeposit.deploy({"from": accounts[0]})

    
    
@pytest.fixture(scope="session")
def dai():
    yield Contract.from_explorer("0x6B175474E89094C44Da98b954EedeAC495271d0F")


@pytest.fixture(scope="session")
def uniswap_dai_exchange():
    yield Contract.from_explorer("0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667")


# buy some dai for account[0]
@pytest.fixture(scope="session", autouse=True)
def buy_dai(dai, uniswap_dai_exchange):
    uniswap_dai_exchange.ethToTokenSwapInput(
        1, 
        99999999999,  
        {
            "from": accounts[0],
            "value": "5 ether"
        }
    )


def test_buy_dai(accounts, dai):
    assert dai.balanceOf(accounts[0]) > 0

def test_contract_is_deployed(deploy_SwapAndDeposit):
    assert deploy_SwapAndDeposit.getOwner() == accounts[0]


def test_swapAndDepositErc20forETH(deploy_SwapAndDeposit):
    amount = 1000*10**18
    with open('mainnet.json', 'r') as f:
        data = json.load(f)
    dai_address = data["Contracts"]["DAI"]
    interface.IERC20(dai_address).approve(deploy_SwapAndDeposit.address, amount, {"from": accounts[0]})
    deploy_SwapAndDeposit.swapAndDepositErc20forETH(dai_address, amount, {"from": accounts[0]})

    ceth = interface.CEth(data["Contracts"]["cETH"])
    assert ceth.balanceOf(accounts[0]) > 0
    

def test_swapAndDepositETHforErc20(deploy_SwapAndDeposit):
    amount = Wei("2 ether")
    with open('mainnet.json', 'r') as f:
        data = json.load(f)
    dai_address = data["Contracts"]["DAI"]
    cdai_address = data["Contracts"]["cDAI"]
    deploy_SwapAndDeposit.swapAndDepositETHforErc20(dai_address, cdai_address, {"from": accounts[0], "value": amount})
    assert interface.CErc20(cdai_address).balanceOf(accounts[0]) > 0



def test_swapAndDepositErc20forErc20(deploy_SwapAndDeposit):
    amount = 1000*10**18
    with open('mainnet.json', 'r') as f:
        data = json.load(f)
    dai_address = data["Contracts"]["DAI"]
    aave_address = data["Contracts"]["AAVE"]
    caave_address = data["Contracts"]["cAAVE"]

    interface.IERC20(dai_address).approve(deploy_SwapAndDeposit.address, amount, {"from": accounts[0]})
    deploy_SwapAndDeposit.swapAndDepositErc20forErc20(dai_address, aave_address, caave_address, amount, {"from": accounts[0]})
    assert interface.CErc20(caave_address).balanceOf(accounts[0]) > 0