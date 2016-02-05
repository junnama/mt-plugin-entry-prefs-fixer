package EntryPrefsFixer::Callbacks;

use strict;
use warnings;

sub _set_entry_prefs {
    my ( $cb, $obj ) = @_;
    my $app = MT->instance();
    if ( ref $app eq 'MT::App::CMS' ) {
        if (! __admin() ) {
            return 1;
        }
        if ( $app->mode eq 'save_entry_prefs' ) {
            require MT::Entry;
            my $type = $app->param( '_type' );
            my $col = $type . '_prefs';
            my $default = $obj->$col;
            require MT::Permission;
            my @perms = MT::Permission->load( { blog_id => $obj->blog_id,
                                                author_id => { not => $obj->author_id } } );
            for my $perm ( @perms ) {
                if ( $type eq 'page' ) {
                    $perm->page_prefs( $default );
                } else {
                    $perm->entry_prefs( $default );
                }
                $perm->save or die $perm->errstr;
            }
            if (! MT::Entry->has_column( 'prefs' ) ) {
                return 1;
            }
            $default =~ s/\|$//;
            my @entries = MT->model( $type )->load( { blog_id => $obj->blog_id } );
            for my $entry ( @entries ) {
                if ( $entry->prefs ne $default ) {
                    $entry->prefs( $default );
                    $entry->save or die $entry->errstr;
                }
            }
        }
    }
    1;
}

sub _hide_entry_prefs {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( __admin() ) {
        return 1;
    }
    my $nodes = $tmpl->getElementsByName( 'display_options' );
    my $node = @$nodes[ 0 ];
    $node->innerHTML( '' );
}

sub __admin {
    my $app = MT->instance();
    my $perm = $app->user->is_superuser;
    if (! $perm ) {
        if ( $app->blog ) {
            my $class = $app->blog->class;
            my $permission = 'can_administer_' . $class;
            $perm = $app->user->permissions( $app->blog->id )->$permission;
        }
    }
    if (! $perm ) {
        return undef;
    }
    return 1;
}

1;