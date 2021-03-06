require 'redis'
require 'redis_support'
require 'resque'
require 'resque_scheduler'

module MapRedus
  include RedisSupport
  
  class InvalidProcess < NotImplementedError
    def initialize; super("MapRedus QueueProcess: need to have perform method defined");end
  end
  
  class ProcessSpecificationError < InvalidProcess
    def initialize; super("MapRedus Process: need to have the specification defined");end
  end

  class InvalidMapper < NotImplementedError
    def initialize; super("MapRedus Mapper: need to have map method defined");end
  end

  class InvalidReducer < NotImplementedError
    def initialize; super("MapRedus Reducer: need to have reduce method defined");end
  end

  class InvalidInputStream < NotImplementedError
    def initialize; super("MapRedus InputStream: need to have scan method defined");end
  end

  class InvalidProcess < NotImplementedError
    def initialize; super("MapRedus Process Creation Failed: Specifications were not specified");end
  end

  class RecoverableFail < StandardError
    def initialize; super("MapRedus Operation Failed: but it is recoverable") ;end
  end
  
  # All Queue Processes should have a function called perform
  # ensuring that when the class is put on the resque queue it can perform its work
  # 
  # Caution: defines redis, which is also defined in RedisSupport
  # 
  class QueueProcess
    def self.queue; :mapredus; end
    def self.perform(*args); raise InvalidProcess; end
  end

  # TODO: When you send work to a worker using a mapper you define, 
  # the worker won't have that class name defined, unless it was started up
  # with the class loaded
  #
  def register_reducer(klass); end;
  def register_mapper(klass); end;

  class Helper
    # resque helpers defines
    #   redis
    #   encode
    #   decode
    #   classify
    #   constantize
    #
    # This is extended here because we want to use the encode and decode function
    # when we interact with resque queues
    extend Resque::Helpers

    # Defines a hash by taking the absolute value of ruby's string
    # hash to rid the dashes since redis keys should not contain any.
    #
    # key - The key to be hashed.
    #
    # Examples
    #
    #   Support::key_hash( key )
    #   # => '8dd8hflf8dhod8doh9hef'
    #
    # Returns the hash.
    def self.key_hash( key )
      key.to_s.hash.abs.to_s(16)
    end

    # Returns the classname of the namespaced class.
    #
    # The full name of the class.
    #
    # Examples
    #
    #   Support::class_get( Super::Long::Namespace::ClassName )
    #   # => 'ClassName'
    #
    # Returns the class name.
    def self.class_get(string)
      constantize(string)
    end
  end 
end

require 'mapredus/keys'
require 'mapredus/filesystem'
require 'mapredus/master'
require 'mapredus/mapper'
require 'mapredus/reducer'
require 'mapredus/finalizer'
require 'mapredus/support'
require 'mapredus/outputter'
require 'mapredus/inputter'
require 'mapredus/default_classes'
require 'mapredus/process'
