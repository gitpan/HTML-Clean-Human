package HTML::Clean::Human;
use strict;
use LEOCHARRE::Class2;
__PACKAGE__->make_accessor_setget_ondisk_file('abs_path');
#__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget('errstr','html_original','html_cleaned');

use Exporter;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION @ISA);
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(
fix_whitespace
rip_tag 
rip_tables
rip_lists
rip_fonts
rip_formatting
rip_headers
rip_comments
rip_forms
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );



sub _read {
   my $self = shift;
   my $abs_path = $self->abs_path 
      or $self->errstr("no abs_path set") and return;
   
   local $/;
   open(FILE,'<',$abs_path) 
      or $self->errstr("Cant open $abs_path for reading, $!") and return;
   my $text = <FILE>;
   close FILE;
   
   $self->html_original($text);
   $self->html_cleaned($text);

   return $text;
}

sub new {
   my $class = shift;
   my $self = {};
   bless $self, $class;

   while ( my $arg = shift @_ ){
      defined $arg or next;
      if( ref $arg eq 'HASH'){ 
         $self = $arg;
      }
      else {
         $self->{abs_path} = $arg;
      }
   }
   
   $self->_read;
   return $self;   
}

sub clean {
   my $self = shift;

   #all
   
   my $html = $self->html_cleaned;
   
   no strict 'refs';
   for my $sub ( qw(rip_headers rip_tables rip_lists rip_fonts rip_formatting fix_whitespace) ){
      $html = &$sub($html);
   }

   return $self->html_cleaned($html);
}

=pod
for my $methname( qw() ){

   my $subname = __PACKAGE__."::$methname";
   
   *{__PACKAGE__."\::$methname
   sub {
      my $self = shift;
      return $self->html_cleaned( $subname($self->html_cleaned) );
   }


}
=cut





# NON OO



# takes a tag and rips all out, including with atts
sub rip_tag {
   my $html = shift;
   
   for my $tag ( @_ ){
      defined $tag or next;
      
      # no atts
      $html=~s/<$tag>|<\/$tag>/ /sig;

      # with atts
      $html=~s/<$tag [^<>]+>/ /sig;

      # without endtag
      $html=~s/<$tag +\/>/ /sig;
   }

   return $html;
}

sub _rip_chunk { # needs to be refined, careful using this
   my $html = shift;

   for my $tag ( @_ ){
      defined $tag or next;
        

      # no atts
      $html=~s/<$tag><\/$tag>/ /sig;

      # with atts
      $html=~s/<$tag [^<>]+>/ /sig;

      # without endtag
      $html=~s/<$tag +\/>/ /sig;
   }

   return $html;


   
}

sub rip_forms {
   my $html = shift;

   $html = rip_tag($html,qw(input option form textarea checkbox));
   return $html;
}

sub fix_whitespace { # in question
   my $html = shift;
      
   $html=~s/\t|&nbsp;/ /sig;   
   
   $html=~s/([\w\,])\s+([a-z])/$1 $2/sg; # no linebreaks between words

   $html=~s/([,])\s+([a-z])/$1 $2/sig; # no linebreaks between word chars

   
   #$html=~s/(\w)\s{2,}(\w)/$1 $2/sig; # no more then x whitespace between word chars

   $html=~s/(\S) {2,}/$1 /sig;

   $html=~s/\n[ \t]+/\n/g;

   $html=~s/\n\s+\n\s*/\n\n/g;      

   return $html;
}


sub rip_tables {
   return rip_tag(+shift, qw(table tr td tbody));
}

sub rip_fonts {
   return rip_tag(+shift, qw(font i b ul strike em strong cite u));
}

sub rip_lists {
   return rip_tag(+shift, qw(ul ol li));
}

sub rip_formatting {
   return rip_tag(+shift, qw(div br hr p span blockquote center));   
}


sub rip_headers { #tags
   my $html = shift;
   $html = rip_tag($html,qw(html));

   $html=~s/.+<body[^<>]*>//is;
   $html=~s/<\/body>//i;

   return $html;
   
}

sub rip_comments {
   my $html = shift;
   $html=~s/\<\!\-\-[^<>]+\-\-\>//sg;
   return $html;
}

sub rip_javascript {}
sub rip_styles {}









1;



sub headings2text {
   my $html = shift;
   my $change = $html;

   HEADING: while( $html=~/<h(\d)[^<>]*>([^<>]+)<\/h\1>/i ){
      my($h,$text) = ($1,$2);
      
      my $text_altered;
      if($h == 1 ){
         $text_altered = uc($text);
         $change=~s/<h$h[^<>]*>$text<\/h$h>/\n$text_altered\n/sig;
         next HEADING;
      }
      
      else {
         $text_altered = lc($text);
         $text_altered=~tr/\b[a-z]/[A-Z]/;
         
         $change=~s/<h$h[^<>]*>$text<\/h$h>/\n$text_altered\n/sig;
         next HEADING;

      }
      
      
      
   }

   # turn <h1> to CAPITALIZED and turn <h2> To Cap First Letter
   return $change;
   
}
# inverse..
#sub text2headings {}





__END__

=pod

=head1 NAME

HTML::Clean::Human - html syntax cleaner and reformatter   

=head1 DESCRIPTION

This takes html like code and takes out the 'non important' stuff.
This is NOT an HTML 2 TXT converter. This is is an html syntax filter/reformatter.

My initial temptation was to simply seek a solution such as html to text. 
But then I realized html code may have links and other ephemera that would be desireable to keep.

What I want it to get rid of; all the stupid html things such as inline font declarations etc.

This code is useful if you edit html, but you have to do it maybe from already existing html
that some whacko wysiwyg junk spat out.
Run it through this and voila.

So, if you have to 'remake' a stupid website somebody else made.. this is useful.
You can just point it to the url and get the code down.

=head1 SYNOPSIS

   use HTML::Clean::Human;

   my $c = HTML::Clean::Human->new('http://leocharre.com'); # directly from the web!
   
   my $cleaned = $c->clean;
   
   my $original = $c->html_original;

Or use the provided script htmlclean

   htmlclean http://leocharre.com > cleaned.html


=head1 PROCEDURAL SUBS

Not exported by default.

All of these take html string as argument and return filtered.

=head2 fix_whitespace()

=head2 headings2text()

=head2 rip_comments()

=head2 rip_fonts()

=head2 rip_formatting()

=head2 rip_forms()

=head2 rip_headers()

=head2 rip_javascript()

=head2 rip_lists()

=head2 rip_styles()

=head2 rip_tables()

=head2 rip_tag()


=head1 BUGS

No doubt, please contact the L<AUTHOR>.


=head1 AUTHOR
 
Leo Charre leocharre at cpan dot org
 
=head1 COPYRIGHT
 
Copyright (c) 2008 Leo Charre. All rights reserved.
 
=head1 LICENSE
 
This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".
 
=head1 DISCLAIMER
 
This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 
See the "GNU General Public License" for more details.

=cut
