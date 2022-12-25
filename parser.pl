#!/usr/bin/perl -w
use strict;
use warnings;
use DBI;
use DBD::Pg; 
use Getopt::Std;
our ($opt_d, $opt_c, $dbh);

getopts('dc');

my $dbname = 'postgres';
my $dbuser = 'postgres';
my $dbpass = 'postgres';
my $dbhost = 'localhost';

$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass, {AutoCommit => 1}) or die $!;

if ($opt_c) {
    create_tables();
    print "Tables recreated.\n" if $opt_d;
}

my %flags = (
    '<=' => 1, # прибытие сообщения (в этом случае за флагом следует адрес отправителя)
    '=>' => 1, # нормальная доставка сообщения
    '->' => 1, # дополнительный адрес в той же доставке
    '**' => 1, # доставка не удалась
    '==' => 1, # доставка задержана (временная проблема)
);

while(<STDIN>) {
    chomp;
    my @data = split(/\s+/, $_, 6);
    if (defined $data[3] 
        && $flags{$data[3]}) {
        if ($data[3] eq "<=") {
            my $id = '';
            if ($data[5] =~ m/\sid=(\S+)/) {
                $id = $1;
                save2message(
                    $data[0]." ".$data[1],
                    $data[2],
                    $id,
                    join(' ', @data[2..$#data])
                );
            } else {
                print "parse err: id not found in line $data[5]\n";
            }
        } else {
            save2log(
                $data[0]." ".$data[1],
                $data[2],
                $data[4],
                join(' ', @data[2..$#data])
            );
        }
    } else {
        # skip this generic log line
    }
}

# В таблицу message должны попасть только строки прибытия сообщения (с флагом <=). Поля таблицы
# должны содержать следующую информацию:
# created - timestamp строки лога
# id - значение поля id=xxxx из строки лога
# int_id - внутренний id сообщения
# str - строка лога (без временной метки)
sub save2message {
    my ($created, $int_id, $id, $str) = @_;
    print "message: $created, $int_id, $id, $str\n" if $opt_d;
    my $sth = $dbh->prepare('INSERT INTO message(created, int_id, id, str) VALUES (?,?,?,?)');
    return $sth->execute($created, $int_id, $id, $str);
}

# В таблицу log записываются все остальные строки:
# created - timestamp строки лога
# int_id - внутренний id сообщения
# str - строка лога (без временной метки)
# address - адрес получателя
sub save2log {
    my ($created, $int_id, $addr, $str) = @_;
    print "log: $created, $int_id, $addr, $str\n" if $opt_d;
    my $sth = $dbh->prepare('INSERT INTO log(created, int_id, address, str) VALUES (?,?,?,?)');
    return $sth->execute($created, $int_id, $addr, $str);
}

sub create_tables {
    $dbh->do('DROP TABLE IF EXISTS message');
    $dbh->do(<<__ENDSQL__);
CREATE TABLE message (
  created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  id VARCHAR NOT NULL,
  int_id CHAR(16) NOT NULL,
  str VARCHAR NOT NULL,
  status BOOL,
  CONSTRAINT message_id_pk PRIMARY KEY(id)
)
__ENDSQL__
    $dbh->do('DROP INDEX IF EXISTS message_created_idx, message_int_id_idx');
    $dbh->do('CREATE INDEX message_created_idx ON message (created)');
    $dbh->do('CREATE INDEX message_int_id_idx ON message (int_id)');
    $dbh->do('DROP TABLE IF EXISTS log');
    $dbh->do(<<__ENDSQL__);
CREATE TABLE log (
created TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
int_id CHAR(16) NOT NULL,
str VARCHAR,
address VARCHAR
)
__ENDSQL__
    $dbh->do('DROP INDEX IF EXISTS log_address_idx');
    $dbh->do('CREATE INDEX log_address_idx ON log USING hash (address)');
}

# vim: set et ts=4 sw=4 ai sr tw=78 backspace=indent,eol,start:
