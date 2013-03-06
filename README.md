# Repository

Build a repository, using Chef.

## Supported 

Currently only providing apt based repositories

## Usage (easy)

Setup the `incoming` repository by adding `repository::incoming` to the run list.
This will create a directory (by default at /srv/repository_incoming). Drop 
packages there and run Chef. Chef will automatically add them into the 
repository. Yay!

### Incoming related attributes

```ruby
default[:repository][:incoming][:codename] = node.lsb.codename
default[:repository][:incoming][:name] = 'incoming'
default[:repository][:incoming][:architecture] = 'amd64'
default[:repository][:incoming][:label] = 'Incoming Repository'
default[:repository][:incoming][:description] = 'Incoming repository for dropped off packages'
default[:repository][:incoming][:directory] = '/srv/repository_incoming'
default[:repository][:incoming][:multi_version] = true
default[:repository][:incoming][:enable_locally] = true
```

## Usage (involved)

### Adding repository

You can add your own repository components using the `repos` array attribute. For
example:

```ruby
node.set[:repository][:repos] = [
  :name => 'my_packages',
  :codename => 'precise',
  :architecture => %w(amd64),
  :multi_version => true
]
```

or via the LWRP:

```ruby
repository 'my_packages' do
  codename 'precise'
  architecture %w(amd64)
  multi_version => true
end
```

### Adding Packages

Add packages to the repository by using the `repository_package` LWRP:

```ruby
repository_package '/path/to/my/cool/package.deb' do
  repository 'my_packages'
end
```

## Keys

Keys are required to sign packages and repository files. They can be provided
via data bag, encrypted data bag, or automatically generated on the node. By
default the keys will be auto generated using the `gpg` cookbook.

### Data bag

* To enable data bag based keys: `node.set[:repository][:pgp_data_bag] = true`
* To enable encrypted data bag based keys: `node.set[:repository][:pgp_data_bag] = 'encrypted'`

Encrypted data bags will use the default secret for decryption.

### Data bag structure

```javascript
{
  "id": "pgp",
  "email": "user@example.com",
  "private": "PRIVATE KEY CONTENTS",
  "public": "PUBLIC KEY CONTENTS"
}
```

## Infos
* Repo: https://github.com/hw-cookbooks/repository
* IRC: Freenode @ #heavywater
