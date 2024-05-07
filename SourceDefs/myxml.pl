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


my $indent_size = 3;

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

## Input: (\@keys)
## Output: nothing
## takes the keys and moves into a nested group in the syntax parsing.
sub moveup_nested2 {
   my $keys = shift;
   my $firstEntry = [];
   my $lastEntry = $firstEntry;
   foreach my $key (@$keys)
   {
      push @$lastEntry, $_ = [$key]; ##- $key is already an array, [keyword, modifier]. putting it inside an array makes it an <entry>
      $lastEntry = $_;
   }
   push @$ref, @$firstEntry;
   push @refarray, $lastEntry;

   $ref = $lastEntry; 
}

## lol, these ended up being the same
sub add_data { 
   push @$ref, @_;
}

sub add_text {
   push @$ref, @_;
}

sub process_indent {
   my $currentindent = shift;
   my $desiredindent = scalar(@refarray);
   die "[indentaion error on line $linenumber of input file. needs indent level $desiredindent. currently $currentindent]\"$line\"" if $currentindent > scalar(@refarray);
   pop @refarray while ($currentindent < $#refarray);
   $ref = $refarray[-1];
} 
#sub process_indent {
#   my $desiredindent = shift;
#   my $currentindent = scalar(@refarray);
#   die "[indentaion error on line $linenumber of input file. needs indent level $desiredindent. currently $currentindent]\"$line\"" if $desiredindent > scalar(@refarray);
#   pop @refarray while ($desiredindent < $#refarray);
#   $ref = $refarray[-1];
#} 
## if the indent is divisable by the indent_size
## Input: length of the actual input, in spaces
#sub check_indent {
#   my $count = shift;
#   my $linebeginning = $line =~ /^((?:$indenttext)*+)(\s*)/;
#   !$2 or die "[indentaion error on line $linenumber of input file]";
#   return length($1)/length($indenttext); 
#}

#sub check_indent {
#   my $indenttext = "   ";
#   my $line = shift;
#   my $linebeginning = $line =~ /^((?:$indenttext)*+)(\s*)/;
#   !$2 or die "[indentaion error on line $linenumber of input file]";
#   return length($1)/length($indenttext); 
#}

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

####################################
##  +------------------+
##  |   new behavior   |
##  +------------------+
##  2024-05-04
##
##   do this before checking other stuff on the line, like if it's plain text
##   this handles nesting entries with a /, so I won't have to do that separately anymore
##   but first, save the position before I do this, so if it doesn't match, I can revert back and continue
##
##   note: any space after <key>: will cause the algorithim to treat everyting after it like a 
##
##   <rootentry>  -->  <entries>
##                  |  \<<string>\> ## could be for something that goes on a single line like <li Class="..."/>. the / will have to be included
##   <entries>  -->
##   //              |  <singlekey>: <space> <stringwithnospaces> [<modifier>]
##   //                 <singlekey> { <entries> } [<modifier>]     // only makes sense when the key isn't the end of some nested thing, and has no modifier initially. but it's simpler if I don't do this optomization
##                 |  <singleentry> <space> <entries>
##                 |  <singleentry>
##
##   // <key>(stuff) :=  <key>[<modifier>] stuff
##   //               |  <key> stuff [<modifier>]
##   //               |  <key> stuff
##
##   <key>  -->  <singlekey>[<modifier>]
##             | <singlekey>
##
##   <singleentry>  -->
##                       |  <keynesting> <data>
##                       |  <keynesting> <data> [<modifier>]
##                       |  <keynesting>:<stringwithnospaces> <wordboundry>  ## an optomization
##   //                    |  <key>:<stringwithnospaces> <wordboundry>
##                       |  -<singlekey>
##                       |  +<singlekey>
##
##   some pseudocode function
##   <keynesting>(stuff) :=
##            repeat ->
##                <key>(?!/)
##              | <key>/<repeat>
##            save all the <key>s found 
##            <key> will look for the modifier automatically
##            this function stores a list of <key>'s, and only builds the data structure until the end
##
##   <slashnesting>  -->    /<key><slashnesting>
##                       |  <nothing>
##
##   <data>   --> 
##              |  : <space> <stringwithnospaces>
##              |  : <space> <singleentry>
##   #           |  : <space> <string with spaces>  // know how many {} I'm inside, and stop when } is detected. I'f I'm not inside {}, continue to $. can't start with {.
##              |  <space>? = <space>? <string with spaces>  // know how many {} I'm inside, and stop when } is detected. I'f I'm not inside {}, continue to $. can't start with {.
##              |  <space>? { <space>? <entries> <space>? }
##
####################################

############################################
## The new inline syntax thing 2024-05-04
## try_get_inline_syntax($string,\@array)
## stores the data into it's argument.
## outputs false if it fails
############################################
##
##
## things it uses

   #my $rec_line;# = shift; ## a copy of $line used in syntax_base
   #my $rec_dataArr;# = shift;
   my $rec_blocksEntered = 0;# = 0;
   my $rec_reachedEnd = 0;
   #my @rec_dataContents = (); ## used to make it easy to switch to matching a raw string, if some point in the line fails to meet the proper syntax.

   ##   <rootentry>  -->  <entries>
   ##                  |  \<<string>\> ## could be for something that goes on a single line like <li Class="..."/>. the / will have to be included
   sub inline_syntax {
      my $pos = pos($line);
      #$rec_line = shift; ## a copy of $line used in syntax_base
      #$rec_dataArr = shift;
      $rec_blocksEntered = 0;
      $rec_reachedEnd = 0;
      ## returns null if there's an error, otherwise a string;
      #$line =~ /^\s*/gc; ## EAT SPACES 
      {
         @_ = rec_entries() and last;
         @_ = ($1) and last if ($line =~ /\G(\[[^]]++\])/gc);
         @_ = ("<$1 Class=\"$2\"/>") and last if ($line =~ /\G<\s*([A-Za-z_.]++) \s+ ([0-9A-Za-z_.]++)\s*>/xgc);
      }
      pos($line) = $pos and return () if $rec_blocksEntered != 0;
      pos($line) = $pos and return () unless $line =~ /\G\s*$/gc;
      return @_;
   }

   ##  <singleentry>  -->  <keynesting> <data> [<modifier>]?
   ##                   |  <keynesting>:<stringwithnospaces> [<modifier>]?  ## an optomization
   ##                   |  -<singlekey>
   ##                   |  +<singlekey>
   ## this produces something that's actually my data structure, so it contains a single entry, which can have more entries nested inside it.
   ## Returns: (<singleentry>)
   sub rec_singleentry {
      if (my @keys = rec_keynesting())
      {
         ##- @keys has something in it now
         my @content;

         #print "\@content size = ".scalar(@content)."\n";

         #if (@_ = rec_data())
         #{
         #   #my ($array, $pos) = @_;
         #   @content = @_;
         #}
         #elsif ($line =~ /\G:([^\s}]++)/gc)   ## never includes } 
         #{
         #   @content = ($1);
         #}
         #else
         #{
         #   return undef; ## if nothing matches
         #}

         {
            next if @content = rec_data();                           ##- match <keynesting><data>
            #last if @content = ($line =~ /\G:([^\s}]++)/gc)[1];  ##- match <keynesting>:<stringwithnospaces>. never includes }
            last if @content = ($line =~ /\G:([^\s}]++)/gc)[0];  ##- match <keynesting>:<stringwithnospaces>. never includes }
            #next if @if ($line =~ /\G:([^\n\s}]++)/gc)
            #{
            #   @content = $1;
            #   next;
            #}##- match <keynesting>:<stringwithnospaces>. never includes }
            return ();  ##- if nothing matches
         }
         return () if !@content;
         #return () if !@content or !defined $content[0];
         #print "\@content size = ".scalar(@content)."\n";
         #print "\@content: ".Dumper(@content);

         $line =~ /\G\s*\[([^\]]++)\]/gc; ##- look for the [modifier]

         #return combine_keys_with_content(\@keys, \@content, $1);
         if (@keys == 1)
         {
            #my $lastKey = $keys[-1]; ##- temporary variable
            #$keys[0] = [$$lastKey[0], $1] if $1;
            #$keys[-1] = $lastKey;
            $_ = $keys[0];
            #$_ = [[$1 ? ($$_[0],$1) : ($_)], @content] ;
            return [$1 ? [$$_[0],$1] : ($_), @content];
            #$_ = $1 ? [ ${$keys[0]}[0], $1 ] : [$keys[0]];
            #return [($1 ? [ ${$keys[0]}[0], $1 ] : [$keys[0]]), ; ## try doing $$keys[0][0]
            #return [($1 ? [$$_[0],$1] : [$_]), ; ## try doing $$keys[0][0]
            #return [[$1 ? (${$keys[0]}[0],$1) : ($keys[0])], @content];
         
         }
         else
         {
            ##- combine the keys with the content. after looking for the [modifier]
            #my $lastKey = $keys[-1]; ##- temporary variable
            #$lastKey = [$$lastKey[0], $1] if $1;
            #$keys[-1] = $lastKey;
            $keys[-1] = [${$keys[-1]}[0], $1] if $1;
            ##- modifier added
         
            my $firstEntry = [];
            my $lastEntry = $firstEntry;
            foreach my $key (@keys)
            {
               push @$lastEntry, $_ = [$key]; ##- $key is already an array, [keyword, modifier]. putting it inside an array makes it an <entry>
               $lastEntry = $_;
            }
            push @$lastEntry, @content;
            #print Dumper(@$firstEntry);
            return @$firstEntry;
         }
      }
      if ($line =~ /\G([+\-])([A-Za-z_.]++)/gc) {
         #$1 = ($1 eq "+")? "true" : "false";
         return [[$2], ($1 eq "+")? "true" : "false"];
      }

      return ();
   }

   ### Input: (\@keys, \@content, $modifier)
   ### @keys is a list of <key>'s
   ### @Content is a list of [<entry>]'s
   ### $modifier 
   ### Outputs: an entry made by combining the keys with the contents
   #sub combine_keys_with_content {
   #   #my (\@keys, \@content, $modifier)
   #   my $keys = shift;
   #   my $content = shift;
   #   my $modifier = shift;
   #   return undef if !@$keys;

   #   if (@$keys == 1)
   #   {
   #      $_ = $$keys[0];
   #      return [[$modifer ? ($$_[0],$modifier) : ($_)], @$content];
   #   }
   #   else
   #   {
   #      ##- combine the keys with the content. after looking for the [modifier]
   #      my $lastKey = $$keys[-1]; ##- temporary variable

   #      $lastKey = [$$lastKey[0], $1] if $1;
   #      $$keys[-1] = $lastKey;
   #      ##- modifier added

   #      my $firstEntry = [];
   #      my $lastEntry = $firstEntry;

   #      foreach $key (@$keys)
   #      {
   #         push @$lastEntry, $_ = [$key]; ##- $key is already an array, [keyword, modifier]. putting it inside an array makes it an <entry>
   #         $lastEntry = $_;
   #      }
   #      
   #      push @$lastEntry, @$content;
   #      return @firstEntry;
   #   }
   #}


   sub rec_entries {
      $rec_blocksEntered = 0;
      $rec_reachedEnd = 0;
      my @data = ();
      {
         @_ = rec_singleentry();
         last unless @_;
         push @data, @_;
         redo if ($line =~ /\G(\s+|(?<=}))/gc);
      }
      return () if !@data; #> if data is not empty
      return @data;
   } 

   ## returns the keyword and the modifier of the keyword in an array [keyword, modifier]
   ## if there's no modifier, it returns [keyword]
   ## also handles class in <> brackets
   sub rec_key {
      #> both modifier and class are here, but they'll never occur together
      #if ($line =~ /\G(?<key>[A-Za-z_.]++) (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+/xgc)
      if ($line =~ /\G([A-Za-z_.]++) (?:\s* (?:\[([^\]]++)\] | <([^>]++)> ))?/xgc) ## note: no space in between the key and the modifier/class
      {
         return [$1, $2]              if $2;
         return [$1, "Class=\"$3\""]  if $3;
         return [$1];
      }
      return ();
   }

   #> returns the list of keys present in the sequence of key/key/key/key...
   #> Returns: a list of keys (<key>, ... )
   sub rec_keynesting {
      #> do the keynesting, then do <data> because it's only used for this
      my @keylist = ();
      {
         $_ = rec_key(); ## rec_key() returns an array
         last if (!defined $_ or !@$_);
         push @keylist, $_;
         redo if $line =~ m{\G/}gc;
      }
      return () if !@keylist;
      #print "keylist: ".Dumper(@keylist);
      return @keylist;
   }

   ## <data>   -->  : <space> <stringwithnospaces> <space>? <lineend> ## very simple, only matches if theres a string, and the end of the line comes right after it
   ##            |  : <space> <stringwithnospaces> <space>? (?=})
   ##            |  : <space> <singleentry>
   ##            |  <space>? = <space>? <string with spaces> <space>? <lineend> // includes everything, even }. done this way because it's simple
   ##            |  <space>? { <space>? <entries> <space>? }
   ## move to bottom
   # ## returns an array of the data, and the position in the string where the beginning of this match was
   # ## returns ([array,array,...], $position)
   ##- returns a list of entries, or a string in a list
   sub rec_data {
      my $pos = pos($line);

      {
         if ($line =~ /\G:\s+/gc)
         {
            #my $pos1 = pos($line);

            ##- match <stringwithnospaces>
            ## this should actually try to match everything that's a valid label, sort of
            #print $line;
            #if ($line =~ /\G([^\s:]+) \s* $/xgc) {
            if (($line =~ /\G([0-9A-Za-z_.]++(?:\s+[A-Za-z_.]++)*) \s* $/xgc) or
               ($line =~ /\G([^\s}][^\s:]*+) \s*+ ( (?![{:\w]) | $ )/xgc)) {
               $rec_reachedEnd = 1 if $2; ##- true if the end is reached
               return ($1);
               #if ($line =~ /\G(?: (\s*)$ | } )/g) {
               #   ## if nothing comes after this, then it has to be a string
               #   $rec_reachedEnd = 1 if $1; ## true if the end is reached
               #   return ($_);
               #}
               #pos($line) = $pos1;
            } 
            ##- match a <singleentry>

            return @_ if @_ = rec_singleentry();
         }
         elsif ($line =~ /\G\s*=\s*(.*\S)/gc) ##- include everything except whitespace at the end
         {
            ##- a string with spaces
            ##return ([$1], $pos);
            return ($1);
         }
         elsif ($line =~ /\G\s*{\s*/gc)
         {
            next if ($line =~ /\G\s*$/gc);
            my $tmp = $rec_blocksEntered++;
            @_ = rec_entries();
            $rec_blocksEntered = $tmp;
            return @_ if ($line =~ /\G\s*}/gc);
         }

      }
      pos($line) = $pos; ##- reset the position if there was an error

      return ();
   }

   # ## returns undef if there's an error, otherwise a string;
   # sub string_with_spaces {
   #    ## should match if I can't match a <singleentry>, but that was tried before this, so I can go ahead with this
   #    if ($rec_blocksEntered == 0) {
   #       $line =~ /\G([^}]*)/gc;
   #    }
   #    else { $line =~ /\G(.*)/gc; }
   #    $_ = $1;
   #    s/\s*$//;
   #    return undef if $_ == "";
   #    return $_;
   # }
