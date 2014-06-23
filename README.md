# DbTools

A hasty utility to back up a data dependency between `mongo` and `postgres` and zip and store the backups in `G-Drive`.
Each `mongo` document contains a `lisp s-expression`, which can be dumped to a json format. 
This distribution comes with the hasty hack of two `SBCL` executables that will work on `linux` and `OS X`

## Usage
        
        Usage: db_tools [options]
            -c, --config config.yml          Contains config parameters
            -D, --data-dir dir               Directory for import/export
            -d, --days-old number_of_days    Delete backups that are so many days old
            -m, --models model               A comma separated list of one or more models
            -i, --import                     Import Data
            -x, --export                     Export Data (default)
            -I, --import-file file           Import input file (implied --import)
            -O, --output-file file           Export output file (implied --export)
            -j, --json                       Dump Models to json format
            -p, --pretty                     Pretty Model Export
            -M, --mongo                      The import/export operation will be performed on Mongo (default)
            -P, --postgres                   The import/export operation will be performed on Postgres
            -r, --remote                     Send backup to remote store (see config/db_tools.yml)
            -z, --zip                        GZip exported files
            -T, --template                   Dump configuration template to standard out
            -h, --help

## Contributing

1. Fork it ( http://github.com/robdbirch/db_tools/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
