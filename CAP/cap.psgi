#!/usr/bin/env perl
use strict;
use warnings;
use CAP;
use Plack::Builder;

my $app = CAP->apply_default_middlewares(CAP->psgi_app(@_));

builder {
    enable "StackTrace", force => 1;
    $app;
};