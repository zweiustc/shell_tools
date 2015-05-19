#!/usr/bin/python

import urllib
import urllib2
import sys
import json
import pycurl 

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

req = urllib2.Request(url, data)
for key in header:
	req.add_header(key, header[key])
try:
	result = urllib2.urlopen(req)
except urllib2.HTTPError as e:
	print 'The server couldn\'t fulfill the request, Error code: ', e.code
except urllib2.URLError as e:
	print "can not open the url: ", e.reason
else:
	response = json.loads(result.read())
	result.close()
