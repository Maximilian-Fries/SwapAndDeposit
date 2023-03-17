from solcx import compile_standard, install_solc
import json
from web3 import Web3
import os
from dotenv import load_dotenv
from brownie import accounts, config, SwapAndDeposit
from scripts.helpers import get_account


def deploy_swapAnddeposit():
    account = get_account()
    swap_and_deposit = SwapAndDeposit.deploy({"from": account})


def this_is_a_test():
    print("success")


def main():
    deploy_swapAnddeposit()

