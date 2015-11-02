# slinked

This script provide a simple way how to "linking" the files in your repositories into defined locations in the system outside the repositories.

It's a simple way how to install (or integrate) the repository into the system.

This script needs a configuration files for each planned linking. The configuration file has to have the same name as the directory or the file with additional extension ".sln" (e.q.: slinked.sh.sln). The configuration file has to contain following format.

`/path/to/target/file|h=hostname|t=type`

Where `/path/to/target/file` is the target of linking.

Optional parameter h define hostname where (and only where) the rule are applied.

Optional parameter t define type of "linking" where
- s is symbolic link (default option)
- l is hard link (applied only on files)
- c is manual copy

Multiple "target lines" are allowed.

Configuration files can contain comments - begging with char # in the begging of the comment line.

See example file `slinked.sh.sln`.

## Usage:
```
usage: slinked.sh [-l link_type] [-d] [-f] [-t] [-h] [-r]
  -l link_type Set link_type as default type of linking instead of standard symlinking
  -d debuging mode
  -f force mode
  -t testing mode
  -r restore the origin files
  -h print help
```

@todo
- global configuration for linking in one file
- examples
