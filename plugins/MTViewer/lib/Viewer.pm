package Viewer;
use strict;
use warnings;

use File::Spec;
use IO::All;
use URI;

use MT::CMS::Blog;

sub init_app {
    my $prepare_dynamic_publishing
        = \&MT::CMS::Blog::prepare_dynamic_publishing;

    no warnings 'redefine';
    *MT::CMS::Blog::prepare_dynamic_publishing = sub {
        my ( $cb, $blog, $cache, $conditional, $site_path, $site_url ) = @_;

        my $ret = $prepare_dynamic_publishing->(@_);

        my ( $htaccess_path, $mtview_server_url, $view_script_path,
            $blog_id );

        $htaccess_path = File::Spec->catfile( $site_path, ".htaccess" );

        $mtview_server_url = new URI($site_url);
        $mtview_server_url = $mtview_server_url->path();
        $mtview_server_url
            .= ( $mtview_server_url =~ m|/$| ? "" : "/" ) . "mtview.php";

        my $config = MT->config;
        $view_script_path = $config->AdminCGIPath;
        if ( $view_script_path !~ /\/$/ ) {
            $view_script_path .= '/';
        }
        $view_script_path .= $config->ViewScript;

        $blog_id = $blog->id;

        my $htaccess = io($htaccess_path)->slurp;
        my $before   = quotemeta($mtview_server_url) . '(\$2)?';
        $htaccess =~ s/$before/$view_script_path?blog_id=$blog_id/gm;
        $htaccess > io($htaccess_path);

        return $ret;
    };
}

1;
