import json
import requests
import matplotlib.pylab as plt

mode = 1
url = "https://e-players6814.an.r.appspot.com//api/user/download"
response = requests.get(url)
d = response.json()

myList = d.items()
myList = sorted(myList)

if mode == 1:
  sum = 0

  for v in range(len(myList)):
    current = myList[v]
    sum = sum + current[1]
    myList[v] = (str(int(current[0]) - 20000000), sum)

print(myList)
x, y = zip(*myList)
plt.plot(x, y)
plt.show()