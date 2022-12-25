# test-log-parser
Have Docker, perl, DBI, DBD::Pg installed.
Start up pogres container, load `out` file with the parser, run the script 
with web search interface.

```
$ docker run --name test-postgres -e POSTGRES_PASSWORD=postgres -d postgres
$ chmod 755 ./parser.pl 
$ cat out |./parser.pl -c -d
$ chmod 755 ./mojo.pl 
$ ./mojo.pl daemon -l http://*:8080
```

Open http://127.0.0.1:8080/
