# -*- coding: utf-8 -*-
"""
Created on Thu Aug 18 10:59:00 2022

@author: flore
"""

netConfig = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/NetworkConfig.txt").json()
    
def downloadFile2Code2(hashname: str, url: str = netConfig["_urlPinata"]):#"https://exorde-testnet.mypinata.cloud/ipfs/"
    
    code = requests.get(hashname).text
    return code

base_url = "https://exorde-testnet.mypinata.cloud/ipfs/"
TAG_RE = re.compile(r'<[^>]+>')

def remove_tags(text):
    return TAG_RE.sub('', text)

def downloadFile(hashname: str, name: str, url: str = base_url):
    
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.146 Safari/537.36',
        'pinata_api_key': "19d2b24b75ad7253aebf", #"0a3c682cdac6f59c497f",
        'pinata_secret_api_key': "f69150422667f79ce5a7fb0997bfdbb3750894cd1734275f77d867647e4f3df4" #"d17b895242d8913b5c5a8dc9933a11223fc5f81696705c78bce150083ad2341d"
        #'Authorization': "Bearer MjRDODM2ODJFMzc1OERBNjNERDk6QjE0OUVRR2QxV3dHTHB1V0hnUEdUNXdRNU9xZ1hQcTNBT1F0VGVCcjpleG9yZGUtc3BvdHMtMQ=="
    }

    url = url+hashname
    r = requests.get(url, headers=headers, allow_redirects=True, stream=True, timeout=1200)
    
    try:
        os.mkdir("ExordeWD")
    except:
        pass
    
    open('ExordeWD\\'+name, 'wb').write(r.content)

def downloadFile2Code(hashname: str, url: str = base_url):
    
    code = requests.get(hashname).text
    return code
    
def downloadFile2Data(hashname: str, url: str = base_url):
    
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.146 Safari/537.36',
        'pinata_api_key': "19d2b24b75ad7253aebf", #"0a3c682cdac6f59c497f",
        'pinata_secret_api_key': "f69150422667f79ce5a7fb0997bfdbb3750894cd1734275f77d867647e4f3df4" 
        #'Authorization': "Bearer MjRDODM2ODJFMzc1OERBNjNERDk6QjE0OUVRR2QxV3dHTHB1V0hnUEdUNXdRNU9xZ1hQcTNBT1F0VGVCcjpleG9yZGUtc3BvdHMtMQ=="
    }

    url = "https://" + hashname + ".ipfs.w3s.link/"
    #url = url+hashname
    r = requests.get(url, headers=headers, allow_redirects=True, stream=True, timeout=1200)
    return r.json()

def extractDomain(url):
    
    m = re.search('https?://([A-Za-z_0-9.-]+).*', url)
    if m:
        return m.group(1)
    else:
        m = url.rsplit("/",3)
        return m
    # #if("http" in str(url) or "www" in str(url)):
    # if(type(url) == str):
    #     if("http" in url or "www" in url):
    #         parsed = tldextract.extract(url)
    #         parsed = ".".join([i for i in parsed if i])
    #         return parsed
    #     else: return None
    # else:
    #     return ""
    
    
def proc_txt(text):
    txt = re.sub(u"(\u2018|\u2019)", "'", str(text))
    txt = re.sub(u"(\u2014)", "-", str(txt))
    return txt


def ls_split(a, n):
    k, m = divmod(len(a), n)
    return (a[i*k+min(i, m):(i+1)*k+min(i+1, m)] for i in range(n))

from os import walk, path, sep
from requests import Session, Request
def pinata_upload(file: str, mode: str = "file"):
    try:
        # directory is the abs path of dir
        #ipfs_url = "https://api.pinata.cloud/pinning/pinFileToIPFS"
        ipfs_url = 'https://api.web3.storage/upload'
        # headers = {
        #     #"Content-Type": "application/json",
        #     'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.146 Safari/537.36',
        #     'pinata_api_key': "19d2b24b75ad7253aebf", #"0a3c682cdac6f59c497f",
        #     'pinata_secret_api_key': "f69150422667f79ce5a7fb0997bfdbb3750894cd1734275f77d867647e4f3df4" #"d17b895242d8913b5c5a8dc9933a11223fc5f81696705c78bce150083ad2341d"
        #     #'Authorization': "Bearer MjRDODM2ODJFMzc1OERBNjNERDk6QjE0OUVRR2QxV3dHTHB1V0hnUEdUNXdRNU9xZ1hQcTNBT1F0VGVCcjpleG9yZGUtc3BvdHMtMQ=="
        # }
        headers = {
            'Accept':' */*',
            "Content-Type": "application/json",
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.146 Safari/537.36',
            #'pinata_api_key': "19d2b24b75ad7253aebf", #"0a3c682cdac6f59c497f",
            #'pinata_secret_api_key': "f69150422667f79ce5a7fb0997bfdbb3750894cd1734275f77d867647e4f3df4" #"d17b895242d8913b5c5a8dc9933a11223fc5f81696705c78bce150083ad2341d"
            'Authorization': "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDQwODM0NzVENjRDQ2JBZWViRUNCYkU5MTQxZTRFQkQyQTNERjhBMUMiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NTk2MTkxMTg4MjUsIm5hbWUiOiJleG9yZGUtdGVzdG5ldC1zcG90In0.AkKUkgbtejixeWcLvrVypY63yg8NEiagqaKzBZEppJk"
        }
        if(mode == "file"):
            # files = []
            # files = [("file", open(file, "rb"))]
            request = Request(
                'POST',
                ipfs_url,
                headers=headers,
                data=file
            ).prepare()
        else:
            if(file.endswith(".pkl") == False):
                headers['Content-type'] = 'application/json'
                headers['Accept'] = 'text/plain'
                request = Request(
                    'POST',
                    #"https://api.pinata.cloud/pinning/pinJSONToIPFS",
                    'https://api.web3.storage/upload',
                    headers=headers,
                    data=file
                ).prepare()
            else:
                request = Request(
                    'POST',
                    ipfs_url,
                    headers=headers,
                    data=file
                ).prepare()
        response = Session().send(request)
        
        #print()
        if(str(response.status_code).startswith("2")):
            result = dict()
            result[0] = response.request.url
            result[1] = response.request.headers
            #result[2] = response.request.body
            result[2] = response.json()
            # print()
            # print("File pinned at : ", result[2])
            #print(response.text)
            
            
            return result
        else:
            print()
            print(response.__dict__)
    except Exception as e:
        print(e)
        
