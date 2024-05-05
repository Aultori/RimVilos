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

## sometimes there's weird stuff at the beginning of a file, removing that
$linedata[0] = ($linedata[0] =~ /^\W*(\w.*)$/)[0];

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

my $line = undef;




sub moveup {
   my $arr = [$_[0]];
   push @$ref, $arr;
   push @refarray, $arr;
   $ref = $refarray[-1];
}

sub moveup_nested {
   my $arr = [shift];
   my $idkwhattocallthis = [@_]; 
   my $firstRef = $arr;
   my $fullyNestedRef = $arr;
   my $tempRef = $firstRef;
   ## if @_ is empty, this will be skiped
   foreach my $a (@_) {
      $fullyNestedRef = [$a];
      push @$tempRef, $fullyNestedRef;
      $tempRef = $fullyNestedRef; 
   }
   push @$ref, $firstRef;
   push @refarray, $fullyNestedRef;

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
   die "[indentaion error on line $linenumber of input file. needs indent level $desiredindent.]" if $desiredindent > 0+@refarray;
   pop @refarray while ($desiredindent < $#refarray);
   $ref = $refarray[-1];
} 
sub getindent {
   my $indenttext = "   ";
   my $line = shift;
   my $linebeginning = $line =~ /^((?:$indenttext)*+)(\s*)/;
   !$2 or die "[indentaion error on line $linenumber of input file]";
   return length($1)/length($indenttext); 
}

## inline stuff:
## get the data and format it
## send to recursive funcion 
## handle the modifier thing in the function by checking for it after the block, if one exists, is exited
# sub inline_stuff {
#    $line =~ /\G(\w+)\s*/gc;
#    my $tmp = [$1];
#    
#    if ($line =~ /\G:\s*([^{\s][^}\s]*)\s*/gc) {
#       push @$tmp, $1;
#    }
#    elsif ($line =~ /\G\{\s*/gc)
#    {
#       while ($line =~ /\G(\w+)\s*/)
#       {
#          push @$tmp, __SUB__->();
#       }
#       die "[syntax error on line $linenumber]" if !($line =~ /\G\}\s*/gc);
#    }
#    
#    if ($line =~ /\G\[([^\]]+)\]\s*/gc)
#    {
#       ## doing a weird thing with the data structure so I can hold extra data
#       my $a = $$tmp[0];
#       $$tmp[0] = [$a,$1];
#    } 
# 
#    return $tmp;
# }


sub new_inline_stuff {
   if ($line =~ /\G([+\-])([A-Za-z_]++)\s*/gc) ## value and key
   {
      my $value = ($1 eq"+")? "true" : "false";
      my $key = $2;
      return [$key,$value];
   }
   elsif ($line =~ /\G([A-Za-z_]++)\s*/gc) ## key
   {
      my $tmp = [$1]; 
      my $modifier = undef;

      ## check for modifier
      $modifier = $1 if $line =~ /\G\[([^\]]++)\]\s*/gc;

      ## get the data
      if ($line =~ /\G:\s*+([^[\]{}\s]++)\s*/gc)
      {
         push @$tmp, $1;
      }
      elsif ($line =~ /\G\{\s*/gc)
      {
         while () {
            my $entry = new_inline_stuff();
            last if !defined $entry;
            push @$tmp, $entry;
         }
         die "syntax error: missing '}'" if !($line =~ /\G\}\s*/gc); 
      } 

      ## check for modifier
      $modifier = $1 if $line =~ /\G\[([^\]]++)\]\s*/gc;

      ## handle modifier
      if (defined $modifier) {
         my $a = $$tmp[0];
         $$tmp[0] = [$a,$1];
      }

      return $tmp; 
   } 

   return undef;
}


##   <entry>  -->     -<key>                    <wordBoundry><entry>
##                 |  +<key>                    <wordBoundry><entry>
##                 |  <key> <data>              <wordBoundry><entry>
##                 |  <key> <data> [<modifier>]
##                 |  <key> [<modifier>] <data> <wordBoundry><entry>
##                 |  <nothing>
##   <data>  -->  : <stringwithnospaces>
##              | { <entry> }
##
##  an exception to all of this is a line that matches /^\s* (?<key>\w+): (?>\s+) (?<value>[^{}:[\]]*) (?<=\S)\s*$/x
##
##  these start groups, and another level of indentaion is needed for stuff inside them:
##  /^\s* (?<key>\w+) (?:\s*\[(?<modifier>[^\]]*)\])?: \s*$/x
##  /^\s* (?<key>\w+) (?>\s*) (?:\[(?<modifier>[^\]]*)\])? \s*\{ \s*$/x

