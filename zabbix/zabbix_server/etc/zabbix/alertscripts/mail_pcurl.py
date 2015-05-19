#!/usr/bin/python

import sys, pycurl, json, pycurl

url = "http://10.161.0.76:8765/smss/open/sendMail"

header = {"Content-Type":"application/json"}
dest = sys.argv[1]
subject = sys.argv[2]
msg = sys.argv[3]

data = json.dumps({
	"sendTo" : dest,
	"subject" : subject,
	"msg" : msg
})

c = pycurl.Curl()
c.setopt(pycurl.URL, '%s' % url)
c.setopt(pycurl.HTTPHEADER, ['Accept: application/json', 'Content-Type: application/json'])
c.setopt(pycurl.POST, 1)
c.setopt(pycurl.POSTFIELDS, data)
c.perform()
