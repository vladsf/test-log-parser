#!/usr/bin/perl
# vim: set et ts=4 sw=4 ai sr tw=78 backspace=indent,eol,start:
use Mojolicious::Lite -signatures;
use DBI;
use DBD::Pg; 
our ($dbh);

my $dbname = 'postgres';
my $dbuser = 'postgres';
my $dbpass = 'postgres';
my $dbhost = 'localhost';

$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass, {AutoCommit => 1}) or die $!;

get '/' => 'form';

# PUT  /address
# POST /address?_method=PUT
put '/address' => sub ($c) {

    my $addr = $c->param('addr');
    if ($addr) {
        my $rows1 = get_rows1($addr);
        my $rows2 = get_rows2($addr);
        my $found1 = scalar(@{$rows1});
        my $found2 = scalar(@{$rows2});
        $c->stash(rows1 => $rows1) if $found1 > 0;
        $c->stash(rows2 => $rows2) if $found2 > 0;
        $c->stash(found1 => $found1);
        $c->stash(found2 => $found2);
        if ($found1 + $found2 > 0) {
            $c->render(template => 'form');
        } else {
            $c->flash(confirmation => "'$addr' not found.");
            $c->redirect_to('form');
        }
    } else {
        $c->flash(confirmation => "Empty address.");
        $c->redirect_to('form');
    }
};

sub get_rows2 {
    my ($addr) = shift;
    my $sth = $dbh->prepare(<<__ENDSQL__);
select created, str from log
where address = ?
order by created
limit 100
__ENDSQL__
    $sth->execute($addr);
    return $sth->fetchall_arrayref();
}

sub get_rows1 {
    my ($addr) = shift;
    my $sth = $dbh->prepare(<<__ENDSQL__);
select created, str from log
where address = ?
order by int_id
limit 100
__ENDSQL__
    $sth->execute($addr);
    return $sth->fetchall_arrayref();
}

app->start;
__DATA__

@@ form.html.ep
<!DOCTYPE html>
<html>
<head>
<style>
table {
  border-collapse: collapse;
}
th, td {
  border: 1px solid black;
}
</style>
</head>
  <body>
    %= form_for address => begin
      %= search_field addr => 'address'
      %= submit_button 'Search'
    % end
    % if (my $confirmation = flash 'confirmation') {
    <p><%= $confirmation %></p>
    % }
    % if (my $rows1 = stash 'rows1') {
    <h2>Table 1 (found <%= stash 'found1' %>)</h2>
    <table>
    <tr><th>created</th><th>str</th></tr>
    % for my $row (@$rows1) {
    <tr><td><%= $row->[0] %></td><td><%= $row->[1] %></td></tr>
    % }
    </table>
    % }
    % if (my $rows2 = stash 'rows2') {
    <h2>Table 2 (found <%= stash 'found2' %>)</h2>
    <table>
    <tr><th>created</th><th>str</th></tr>
    % for my $row (@$rows2) {
    <tr><td><%= $row->[0] %></td><td><%= $row->[1] %></td></tr>
    % }
    </table>
    % }
  </body>
</html>
