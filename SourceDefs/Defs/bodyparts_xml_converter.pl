#!/usr/bin/perl
use strict;
use warnings;
use feature qw(current_sub);
use Syntax::Feature::Try;
use Data::Dumper;
use XML::Tidy;
use syntax 'try';

my $input_file = $ARGV[0]; ## first command line argument

#my ($output_file) =  $input_fh =~ /([!.]+)\./ ;

my $input_fh = undef;
 
open( $input_fh, "<", $input_file ) or die "Can't open $input_file: $!"; 
#open( my $output_fh, ">", $output_file ) or die "Can't open $output_file: $!";

## example of my format

# my $customdata = join( "", <$input_fh> ); 
## do this line-by-line this time
 





# print STDOUT $corepart;
## structured like this: ( [ key, data, data, data ], ...)
## where data -> <string> | [ key, data ] | [ key, data, data, ...]



## I want to preserve the XML header, so I'm doing a thing to put text directly onto lines
## the "file" part won't be outputted like a group


my @linedata = <$input_fh>;
my $linenumber = 0;
# sub Line {
#    my $key = shift;
#    my %dispatch_table = {
#          advance    => sub { return ++$linenumber <= $#linedata },
#          get        => sub { $linedata_[$linenumber] },
#          number     => sub { return $linenumber }
#    }; 
# 
#    return &{$dispatch_table->$key};
# 
#    ## exit if end of file
#    return $linenumber <= $#data;
# }

sub getline {
   return $linedata[$linenumber]
}
sub advanceline {
   return ++$linenumber <= $#linedata
}


my @data = ( "file" );
my $ref = \@data;
my @refarray = ($ref); 



sub moveup {
   my $arr = [$_[0]];
   push @$ref, $arr;
   push @refarray, $arr;
   $ref = $refarray[-1];
}

## lol, these ended up being the same
sub add_data { 
   push @$ref, shift;
}

sub add_text {
   push @$ref, shift;
}

sub process_indent {
   my $desiredindent = shift;
   die "indentaion error on line $linenumber of input file. needs indent level $desiredindent." and return if $desiredindent > 0+@refarray;
   pop @refarray while ($desiredindent < $#refarray);
   $ref = $refarray[-1];
} 
sub getindent {
   my $indenttext = "  ";
   my $line = shift;
   my $linebeginning = $line =~ /^((?>(?:$indenttext)*))(\s*)/;
   !$2 or die "indentaion error on line $linenumber of input file";
   return length($1)/length($indenttext); 
}

sub syntax_base {{
   my $bracket = "defName";
   my $quote = "label";
   my $parens = "hitPoints";

   my $line = getline();
   add_text('') and next  if !defined $line;
   add_text('') and next  if $line =~ /^\s*$/;
   add_text("$1") and next  if $line =~ m/^#(.*)/;
 
   ## for environments with brackets, load the regex to close it first?
   ## just loop through the environment from last to first;
 
   ## check indentation
   ## exit environments
   my $indent = getindent($line);
   print "$indent $line";
   process_indent($indent); 
 
   $line =~ /^\s*/gc; ## EAT SPACES

   ## true/false things
   while ($line =~ /\G[+\-]\w|\G\w+:/)
   {
      add_data(["$1", "$2"])  if $line =~ /\G(\w+):(?>\s*)(\w.*?)\s*$/gc;
      add_text("<$1>true</$1>")  if $line =~ /\G[+](\w+)/gc;
      add_text("<$1>false</$1>")  if $line =~ /\G[\-](\w+)/gc;
      $line =~ /\G\s*/gc; ## EAT SPACES
   }

   add_text("<$1>$2</$1>") and next  if ($line =~ /\G(\w+):(?>\s*)(\w.*?)\s*$/gc);
   moveup("$1") and next  if ($line =~ /\G(\w+):\s*$/gc); 

   add_data(["$bracket", $1])  if ($line =~ / \[ (\w+) \] /x); 
   add_data(["$quote", $1])    if ($line =~ / " ( [^"]* ) " /x);
   add_data(["$parens", $1])   if ($line =~ / \( ([\d.]+) \) /x); 

}}

