
module Dav4rack

  class InterceptorResource < Resource
    attr_reader :path, :options
    
    def initialize(*args)
      super
      @root_paths = @options[:mappings].keys
      @mappings = @options[:mappings]
    end
        
    def children
      childs = @root_paths.find_all{|x|x =~ /^#{Regexp.escape(@path)}/}
      childs = childs.map{|a| child a.gsub(/^#{Regexp.escape(@path)}/, '').split('/').delete_if{|x|x.empty?}.first }.flatten
    end

    def collection?
      true if exist?
    end

    def exist?
      !@root_paths.find_all{|x| x =~ /^#{Regexp.escape(@path)}/}.empty?
    end
    
    def creation_date
      Time.now
    end

    def last_modified
      Time.now
    end
    
    def last_modified=(time)
      Time.now
    end

    def etag
      Digest::SHA1.hexdigest(@path)
    end

    def content_type
      'text/html'
    end

    def content_length
      0
    end

    def get(request, response)
      raise Forbidden
    end

    def put(request, response)
      raise Forbidden
    end
    
    def post(request, response)
      raise Forbidden
    end
    
    def delete
      raise Forbidden
    end
    
    def copy(dest)
      raise Forbidden
    end
  
    def move(dest)
      raise Forbidden
    end
    
    def make_collection
      raise Forbidden
    end

    def ==(other)
      path == other.path
    end

    def name
      ::File.basename(path)
    end

    def display_name
      ::File.basename(path.to_s)
    end
    
    def child(name, option={})
      new_path = path.dup
      new_path = '/' + new_path unless new_path[0,1] == '/'
      new_path.slice!(-1) if new_path[-1,1] == '/'
      name = '/' + name unless name[-1,1] == '/'
      new_path = "#{new_path}#{name}"
      new_public = public_path.dup
      new_public = '/' + new_public unless new_public[0,1] == '/'
      new_public.slice!(-1) if new_public[-1,1] == '/'
      new_public = "#{new_public}#{name}"
      if(key = @root_paths.find{|x| new_path =~ /^#{Regexp.escape(x.downcase)}\/?/})
        @mappings[key][:resource_class].new(new_public, new_path.gsub(key, ''), request, response, {:root_uri_path => key, :user => @user}.merge(options).merge(@mappings[key]))
      else
        self.class.new(new_public, new_path, request, response, {:user => @user}.merge(options))
      end
    end
    
    def descendants
      list = []
      children.each do |child|
        list << child
        list.concat(child.descendants)
      end
      list
    end

  end

end
