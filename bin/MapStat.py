#!/usr/bin/python 
import os
import re
import sys
import glob
import argparse

def ReadFlag(indir):
	dict={}
	for file in glob.glob(indir+"/*flagstat"):
		Name=os.path.splitext(os.path.split(file)[1])[0]
		f=open(file,'r')
		Cont=f.read()
		Nums=re.findall('(\d*.\d*%)',Cont)
		Reads=re.sub(r"(?<=\d)(?=(?:\d\d\d)+$)", ",",re.findall('\d+',Cont)[0])
		#print Name,Reads,Nums[0],Nums[1],Nums[2]
		f.close()
		dict[Name]="%s\t%s\t%s\t" %(Reads,Nums[0],Nums[1])
	return dict

def ReadDeep(indir):
	dict={}
	for file in glob.glob(indir+"/*depth.stat"):
		f=open(file,'r')
		for line in f.readlines():
			if line.startswith('#'):
				continue
			else:
				list=line.split('\t')
				dict[list[0]]="%s\t%s\t%s" % (list[1],list[4],list[5])
	return dict

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('-i',dest='indir',help='in dir with *flagstat and *deepstat')
	parser.add_argument('-o',dest='outfile',help='out result file')
	args = parser.parse_args()
	Flag=ReadFlag(args.indir)
	Deep=ReadDeep(args.indir)
	out=open(args.outfile,"w")
	out.write("#Sample\tTotalReads\tMapRate\tUniqMapRate\tCovrage\tDepth\tCovrageBase\n")
	for key in Flag.keys():
		out.write(key+'\t'+Flag[key]+Deep[key])

if __name__ == '__main__':
	main()