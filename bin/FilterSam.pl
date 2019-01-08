#!/usr/bin/perl -w
use strict;
use lib "/export/personal/mengmh/software/lib/lib64/perl5/";
use lib "/export/personal/pengh/module/perl/PerlIO-gzip-0.20/lib64/perl5/";
use PerlIO::gzip;
die "\tUsage: perl $0 < in sam.gz > < out sam.gz >\n" unless(@ARGV==2);
my $in = $ARGV[0];
my $out= $ARGV[1];
open (IN,"<:gzip","$in") or die "Failed to open $in\n";
open (OUT,">:gzip","$out") or die "Failed to open $out\n";
while(<IN>){
	next if (/^$/);
	if (/^@/){
		print OUT $_;
        }
        else{
                my $flag=(split/\s+/,$_)[1];
                print OUT $_ if ($flag == 99 || $flag == 147 || $flag == 83 || $flag == 163 );
        }
}

