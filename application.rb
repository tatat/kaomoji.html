# -*- coding: utf-8 -*-
  
require 'rubygems'
require 'sinatra/base'
require 'yaml'
require 'json'
require 'erb'
require 'dm-core'
require 'dm-migrations'
require 'dm-aggregates'
require 'dm-pager'
require 'models/kaomoji'

class Application < Sinatra::Base

  configure do
    set :config_dir, File.join(APP_ROOT, 'config')
    set :db, 'sqlite3://' + File.join(APP_ROOT, 'db', "#{settings.environment.to_s}.sqlite3")
    set :basic_authentication, YAML.load_file(File.join(settings.config_dir, 'basic_authentication.yml'))

    DataMapper::Model.raise_on_save_failure = true
    DataMapper.setup :default, settings.db
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end
  
  helpers do
    include Rack::Utils

    alias_method :h, :escape_html

    def kaomoji_format_for_json(record)
      {
        id: record.id,
        text: record.text.force_encoding("utf-8")
      }
    end

    def kaomoji_format_for_json_include_created_at(record)
      {
        id: record.id,
        text: record.text.force_encoding("utf-8"),
        created_at: record.created_at.to_time.to_i
      }
    end

    def respond_to_json(hash)
      if params[:callback].nil? || !params[:callback].is_a?(String)
        content_type :json
        hash.to_json
      else
        content_type :js
        callback = params[:callback].gsub(/\\/, '\\\\\\').gsub(/"/, '\\"')
        'this["%s"](%s);' % [callback, hash.to_json]
      end
    end

    def allow_origin!(*args)
      args << '*' if args.length == 0
      response.header['Access-Control-Allow-Origin'] = args.join(', ')
    end

    def is_html?()
      content_type = response.header['Content-Type']
      content_type.nil? || /^text\/html(?:;.+)?$/ =~ content_type
    end

    def is_true?(value)
      if value.is_a? String
        %w|1 true TRUE True T t yes YES Yes Y y|.include? value
      elsif value.is_a? Integer
        value == 1
      elsif value.is_a? TrueClass
        true
      else
        false
      end
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && settings.basic_authentication['users'].include?(@auth.credentials)
    rescue
      false
    end
  end

  post %r{^/create(?:\.json)?$} do
    protected!
    allow_origin!

    halt 400, respond_to_json({error: 'bad request'}) if params[:text].nil?

    begin
      record = Kaomoji.first_or_create({text: params[:text]}, {created_at: Time.now})
      respond_to_json({error: nil, result: kaomoji_format_for_json(record)})
    rescue DataMapper::SaveFailureError => err
      halt 500, respond_to_json({error: 'internal server error'})
    end
  end

  delete %r{^/delete/(.+?)(?:\.json)?$} do
    protected!
    allow_origin!

    record = Kaomoji.get(params[:captures].first)

    halt 404, respond_to_json({error: 'not found'}) if record.nil?
    halt 500, respond_to_json({error: 'internal server error'}) unless record.destroy

    respond_to_json({error: nil, result: kaomoji_format_for_json(record)})
  end

  get %r{^/benchmark(?:\.html)?$} do
    erb :benchmark, :layout => false, :locals => {
      records_json: Kaomoji.all(order: :text.asc).map {|record|
        kaomoji_format_for_json record
      }.to_json
    }
  end
  
  get %r{^(?:/|/(pagination|kaomoji)(?:\.([^/]+))?)$} do |type, format|
    allow_origin!

    query = {order: :id.desc}
    
    options = {
      query: request.env['rack.request.query_hash'],
      path: request.path,
      fullpath: request.fullpath,
      filter: ''
    }

    if params[:filter].is_a?(String) && !(/^([_%]+)?$/ =~ params[:filter])
      # DataMapperでSQLiteのLIKEのエスケープどうやるの..
      options[:filter] = params[:filter]
      query[:text.like] = "%#{params[:filter]}%"
    end

    if params[:since].is_a?(String) && /^[0-9]+$/ =~ params[:since]
      options[:since] = query[:created_at.gt] = Time.at(params[:since].to_i)
    end

    is_pagination = type.nil? || type == 'pagination'

    pagination_params = {
      page: params[:page],
      per_page: params[:per_page] || 200
    }

    records = Kaomoji.all(query)

    case format
    when 'html', nil
      locals = {
        options: options,
        modified: Kaomoji.max(:created_at).to_time
      }

      if is_pagination
        locals[:records] = records.page(pagination_params)
        erb :pagination, :layout => false, :locals => locals
      else
        locals[:records] = records
        erb :index, :layout => false, :locals => locals
      end
    when 'json'
      result = {modified: Kaomoji.max(:created_at).to_time.to_i}

      if is_pagination
        records = records.page(pagination_params)
        result.merge!({
          current: records.pager.current_page,
          total: records.pager.total_pages
        })
      end

      format_fn = is_true?(params[:include_created_at]) ?
        Proc.new { |record| kaomoji_format_for_json_include_created_at record } :
        Proc.new { |record| kaomoji_format_for_json record }

      result[:records] = records.map(&format_fn)
      respond_to_json(result)
    when 'txt', 'text'
      content_type :text
      records = records.page(pagination_params) if is_pagination
      records.map {|record| record.text.force_encoding("utf-8") }.join("\n")
    else
      raise Sinatra::NotFound
    end
  end

  get %r{^/([^/\.]+)(?:\.([^/]+))?$} do |id, format|
    allow_origin!

    record = case id
    when 'random'
      Kaomoji.first(offset: rand(Kaomoji.count))
    else
      Kaomoji.get(id)
    end
    
    case format
    when 'html', nil
      raise Sinatra::NotFound if record.nil?
      erb :single, :layout => false, :locals => {record: record}
    when 'json'
      halt 404, respond_to_json({error: 'not found'}) if record.nil?

      format_method = is_true?(params[:include_created_at]) ?
        :kaomoji_format_for_json_include_created_at :
        :kaomoji_format_for_json

      respond_to_json({record: send(format_method, record)})
    when 'txt', 'text'
      content_type :text
      halt 404, 'not found' if record.nil?
      record.text.force_encoding("utf-8")
    else
      raise Sinatra::NotFound
    end
  end

  # error
  
  not_found do
    return response.body.first unless is_html?
    erb :"404", :locals => {title: 'Not found'}
  end
  
  error do
    return response.body.first unless is_html?
    erb :"500", :locals => {title: 'Internal server error'}
  end
end
