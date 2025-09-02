from web3 import Web3, Account

w3 = Web3(Web3.HTTPProvider("YOUR_INFURA_URL"))
account = Account.from_key("YOUR_PRIVATE_KEY")

def add_record(contract, ...):
    tx = contract.functions.addIDRecord(...).build_transaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 2000000,
        'gasPrice': w3.toWei('50', 'gwei')
    })
    signed_tx = account.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
    return w3.eth.wait_for_transaction_receipt(tx_hash)
