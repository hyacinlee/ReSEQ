#!/usr/bin/env python 

import argparse
from Molde import readFasta 


# edit globa variable here
_CONTACT_              = "mengminghui@grandomics.com"


class HelpFormatter(argparse.RawDescriptionHelpFormatter,argparse.ArgumentDefaultsHelpFormatter):
    pass


def main():

    args = get_args()

    fasta = readFasta(args.ref)

    out_put(args,fasta)



def out_put(args,fasta):

    out1 = open("%s.sequence" % (args.out),"w")
    out2 = open("%s.sequence.fasta" % (args.out),"w")

    for line in open(args.list,"r"):
        info  = line.strip().split()

        if line.startswith("#"):
            out1.write("%s\tSequence\n" % (line.strip()) )
            continue

        (chr,pos,ref,alt) = (info[args.col_chr-1],int(info[args.col_pos-1]),info[args.col_ref-1],info[args.col_alt-1])

        start = max(pos - args.size , 0)
        leng  = max(len(ref)-len(alt),0)
        end   = min(pos + args.size , len(fasta[chr])) + leng

        sequence = fasta[info[args.col_chr-1]]          
        seq      = "%s[%s|%s]%s" % (sequence[start:pos-1],ref,alt,sequence[pos+leng:end])
        seq2     = sequence[start:end]
        
        out1.write("%s\t%s\n" %(line.strip(),seq))
        out2.write(">%s:%s-%s\n%s\n" %(chr,start+1,end+1,seq2))

    out1.close()
    out2.close()


def get_args():

    parser = argparse.ArgumentParser(
    formatter_class = HelpFormatter,
    description = '''
        Funciton: Get up/down-stream Sequence of SNP/INDEL makers  
    
        Usage:    python trans_matrix.py --indir ../02_MAP/validPairs/ -b out/groups.agp -r reference.fasta -o . -s 500 --bed  -n Name 
    '''
    )
    parser.add_argument('-l','--list',metavar='',help='SNP or INDEL list file ,or any file split by tab is ok ~')
    parser.add_argument('-f','--ref',metavar='',help='reference fasta file')
    parser.add_argument('-o','--out',metavar='',help='out file',type=str,default="./input")
    parser.add_argument('-s','--size',metavar='',help='up/down-stream length',type=int,default=500)
    parser.add_argument('--col_chr',metavar='',help='column number of contig name in list ',type=int,default=1)
    parser.add_argument('--col_pos',metavar='',help='column number of maker postion in chromsome',type=int,default=2)
    parser.add_argument('--col_ref',metavar='',help='column number of ref base ',type=int,default=3)
    parser.add_argument('--col_alt',metavar='',help='column number of alt base ',type=int,default=4)
    args = parser.parse_args()

    if not args.list or not args.ref:
        parser.print_help()
        exit(1)

    return args



if __name__ == '__main__':
    main()