require 'sinatra/base'
require 'mongoid'
require 'sinatra/jsonp'
require 'newrelic_rpm'
require 'sidekiq'

class Impression
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :external_user_id, type: String
  field :external_product_id, type: String
  field :position, type: Integer
  field :anonymous, type: Boolean

  validates_presence_of :external_user_id, :external_product_id
end

class ApiImpressions < Sinatra::Base
  helpers Sinatra::Jsonp

  configure do
    set :environments, %w{development test production staging peixe}
    Mongoid.load!("config/mongoid.yml", ENV['RACK_ENV'])
  end

  # routes
  get '/' do
    # content_type :json
    data = {success: false, message: 'invalid endpoint', environment: settings.environment} #, db: "#{settings.db_host}:#{settings.db_port}/#{settings.db_base}"
    jsonp data
  end

  get '/impression/:user_id/:product_id/:position' do
    unless params[:user_id]=='0'
      anonymous = params[:user_id].match(/^hmrtmp/) ? 1 : 0
      impression_date = Time.now
      Impression.with(write: { w: 0 }).create(external_user_id: params[:user_id], external_product_id: params[:product_id], position: params[:position], anonymous: anonymous, created_at: impression_date)
      Sidekiq::Client.push('class' => 'ImpressionWorker', 'args' => [params[:user_id], params[:product_id], impression_date.utc.strftime("%FT%T.%3NZ")], 'queue' => "impression")
    end
    data = {success: true}
    jsonp data
  end


end

