# -*- coding: utf-8 -*-
#
# graphviz.rb - embed image from graphviz
#
# Copyright (C) 2010, tamoot <tamoot+tdiary@gmail.com>
# You can redistribute it and/or modify it under GPL2.
#

require 'digest/md5'
require 'tempfile'

def graphviz(dot_string, option = {})
   default = {:format => :jpg}
   
   # option
   img_attr = default.dup
   img_attr.merge!(:width  => option[:width])  if !option[:width].nil?  && option[:width].to_i  > 0
   img_attr.merge!(:height => option[:height]) if !option[:height].nil? && option[:height].to_i > 0
   img_attr.merge!(:alt    => option[:alt])    if !option[:alt].nil?
   img_attr.merge!(:class  => option[:class])  if !option[:class].nil?
   img_attr_str = img_attr.collect{|k, v| "#{k}=\"#{v}\"" }.join(' ')
   
   # graphviz process
   img_src_url = Graphviz::Cache::read(graphviz_conf, dot_string)
   begin
      img_src_url = Graphviz::Dot.new(graphviz_conf, dot_string).export(img_attr) if img_src_url.nil? || img_src_url == ''
   rescue StandardError => e
      return e.message
   end

   %Q|<img src="#{graphviz_conf.img_uri}/#{img_src_url}" #{img_attr_str}>|
end

add_conf_proc( 'graphviz', 'Graphviz' ) do
   if @mode == 'saveconf' then
      @conf['graphviz.dot.path'] = @cgi.params['graphviz.dot.path'][0]
      @conf['graphviz.img.uri']  = @cgi.params['graphviz.img.uri'][0]
      @conf['graphviz.img.path'] = @cgi.params['graphviz.img.path'][0]
   end

   <<-HTML
   <h3 class="subtitle"><i>dot</i> Command Path</h3>
   <p><input name="graphviz.dot.path" value="#{h @conf['graphviz.dot.path']}" size="70"></p>
   <p>Example)</p>
   <p>Windows: C:\\\\graphviz\\\\bin\\\\dot.exe</p>
   <p>Other: /usr/bin/dot</p>
   <h3 class="subtitle">Image URI</h3>
   <p><input name="graphviz.img.uri" value="#{h @conf['graphviz.img.uri']}" size="70"></p>
   <p>Example)</p>
   <p>/diary/graphviz/ => #{h '<img src="/diary/graphviz/hogehoge.jpg"> '}</p>
   <h3 class="subtitle">Image Path(Absolute)</h3>
   <p><input name="graphviz.img.path" value="#{h @conf['graphviz.img.path']}" size="70"></p>
   <p>Output of <i>dot</i> command.</p>
   <p>Example)</p>
   <p>/home/user/tdiary/graphviz/</p>
   HTML
end

def graphviz_conf
   @graphviz_conf_proc ||= Proc.new do |key|
      @conf[key]
   end
   def @graphviz_conf_proc.dot_path 
      self.call('graphviz.dot.path')
   end
   def @graphviz_conf_proc.img_path
      self.call('graphviz.img.path')
   end
   def @graphviz_conf_proc.img_uri
      self.call('graphviz.img.uri')
   end
   @graphviz_conf_proc
end

module ::Graphviz
   class Cache
      def self.read(cache, dot_string)
         digest = Digest::MD5.hexdigest(dot_string)
         Dir::glob("#{cache.img_path}").grep(/#{digest}/).first
      end
   end
   
   class Dot
      attr_reader :dot_string, :g_conf
      
      def initialize(conf, dot_string)
         @dot_string = dot_string
         @g_conf       = conf
      end
      
      def export(option = {:format => :jpg})
         digest = Digest::MD5.hexdigest(@dot_string)
         img_file = "#{digest}.#{option[:format].to_s}"
         img_path = "#{g_conf.img_path}/#{img_file}"
         begin
            dot_file = Tempfile.new(digest)
            dot_file.puts @dot_string
            dot_file.flush
            stdout = `#{g_conf.dot_path} -T#{option[:format].to_s} #{dot_file.path} -o #{img_path}`
            raise StandardError.new("code=#{$?.to_i / 256}, #{stdout}") if stdout != "" || $?.to_i / 256 != 0
         ensure
            dot_file.close
            dot_file.unlink
         end
         img_file
      end
   end
end


# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:
# vim: ts=3
