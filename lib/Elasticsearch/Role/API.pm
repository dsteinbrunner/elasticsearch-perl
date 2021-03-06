package Elasticsearch::Role::API;

use Moo::Role;

use Elasticsearch::Util qw(throw);
use Elasticsearch::Util::API::QS qw(qs_init);
use Elasticsearch::Util::API::Path qw(path_init);
use namespace::clean;

our %API;

#===================================
sub api {
#===================================
    my $name = $_[1] || return \%API;
    return $API{$name}
        || throw( 'Internal', "Unknown api name ($name)" );
}

#===================================
%API = (
#===================================
    'bulk' => {
        body => {
            desc => 'The operation definition and data (action-data pairs), '
                . 'separated by newlines'
        },
        doc       => 'docs-bulk',
        method    => 'POST',
        path      => '{index-when-type}/{type|blank}/_bulk',
        serialize => 'bulk',
        qs        => [ 'consistency', 'refresh', 'replication', 'type' ],
    },

    'clear_scroll' => {
        method => 'DELETE',
        doc    => 'search-request-search-type',
        path   => '_search/scroll/{scroll_ids}'
    },

    'count' => {
        body => { desc => 'A query to restrict the results (optional)' },
        doc  => 'search-count',
        path => '{indices|all-type}/{types}/_count',
        qs   => [
            'ignore_indices', 'min_score', 'preference', 'routing',
            'source'
        ],
    },

    'delete' => {
        doc    => 'docs-delete',
        method => 'DELETE',
        path   => '{index}/{type}/{id}',
        qs     => [
            'consistency', 'parent',  'replication', 'refresh',
            'routing',     'timeout', 'version',     'version_type'
        ],
    },

    'delete_by_query' => {
        body =>
            { desc => 'A query to restrict the operation', required => 1 },
        doc    => 'docs-delete-by-query',
        method => 'DELETE',
        path   => '{indices|all-type}/{types}/_query',
        qs     => [
            'analyzer',         'consistency',
            'default_operator', 'df',
            'ignore_indices',   'q',
            'replication',      'routing',
            'source',           'timeout'
        ],
    },

    'exists' => {
        doc    => 'docs-get',
        method => 'HEAD',
        path   => '{index}/{type|all}/{id}',
        qs => [ 'parent', 'preference', 'realtime', 'refresh', 'routing' ],
    },

    'explain' => {
        body => {
            desc     => 'The query definition using the Query DSL',
            required => 1
        },
        doc  => 'search-explain',
        path => '{index}/{type}/{id}/_explain',
        qs   => [
            'analyze_wildcard',         'analyzer',
            'default_operator',         'df',
            'fields',                   'lenient',
            'lowercase_expanded_terms', 'parent',
            'preference',               'q',
            'routing',                  'source',
            '_source',                  '_source_include',
            '_source_exclude'
        ],
    },

    'get' => {
        doc  => 'docs-get',
        path => '{index}/{type|all}/{id}',
        qs   => [
            'fields',     'parent',
            'preference', 'realtime',
            'refresh',    'routing',
            '_source',    '_source_include',
            '_source_exclude'
        ],
    },

    'get_source' => {
        doc  => 'docs-get',
        path => '{index}/{type|all}/{id}/_source',
        qs   => [
            'parent',   'preference',
            'realtime', 'refresh',
            'routing',  '_source_include',
            '_source_exclude'
        ],
    },

    'index' => {
        body => {
            desc     => 'The document',
            required => 1
        },
        doc    => 'docs-index_',
        method => 'PUT',
        path   => '{index}/{type}/{id|blank}',
        qs     => [
            'consistency', 'op_type',     'parent',  'percolate',
            'refresh',     'replication', 'routing', 'timeout',
            'timestamp',   'ttl',         'version', 'version_type'
        ],
    },

    'info' => {
        doc  => 'index',
        path => '',
    },

    'mget' => {
        body => {
            required => 1,
            desc     => 'Document identifiers; can be either'
                . ' `docs` (containing full document information) or '
                . '`ids` (when index and type is provided in the URL.'
        },
        doc  => 'docs-multi-get',
        path => '{index-when-type}/{type|blank}/_mget',
        qs   => [
            'fields',   'preference',
            'realtime', 'refresh',
            '_source',  '_source_include',
            '_source_exclude'
        ],
    },

    'mlt' => {
        body => { desc => 'A specific search request definition' },
        doc  => 'search-more-like-this',
        path => '{index}/{type|all}/{id}/_mlt',
        qs   => [
            'boost_terms',            'max_doc_freq',
            'max_query_terms',        'max_word_len',
            'min_doc_freq',           'min_term_freq',
            'min_word_len',           'mlt_fields',
            'percent_terms_to_match', 'routing',
            'search_from',            'search_indices',
            'search_query_hint',      'search_scroll',
            'search_size',            'search_source',
            'search_type',            'search_types',
            'stop_words'
        ],
    },

    'msearch' => {
        body => {
            required => 1,
            desc     => 'The request definitions (metadata-search '
                . 'request definition pairs), separated by newlines'
        },
        doc       => 'search-multi-search',
        path      => '{indices|all-type}/{types}/_msearch',
        serialize => 'bulk',
        qs        => ['search_type'],
    },

    'percolate' => {
        body => {
            required => 1,
            desc     => 'The document (`doc`) to percolate against '
                . 'registered queries; optionally also a '
                . '`query` to limit the percolation to '
                . 'specific registered queries'
        },
        doc  => 'search-percolate',
        path => '{index}/{type}/_percolate',
        qs   => ['prefer_local'],
    },

    'ping' => {
        doc    => 'index',
        method => 'HEAD',
        path   => '',
    },

    'scroll' => {
        body => {
            desc => 'The scroll ID if not passed by URL or query parameter.'
        },
        doc  => 'search-request-scroll',
        path => '_search/scroll',
        qs   => [ 'scroll', 'scroll_id' ],
    },

    'search' => {
        body => { desc => 'The search definition using the Query DSL' },
        doc  => 'search-search',
        path => '{indices|all-type}/{types}/_search',
        qs   => [
            'analyze_wildcard', 'analyzer',
            'default_operator', 'df',
            'explain',          'fields',
            'from',             'ignore_indices',
            'lenient',          'lowercase_expanded_terms',
            'preference',       'q',
            'routing',          'scroll',
            'search_type',      'size',
            'sort',             'source',
            '_source',          '_source_include',
            '_source_exclude',  'stats',
            'suggest_field',    'suggest_mode',
            'suggest_size',     'suggest_text',
            'timeout',          'version'
        ],
    },

    'suggest' => {
        body => { desc => 'The request definition' },
        doc  => 'search-suggesters',
        path => '{indices|all-type}/{types}/_suggest',
        qs   => [ 'ignore_indices', 'preference', 'routing', 'source' ],
    },

    'update' => {
        body => {
            desc => 'The request definition using either '
                . '`script` or partial `doc`'
        },
        doc    => 'docs-update',
        method => 'POST',
        path   => '{index}/{type}/{id}/_update',
        qs     => [
            'consistency',       'fields',
            'lang',              'parent',
            'percolate',         'realtime',
            'refresh',           'replication',
            'retry_on_conflict', 'routing',
            'script',            'timeout',
            'timestamp',         'ttl',
            'version',           'version_type'
        ],
    },

    'cluster.get_settings' => {
        doc  => 'cluster-update-settings',
        path => '_cluster/settings',
    },

    'cluster.health' => {
        doc  => 'cluster-health',
        path => '_cluster/health',
        qs   => [
            'level',                      'local',
            'master_timeout',             'timeout',
            'wait_for_active_shards',     'wait_for_nodes',
            'wait_for_relocating_shards', 'wait_for_status'
        ],
    },

    'cluster.hot_threads' => {
        doc  => 'cluster-nodes-hot-threads',
        path => '_nodes/{nodes|blank}/hot_threads',
        qs   => [ 'interval', 'snapshots', 'threads', 'type' ],
    },

    'cluster.node_info' => {
        doc  => 'cluster-nodes-info',
        path => '_nodes/{nodes|blank}',
        qs   => [
            'all',      'clear',   'http',        'jvm',
            'network',  'os',      'plugin',      'process',
            'settings', 'timeout', 'thread_pool', 'transport'
        ],
    },

    'cluster.shutdown' => {
        doc    => 'cluster-nodes-shutdown',
        method => 'POST',
        path   => '_cluster/nodes/{nodes|blank}/_shutdown',
        qs     => [ 'delay', 'exit' ],
    },

    'cluster.node_stats' => {
        doc  => 'cluster-nodes-stats',
        path => '_nodes/{nodes|blank}/stats/{metric|blank}',
        qs   => [
            'all',  'clear',   'fields',      'fs',
            'http', 'indices', 'jvm',         'network',
            'os',   'process', 'thread_pool', 'transport'
        ],
    },

    'cluster.put_settings' => {
        body => {
            desc => 'The settings to be updated. Can be either '
                . '`transient` or `persistent`.'
        },
        doc    => 'cluster-update-settings',
        method => 'PUT',
        path   => '_cluster/settings',
    },

    'cluster.reroute' => {
        body => {
            desc => 'The definition of `commands` to perform '
                . '(`move`, `cancel`, `allocate`)'
        },
        doc    => 'cluster-reroute',
        method => 'POST',
        path   => '_cluster/reroute',
        qs     => [ 'dry_run', 'filter_metadata' ],
    },

    'cluster.state' => {
        doc  => 'cluster-state',
        path => '_cluster/state',
        qs   => [
            'filter_blocks',  'filter_index_templates',
            'filter_indices', 'filter_metadata',
            'filter_nodes',   'filter_routing_table',
            'local',          'master_timeout'
        ],
    },

    'indices.analyze' => {
        body =>
            { desc => 'The text on which the analysis should be performed' },
        doc    => 'indices-analyze',
        method => 'POST',
        path   => '{index|blank}/_analyze',
        qs     => [
            'analyzer', 'field',        'filters', 'format',
            'index',    'prefer_local', 'text',    'tokenizer'
        ],
    },

    'indices.clear_cache' => {
        doc    => 'indices-clearcache',
        method => 'POST',
        path   => '{indices}/_cache/clear',
        qs     => [
            'fielddata',      'fields',
            'filter',         'filter_cache',
            'filter_keys',    'id',
            'ignore_indices', 'index',
            'recycler'
        ],
    },

    'indices.close' => {
        doc    => 'indices-open-close',
        method => 'POST',
        path   => '{req_indices}/_close',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.create' => {
        body => {
            desc => 'The configuration for the index '
                . '(`settings` and `mappings`)'
        },
        doc    => 'indices-create-index',
        method => 'PUT',
        path   => '{index}',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.delete' => {
        doc    => 'indices-delete-index',
        method => 'DELETE',
        path   => '{req_indices}',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.delete_alias' => {
        doc    => 'indices-aliases',
        method => 'DELETE',
        path   => '{index}/_alias/{name}',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.delete_mapping' => {
        doc    => 'indices-delete-mapping',
        method => 'DELETE',
        path   => '{req_indices}/{type}',
        qs     => ['master_timeout'],
    },

    'indices.delete_template' => {
        doc    => 'indices-templates',
        method => 'DELETE',
        path   => '_template/{name}',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.delete_warmer' => {
        doc    => 'indices-warmers',
        method => 'DELETE',
        path   => '{req_indices}/_warmer/{names}',
        qs     => ['master_timeout'],
    },

    'indices.exists' => {
        doc    => 'indices-exists',
        method => 'HEAD',
        path   => '{req_indices}',
    },

    'indices.exists_alias' => {
        doc    => 'indices-aliases',
        method => 'HEAD',
        path   => '{indices}/_alias/{names}',
        qs     => ['ignore_indices'],
    },

    'indices.exists_type' => {
        doc    => 'indices-types-exists',
        method => 'HEAD',
        path   => '{indices|all}/{req_types}',
        qs     => ['ignore_indices'],
    },

    'indices.flush' => {
        doc    => 'indices-flush',
        method => 'POST',
        path   => '{indices}/_flush',
        qs     => [ 'force', 'full', 'ignore_indices', 'refresh' ],
    },

    'indices.get_alias' => {
        doc  => 'indices-aliases',
        path => '{indices}/_alias/{names}',
        qs   => ['ignore_indices'],
    },

    'indices.get_aliases' => {
        doc  => 'indices-aliases',
        path => '{indices}/_aliases',
        qs   => ['timeout'],
    },

    'indices.get_field_mapping' => {
        doc  => 'indices-get-field-mapping',
        path => '{indices|all-type}/{types}/_mapping/field/{field}',
        qs   => ['include_defaults'],
    },

    'indices.get_mapping' => {
        doc  => 'indices-get-mapping',
        path => '{indices|all-type}/{types}/_mapping',
    },

    'indices.get_settings' => {
        doc  => 'indices-get-settings',
        path => '{indices}/_settings',
    },

    'indices.get_template' => {
        doc  => 'indices-templates',
        path => '_template/{name|blank}',
    },

    'indices.get_warmer' => {
        doc  => 'indices-warmers',
        path => '{indices|all}/_warmer/{names}',
    },

    'indices.open' => {
        doc    => 'indices-open-close',
        method => 'POST',
        path   => '{indices|all}/_open',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.optimize' => {
        doc    => 'indices-optimize',
        method => 'POST',
        path   => '{indices}/_optimize',
        qs     => [
            'flush',            'ignore_indices',
            'max_num_segments', 'only_expunge_deletes',
            'refresh',          'wait_for_merge'
        ],
    },

    'indices.put_alias' => {
        body => {
            desc => 'The settings for the alias, '
                . 'such as `routing` or `filter`',
        },
        doc    => 'indices-aliases',
        method => 'PUT',
        path   => '{index}/_alias/{name}',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.put_mapping' => {
        body => {
            desc     => 'The mapping definition',
            required => 1
        },
        doc    => 'indices-put-mapping',
        method => 'PUT',
        path   => '{indices|all}/{type}/_mapping',
        qs     => [ 'ignore_conflicts', 'timeout', 'master_timeout' ],
    },

    'indices.put_settings' => {
        body => {
            desc     => 'The index settings to be updated',
            required => 1
        },
        doc    => 'indices-update-settings',
        method => 'PUT',
        path   => '{indices}/_settings',
        qs     => ['master_timeout'],
    },

    'indices.put_template' => {
        body => {
            desc     => 'The template definition',
            required => 1
        },
        doc    => 'indices-templates',
        method => 'PUT',
        path   => '_template/{name}',
        qs     => [ 'order', 'timeout', 'master_timeout' ],
    },

    'indices.put_warmer' => {
        body => {
            desc => 'The search request definition for'
                . ' the warmer (query, filters, facets, sorting, etc)',
            required => 1
        },
        doc    => 'indices-warmers',
        method => 'PUT',
        path   => '{indices|all}/_warmer/{name}',
        qs     => ['master_timeout'],
    },

    'indices.refresh' => {
        doc    => 'indices-refresh',
        method => 'POST',
        path   => '{indices}/_refresh',
        qs     => ['ignore_indices'],
    },

    'indices.segments' => {
        doc  => 'indices-segments',
        path => '{indices}/_segments',
        qs   => [ 'ignore_indices', ],
    },

    'indices.snapshot_index' => {
        docs   => 'indices-gateway-snapshot',
        method => 'POST',
        path   => '{indices}/_gateway/snapshot',
        params => ['ignore_indices']
    },

    'indices.stats' => {
        doc  => 'indices-stats',
        path => '{indices}/_stats',
        qs   => [
            'all',              'clear',
            'completion',       'completion_fields',
            'docs',             'fielddata',
            'fielddata_fields', 'fields',
            'filter_cache',     'flush',
            'get',              'groups',
            'id_cache',         'ignore_indices',
            'indexing',         'merge',
            'refresh',          'search',
            'store',            'warmer'
        ],
    },

    'indices.status' => {
        doc  => 'indices-status',
        path => '{indices}/_status',
        qs   => [ 'ignore_indices', 'recovery', 'snapshot' ],
    },

    'indices.update_aliases' => {
        body => {
            required => 1,
            desc     => 'The definition of `actions` to perform'
        },
        doc    => 'indices-aliases',
        method => 'POST',
        path   => '_aliases',
        qs     => [ 'timeout', 'master_timeout' ],
    },

    'indices.validate_query' => {
        body => { desc => 'The query definition' },
        doc  => 'search-validate',
        path => '{indices|all-type}/{types}/_validate/query',
        qs   => [ 'explain', 'ignore_indices', 'q', 'source' ],
    },

);

