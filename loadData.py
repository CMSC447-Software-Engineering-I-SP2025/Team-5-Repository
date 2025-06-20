import requests, json
import zipfile

# load zipfile
archive = zipfile.ZipFile('movie_dump.zip','r')
# pull db dump from zip
dump = archive.open('movie_dump.json')
# parse json
parsed = json.load(dump)

# request setup
url='http://localhost:8080/movies'
headers = { 'Content-Type': 'application/json' }

# post each entry
for k in parsed.keys():
    resp = requests.post(url, json=parsed[k], headers=headers)
    print(k, resp.status_code)