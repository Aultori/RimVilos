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
## structured like this: ( [ key, data, data, data ], ...)
## where data -> <string> | [ key, data ] | [ key, data, data, ...]

my @data = ("corePart");
my $ref = \@data;
my @in_li = (0);
my @refarray = ($ref); 

sub moveup {
   my $arr = [$_[0]];
   push @$ref, $arr;
   push @refarray, $arr;
   push @in_li, 0;
   $ref = $refarray[-1];
}
sub goback {
   push @$ref, "</li>" if $in_li[-1];
   pop @refarray;
   pop @in_li unless (0+@in_li); ## if in_li not empty
   $ref = $refarray[-1];
}
sub add_groups
{
   my $name = shift;
   my $text = shift;
   push @$ref, ["$name", map {"<li>$_</li>"} ($text =~ /\s*,(\w+)/g) ];
}
 

sub syntax_base {{
   $corepart =~ /\G\s+/gc; # EAT SPACES 

   push @$ref, ["def",$1]        and next if ($corepart =~ / \G \[ (\w+) \] /xgc); 
   push @$ref, ["coverage",$1]   and next if ($corepart =~ / \G \( ([\d.]+) \) /xgc);

   add_groups($1,$2) and next if ($corepart =~ / \G (\w+):\s* \( ([^)]+) \) /xgc );
   add_groups($1,$2) and next if ($corepart =~ / \G (\w+):\s*+ \{ ([^}\n]++) \} /xgc );

   moveup($1) and next if ($corepart =~ / \G (\w+): \s+ [{](?![{]) /xgc);
   goback()   and next if ($corepart =~ / \G }(?!}) /xgc);

   moveup("parts") and next if ($corepart =~ /\G\Q{{\E\s*/gc);
   goback()        and next if ($corepart =~ /\G\Q}}\E/gc);

   moveup("$1")    and next if ($corepart =~ /\G(\w+)\s*\Q{\E\s*/gc);
   goback()        and next if ($corepart =~ /\G\Q}\E/gc);

   push @$ref, [$1,$2]      and next if ($corepart =~ / \G -(\w+) \s+ (\w+)  /xgc);
   push @$ref, [$1,$2]      and next if ($corepart =~ / \G (\w+): \s* (\w+)  /xgc);
   push @$ref, ["customLabel",$1] and next if ($corepart =~ / \G " ( [^"]* ) " /xgc);

   if ($corepart =~ /\G,[ ]+(\w+)/gc)
   {
      push @$ref, ["li", $1];
      next;
   }
   if ($corepart =~ /\G,/gc)
   {
      push @$ref, "</li>" if $in_li[-1];
      push @$ref, "<li>";
      $in_li[-1] = 1;
      next;
   } 

   print STDOUT "\nerror: '$1'" if ($corepart =~ / \G ([^\s{}[(,\-]+) /xgc);
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
      ## this is how the loop stops normaly too
      $errorcount < $errorcountlimit or die "caught in a loop";
      $lastpos = pos $corepart; 
   }
}
catch ($e) {
   # warn "An error occurred while processing the data: $e";
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
sub build_corepart { 
   if (0+@_ == 1) {
      $output .= "\n$_[0]";
      return;
   }
   if (0+@_ == 2 and !ref($_[1])) {
      $output .= "\n<$_[0]>$_[1]</$_[0]>";
      return;
   }
   $output .= "\n<$_[0]>";
   foreach $ref (@_[1..$#_])
   {
      if (!ref($ref)) {
          $output .= "\n$ref"; 
      } else
      {
         __SUB__->(@$ref);
      }

   }
   $output .= "\n</$_[0]>";
}

# @data = ([1,3], ["parts",[["egg",90],["egg",90]], 1]);


# print Dumper(@data);

build_corepart(@data);

$output = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
<Defs>

<BodyDef>
<defName>RimVilos_HumanoidFourArms</defName>
<label>vilos</label>\n".$output . "
</BodyDef>

</Defs>";

print "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" . XML::Tidy->new('xml' => $output)->tidy()->toString();

# print STDOUT $output;

