package Elasticsearch::Scroll;

use Moo;
use Elasticsearch::Util qw(parse_params);
use namespace::clean;

has 'es' => ( is => 'ro', required => 1 );
has 'scroll'     => ( is => 'ro' );
has 'total'      => ( is => 'ro' );
has 'max_score'  => ( is => 'ro' );
has 'facets'     => ( is => 'ro' );
has 'suggest'    => ( is => 'ro' );
has 'took'       => ( is => 'ro' );
has 'total_took' => ( is => 'rwp' );
has '_scroll_id' => ( is => 'rw' );
has '_buffer'    => ( is => 'ro' );
has 'eof'        => ( is => 'rw' );

#===================================
sub BUILDARGS {
#===================================
    my ( $class, $params ) = parse_params(@_);
    my $es      = delete $params->{es};
    my $scroll  = $params->{scroll} ||= '1m';
    my $results = $es->search($params);

    return {
        es         => $es,
        scroll     => $scroll,
        facets     => $results->{facets},
        suggest    => $results->{suggest},
        took       => $results->{took},
        total_took => $results->{took},
        total      => $results->{hits}{total},
        max_score  => $results->{hits}{max_score},
        _buffer    => $results->{hits}{hits},
        _scroll_id => $results->{_scroll_id},
        eof        => !$results->{_scroll_id},
    };
}

#===================================
sub next {
#===================================
    my ( $self, $n ) = @_;
    $n ||= 1;
    while ( !$self->eof and $self->buffer_size < $n ) {
        $self->refill_buffer;
    }
    return splice( @{ $self->_buffer }, 0, $n );
}

#===================================
sub drain_buffer {
#===================================
    my $self = shift;
    return splice( @{ $self->_buffer } );
}

#===================================
sub buffer_size { 0 + @{ shift->_buffer } }
#===================================

#===================================
sub refill_buffer {
#===================================
    my $self   = shift;
    my $buffer = $self->_buffer;

    return 0 + @$buffer if $self->eof;

    my $results = $self->es->scroll(
        scroll => $self->scroll,
        body   => $self->_scroll_id
    );

    $self->_scroll_id( $results->{_scroll_id} );
    my $hits = $results->{hits}{hits};
    $self->_set_total_took( $self->total_took + $results->{took} );

    if ( @$hits == 0 ) {
        $self->eof(1);
    }
    else {
        push @$buffer, @$hits;
    }
    return 0 + @$buffer;
}

#===================================
sub finish {
#===================================
    my $self = shift;
    return if $self->eof;

    @{ $self->_buffer } = ();
    $self->eof(1);
    eval { $self->es->clear_scroll( scroll_id => $self->_scroll_id ) };
    return 1;
}

#===================================
sub DESTROY {
#===================================
    my $self = shift;
    eval { $self->finish };
}

1;

__END__

# ABSTRACT: A helper module for scrolled searches

=head1 SYNOPSIS

    use Elasticsearch;
    use Elasticearch::Scroll;

    my $es     = Elasticsearch->new;

    my $scroll = ElasticSearch::Scroll->new(
        es          => $es,
        index       => 'my_index',
        search_type => 'scan',
        size        => 500
    );

    say "Total hits: ". $scroll->total;

    while (my $doc = $scroll->next) {
        # do something
    }

=head1 DESCRIPTION

A I<scrolled search> is a search that allows you to keep pulling results
until there are no more matching results, much like a cursor in an SQL
database.

Unlike paginating through results (with the C<from> parameter in
L<search()|Elasticsearch::Client::Direct/search()>),
scrolled searches take a snapshot of the current state of the index. Even
if you keep adding new documents to the index or updating existing documents,
a scrolled search will only see the index as it was when the search began.

This module is a helper utility that wraps the functionality of the
L<search()|Elasticsearch::Client::Direct/search()> and
L<scroll()|Elasticsearch::Client::Direct/scroll()> methods to make
them easier to use.

B<IMPORTANT>: Deep scrolling can be expensive.  See L</DEEP SCROLLING>
for more.

=head1 USE CASES

There are two primary use cases:

=head2 Pulling enough results

Perhaps you want to group your results by some field, and you don't know
exactly how many results you will need in order to return 10 grouped
results.  With a scrolled search you can keep pulling more results
until you have enough.  For instance, you can search emails in a mailing
list, and return results grouped by C<thread_id>:

    my (%groups,@results);

    my $scroll = Elasticsearch::Scroll->new(
        es    => $es,
        index => 'my_emails',
        type  => 'email',
        body  => { query => {... some query ... }}
    );

    my $doc;
    while (@results < 10 and $doc = $scroll->next) {

        my $thread = $doc->{_source}{thread_id};

        unless ($groups{$thread}) {
            $groups{$thread} = [];
            push @results, $groups{$thread};
        }
        push @{$groups{$thread}},$doc;

    }


=head2 Extracting all documents