# # until ($corepart =~ / \G ([^{}[(,\-]+) /xgc) {
# my $foundthing = 1;
# until ($corepart =~ / \G ([^{}[(,\-]+) /xgc) {
#    my $foundthing = $corepart =~ /\G\s+/gc; # EAT SPACES, also this counts as something matched
#    for (@syntax_base)
#    {
#       if (&{$_[0]}) {
#          $foundthing = 1;
#          &{$_[1]};
#          last;
#       }
#    } 
#    die "something went wrong" if !$foundthing;
# }


# syntax_base() until ($corepart =~ /\G\s*$/xgc);

## process the data!
do {
   syntax_base();
} while (advanceline());

# sub testThing {
#    $corepart =~ /\G\s*/gcs; # EAT SPACES
# 
#    print STDOUT "1\n" if ($corepart =~ /\G\Q{{\E/gc); # start nesting stuff
#    print STDOUT "2\n" if ($corepart =~ /\G\Q}}\E/gc); # exit the thing 
#    print STDOUT "3\n" if ($corepart =~ / \G \[ (\w+) \] /xgc); 
#    print STDOUT "4\n" if ($corepart =~ / \G \( (\d\+(?>\.\d\+)) \) /xgc);
#    print STDOUT "5\n" if ($corepart =~ / \G \(\s*(?=,) /xgc);
#    print STDOUT "6\n" if ($corepart =~ /\)/xgc ); 
#    print STDOUT "7\n" if ($corepart =~ / \G -(\w+) \s+ (\w\S*) /xgc);
#    print STDOUT "8\n" if ($corepart =~ / \G -(\w+) \s+ [{](?![{]) /xgc);
#    print STDOUT "9\n" if ($corepart =~ / \G }(?!}) /xgc); 
#    print STDOUT "10\n" if ($corepart =~ / \G , \s (\w+) /xgc );
# 
#    print STDOUT "" if ($corepart =~ / \G ([^{}[(,\-]+) /xgc );
# }
#
# until ($corepart =~ /\G$/) {
#    testThing();
# } 

# my $output = "";
# sub build_corepart {
#    foreach $ref (@_)
#    {
#       if (0+@$ref == 1) {
#          $output .= "\n$$ref[0]";
#       }
#       if (0+@$ref == 2) {
#          $output .= "\n<$$ref[0]> $$ref[1] </$$ref[0]>";
#       }
#       if (0+@$ref == 3) {
#          $output .= "\n<$$ref[0]>";
#          __SUB__->(@{$$ref[1]});
#          $output .= "\n</$$ref[0]>";
#       }
#    } 
# }




my $output = "";
sub process_data { 
   if (0+@_ == 1) {
      $output .= "$_[0]\n";
      return;
   }
   if (0+@_ == 2 and !ref($_[1])) {
      $output .= "<$_[0]>$_[1]</$_[0]>\n";
      return;
   }
   $output .= "<$_[0]>\n";
   foreach $ref (@_[1..$#_])
   {
      if (!ref($ref)) {
          $output .= "$ref\n"; 
      } else {
         __SUB__->(@$ref);
      } 
   }
   $output .= "</$_[0]>\n";
}

sub build_file { 
   foreach $ref (@_[1..$#_])
   {
      if (!ref($ref)) {
          $output .= "$ref\n"; 
      } else {
         process_data(@$ref);
      } 
   }
}

# @data = ([1,3], ["parts",[["egg",90],["egg",90]], 1]);


# print Dumper(@data);

build_file(@data);
print $output;
  
print XML::Tidy->new('xml' => $output)->tidy()->toString();

# print STDOUT $output;

