actions :add, :remove
default_action :add

attribute :path, kind_of: String
attribute :repository, kind_of: String, required: true
