# -*- coding: utf-8 -*-
"""
Created on Thu Aug 18 10:59:00 2022

@author: flore
"""

import requests
import web3
from web3 import Web3, HTTPProvider
import time
import tkinter as tk
from tkinter import ttk
import tkinter.messagebox

    

def downloadFile2Code(hashname: str):
    
    code = requests.get(hashname).text
    return code
    

netConfig = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/NetworkConfig.txt").json()
w3 = Web3(Web3.HTTPProvider(netConfig["_urlSkale"]))


to = 60    
contracts = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/ContractsAddresses.txt", timeout=to).json()
abis = dict()
abis["ConfigRegistry"] = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/ABIs/ConfigRegistry.sol/ConfigRegistry.json", timeout=to).json()

contract = w3.eth.contract(contracts["ConfigRegistry"], abi=abis["ConfigRegistry"]["abi"])

for value in ["_moduleHashContracts","_moduleHashSpotting","_moduleHashSpotChecking","_moduleHashApp"]:
    print(value)
    success = False
    trials = 0
    delay = 5
    
    while(trials < 5):
        try:
            hashValue = contract.functions.get(value).call()
            print(hashValue)
            code = downloadFile2Code(hashValue)
            success = True
            break
        except:
            time.sleep(5*(trials + 1))
            trials += 1
            
    if(success == True):
        exec(code)
    else:
        tk.messagebox("Initialization error", "Something went wrong, please try again in a few moments.")



x = threading.Thread(target=desktop_app())
x.start()
