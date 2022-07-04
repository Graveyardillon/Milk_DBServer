import json
import requests
import matplotlib.pylab as plt

print("select mode\nDaily increase : 0\nAccumulation : 1\nmode = ", end="")
mode = int(input())
print("Please enter the start date of the data")
print("yyyymmdd = ", end="")
min = int(input())
print("Please enter the end date of the data")
print("yyyymmdd = ", end="")
max = int(input())

# url = "https://e-players6814.an.r.appspot.com//api/tournament/download"
url_tournament = "http://localhost:4000/api/tournament/download"
# url1 = "https://e-players6814.an.r.appspot.com//api/tournament/download_log"
url_tournament_log = "http://localhost:4000/api/tournament_log/download"
# url = "https://e-players6814.an.r.appspot.com//api/bracket/download"
url_bracket = "http://localhost:4000/api/bracket/download"
# url3 = "https://e-players6814.an.r.appspot.com//api/bracket/download_log"
url_bracket_log = "http://localhost:4000/api/bracket_log/download"
# url4 = "https://e-players6814.an.r.appspot.com//api/bracket/download_archive"
url_bracket_archive = "http://localhost:4000/api/bracket_archive/download"

url_list = [url_tournament, url_tournament_log, url_bracket, url_bracket_log, url_bracket_archive]

myList = []
for url in url_list:
  response = requests.get(url)
  d = response.json()
  myList.append(d.items())

myList = sorted(myList)

if mode == 1:
  modeName = "Accumulation"
  sum = 0
  deleted = 0
  for v in range(len(myList)):
    current = myList[v -deleted]
    sum = sum + current[1]
    if int(current[0]) > min and int(current[0]) < max:
      myList[v - deleted] = (str(int(current[0]) - 20000000), sum)
    else:
      del(myList[v - deleted])
      deleted = deleted + 1
else:
  modeName = "Daily increase"
  deleted = 0
  for v in range(len(myList)):
    current = myList[v -deleted]
    if int(current[0]) > min and int(current[0]) < max:
      myList[v - deleted] = (str(int(current[0]) - 20000000), current[1])
    else:
      del(myList[v - deleted])
      deleted = deleted + 1
print(myList)
x, y = zip(*myList)

plt.plot(x, y)
plt.xticks(rotation=90)
plt.title("Duration : " + str(min) + " - " + str(max) + "\nMode : " + modeName)
plt.tight_layout()
plt.show()