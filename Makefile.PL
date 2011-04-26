use inc::Module::Install;

# Define metadata
name           'Web-SoundCloud-Fetch';
all_from       'lib/Web/SoundCloud/Fetch.pm';

# Specific dependencies
requires       'namespace::autoclean'  => 0;
requires       'MooseX::Declare'       => 0;
requires       'MooseX::Types';
requires       'MooseX::Types::URI';
requires       'MooseX::Types::JSON';
requires 'HTML::TreeBuilder';
requires 'HTML::TreeBuilder::XPath';
requires 'WWW::Mechanize::TreeBuilder';

test_requires  'Test::Most'  => 0;

WriteAll;
