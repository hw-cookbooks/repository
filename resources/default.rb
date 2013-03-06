actions :create, :remove
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :type, :equal_to => [:apt, 'apt'], :default => :apt
attribute :component, :kind_of => String
attribute :codename, :kind_of => String, :required => true
attribute :architecture, :kind_of => [Array, String], :required => true
attribute :label, :kind_of => String, :default => 'Repository'
attribute :description, :kind_of => String, :default => 'APT Repository'
attribute :component_label, :kind_of => String
attribute :component_description, :kind_of => String
attribute :multi_version, :kind_of => [TrueClass, FalseClass], :default => true