##  +------------------+
##  |   new behavior   |
##  +------------------+
##  2024-05-04
##
##   do this before checking other stuff on the line, like if it's plain text
##   this handles nesting entries with a /, so I won't have to do that separately anymore
##
##   <entry>  -->
##                    <singlekey> { <entry> } [<modifier>]
##                 |  <singleentry> <space> <entry>
##                 |  <nothing>
##
##   <key>  -->  <singlekey>
##             | <singlekey>[<modifier>]
##
##   <singleentry>  -->     -<singlekey>
##                       |  +<singlekey>
##                       |  <key>:<stringwithnospaces> <wordboundry>
##                       |  <key><slashnesting> <data>
##
##   <slashnesting>  -->    /<key><slashnesting>
##                       |  <nothing>
##
##   <data>   -->  { <entry> }
##              |  : <space> <singleentry>
##
##  an exception to all of this is a line that matches /^\s* (?<key>\w+): (?>\s+) (?<value>[^{}:[\]]*) (?<=\S)\s*$/x
##
##  these start groups, and another level of indentaion is needed for stuff inside them:
##  /^\s* (?<key>\w+) (?:\s*\[(?<modifier>[^\]]*)\])?: \s*$/x
##  /^\s* (?<key>\w+) (?>\s*) (?:\[(?<modifier>[^\]]*)\])? \s*\{ \s*$/x


## to fix the problem where text and comments appear nested in the wrong thing
my @space_stuff = ();
sub add_space_stuff {
   push @space_stuff, shift;
}

sub syntax_base {{
   $line = getline();
   add_space_stuff('') and next  if !defined $line;
   add_space_stuff('') and next  if $line =~ /^\s*$/;
   $line =~ /^\s*/gc; ## EAT SPACES 
   ## brackets are ignored
   next if $line =~ /\G[{}]\s*$/gc;
   add_space_stuff("<!-- $1 -->") and next if $line =~ /\G\/\/\s*+(.*)(?<=\S)/gc;
   add_space_stuff("$1") and next  if $line =~ m/^#(.*)(?<=\S)/gc;
 
 
   ## check indentation
   ## exit environments
   my $indent = getindent($line);
   # print "$indent $line";
   process_indent($indent); 

   push @$ref, @space_stuff; ## add xml comments and stuff
   @space_stuff = ();
 
   # if ($line =~ /\G(?<key>[A-Za-z_.]++) (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ :\s*+$/xgc) {
   #    my $temp = $+{key};
   #    if ($+{modifier}) { $temp = [$+{key}, $+{modifier}] }
   #    if ($+{class}) { $temp = [$+{key}, 'Class="'.$+{class}.'"'] } 
   #    my @nest = ();
   #    @nest = ($+{nesting} =~ /\s*+\/(\w++)/g) if $+{nesting};
   #    moveup_nested( $temp, @nest ) and next; 
   # } 
   ## brackets are ignored
   #if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ \s*+ \{?\s* $/xgc) {
   ## remove later
   if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ (?: :\s*+$ | \s*+\{?\s*+$ )/xgc) {
      my $temp = $+{key};
      my @nest = ();
      $temp = [$+{key}, $+{modifier}]             if $+{modifier}; 
      $temp = [$+{key}, 'Class="'.$+{class}.'"']  if $+{class}; 
      @nest = ($+{nesting} =~ /\s*+\/(\w++)/g)    if $+{nesting};
      moveup_nested( $temp, @nest ) and next; 
   } 

   # if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ /xgc) {
   #    my $hasModifier = defined $+{modifier};
   #    my $hasClass = defined $+{class};
   #    my $temp = $+{key};
   #    my @nest = ();
   #    $temp = [$+{key}, $+{modifier}]             if $hasModifier;
   #    $temp = [$+{key}, 'Class="'.$+{class}.'"']  if $hasClass; 
   #    @nest = ($+{nesting} =~ /\s*+\/(\w++)/g)    if $+{nesting};
   #    my $nested = $#nest != 0;
   #    if ($line =~ /\G(?: :\s*+$ | \s*+\{?\s*+$ )/xgc)
   #    {
   #       moveup_nested( $temp, @nest ) and next;
   #    }
   #    if ( !$nested and !$hasModifier and !$hasClass)
   #    {
   #       add_text( "<$temp $2>$1</$temp>" ) and next if $line =~ /\G : \s++ ([^{}\->]++)\s*+\[([^\]]++)\] \s*+$/xgc
   #    }
   #    ## only supports { for inline stuff inside it
   #    if ($line =~ /\G \s*+ {(.*)}\s*$/xgc)
   #    {
   #       # my @entries = ();
   #       my $entry = undef;
   #       #push(@entries, $entry) while (defined ($entry = new_inline_stuff()));
   #       #moveup_nested( $temp, @nest );
   #       moveup_nested( $temp, @nest );
   #       add_data($entry) while (defined ($entry = new_inline_stuff()));
   #       next;
   #    }

   #    ## reset the position of the line
   #    $line = getline();
   #    $line =~ /^\s*/gc; ## EAT SPACES 
   # } 

   ## for things like "<.../>"
   if ($line =~ /\G<\s*+(\w++)\s++([^>]++)>/xgc) {
      add_text("<$1 Class=\"$2\"/>") and next;
   }

   add_text( "<$1 $3>$2</$1>" ) and next  if $line =~ /\G (\w++): \s++ ([^\->]++)\s*+\[([^\]]++)\] \s*+$/xgc;

   add_text("<$1/>") and next  if ($line =~ /\G\[([^\]]++)\]\s*$/xgc);



   ## for entries with text
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (?> ([^{}:[\]]+) (?<=\S) ) \s*+$/xgc;
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (?> ([^{}:]+) (?<=\S) )(?<!\]) \s*+$/xgc;
   ## if at any point " [...] something here" it's plain text
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?>[^}\]:]+(?<=\S)) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;
   add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?>[^}\]:]+(?<=\S)) (?:\s*+\S.*(?<=\S))?+  ) (?<!\]) \s*+$/xgc;

   ## for rules
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?> [\s0-9A-Za-z_+\-=<>.,()[\]{}]*? -> ) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;
   add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?> .*? -> ) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;


   ## todo: get blocks working. the {} don't actually do anything
 
   ## inline stuff:
   ## get the data and format it
   ## send to recursive funcion 
   ## my current position is already saved by \G 
   ## I should've covered all the syntax possibilities by now. if it doesn't make it to the end, that's an error.
   while () {
      my $entry = new_inline_stuff();
      last if !defined $entry;
      add_data($entry);
   } 

   #add_text("<$1/>") and next  if ($line =~ /\G\[([^\]]++)\]\s*$/xgc);
}} 

