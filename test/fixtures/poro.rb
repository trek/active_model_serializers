verbose = $VERBOSE
$VERBOSE = nil
class Model < ActiveModelSerializers::Model
  FILE_DIGEST = Digest::MD5.hexdigest(File.open(__FILE__).read)

  ### Helper methods, not required to be serializable

  # Convenience when not adding @attributes readers and writers
  def method_missing(meth, *args)
    if meth.to_s =~ /^(.*)=$/
      attributes[$1.to_sym] = args[0]
    elsif attributes.key?(meth)
      attributes[meth]
    else
      super
    end
  end

  def cache_key_with_digest
    "#{cache_key}/#{FILE_DIGEST}"
  end
end

class Profile < Model
end

class ProfileSerializer < ActiveModel::Serializer
  attributes :name, :description

  def arguments_passed_in?
    instance_options[:my_options] == :accessible
  end
end

class ProfilePreviewSerializer < ActiveModel::Serializer
  attributes :name
end

Post     = Class.new(Model)
Like     = Class.new(Model)
Author   = Class.new(Model)
Bio      = Class.new(Model)
Blog     = Class.new(Model)
Role     = Class.new(Model)
User     = Class.new(Model)
Location = Class.new(Model)
Place    = Class.new(Model)
Tag      = Class.new(Model)
VirtualValue = Class.new(Model)
Comment = Class.new(Model) do
  # Uses a custom non-time-based cache key
  def cache_key
    "#{self.class.name.downcase}/#{self.id}"
  end
end

module Spam; end
Spam::UnrelatedLink = Class.new(Model)

PostSerializer = Class.new(ActiveModel::Serializer) do
  cache key: 'post', expires_in: 0.1, skip_digest: true
  attributes :id, :title, :body

  has_many :comments
  belongs_to :blog
  belongs_to :author

  def blog
    Blog.new(id: 999, name: 'Custom blog')
  end

  def custom_options
    instance_options
  end
end

SpammyPostSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id
  has_many :related

  def self.root_name
    'posts'
  end
end

CommentSerializer = Class.new(ActiveModel::Serializer) do
  cache expires_in: 1.day, skip_digest: true
  attributes :id, :body

  belongs_to :post
  belongs_to :author

  def custom_options
    instance_options
  end
end

AuthorSerializer = Class.new(ActiveModel::Serializer) do
  cache key: 'writer', skip_digest: true
  attribute :id
  attribute :name

  has_many :posts
  has_many :roles
  has_one :bio
end

RoleSerializer = Class.new(ActiveModel::Serializer) do
  cache only: [:name], skip_digest: true
  attributes :id, :name, :description, :slug

  def slug
    "#{name}-#{id}"
  end

  belongs_to :author
end

LikeSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :time

  belongs_to :likeable
end

LocationSerializer = Class.new(ActiveModel::Serializer) do
  cache only: [:place], skip_digest: true
  attributes :id, :lat, :lng

  belongs_to :place

  def place
    'Nowhere'
  end
end

PlaceSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id, :name

  has_many :locations
end

BioSerializer = Class.new(ActiveModel::Serializer) do
  cache except: [:content], skip_digest: true
  attributes :id, :content, :rating

  belongs_to :author
end

BlogSerializer = Class.new(ActiveModel::Serializer) do
  cache key: 'blog'
  attributes :id, :name

  belongs_to :writer
  has_many :articles
end

PaginatedSerializer = Class.new(ActiveModel::Serializer::CollectionSerializer) do
  def json_key
    'paginated'
  end
end

AlternateBlogSerializer = Class.new(ActiveModel::Serializer) do
  attribute :id
  attribute :name, key: :title
end

CustomBlogSerializer = Class.new(ActiveModel::Serializer) do
  attribute :id
  attribute :special_attribute

  has_many :articles
end

CommentPreviewSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id

  belongs_to :post
end

AuthorPreviewSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :posts
end

PostPreviewSerializer = Class.new(ActiveModel::Serializer) do
  def self.root_name
    'posts'
  end

  attributes :title, :body, :id

  has_many :comments, serializer: CommentPreviewSerializer
  belongs_to :author, serializer: AuthorPreviewSerializer
end

PostWithTagsSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :tags
end

PostWithCustomKeysSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :comments, key: :reviews
  belongs_to :author, key: :writer
  has_one :blog, key: :site
end

VirtualValueSerializer = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :reviews, virtual_value: [{ id: 1 }, { id: 2 }]
  has_one :maker, virtual_value: { id: 1 }

  def reviews
  end

  def maker
  end
end

Spam::UnrelatedLinkSerializer = Class.new(ActiveModel::Serializer) do
  cache only: [:id]
  attributes :id
end
$VERBOSE = verbose