##
##################
##
##
   # ## Returns: (<entries>)
   # sub get_inline_syntax {
   #    my $line = shift; ## a copy of $line used in syntax_base
   #    my $rec_dataArr = shift;
   #    my $rec_blocksEntered = 0;
   #    ## returns null if there's an error, otherwise a string;
   #    $line =~ /^\s*/gc; ## EAT SPACES 
   #    return inline_syntax();
   # }
##
##################

## to fix the problem where text and comments appear nested in the wrong thing
my @space_stuff = ();
sub add_space_stuff {
   push @space_stuff, shift;
}

sub syntax_base {{
   $line = getline();
   add_space_stuff('') and next  if !defined $line;
   add_space_stuff('') and next  if $line =~ /^\s*$/;

   $line =~ /^(\s*)/gc; ## EAT SPACES 
   my $indent_level = length($1)/$indent_size;

   ## brackets are ignored
   next if $line =~ /\G[{}]\s*$/gc;
   add_space_stuff("<!-- $1 -->") and next if $line =~ /\G\/\/\s*+(.*)(?<=\S)/gc;
   add_space_stuff("$1") and next  if $line =~ m/^#(.*)(?<=\S)/gc;

   die "[indentaion error on line $linenumber of input file]" unless $indent_level =~ /^\d+\z/;
 
 
   ## check indentation
   ## exit environments
   #my $indent = getindent($line);
   # print "$indent $line";
   process_indent($indent_level); 

   push @$ref, @space_stuff; ## add xml comments and stuff
   @space_stuff = ();

   #if (try_get_inline_syntax( $line, \{my @inline_data} ))
   #{
   #   push @$ref, @inline_data;
   #   next;
   #}

   #print "got here1\n";
   if (@_ = inline_syntax())
   {
      #print "inline_syntax size:".scalar(@_)." ".Dumper(@_)."\n";
      push @$ref, @_;
      next;
   }

   #print "got past inline entries\n";
   if (@_ = rec_keynesting())
   {
      #print "got into block stuff\n";
      ## check if this is the beginning of a new nesting level
      moveup_nested2(\@_) and next  if ($line =~ /\G:\s*+$/gc);
      moveup_nested2(\@_) and next  if ($line =~ /\G\s*+{?\s*+$/gc);
      #print "couldn't move up\n";
   }



 
   # # if ($line =~ /\G(?<key>[A-Za-z_.]++) (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ :\s*+$/xgc) {
   # #    my $temp = $+{key};
   # #    if ($+{modifier}) { $temp = [$+{key}, $+{modifier}] }
   # #    if ($+{class}) { $temp = [$+{key}, 'Class="'.$+{class}.'"'] } 
   # #    my @nest = ();
   # #    @nest = ($+{nesting} =~ /\s*+\/(\w++)/g) if $+{nesting};
   # #    moveup_nested( $temp, @nest ) and next; 
   # # } 
   # ## brackets are ignored
   # #if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ \s*+ \{?\s* $/xgc) {
   # ## remove later
   # if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ (?: :\s*+$ | \s*+\{?\s*+$ )/xgc) {
   #    my $temp = $+{key};
   #    my @nest = ();
   #    $temp = [$+{key}, $+{modifier}]             if $+{modifier}; 
   #    $temp = [$+{key}, 'Class="'.$+{class}.'"']  if $+{class}; 
   #    @nest = ($+{nesting} =~ /\s*+\/(\w++)/g)    if $+{nesting};
   #    moveup_nested( $temp, @nest ) and next; 
   # } 

   # # if ($line =~ /\G(?<key>[A-Za-z_.]++) \s*+ (?:\[(?<modifier>[^\]]++)\])?+ (?:\<(?<class>[^\>]++)\>)?+ (?<nesting> (\/[^\/:{]+)++ )?+ /xgc) {
   # #    my $hasModifier = defined $+{modifier};
   # #    my $hasClass = defined $+{class};
   # #    my $temp = $+{key};
   # #    my @nest = ();
   # #    $temp = [$+{key}, $+{modifier}]             if $hasModifier;
   # #    $temp = [$+{key}, 'Class="'.$+{class}.'"']  if $hasClass; 
   # #    @nest = ($+{nesting} =~ /\s*+\/(\w++)/g)    if $+{nesting};
   # #    my $nested = $#nest != 0;
   # #    if ($line =~ /\G(?: :\s*+$ | \s*+\{?\s*+$ )/xgc)
   # #    {
   # #       moveup_nested( $temp, @nest ) and next;
   # #    }
   # #    if ( !$nested and !$hasModifier and !$hasClass)
   # #    {
   # #       add_text( "<$temp $2>$1</$temp>" ) and next if $line =~ /\G : \s++ ([^{}\->]++)\s*+\[([^\]]++)\] \s*+$/xgc
   # #    }
   # #    ## only supports { for inline stuff inside it
   # #    if ($line =~ /\G \s*+ {(.*)}\s*$/xgc)
   # #    {
   # #       # my @entries = ();
   # #       my $entry = undef;
   # #       #push(@entries, $entry) while (defined ($entry = new_inline_stuff()));
   # #       #moveup_nested( $temp, @nest );
   # #       moveup_nested( $temp, @nest );
   # #       add_data($entry) while (defined ($entry = new_inline_stuff()));
   # #       next;
   # #    }
   # #    ## reset the position of the line
   # #    $line = getline();
   # #    $line =~ /^\s*/gc; ## EAT SPACES 
   # # } 

   # ## for things like "<.../>"
   # if ($line =~ /\G<\s*+(\w++)\s++([^>]++)>/xgc) {
   #    add_text("<$1 Class=\"$2\"/>") and next;
   # }

   # add_text( "<$1 $3>$2</$1>" ) and next  if $line =~ /\G (\w++): \s++ ([^\->]++)\s*+\[([^\]]++)\] \s*+$/xgc;
   # add_text("<$1/>") and next  if ($line =~ /\G\[([^\]]++)\]\s*$/xgc);



   # ## for entries with text
   # # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (?> ([^{}:[\]]+) (?<=\S) ) \s*+$/xgc;
   # # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (?> ([^{}:]+) (?<=\S) )(?<!\]) \s*+$/xgc;
   # ## if at any point " [...] something here" it's plain text
   # # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?>[^}\]:]+(?<=\S)) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?>[^}\]:]+(?<=\S)) (?:\s*+\S.*(?<=\S))?+  ) (?<!\]) \s*+$/xgc;
   # 
   # ## for rules
   # # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?> [\s0-9A-Za-z_+\-=<>.,()[\]{}]*? -> ) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;
   # add_data( [$1,$2] ) and next  if $line =~ /\G (\w++): \s++ (  (?> .*? -> ) (?:\s*+\S.*(?<=\S))?+  ) \s*+$/xgc;
   # 
   # 
   # ## todo: get blocks working. the {} don't actually do anything
   # 
   # ## inline stuff:
   # ## get the data and format it
   # ## send to recursive funcion 
   # ## my current position is already saved by \G 
   # ## I should've covered all the syntax possibilities by now. if it doesn't make it to the end, that's an error.
   # while () {
   #    my $entry = new_inline_stuff();
   #    last if !defined $entry;
   #    add_data($entry);
   # } 

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

# print Dumper(@$ref);

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

my $indent = "";
my $indent_count = 0;
my $indent_text = '  ';
sub indent { $indent_text x $indent_count }
sub process_data {

   sub add_line {
      $_ = shift;
      $output .= "$indent$_\n"
   }
   sub set_indent {
      $indent_count = shift;
      $indent = $indent_text x $indent_count;
   }

   ## s means scalar
   ## a means array
   ## these are the lines of xml that are outputted
   ## (scalar)                      => scalar
   ## ([keyname])                   => <keyname/>
   ## ([keyname, modifier])         => <keyname modifier/>
   ## ([keyname], scalar)           => <keyname>scalar</keyname>
   ## ([keyname, modifier], scalar) => <keyname modifier>scalar</keyname>

   ## +-------------------------+
   ## |    The Datastructure    |
   ## +-------------------------+
   ##
   ## <arguments> --> (<entry>)
   ##
   ## <entry> --> (<scalar>)
   ##           | (<key>)
   ##           | (<key>, <scalar>)
   ##           | (<key>, <contents>)
   ##
   ## <key> --> [<name>]
   ##         | [<name>, <modifier>]
   ##
   ## <contents> --> (<entry>, <contents>)
   ##              | (<entry>)

   my $param1 = shift;

   my ($key, $mod);
   ($key, $mod) = @$param1 if (ref($param1) eq "ARRAY");

   ## if there was only one argument
   if (!@_) {
      add_line($mod ? "<$key $mod/>" : "<$key/>") and return  if ($key); ## <entry> --> (<key>)
      add_line("$param1") and return; ## <entry> --> (<scalar>)
      #return;
      #if ($key) {
      #   ## $output .= &indent.($mod ? "<$key $mod/>\n" : "<$key/>\n"); ## <entry> --> (<key>)
      #   add_line($mod ? "<$key $mod/>" : "<$key/>"); ## <entry> --> (<key>)
      #} else {
      #   ## $output .= &indent."$param1\n"; ## <entry> --> (<scalar>)
      #   add_line("$param1"); ## <entry> --> (<scalar>)
      #}
      #return;
   }

   my $b0 = $mod ? "<$key $mod>" : "<$key>";
   my $b1 = "</$key>";

   ## <entry> --> (<key>, <scalar>)
   if ( @_ == 1 and !ref($_[0]) ) 
   {
      add_line("$b0$_[0]$b1");
      return;
   }

   ## <contents>
   add_line($b0);
   my $tmpindent = $indent_count;
   set_indent($indent_count+1);
   foreach my $var (@_)
   {
      process_data( ref($var)? @$var : $var );
   }
   set_indent($tmpindent);
   add_line($b1);
}
#sub process_data {
#   if (0+@_ == 1) {
#      $output .= &indent."$_[0]\n";
#      return;
#   }
#
#   ## todo: simplify this part later
#   ## this does something I don't know how to explain in words
#   ## also it shifts one entry off @_
#   my $param1 = shift;
#   my ($key,$modifier) = (undef,undef);
#   if ("ARRAY" eq ref($param1)) {
#      ($key,$modifier) = @$param1;
#   } else {
#      $key = $param1;
#   }
#
#   my @brackets = ($key,$key);
#   if (ref($param1) eq "ARRAY") {
#      $brackets[0] = "$key $modifier";
#   } 
#   
#   ## thing containing text
#   if (0+@_ == 1 and !ref($_[0])) {
#      $output .= &indent."<$brackets[0]>$_[0]</$brackets[1]>\n";
#      return;
#   }
#
#   ## thing containing other things
#   $output .= &indent."<$brackets[0]>\n";
#   my $tempindent = $indent++;
#   foreach $ref (@_)
#   {
#      if (!ref($ref)) {
#         ## a scalar
#         $output .= &indent."$ref\n"; 
#      } else {
#         __SUB__->(@$ref);
#      } 
#   }
#   $indent = $tempindent;
#   $output .= &indent."</$brackets[1]>\n"; 
#}

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

$output = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
build_file(@data);
#$output =~ s/\r/\x0A\x0D/g; # CRLF

print "$output";
# print $output;
  
# print "===============\r";
# print XML::Tidy->new('xml' => $output)->tidy()->toString();

# print STDOUT $output;