## process the data!
do {
   syntax_base();
   #die "[syntax error on line $linenumber] \"".($line =~ /^(.*?\G[^\n]*)$/)[0]."\""  unless $line =~ /\G\s*$/
   unless ($line =~ /\G\s*+$/) {
      my $error = ($line =~ /^(.*?\G.*)$/)[0];
      $error =~ s/\S\K\s+$//;
      die qq{[syntax error on line $linenumber] "$error"};
   }
    
#   die "[syntax error on line $linenumber]".($line =~ /\G.*/)  unless $line =~ /\G\s*$/
} while (advanceline());

push @$ref, @space_stuff; ## add xml comments and stuff

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
# sub process_data { 
#    if (0+@_ == 1) {
#       $output .= "$_[0]\n";
#       return;
#    }
#    if (0+@_ == 2 and !ref($_[1])) {
#       $output .= "<$_[0]>$_[1]</$_[0]>\n";
#       return;
#    }
#    $output .= "<$_[0]>\n";
#    foreach $ref (@_[1..$#_])
#    {
#       if (!ref($ref)) {
#           $output .= "$ref\n"; 
#       } else {
#          __SUB__->(@$ref);
#       } 
#    }
#    $output .= "</$_[0]>\n";
# }

my $indent = 0;
my $indent_text = '  ';
sub indent { $indent_text x $indent }
sub process_data {
   if (0+@_ == 1) {
      $output .= &indent."$_[0]\n";
      return;
   }

   ## todo: simplify this part later
   ## this does something I don't know how to explain in words
   ## also it shifts one entry off @_
   my $datathing = shift;
   my ($key,$modifier) = (undef,undef);
   if ("ARRAY" eq ref($datathing)) {
      ($key,$modifier) = @$datathing;
   } else {
      $key = $datathing;
   }
   my @brackets = ($key,$key);
   if (ref($datathing) eq "ARRAY") {
      $brackets[0] = "$key $modifier";
   } 
   
   ## thing containing text
   if (0+@_ == 1 and !ref($_[0])) {
      $output .= &indent."<$brackets[0]>$_[0]</$brackets[1]>\n";
      return;
   }
   ## thing containing other things
   $output .= &indent."<$brackets[0]>\n";
   my $tempindent = $indent++;
   foreach $ref (@_)
   {
      if (!ref($ref)) {
         ## a scalar
         $output .= &indent."$ref\n"; 
      } else {
         __SUB__->(@$ref);
      } 
   }
   $indent = $tempindent;
   $output .= &indent."</$brackets[1]>\n"; 
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
#$output =~ s/\r/\x0A\x0D/g; # CRLF

print "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\r$output";
# print $output;
  
# print "===============\r";
# print XML::Tidy->new('xml' => $output)->tidy()->toString();

# print STDOUT $output;

