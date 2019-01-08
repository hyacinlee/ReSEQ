#!/usr/bin/perl -w 
use strict;
use lib "/export/apps/software/smrtanalysis/install/smrtanalysis_2.3.0.140936/miscdeps/basesys/usr/lib/perl5/5.8.8/File/";
use File::Basename qw(basename dirname);
die "\tUsage: perl $0 < in bam dir > < ref fai > < split size | chr >\n" unless (@ARGV==3);
die "\tError: < split size > must less than 100 and large than 10   or  < split size > == \"chr\" \n" if($ARGV[2] ne "chr" && ($ARGV[2]>100 || $ARGV[2]<10));

my (%split,$len);
if($ARGV[2] ne "chr"){
	my $GenomeSize=`tail -1 $ARGV[1]|cut -f3`;
	chomp $GenomeSize;
	my $BlockSize=int($GenomeSize/$ARGV[2])+100000;
	open IN,"<$ARGV[1]" or die "Cant open $ARGV[1] because $!";
	while(<IN>){
		my @l=split;
		$len+=$l[1];
		my $SplitNum=int($len/$BlockSize)+1;
		#print "$l[2]\t$BlockSize\t$SplitNum\n";
		my $k="Split".(sprintf "%02d", $SplitNum);
		$split{$k}.="$l[0] ";
	}
}
else{
	open IN,"<$ARGV[1]" or die "Cant open $ARGV[1] because $!";
	while(<IN>){
		my @l=split;
		$split{$l[0]}=$l[0];
	}
}

open LIST,">$ARGV[0]/Split.list" or die "$! for $ARGV[0]/Split.list\n";
foreach my $key (sort {$a cmp $b} keys %split){
	print LIST "$key\t$split{$key}\n";
}
close LIST;

open CMD,">$ARGV[0]/01.cmd.SplitBam.sh" or die "$! for $ARGV[0]/Split.sh\n";
my @bam=glob "$ARGV[0]/*bam";
foreach my $bam (@bam){
	my $dir="$bam.split";
	mkdir $dir if(!-d $dir);
	my $BamName=basename($bam);
	$BamName=~s/.bam$//;
	foreach my $key (sort {$a cmp $b} keys %split){
		print CMD "cd $dir && /export/personal/mengmh/software/samtools-1.4/samtools view -h $bam $split{$key} | /export/personal/mengmh/software/samtools-1.4/samtools view -bS > $dir/$BamName.$key.bam\n";
		#print CMD "samtools index $BamName.$key.bam\n";
	}
}
close CMD;
chdir $ARGV[0];
#`/home/mengmh/bin/qsubSge -q asm.q -m 500 --pe smp 1 -l 2 -j SplitBam SplitBam.sh`