Often you will want to extract all (or a subset of) documents in an index.
If you want to change your type mappings, you will need to reindex all of your
data. Or perhaps you want to move a subset of the data in one index into
a new dedicated index. In these cases, you don't care about sort
order, you just want to retrieve all documents which match a query, and do
something with them. For instance, to retrieve all the docs for a particular
C<client_id>:

    my $scroll = Elasticsearch::Scroll->new(
        es          => $es,
        index       => 'my_index',
        search_type => 'scan',          # important!
        size        => 500,
        body        => {
            query => {
                match => {
                    client_id => 123
                }
            }
        }
    );

    while my ( $doc = $scroll->next ) {
        # do something
    }

Very often the I<something> that you will want to do with these results
involves bulk-indexing them into a new index. The easiest way to
marry a scrolled search with bulk indexing is to use the
L<Elasticsearch::Bulk/reindex()> method.

=head1 DEEP SCROLLING

Deep scrolling (and deep pagination) are very expensive in a distributed
environment, and the reason they are expensive is that results need to
be sorted in a global order.

For example, if we have an index with 5 shards, and we request the first
10 results, each shard has to return its top 10, and then the I<requesting
node> (the node that is handling the search request) has to resort these
50 results to return a global top 10. Now, if we request page 1,000
(ie results 10,001 .. 10,010), then each shard has to return 10,010 results,
and the requesting node has to sort through 50,050 results just to return
10 of them!

You can see how this can get very heavy very quickly. This is the reason that
web search engines never return more than 1,000 results.

=head2 Disable sorting for efficient scrolling

The problem with deep scrolling is the sorting phase.  If we disable sorting,
then we can happily scroll through millions of documents efficiently.  The
way to do this is to set C<search_type> to C<scan>:

    $scroll = Elasticsearch::Scroll->new(
        es          => $es,
        search_type => 'scan',
        size        => 500,
    );

Scanning disables sorting and will just return C<size> results from each
shard until there are no more results to return. B<Note>: this means
that, when querying an index with 5 shards, the scrolled search
will pull C<size * 5> results at a time. If you have large documents or
are memory constrained, you will need to take this into account.

=head1 METHODS

=head2 C<new()>

    use Elasticsearch;
    use Elasticsearch::Scroll;

    my $es = Elasticsearch->new(...);
    my $scroll = Elasticsearch::Scroll->new(
        es      => $es,                         # required
        scroll  => '1m',                        # optional
        %search_params
    );

The C<new()> method returns a new C<$scroll> object.  You must pass your
Elasticsearch client as the C<es> argument, and you can specify
a C<scroll> duration (which defaults to C<"1m">).  Any other parameters
are passed directly to L<Elasticsearch::Client::Direct/search()>.

The C<scroll> duration tells Elasticearch how long it should keep the scroll
alive.  B<Note>: this duration doesn't need to be long enough to process
all results, just long enough to process a single B<batch> of results.
The expiry gets renewed for another C<scroll> period every time new
a new batch of results is retrieved from the cluster.

=head2 C<next()>

    $doc  = $scroll->next;
    @docs = $scroll->next($num);

The C<next()> method returns the next result, or the next C<$num> results
(pulling more results if required).  If all results have been exhausted,
it returns an empty list.

=head2 C<drain_buffer()>

    @docs = $scroll->drain_buffer;

The C<drain_buffer()> method returns all of the documents currently in the
buffer, without fetching any more from the cluster.

=head2 C<refill_buffer()>

    $total = $scroll->refill_buffer;

The C<refill_buffer()> method fetches the next batch of results from the
cluster, stores them in the buffer, and returns the total number of docs
currently in the buffer.

=head2 C<buffer_size()>

    $total = $scroll->buffer_size;

The C<buffer_size()> method returns the total number of docs currently in
the buffer.

=head2 C<eof()>

    $bool = $scroll->eof;

The C<eof()> method reports whether there may be more results to pull from the
cluster or not.  If it returns C<false> it doesn't mean that there are
definitely more results, just that we don't yet know.  If it returns
C<true> then there are definitely no more results to be retrieved from
the cluster, but there may still be results in local buffer.

=head2 C<finish()>

    $scroll->finish;

The C<finish()> method clears out the buffer, sets L</eof()> to C<true>
and tries to clear the C<scroll_id> on Elasticsearch.  This API is only
supported since v0.90.5, but the call to C<clear_scroll> is wrapped in an
C<eval> so the C<finish()> method can be safely called with any version
of Elasticsearch.

When the C<$scroll> instance goes out of scope, L</finish()> is called
automatically unless L</eof()> returns C<true>.

=head1 INFO ACCESSORS

The information from the original search is returned via the following
accessors:

=head2 C<total>

The total number of documents that matched your query.

=head2 C<max_score>

The maximum score of any documents in your query.

=head2 C<facets>

Any facets that were specified, or C<undef>

=head2 C<suggest>

Any suggestions that were specified, or C<undef>

=head2 C<took>

How long the original search took, in milliseconds

=head2 C<took_total>

How long the original search plus all subsequent batches took, in milliseconds.

=head1 SEE ALSO

=over

=item * L<Elasticsearch::Bulk/reindex()>

=item * L<Elasticsearch::Client::Direct/search()>

=item * L<Elasticsearch::Client::Direct/scroll()>

=back
