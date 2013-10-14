actions :add, :remove
default_action :add

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String
attribute :repository, :kind_of => String, :required => true
attribute :signing_key, :kind_of => String
attribute :signature_type, :kind_of => String, :default => 'origin', :required => true
