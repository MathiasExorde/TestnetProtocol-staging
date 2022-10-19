# -*- coding: utf-8 -*-
"""
Created on Thu Aug 18 10:59:00 2022

@author: flore
"""
import boto3
from collections import Counter, deque
import csv
import datetime as dt
from datetime import timezone
from dateutil.parser import parse
from eth_account import Account
import facebook_scraper  as fb
from functools import partial
from ftlangdetect import detect
from geopy.geocoders import Nominatim
import html
from idlelib.tooltip import Hovertip
from iso639 import languages
import itertools
import json
import keyboard
import libcloud
from lxml.html.clean import Cleaner
import numpy as np
from operator import itemgetter
import os
import pandas as pd
from pathlib import Path
import pickle
from PIL import Image, ImageTk, ImageFile
from plyer import notification
import pytz
from queue import Queue
import random
import re
import requests
from requests_html import HTML
from requests_html import HTMLSession
from scipy.special import softmax, expit
import shutils
import snscrape.modules
import string
import sys
import threading
import time
import tkinter as tk
from tkinter import ttk
import tkinter.messagebox
import tldextract
import transformers
from transformers import AutoModelForSequenceClassification, AutoTokenizer, AutoConfig, TFAutoModelForSequenceClassification
import unicodedata
import urllib.request
import warnings
import web3
from web3 import Web3, HTTPProvider
import webbrowser
import yake



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
    #print(value)
    success = False
    trials = 0
    delay = 5
    
    while(trials < 5):
        try:
            hashValue = contract.functions.get(value).call()
            #print(hashValue)
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
