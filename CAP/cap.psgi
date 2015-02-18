#!/usr/bin/env perl
use strict;
use warnings;
use CAP;

#  Catalyst::Helper::PSGI created the following...
#CAP->setup_engine('PSGI');
#my $app = sub { CAP->run(@_) };

# Modifying what CIHM::Cowbell had.

my $app = CAP->apply_default_middlewares(CAP->psgi_app);
$app;
