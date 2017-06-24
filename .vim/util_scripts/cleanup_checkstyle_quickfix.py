#!/usr/bin/python

# This simple script takes the output of the Java checkstyle utility and cleans
# it up so it works well in a quickfix list. Specifically it converts the error
# lines, which look like this:
#
# || /home/odain/Documents/code/spar/java/src/edu/mit/ll/spar/PublishingBrokerTest.java:129:20: warning: Unable to get class information for JMSException.
# to lines that are "%f %l %c %m" (i.e. file line column message)

import sys
import re

error_re = re.compile('([^:]+):([^:]+):([^:]+): [^:]+: (.*)')
# This is a hack to work around a known bug in checkstyle where it complains
# that it can't find information on certain exceptions even though they're
# on the classpath.
bug_re = re.compile('.*Unable to get class information for .*Exception.')

for line in sys.stdin:
    if bug_re.match(line):
        continue
    match = error_re.match(line)
    if match:
        print ' '.join(match.groups())


