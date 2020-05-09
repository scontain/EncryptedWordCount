#!/usr/bin/python
import sys
file=open(sys.argv[1],"r+")

wordcount={}
for word in file.read().split():
    if word not in wordcount:
        wordcount[word] = 1
    else:
        wordcount[word] += 1
for k,v in wordcount.items():
    print(k, v)

