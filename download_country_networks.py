#!/usr/bin/python

import sys
import ipaddr
import urllib2
import gzip
import io
import csv

def main(outputFilePath, countryIsoCodes):
	fromIpIndex = 0
	toIpIndex = 1
	isoCodeIndex = 4

	print "Downloading global IP blocks..."
	stream = urllib2.urlopen('http://software77.net/geo-ip/?DL=1')
	print "Done."

	print "Dumping CIDRs for {}...".format(", ".join(countryIsoCodes))
	with gzip.GzipFile(fileobj=io.BytesIO(stream.read())) as database:
		with open(outputFilePath, 'w') as outputFile:
			for row in csv.reader(database):
				# Ignore comments in file (starting with '#')
				if len(row) > 0 and not row[0].startswith('#'):
					isoCode = row[isoCodeIndex]

					if isoCode in countryIsoCodes:
						fromIpString = row[fromIpIndex]
						toIpString = row[toIpIndex]

						try:
							fromIp = ipaddr.IPv4Address(int(fromIpString))
							toIp = ipaddr.IPv4Address(int(toIpString))
							networks = ipaddr.summarize_address_range(fromIp, toIp)

							# Ensure that range only produced one network
							if len(networks) == 1:
								network = networks[0]
								outputFile.write(str(network) + '\n')
							else:
								print "Range contains more than a single network! From: {}, to: {}".format(fromIpString, toIpString)
						except:
							print "Error adding a network! From: {}, to: {}".format(fromIpString, toIpString)

	print "Done."

if __name__ == "__main__":
	programName = sys.argv[0]

	if len(sys.argv) < 3:
		print "Usage: %s <output file> <country ISO code 1> [<country ISO code 2> ...]" % programName
	else:
		outputFile = sys.argv[1]
		countryIsoCodes = sys.argv[2:]

		main(outputFile, countryIsoCodes)
