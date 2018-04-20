#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use LWP;
use JSON;

my $DOMAIN = "tralala.ru";
my $AWS_ZONE_BACKUP="backup/backup_2018-04-18-060001.json";
my $SELECTEL_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";


my $URL="https://api.selectel.ru/domains/v1/";

my $currentZones = &getZones();
my $zone_id = &getZoneId($DOMAIN, $currentZones);
my $records = &getRecords($zone_id);

my $lastAws = &getAws($AWS_ZONE_BACKUP);
my @create;
foreach(@{${$lastAws}{'ResourceRecordSets'}}) {
	my $tmp = &translateRecord($_);
	push(@create, @$tmp);
}
foreach(@create) {
	&addRecord($_);
}

sub getZoneId() {
	my ($domain, $list) = @_;
	my $result;
	foreach(@{$list}) {
		$result = ${$_}{'id'} if (${$_}{'name'} eq $domain);
	}
	return $result;
}
sub translateRecord() {
	my ($aws) = @_;
	my @newrec;
	my %srec;
	$srec{'name'} = ${$aws}{'Name'};
	$srec{'type'} = ${$aws}{'Type'};
	$srec{'ttl'} = ${$aws}{'TTL'};
#	$srec{'location'} = '';
	# SOA, NS, A/AAAA, CNAME, SRV, MX, TXT, SPF
	if ($srec{'type'} eq 'A' || $srec{'type'} eq 'AAAA') {
		$srec{'content'} = ${$aws}{'ResourceRecords'}[0]{'Value'};
		push(@newrec, \%srec);
	} elsif ($srec{'type'} eq 'MX') {
		foreach(@{${$aws}{'ResourceRecords'}}) {
		#### TODO: This records must not be overwriten
			my ($p, $c) = split / /, ${$_}{'Value'};
			$srec{'content'} = $c;
			$srec{'content'} =~ s/"//g;
			$srec{'priority'} = $p;
			my $copy = { %srec };
			push(@newrec, $copy);
		}
	} elsif ($srec{'type'} eq 'SPF') {
		$srec{'content'} = ${$aws}{'ResourceRecords'}[0]{'Value'};
		$srec{'content'} =~ s/"//g;
		push(@newrec, \%srec);
	} elsif ($srec{'type'} eq 'TXT') {
		foreach(@{${$aws}{'ResourceRecords'}}) {
                #### TODO: This records must not be overwriten
                        $srec{'content'} = ${$_}{'Value'};
			$srec{'content'} =~ s/"//g;
			my $copy = { %srec };
                        push(@newrec, $copy);
                }
	} elsif ($srec{'type'} eq 'CNAME') {
		$srec{'content'} = ${$aws}{'ResourceRecords'}[0]{'Value'};
		push(@newrec, \%srec);
	} elsif ($srec{'type'} eq 'SOA') {
		# Skip
		next;
		#$srec{'email'} = '';
		#$srec{'content'} = '';
	} elsif ($srec{'type'} eq 'NS') {
		# Skip
		next;
		#$srec{'content'} = '';
#	} elsif ($srec{'type'} eq 'SRV') {
#		$srec{'priority'} = '';
#		$srec{'weight'} = '';
#		$srec{'port'} = '';
#		$srec{'target'} = '';
	} else {
		print "Unknown record type: ". $srec{'type'} ."\n";
	}
#	print Dumper([$aws]);
#	print Dumper([\@newrec]);
	return \@newrec;
}
sub addRecord() {
	my ($record) = @_;
	my $ua = LWP::UserAgent->new;
        my $h = HTTP::Headers->new(
		'Content-type' => 'application/json',
                'X-Token' => $SELECTEL_KEY,
        );
        my $req = HTTP::Request->new('POST', $URL . $zone_id ."/records/", $h, encode_json($record));
        my $res = $ua->request($req);
        if ($res->is_success) {
                my $data = decode_json($res->decoded_content);
                print Dumper([$data]);
        } else {
		print $res->decoded_content;
        }
}
sub getRecords() {
	my ($zone_id) = @_;
	my $ua = LWP::UserAgent->new;
        my $h = HTTP::Headers->new(
                'X-Token' => $SELECTEL_KEY,
        );
        my $req = HTTP::Request->new('GET', $URL . $zone_id ."/records/", $h);
	my $res = $ua->request($req);
	my $result;
        if ($res->is_success) {
                my $data = decode_json($res->decoded_content);
                $result = $data;
                print Dumper([$data]);
        } else {
                die $res->status_line;
        }
        return $result;
}
# curl -H 'X-Token: <ключ>' -H "Content-Type: application/json" https://api.selectel.ru/domains/v1/
sub getZones() {
	my $ua = LWP::UserAgent->new;
	my $h = HTTP::Headers->new(
                'X-Token' => $SELECTEL_KEY,
        );
        my $req = HTTP::Request->new('GET', $URL, $h); # . "\&\$format=json");
        my $res = $ua->request($req);
#	print Dumper([$res]);
        my $result;
        if ($res->is_success) {
                my $data = decode_json($res->decoded_content);
                $result = $data;
             #   print Dumper([$data]);
        } else {
                die $res->status_line;
        }
        return $result;
}
sub getAws() {
	my ($file) = @_;

	open(FH, "<$file") or die $!;
	my $str;
	while(<FH>) {
		chomp;
		$str .= $_;
	}
	my $result = decode_json($str);	
	close(FH);
	return $result;
}
