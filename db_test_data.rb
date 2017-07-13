require 'yaml'
require_relative 'validator'

def db_validation
  {
    database: {
      type: Hash,
      required: true,
      entry: {
        bootstrap: {
          type: String,
          required: true,
          example: 'bin/rails db:setup'
        },
        migrate: {
          type: String,
          required: true,
          example: 'bin/rails db:migrate'
        },
        migration_folders: {
          type: Array,
          entry: [{ type: String }],
          example: ['db/migrate', 'db/lhm']
        },
        host: {
          type: String,
          required: true,
          example: 'localhost'
        },
        user: {
          type: String,
          required: true,
          example: 'root'
        },
        password: {
          type: String,
          required: true,
          example: 'password'
         },
        database: {
          type: String,
          required: true,
          example: 'my_app_development'
        },
        vendor: {
          type: String,
          values: %w(mysql postgres sqlite),
          default: 'mysql',
          example: 'mysql'
        }
      }
    }
  }
end

def db_valid_config
  config=<<-EOF
  database:
    bootstrap: bin/rails db:setup db:test:prepare
    migrate: bin/rails db:migrate db:test:prepare
    host: mysql.authme.svc.cluster.local
    user: root
    password: ""
    database: authme_dev
    vendor: mysql
  EOF
  YAML.load(config)
end

def db_invalid_config
  { 'database' => { 'host' => 'localhost' } }
end
