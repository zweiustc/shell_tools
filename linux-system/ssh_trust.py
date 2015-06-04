import os
import pexpect
import time
username="root"
password="test"
fail_mac_list = []

def ssh_cmd(machines):
    fd = open(machines,'r')
    lines = fd.readlines()
    fd.close()
    for line in lines:
        time.sleep(2)
        if line:
            line = line.rstrip().lstrip()
            if len(line) < 4:
                continue
            #print line,len(line)
            cmd = "ssh-copy-id  %s" % (line)
            print cmd
            child = pexpect.spawn(cmd)
            try:
                i = child.expect(['password:', 'continue connecting (yes/no)?'], timeout=10)
                if i == 0:
                    child.sendline(password)
                elif i == 1:
                    child.sendline('yes')
                    child.expect('password:')
                    child.sendline(password)
            except pexpect.EOF:
                print "EOF,success"
            except pexpect.TIMEOUT:
                print "timeout"
                fail_mac_list.append(line)

def updateKernal(machines):
    pass
if __name__ == "__main__":
    #cmd = "ssh-copy-id  %s" % (line)
    ssh_cmd('./mac_list')
    if len(fail_mac_list) == 0:
        print "congratulation"
    else:
        print fail_mac_list
    print fail_mac_list
