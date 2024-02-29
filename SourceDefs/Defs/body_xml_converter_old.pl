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
 
## use an array with two or more values for the _tag_ and it's _content_ 
#  ,
#  [VilosSpine]    # becomes <def>VilosSpine</def>
#  -depth Inside   # becomes <depth>Inside</depth>
#  ( ,VilosTorso ) # becomes <groups> <li>VilosTorso</li> </groups>
#  
#  ,
#  [VilosNeck]
#  ( ,vilosneck )
#  -height Top
#  {{
#     ,
#     [head]
#     ( ,upperhead ,fullhead ,headattacktool )
#     {{
#        ,
#        [skull]
#        -depth inside
#        ( ,upperhead ,eyes ,fullhead )
#        {{
#           ,
#           [brain]
#           ( ,upperhead ,eyes ,fullhead )
#        }}
#     }} 
#  }}

my $customdata = join( "", <$input_fh> );
 

## I know the field where I'll put all my formatted data 
#my @CorePart = $customdata =~ s:<CorePart>(.*?)</CorePart>::g ;
my ($corepart) = $customdata =~ m:<corePart>(.*?)</corePart>:s
or die "couldn't find corePart'";

# print STDOUT $corepart;

my @data = (["corePart",[],0]);
my $in_li = 0;
# doing this instead of 
my @in_li = (0)

## structured like this: ( [ key, dataref, in_li ], [ key, dataref, in_li ], ...)
## you'll see ( key, dataref ) in there if the data consists of text
my $ref = [];
$data[0][1] = $ref;
my @refarray = ($ref);

# sub format_corepart { 
# 
#    $corepart =~ /\G\s*/gcs; # EAT SPACES
# 
#    moveup("parts") if ($corepart =~ /\G\{\{/gc); # start nesting stuff
#    goback()        if ($corepart =~ /\G}}/gc); # exit the thing
# 
#    push(@data, ["def", $1]) if ($customdata =~ / \G \[ (\w+) ] /xgc);
# 
# 
#    push(@data, ["coverage", $1]) if ($customdata =~ / \G \( (\d\+(?>\.\d\+)) \) /xgc);
#    moveup("group")               if ($customdata =~ / \G \(\s*(?=,) /xgc);
#    goback() if ($customdata =~ /\)/xgc );
# 
# 
#    push(@data, [$1, $2]) if ($customdata =~ / \G -(\w+) \s+ (\w\S*) /xgc);
#    moveup($1)            if ($customdata =~ / \G -(\w+) \s+ [{](?![{]) /xgc);
#    goback()              if ($customdata =~ / \G }(?!}) /xgc);
# 
#    push(@data, ["li", $1]) if ($customdata =~ / \G , \s (\w+) /xgc );
# 
#    if ($customdata =~ /\G,/xgc )
#    {
#       goback() if $in_li;
#       moveup("li");
#       $in_li = 1;
#    }
# } 
# foreach $corepart (@CorePart)
# {
#    until ($corepart =~ /\G$/) {
#       format_corepart(); 
#    } 
# }

# until ($corepart =~ /\G$/) {
#    format_corepart();
# } 




sub add_thing {

   my $arr = $_[0];
   push @$ref, $arr; 
}
sub moveup {
   try {
      # keep it from accessing a non-existing index
   ${$refarray[-2]}[2] = $in_li;
   } catch ($e) {}
   # $$ref[2] = $in_li;
   $in_li = 0;
   my $arr = [$_[0], [], $in_li];
   push @$ref, $arr;
   # $ref = $refarray[-1];
   $ref = $$arr[1];
   push @refarray, $ref;

   print "pushed $_[0] to \@refarray with \$in_li == $in_li\n";
   return 1;
}
sub goback {
   push @$ref, ["</li>"] if $in_li;
   pop (@refarray);
   $ref = $refarray[-1]; 
   $in_li = $ref->[2]; 
   print "went back to $$ref[0] with \$in_li == $in_li\n";
   return 1;
}
sub add_groups
{
   my ($text) = @_;
   print "$text\n";
   # my $groups = ["groups", [], 0];
   # my $g = $$groups[1];
   # $text =~ s/^\s*,//;
   # foreach my $x (map {/^(?>\s*)(.*)(?<!\s)\s*\$|.*/} split(/,/, $text))
   # { push @$g, ["li", $x, "aaaa"] }
   my $groups = ["groups", [], 0];
   my @temp = [ $text =~ /\s*,(\w+)/i ];
   $$groups[1] = [ $text =~ /\s*,(\w+)/i ];
   push @$ref, $groups;
   return 1;
}
 

