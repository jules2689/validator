validator

# validator.rb

This class can accept a `validations` hash on initialize, and then validate configs.

### example
```ruby
 host_validation = {
    config: {
      type: Hash,
      required: true,
      entry: {
        host: {
          type: String,
          required: true,
          matches: [:ip, :host]
        },
        host2: {
          type: String,
          matches: [:ip, :host]
        }
      }
    }
  }
  
  example_config =   { 'config' => { 'host' => '192.168.1.1' } }
  v = Validator.new(host_validation)
  v.validate!(example_config)
  v.valid? # true
  
  example_config_2 =   { 'config' => { 'host' => 'no_match' } }
  v2 = Validator.new(host_validation)
  v2.validate!(example_config_2)
  v2.valid? # false
  v2.errors # {:host=>["must match a regex for one of (ip, host), but no_match did not"]}
  
  example_config_3 =   { 'config' => { 'host2' => 'no_match' } }
  v3 = Validator.new(host_validation)
  v3.validate!(example_config_3)
  v3.valid? # false
  v3.errors # :host=>["was required", "must match a regex for one of (ip, host), but  did not"], :host2=>["must match a regex for one of (ip, host), but no_match did not"]}
  ```
  
  To see tests run, run `ruby test`
  
  ## Docs
  
  Run `ruby docs`. We can also parse the validations to generate schema examples for docs.
```
~/src/github.com/jules2689/validator(master*) ➜ ruby docs
---
database:
  bootstrap: 'bin/rails db:setup # (required)'
  migrate: 'bin/rails db:migrate # (required)'
  migration_folders:
  - 'db/migrate # (optional)'
  - 'db/lhm # (optional)'
  host: 'localhost # (required)'
  user: 'root # (required)'
  password: 'password # (required)'
  database: 'my_app_development # (required)'
  vendor: 'mysql # (optional), must be one of mysql, postgres, sqlite, default is mysql'
```