def pinata_unpin(hashKey: str):
    
    x = threading.Thread(target = real_unpin, args=(hashKey,)).start()

def real_unpin(hashKey):
    
    time.sleep(360)
    try:
        url = "https://api.pinata.cloud/pinning/unpin/"+hashKey
    
        payload={}
        headers = {
          'Authorization': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJmNWQwNmIwYS0wNzFmLTRkMTEtYTM0Zi0zOTU5ZGQ2ZTA2NzMiLCJlbWFpbCI6Im1hdGhpYXNAZXhvcmRlbGFicy5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJpZCI6IkZSQTEiLCJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MX0seyJpZCI6Ik5ZQzEiLCJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MX1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiMTlkMmIyNGI3NWFkNzI1M2FlYmYiLCJzY29wZWRLZXlTZWNyZXQiOiJmNjkxNTA0MjI2NjdmNzljZTVhN2ZiMDk5N2JmZGJiMzc1MDg5NGNkMTczNDI3NWY3N2Q4Njc2NDdlNGYzZGY0IiwiaWF0IjoxNjU1NzM4MzYzfQ.FQyml2D98rdF9i--2nZJ-L1GpzHNuKhRuY5Q_AlGQeE',
          'Authorization': "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ"
        #'Authorization': "Bearer MjRDODM2ODJFMzc1OERBNjNERDk6QjE0OUVRR2QxV3dHTHB1V0hnUEdUNXdRNU9xZ1hQcTNBT1F0VGVCcjpleG9yZGUtc3BvdHMtMQ=="
        }
        
        response = requests.request("DELETE", url, headers=headers, data=payload)
    except Exception as e:
        print(e)


w3 = Web3(Web3.HTTPProvider(netConfig["_urlSkale"]))#"https://staging-v2.skalenodes.com/v1/whispering-turais"



to = 60    
contracts = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/ContractsAddresses.txt", timeout=to).json()
abis = dict()
abis["ConfigRegistry"] = requests.get("https://raw.githubusercontent.com/MathiasExorde/TestnetProtocol-staging/main/ABIs/ConfigRegistry.sol/ConfigRegistry.json", timeout=to).json()

contract = w3.eth.contract(contracts["ConfigRegistry"], abi=abis["ConfigRegistry"]["abi"])

for value in ["_moduleHashContracts","_moduleHashTransaction","_moduleHashSpotting","_moduleHashSpotChecking","_moduleHashFormatting","_moduleHashApp"]:
    
    hashValue = contract.functions.get(value).call()
    code = downloadFile2Code(hashValue)
    exec(code)

    


# for value in ["https://ipfs.io/ipfs/bafybeidelohxapyx4iyko5gdvjwqek7uogqbpcmwlz3xv7mytkazs6a7s4/ContractManager.py",                 #Contracts
#               "https://ipfs.io/ipfs/bafybeifutccfdkeikkfz52z3hcrhf7nzk5frjavcgwazyvfuz54e32o5ti/TransactionManager.py",              #Transactions
#               "https://ipfs.io/ipfs/bafybeigwxqrl4yk4etbaiipkhtoeckbugliegxqru3upz7zxvonk6rcfri/Scraping.py",                        #Spotting
#               "https://ipfs.io/ipfs/bafybeigfjih2o24cotjsrxo3wmhqn5rhsy66jfoo6fsfqeswhlccua4uku/SpottingValidation.py",              #SpotChecking
#               "https://ipfs.io/ipfs/bafybeihkneksx3ohzmkmkyfqf7anxhjput6dxqt5tdmk63tw5qjg4ye3xu/Formatting.py",                      #Formatting
#               "https://ipfs.io/ipfs/bafybeidyddmrvqcduow5likint7ozar6lunymmoedni76ndemaccnpamoe/ExordeApp.py"]:                      #App
#     print(value)
    
#     #code = requests.get(value).text
#     code=downloadFile2Code(value)
#     #print(code)
#     exec(code)

try:

    x = threading.Thread(target=run)
    x.start()
    
except Exception as e:
    
    tk.messagebox("Initialization error", "Something went wrong, please try again.")
    print(e)

# if(__name__ == "__main__"):

#     try:

#         x = threading.Thread(target=run)
#         x.start()
        
#     except Exception as e:
        
#         tk.messagebox("Initialization error", "Something went wrong, please try again.")
#         print(e)