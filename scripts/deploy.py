from brownie import SwapAndDeposit
from scripts.helpers import get_account


def deploy_swapAnddeposit():
    account = get_account()
    SwapAndDeposit.deploy({"from": account})


def main():
    deploy_swapAnddeposit()