my $partcount = 0;
sub syntax_base {{
   $corepart =~ /\G\s+/gc; # EAT SPACES


   # print Dumper(@$ref);

   push @$ref, ["def",$1]        and next if ($corepart =~ / \G \[ (\w+) \] /xgc); 
   push @$ref, ["coverage",$1]   and next if ($corepart =~ / \G \( ([\d.]+) \) /xgc);

   # moveup("groups") and next if ($corepart =~ / \G \(\s+(?=,) /xgc);
   # goback()         and next if ($corepart =~ / \G \)/xgc );

   add_groups($1) and next if ($corepart =~ / \G \( ([^)]+) \) /xgc );

   moveup($1) and next if ($corepart =~ / \G -(\w+) \s+ [{](?![{]) /xgc);
   goback()   and next if ($corepart =~ / \G }(?!}) /xgc);

   moveup("parts".++$partcount) and next if ($corepart =~ /\G\Q{{\E\s*/gc);
   goback()        and next if ($corepart =~ /\G\Q}}\E/gc);

   # push @$ref, [$1,$2]      and next if ($corepart =~ / \G -(\w+) \s+ "? (?>( (?<=")[^"]* | \w[^\s{}[(,\-]* )) "? /xgc); #works?
   push @$ref, [$1,$2]      and next if ($corepart =~ / \G -(\w+) \s+ (\w+)  /xgc);
   push @$ref, ["label",$1] and next if ($corepart =~ / \G " ( [^"]* ) " /xgc);

   if ($corepart =~ /\G,[ ]+(\w+)/gc)
   {
      push @$ref, ["li", $1];
      next;
   }
   if ($corepart =~ /\G,/gc)
   {
      push @$ref, ["</li>"] if $in_li;
      push @$ref, ["<li>"];
      $in_li = 1;
      next;
   } 

   print STDOUT "\nerror: '$1'\n" if ($corepart =~ / \G ([^\s{}[(,\-]+) /xgc);
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
$corepart =~ /\G/gc;
try {
   my $lastpos = 0;
   my $errorcount = 0;
   my $errorcountlimit = 8;
   # until (length($corepart) >= pos $corepart)
   while ()
   { 
      syntax_base();
      if (pos $corepart==$lastpos)
         { ++$errorcount } else { $errorcount = 0 }
      $errorcount < $errorcountlimit or die "caught in a loop";
      $lastpos = pos $corepart; 
   }
}
catch ($e) {
   warn "An error occurred while processing the data: $e";
} 

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

my $output = "";
sub build_corepart {
   foreach $ref (@_)
   {
      if (0+@$ref == 1) {
         $output .= "\n$$ref[0]";
      }
      if (0+@$ref == 2) {
         $output .= "\n<$$ref[0]> $$ref[1] </$$ref[0]>";
      }
      if (0+@$ref == 3) {
         $output .= "\n<$$ref[0]>";
         __SUB__->(@{$$ref[1]});
         $output .= "\n</$$ref[0]>";
      }
   } 
}

# @data = ([1,3], ["parts",[["egg",90],["egg",90]], 1]);


print Dumper(@data);

build_corepart(@data);
 
# XML::Tidy->new('xml' => $output)->tidy()->write();
print $output;

# print STDOUT $output;