for ( values %API ) {
    $_->{qs_handlers}  = qs_init( @{ $_->{qs} } );
    $_->{path_handler} = path_init( $_->{path} );
}

1;

__END__

# ABSTRACT: This class contains the spec for the Elasticsearch APIs

=head1 DESCRIPTION

All of the Elasticsearch APIs are defined in this role. The example given below
is the definition for the L<Elasticsearch::Client::Direct/index()> method:

    'index' => {
        body => {
            desc     => 'The document',
            required => 1
        },
        doc    => '/api/index_/',
        method => 'PUT',
        path   => '{index}/{type}/{id|blank}',
        qs     => [
            'consistency', 'op_type',     'parent',  'percolate',
            'refresh',     'replication', 'routing', 'timeout',
            'timestamp',   'ttl',         'version', 'version_type'
        ],
    },

These definitions can be used by different L<Elasticsearch::Role::Client>
implementations to provide distinct user interfaces.

=head1 METHODS

=head2 C<api()>

    $defn = $api->api($name);

The only method in this class is the C<api()> method which takes the name
of the I<action> and returns its definition.  Actions in the
C<indices> or C<cluster> namespace use the namespace as a prefix, eg:

    $defn = $e->api('indices.create');
    $defn = $e->api('cluster.node_stats');

=head1 SEE ALSO

=over

=item *

L<Elasticsearch::Util::API::Path>

=item *

L<Elasticsearch::Util::API::QS>

=item *

L<Elasticsearch::Client::Direct>

=back
