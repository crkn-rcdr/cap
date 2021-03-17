#!/usr/bin/env perl
use strict;
use warnings;
use CAP;

CAP->apply_default_middlewares(CAP->psgi_app(@_));