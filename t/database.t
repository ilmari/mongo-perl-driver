use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use MongoDB::Timestamp; # needed if db is being run as master

use MongoDB;

use lib "t/lib";
use MongoDBTest '$conn';

plan tests => 13;

isa_ok($conn, 'MongoDB::MongoClient');

my $db = $conn->get_database('test_database');
$db->drop;

isa_ok($db, 'MongoDB::Database');

$db->drop;

is(scalar $db->collection_names, 0, 'no collections');
my $coll = $db->get_collection('test');
is($coll->count, 0, 'collection is empty');

is($coll->find_one, undef, 'nothing for find_one');

my $id = $coll->insert({ just => 'another', perl => 'hacker' });

is(scalar $db->collection_names, 2, 'test and system.indexes');
ok((grep { $_ eq 'test' } $db->collection_names), 'collection_names');
is($coll->count, 1, 'count');
is($coll->find_one->{perl}, 'hacker', 'find_one');
is($coll->find_one->{_id}->value, $id->value, 'insert id');

my $result = $db->run_command({ foo => 'bar' });
ok ($result =~ /no such cmd/, "run non-existent command: $result");

# getlasterror
SKIP: {
    my $admin = $conn->get_database('admin');
    my $buildinfo = $admin->run_command({buildinfo => 1});

    #skip "MongoDB 1.5+ needed", 1 if $buildinfo->{version} =~ /(0\.\d+\.\d+)|(1\.[1234]\d*.\d+)/;
    #my $result = $db->last_error({w => 20, wtimeout => 1});
    #is($result, 'timed out waiting for slaves', 'last error timeout');

    skip "MongoDB 1.5+ needed", 2 if $buildinfo->{version} =~ /(0\.\d+\.\d+)|(1\.[1234]\d*.\d+)/;

    my $result = $db->last_error({fsync => 1});
    is($result->{ok}, 1);
    is($result->{err}, undef);
}


END {
    if ($conn) {
        $conn->get_database( 'foo' )->drop;
    }
    if ($db) {
        $db->drop;
    }
}
